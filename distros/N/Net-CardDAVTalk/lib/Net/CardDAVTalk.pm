package Net::CardDAVTalk;

use 5.006;
use strict;
use warnings FATAL => 'all';


use Net::DAVTalk;
use base qw(Net::DAVTalk);

use Carp;
use Text::VCardFast qw(vcard2hash);
use XML::Spice;
use URI::Escape qw(uri_unescape);
use Net::CardDAVTalk::VCard;
use Data::Dumper;


=head1 NAME

Net::CardDAVTalk - A library for talking to CardDAV servers

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

This module maps from CardDAV to an old version of the FastMail API.
It's mostly useful as an example of how to talk CardDAV and for the
Cyrus IMAP test suite Cassandane.

    use Net::CardDAVTalk;

    my $foo = Net::CardDAVTalk->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 $class->new()

Takes the same arguments as Net::DAVTalk and adds the single
namespace:

    C => 'urn:ietf:params:xml:ns:carddav'

=cut

sub new {
  my ($Class, %Params) = @_;

  $Params{homesetns} = 'C';
  $Params{homeset} = 'addressbook-home-set';
  $Params{wellknown} = 'carddav';

  my $Self = $Class->SUPER::new(%Params);

  $Self->ns(C => 'urn:ietf:params:xml:ns:carddav');
  $Self->ns(CY => 'http://cyrusimap.org/ns/');

  return $Self;
}

# Address book methods {{{

=head2 $self->NewAddressBook($Path, %Args)

Creates a new addressbook collection.  Requires the full
path (unlike Net::CalDAVTalk, which creates paths by UUID)
and takes a single argument, the name:

e.g.

    $CardDAV->NewAddressBook("Default", name => "Addressbook");

=cut

sub NewAddressBook {
  my ($Self, $Path, %Args) = @_;

  $Path || confess 'New address book path not specified';

  $Self->Request(
    'MKCOL',
    "$Path/",
    x('D:mkcol', $Self->NS(),
      x('D:set',
        x('D:prop',
          x('D:resourcetype',
            x('D:collection'),
            x('C:addressbook'),
          ),
          x('D:displayname', $Args{name}),
        ),
      ),
    ),
  );

  return $Path;
}

=head2 $self->DeleteAddressBook($Path)

Deletes the addressbook at the given path

e.g.

    $CardDAV->DeleteAddressBook("Shared");

=cut

sub DeleteAddressBook {
  my ($Self, $Path) = @_;

  $Path || confess 'Delete address book path not specified';

  $Self->Request(
    'DELETE',
    "$Path/"
  );

  return 1;
}

=head2 $self->UpdateAddressBook($Path, %Args)

Like 'new', but for an existing addressbook.  For now, can only change
the name.

e.g.

    $CardDAV->UpdateAddressBook("Default", name => "My Happy Addressbook");

=cut

sub UpdateAddressBook {
  my ($Self, $Path, %Args) = @_;

  $Path || confess 'Update address book path not specified';

  my @Params;

  if (defined $Args{name}) {
    push @Params, x('D:displayname', $Args{name});
  }

  return undef unless @Params;

  $Self->Request(
    'PROPPATCH',
    "$Path/",
    x('D:propertyupdate', $Self->NS(),
      x('D:set',
        x('D:prop',
          @Params,
        ),
      ),
    ),
  );

  return 1;
}

=head2 $self->GetAddressBook($Path, %Args)

Calls 'GetAddressBooks' with the args, and greps for the one with the
matching path.

e.g.

    my $AB = $CardDAV->GetAddressBook("Default");

=cut

sub GetAddressBook {
  my ($Self, $Id, %Args) = @_;

  my $Data = $Self->GetAddressBooks(%Args);

  die "Can't read data" unless $Data;
  my ($AddressBook) = grep { $_->{path} eq $Id } @$Data;

  return $AddressBook;
}

=head2 $self->GetAddressBooks(%Args)

Get all the addressbooks on the server.  If the arg 'Sync' is true,
also requests the DAV:sync-token and returns it as syncToken in the
addressbook hash.

Returns an arrayref of hashrefs

e.g.

    my $ABs = $CardDAV->GetAddressBooks(Sync => 1);
    foreach my $AB (@$ABs) {
        say "$AB->{path}: $AB->{name}";
    }

=cut

sub GetAddressBooks {
  my ($Self, %Args) = @_;

  my @props;
  if ($Args{Sync}) {
    push @props, x('D:sync-token');
  }

  my $Response = $Self->Request(
    'PROPFIND',
    '',
    x('D:propfind', $Self->NS(),
      x('D:prop',
        x('D:displayname'),
        x('D:resourcetype'),
        x('D:current-user-privilege-set'),
        x('D:acl'),
        @props,
      ),
    ),
    Depth => 1,
  );

  my @AddressBooks;

  my $NS_C = $Self->ns('C');
  my $NS_D = $Self->ns('D');
  my $NS_CY = $Self->ns('CY');
  foreach my $Response (@{$Response->{"{$NS_D}response"} || []}) {
    my $HRef = $Response->{"{$NS_D}href"}{content}
      || next;
    my $Path = $Self->_unrequest_url($HRef);

    foreach my $Propstat (@{$Response->{"{$NS_D}propstat"} || []}) {
      next unless $Propstat->{"{$NS_D}prop"}{"{$NS_D}resourcetype"}{"{$NS_C}addressbook"};

      # XXX - this is really quite specific and probably wrong-namespaced...
      my $Perms = $Propstat->{"{$NS_D}prop"}{"{$NS_D}current-user-privilege-set"}{"{$NS_D}privilege"};

      my @ShareWith;
      my $ace = $Propstat->{"{$NS_D}prop"}{"{$NS_D}acl"}{"{$NS_D}ace"};
      $ace = [] unless ($ace and ref($ace) eq 'ARRAY');
      foreach my $Acl (@$ace) {
        next if $Acl->{"{$NS_D}protected"};  # ignore admin ACLs
        my $user = uri_unescape($Acl->{"{$NS_D}principal"}{"{$NS_D}href"}{content} // '');
        next unless $user =~ m{^/dav/principals/user/([^/]+)};
        my $email = $1;
        next if $email eq 'admin';
        my %ShareObject = (
          email => $email,
          mayAdmin => $JSON::false,
          mayWrite => $JSON::false,
          mayRead => $JSON::false,
        );
        foreach my $item (@{$Acl->{"{$NS_D}grant"}{"{$NS_D}privilege"}}) {
          $ShareObject{'mayAdmin'} = $JSON::true if $item->{"{$NS_CY}admin"};
          $ShareObject{'mayWrite'} = $JSON::true if $item->{"{$NS_D}write-content"};
          $ShareObject{'mayRead'} = $JSON::true if $item->{"{$NS_D}read"};
        }

        push @ShareWith, \%ShareObject;
      }

      my %AddressBook = (
        href       => $HRef,
        path       => $Path,
        name       => ($Propstat->{"{$NS_D}prop"}{"{$NS_D}displayname"}{content} || ''),
        isReadOnly => (grep { exists $_->{"{$NS_D}write-content"} } @{$Perms || []}) ? $JSON::false : $JSON::true,
        mayRead    => (grep { exists $_->{"{$NS_D}read"} } @{$Perms || []}) ? $JSON::true : $JSON::false,
        mayWrite   => (grep { exists $_->{"{$NS_D}write-content"} } @{$Perms || []}) ? $JSON::true : $JSON::false,
        mayAdmin   => (grep { exists $_->{"{$NS_CY}admin"} } @{$Perms || []}) ? $JSON::true : $JSON::false,
        shareWith  => (@ShareWith ? \@ShareWith : $JSON::false),
      );
      if ($Args{Sync}) {
        $AddressBook{syncToken} = $Propstat->{"{$NS_D}prop"}{"{$NS_D}sync-token"}{content} || '';
      }
      push @AddressBooks, \%AddressBook;
    }
  }

  return \@AddressBooks;
}

# }}}

# Contact methods {{{

=head2 $Self->NewContact($AddressBookPath, $VCard)

Create a new contact from the Net::CardDAVTalk::VCard object,
either using its uid field or generating a new UUID and appending
.vcf for the filename.

Returns the full path to the card.

NOTE: can also be used for a kind: group v4 style group.

=cut

sub NewContact {
  my ($Self, $Path, $VCard) = @_;

  $Path || confess "New contact path not specified";
  $VCard->isa("Net::CardDAVTalk::VCard") || confess "Invalid contact";

  my $Uid = $VCard->uid() // $VCard->uid($Self->genuuid());

  $Self->Request(
    'PUT',
    "$Path/$Uid.vcf",
    $VCard->as_string(),
    'Content-Type'  => 'text/vcard',
    'If-None-Match' => '*',
  );

  return $VCard->{CPath} = "$Path/$Uid.vcf";
}

=head2 $self->DeleteContact($Path)

Delete the contact at path $Path.

=cut

sub DeleteContact {
  my ($Self, $CPath) = @_;

  $CPath || confess "Delete contact path not specified";

  $Self->Request(
    'DELETE',
    $CPath,
  );

  return $CPath;
}

=head2 $Self->UpdateContact($Path, $VCard)

Identical to NewContact, but will fail unless there is an
existing contact with that path.  Also takes the full path
instead of just the addressbook path.

NOTE: can also be used for a kind: group v4 style group.

=cut

sub UpdateContact {
  my ($Self, $CPath, $VCard) = @_;

  $CPath || confess "Update contact path not specified";
  $VCard->isa("Net::CardDAVTalk::VCard") || confess "Invalid contact";

  $Self->Request(
    'PUT',
    $CPath,
    $VCard->as_string(),
    'Content-Type' => 'text/vcard',
    'If-Match'     => '*',
  );

  return $VCard->{CPath} = $CPath;
}

=head2 $Self->GetContact($Path)

Fetch a specific contact by path.  Returns a
Net::CardDAVTalk::VCard object.

=cut

sub GetContact {
  my ($Self, $CPath) = @_;

  $CPath || confess "Get contact path not specified";

  my $Response = $Self->Request(
    'GET',
    $CPath,
  );

  my $Data = $Response && $Response->{content}
    // return undef;

  my $VCard = eval { Net::CardDAVTalk::VCard->new_fromstring($Data) }
    // return undef;

  $VCard->{CPath} = $CPath;

  return $VCard;
}

=head2 $Self->GetContactAndProps($Path, $Props)

Use a multiget to fetch the properties in the arrayref as well
as the card content.

Returns the card in scalar context - the card and an array of errors
in list context.

=cut

sub GetContactAndProps {
  my ($Self, $CPath, $Props) = @_;
  $Props //= [];

  $CPath || confess "Get contact path not specified";

  my $Response = $Self->Request(
    'REPORT',
    $CPath,
    x('C:addressbook-multiget', $Self->NS(),
      x('D:prop',
        x('D:getetag'),
        x('C:address-data'),
        map { x(join ":", @$_) } @$Props,
      ),
      x('D:href', $CPath),
    ),
    Depth => '0',
  );

  my ($Contact, @Errors);

  my $NS_C = $Self->ns('C');
  my $NS_D = $Self->ns('D');
  foreach my $Response (@{$Response->{"{$NS_D}response"} || []}) {
    foreach my $Propstat (@{$Response->{"{$NS_D}propstat"} || []}) {
      my $VCard = eval { $Self->_ParseReportData($Response, $Propstat, $Props) } || do {
        push @Errors, $@ if $@;
        next;
      };

      $Contact = $VCard;
    }
  }

  return wantarray ? ($Contact, \@Errors) : $Contact;
}

=head2 $self->GetContacts($Path, $Props, %Args)

Get multiple cards, possibly including props, using both a propfind
AND a multiget.

Returns an arrayref of contact and an arrayref of errors (or just the
contacts in scalar context again)

=cut

sub GetContacts {
  my ($Self, $Path, $Props, %Args) = @_;
  $Props //= [];

  my $Response = $Self->Request(
    'PROPFIND',
    "$Path/",
    x('D:propfind', $Self->NS(),
      x('D:prop',
        x('D:getcontenttype'),
        x('D:getetag'),
      ),
    ),
    Depth => '1',
  );

  my @Urls;
  my $NS_C = $Self->ns('C');
  my $NS_D = $Self->ns('D');
  foreach my $Response (@{$Response->{"{$NS_D}response"} || []}) {
    my $HRef = $Response->{"{$NS_D}href"}{content};
    next unless $HRef;
    if ($Response->{"{$NS_D}prop"}{"{$NS_D}getcontenttype"}) {
      my $type = $Response->{"{$NS_D}prop"}{"{$NS_D}getcontenttype"}{content} || '';
      next unless $type =~ m{text/(x-)?vcard};
    }
    push @Urls, $HRef;
  }

  my (@Contacts, @Errors);

  if (@Urls) {
    my $Response = $Self->Request(
      'REPORT',
      "$Path/",
      x('C:addressbook-multiget', $Self->NS(),
        x('D:prop',
          x('D:getetag'),
          x('C:address-data'),
          map { x(join ":", @$_) } @$Props,
        ),
        map { x('D:href', $_) } @Urls,
      ),
      Depth => '0',
    );

    my $NS_C = $Self->ns('C');
    my $NS_D = $Self->ns('D');
    foreach my $Response (@{$Response->{"{$NS_D}response"} || []}) {
      foreach my $Propstat (@{$Response->{"{$NS_D}propstat"} || []}) {
        my $VCard = eval { $Self->_ParseReportData($Response, $Propstat, $Props) } || do {
          push @Errors, $@ if $@;
          next;
        };

        push @Contacts, $VCard;
      }
    }
  }

  return wantarray ? (\@Contacts, \@Errors) : \@Contacts;
}

=head2 $self->SyncContacts($Path, $Props, %Args)

uses the argument 'syncToken' to find newly added and removed
cards from the server.  Returns just the added/changed contacts
in scalar context, or a list of array of contacts, array of
removed, array of errors and the new syncToken as 4 items in
list context.

=cut

sub SyncContacts {
  my ($Self, $Path, $Props, %Args) = @_;
  $Props //= [];

  $Path || confess "Sync contacts path required";

  # WebDAV Collection Synchronization (RFC6578)
  my $Response = $Self->Request(
    'REPORT',
    "$Path/",
    x('D:sync-collection', $Self->NS(),
      x('D:sync-token', ($Args{syncToken} ? ($Args{syncToken}) : ())),
      x('D:sync-level', 1),
      x('D:prop',
        x('D:getetag'),
        x('C:address-data'),
        map { x(join ":", @$_) } @$Props,
      ),
    ),
  );

  if (($Response->{error} // "") eq 'valid-sync-token') {
    delete $Args{syncToken};
    return $Self->SyncContacts($Path, $Props, %Args);
  }

  my (@Contacts, @Removed, @Errors);

  my $NS_C = $Self->ns('C');
  my $NS_D = $Self->ns('D');
  foreach my $Response (@{$Response->{"{$NS_D}response"} || []}) {
    my $HRef = $Response->{"{$NS_D}href"}{content}
      || next;
    my $CPath = $Self->_unrequest_url($HRef);

    # For members that have been removed, the DAV:response MUST
    # contain one DAV:status with a value set to '404 Not Found' and
    # MUST NOT contain any DAV:propstat element
    if (!$Response->{"{$NS_D}propstat"}) {
      my $Status = $Response->{"{$NS_D}status"}{content};
      if ($Status =~ m/ 404 /) {
        push @Removed, $CPath;
      } else {
        warn "ODD STATUS";
        push @Errors, "Odd status in non-propstat response: $Status";
      }
      next;
    }

    # For members that have changed (i.e., are new or have had their
    # mapped resource modified), the DAV:response MUST contain at
    # least one DAV:propstat element and MUST NOT contain any
    # DAV:status element.
    foreach my $Propstat (@{$Response->{"{$NS_D}propstat"} || []}) {
      my $Status = $Propstat->{"{$NS_D}status"}{content};

      if ($Status =~ m/ 200 /) {
        my $VCard = eval { $Self->_ParseReportData($Response, $Propstat, $Props) } || do {
          push @Errors, $@ if $@;
          next;
        };

        push @Contacts, $VCard;
      }
      elsif ($Status =~ m/ 404 /) {
        # Missing properties return 404 status response, ignore

      }
      else {
        warn "ODD STATUS";
        push @Errors, "Odd status in propstat response: $Status";
      }
    }
  }

  my $SyncToken = $Response->{"{$NS_D}sync-token"}{content};

  return wantarray ? (\@Contacts, \@Removed, \@Errors, $SyncToken) : \@Contacts;
}

=head2 $self->MoveContact($Path, $NewPath)

Move a contact to a new path (usually in a new addressbook) - both
paths are card paths.

=cut

sub MoveContact {
  my ($Self, $CPath, $NewPath) = @_;

  $CPath || confess "Move contact path not specified";
  $NewPath || confess "Move contact destination path not specified";

  $Self->Request(
    'MOVE',
    $CPath,
    undef,
    'Destination'  => $Self->request_url($NewPath),
  );

  return $NewPath;
}

# }}}

sub _ParseReportData {
  my ($Self, $Response, $Propstat, $Props) = @_;

  my $NS_C = $Self->ns('C');
  my $NS_D = $Self->ns('D');

  my $HRef = $Response->{"{$NS_D}href"}{content}
    // return;
  my $CPath = $Self->_unrequest_url($HRef);

  my $Data = $Propstat->{"{$NS_D}prop"}{"{$NS_C}address-data"}{content}
    // return;

  my $VCard = Net::CardDAVTalk::VCard->new_fromstring($Data);
  return unless $VCard;

  $VCard->{CPath} = $CPath;

  my %Props;
  for (@$Props) {
    my ($NS, $PropName) = @$_;
    my $NS_P = $Self->ns($NS);
    my $PropValue = $Propstat->{"{$NS_D}prop"}{"{$NS_P}$PropName"}{content}
      // next;
    $Props{"${NS}:${PropName}"} = $PropValue;
  }

  $VCard->{meta} = \%Props;

  return $VCard;
}

sub _unrequest_url {
  my $Self = shift;
  my $Path = shift;

  if ($Path =~ m{^/}) {
    $Path =~ s#^\Q$Self->{basepath}\E/?##;
  } else {
    $Path =~ s#^\Q$Self->{url}\E/?##;
  }
  $Path =~ s#/$##;

  return $Path;
}

=head1 AUTHOR

Bron Gondwana, C<< <brong at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-carddavtalk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-CardDAVTalk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::CardDAVTalk


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-CardDAVTalk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-CardDAVTalk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-CardDAVTalk>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-CardDAVTalk/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 FastMail Pty. Ltd.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Net::CardDAVTalk
