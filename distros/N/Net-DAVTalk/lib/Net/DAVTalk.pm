package Net::DAVTalk;

use strict;

use Carp;
use DateTime::Format::ISO8601;
use DateTime::TimeZone;
use HTTP::Tiny;
use JSON;
use Tie::DataUUID qw{$uuid};
use XML::Spice;
use Net::DAVTalk::XMLParser;
use MIME::Base64 qw(encode_base64);
use Encode qw(encode);
use URI::Escape qw(uri_escape uri_unescape);
use URI;

=head1 NAME

Net::DAVTalk - Interface to talk to DAV servers

=head1 VERSION

Version 0.23

=cut

our $VERSION = '0.23';

=head1 SYNOPSIS

Net::DAVTalk is was originally designed as a service module for Net::CalDAVTalk
and Net::DAVTalk, abstracting the process of connecting to a DAV server and
parsing the XML responses.

Example:

    use Net::DAVTalk;
    use XML::Spice;

    my $davtalk = Net::DAVTalk->new(
        url => "https://dav.example.com/",
        user => "foo\@example.com",
        password => "letmein",
        headers => { Cookie => "123", Referer => "456" },
    );

    $davtalk->Request(
        'MKCALENDAR',
        "$calendarId/",
        x('C:mkcalendar', $Self->NS(),
            x('D:set',
                 x('D:prop', @Properties),
            ),
        ),
    );

    $davtalk->Request(
        'DELETE',
        "$calendarId/",
    );

=head1 SUBROUTINES/METHODS

=head2 $class->new(%Options)

Options:

    url: either full https?:// url, or relative base path on the
    server to the DAV endpoint

    host, scheme and port: alternative to using full URL.
    If URL doesn't start with https?:// then these will be used to
    construct the endpoint URI.

    expandurl and wellknown: if these are set, then the wellknown
    name (caldav and carddav are both defined) will be used to
    resolve /.well-known/$wellknown to find the current-user-principal
    URI, and then THAT will be resovlved to find the $wellknown-home-set
    URI, which will be used as the URL for all further actions on
    this object.

    user and password: if these are set, perform basic authentication.
    user and access_token: if these are set, perform Bearer (OAUTH2)
    authentication.

    headers: a hashref of additional headers to add to every request

    SSL_options: a hashref of SSL options to pass down to the default
    user agent
=cut

# General methods

sub new {
  my ($Class, %Params) = @_;

  unless ($Params{url}) {
    confess "URL not supplied";
  }

  # Assume url points to xyz-home-set, otherwise expand the url
  if (delete $Params{expandurl}) {
    # Locating Services for CalDAV and CardDAV (RFC6764)
    my $PrincipalURL = $Class->GetCurrentUserPrincipal(%Params);
    $Params{principal} = $PrincipalURL;

    my $HomeSet = $Class->GetHomeSet(
      %Params,
      url => $PrincipalURL,
    );

    $Params{url} = $HomeSet;
  }

  my $Self = bless \%Params, ref($Class) || $Class;
  $Self->SetURL($Params{url});
  $Self->SetPrincipalURL($Params{principal});
  $Self->ns(D => 'DAV:');

  return $Self;
}

=head2 my $ua = $Self->ua();
=head2 $Self->ua($setua);

Get or set the useragent (HTTP::Tiny or compatible) that will be used to make
the requests:

e.g.

    my $ua = $Self->ua();

    $Self->ua(HTTP::Tiny->new(agent => "MyAgent/1.0", timeout => 5));

=cut

sub ua {
  my $Self = shift;
  if (@_) {
    $Self->{ua} = shift;
  }
  else {
    $Self->{ua} ||= HTTP::Tiny->new(
      agent => "Net-DAVTalk/$VERSION",
      SSL_options => $Self->{SSL_options},
    );
  }
  return $Self->{ua};
}

=head2 $Self->SetURL($url)

Change the endpoint URL for an existing connection.

=cut

sub SetURL {
  my ($Self, $URL) = @_;

  $URL =~ s{/$}{}; # remove any trailing slash

  if ($URL =~ m{^https?://}) {
    my ($HTTPS, $Hostname, $Port, $BasePath)
      = $URL =~ m{^http(s)?://([^/:]+)(?::(\d+))?(.*)?};

    unless ($Hostname) {
      confess "Invalid hostname in '$URL'";
    }

    $Self->{scheme}   = $HTTPS ? 'https' : 'http';
    $Self->{host}     = $Hostname;
    $Self->{port}     = ($Port || ($HTTPS ? 443 : 80));
    $Self->{basepath} = $BasePath;
  }
  else {
    $Self->{basepath} = $URL;
  }

  $Self->{url} = "$Self->{scheme}://$Self->{host}:$Self->{port}$Self->{basepath}";

  return $Self->{url};
}

=head2 $Self->SetPrincipalURL($url)

Set the URL to the DAV Principal

=cut

sub SetPrincipalURL {
  my ($Self, $PrincipalURL) = @_;

  return $Self->{principal} = $PrincipalURL;
}

=head2 $Self->fullpath($shortpath)

Convert from a relative path to a full path:

e.g
    my $path = $Dav->fullpath('Default');
    ## /dav/calendars/user/foo/Default

NOTE: a you can pass a non-relative full path (leading /)
to this function and it will be returned unchanged.

=cut

sub fullpath {
  my $Self = shift;
  my $path = shift;
  my $basepath = $Self->{basepath};
  return $path if $path =~ m{^/};
  return "$basepath/$path";
}

=head2 $Self->shortpath($fullpath)

Convert from a full path to a relative path

e.g
    my $path = $Dav->fullpath('/dav/calendars/user/foo/Default');
    ## Default

NOTE: if the full path is outside the basepath of the object, it
will be unchanged.

    my $path = $Dav->fullpath('/dav/calendars/user/bar/Default');
    ## /dav/calendars/user/bar/Default

=cut

sub shortpath {
  my $Self = shift;
  my $origpath = shift;
  my $basepath = $Self->{basepath};
  my $path = $origpath;
  $path =~ s{^$basepath/?}{};
  return ($path eq '' ? $origpath : $path);
}

=head2 $Self->Request($method, $path, $content, %headers)

The whole point of the module!  Perform a DAV request against the
endpoint, returning the response as a parsed hash.

   method: http method, i.e. GET, PROPFIND, MKCOL, DELETE, etc

   path: relative to base url.  With a leading slash, relative to
         server root, i.e. "Default/", "/dav/calendars/user/foo/Default".

   content: if the method takes a body, raw bytes to send

   headers: additional headers to add to request, i.e (Depth => 1)

=cut

sub Request {
  my ($Self, $Method, $Path, $Content, %Headers) = @_;

  # setup request {{{

  $Content = '' unless defined $Content;
  my $Bytes = encode('UTF-8', $Content);

  my $ua = $Self->ua();

  $Headers{'Content-Type'} //= 'application/xml; charset=utf-8';

  if ($Self->{user}) {
    $Headers{'Authorization'} = $Self->auth_header();
  }

  if ($Self->{headers}) {
      $Headers{$_} = $Self->{headers}->{$_} for ( keys %{ $Self->{headers} } );
  }

  # XXX - Accept-Encoding for gzip, etc?

  # }}}

  # send request {{{

  my $URI = $Self->request_url($Path);

  my $Response = $ua->request($Method, $URI, {
    headers => \%Headers,
    content => $Bytes,
  });

  if ($Response->{status} == '599' and $Response->{content} =~ m/timed out/i) {
    confess "Error with $Method for $URI (504, Gateway Timeout)";
  }

  my $count = 0;
  while ($Response->{status} =~ m{^30[1278]} and (++$count < 10)) {
    my $location = URI->new_abs($Response->{headers}{location}, $URI);
    if ($ENV{DEBUGDAV}) {
      warn "******** REDIRECT ($count) $Response->{status} to $location\n";
    }

    $Response = $ua->request($Method, $location, {
      headers => \%Headers,
      content => $Bytes,
    });

    if ($Response->{status} == '599' and $Response->{content} =~ m/timed out/i) {
      confess "Error with $Method for $location (504, Gateway Timeout)";
    }
  }

  # one is enough

  my $ResponseContent = $Response->{content} || '';

  if ($ENV{DEBUGDAV}) {
    warn "<<<<<<<< $Method $URI HTTP/1.1\n$Bytes\n" .
         ">>>>>>>> $Response->{protocol} $Response->{status} $Response->{reason}\n$ResponseContent\n" .
         "========\n\n";
  }

  if ($Method eq 'REPORT' && $Response->{status} == 403) {
    # maybe invalid sync token, need to return that fact
    my $Xml = xmlToHash($ResponseContent);
    if (exists $Xml->{"{DAV:}valid-sync-token"}) {
      return {
        error => "valid-sync-token",
      };
    }
  }

  unless ($Response->{success}) {
    confess("ERROR WITH REQUEST\n" .
         "<<<<<<<< $Method $URI HTTP/1.1\n$Bytes\n" .
         ">>>>>>>> $Response->{protocol} $Response->{status} $Response->{reason}\n$ResponseContent\n" .
         "========\n\n");
  }

  if ((grep { $Method eq $_ } qw{GET DELETE}) or ($Response->{status} != 207) or (not $ResponseContent)) {
    return { content => $ResponseContent };
  }

  # }}}

  # parse XML response {{{
  my $Xml = xmlToHash($ResponseContent);

  # Normalise XML

  if (exists($Xml->{"{DAV:}response"})) {
    if (ref($Xml->{"{DAV:}response"}) ne 'ARRAY') {
      $Xml->{"{DAV:}response"} = [ $Xml->{"{DAV:}response"} ];
    }

    foreach my $Response (@{$Xml->{"{DAV:}response"}}) {
      if (exists($Response->{"{DAV:}propstat"})) {
        unless (ref($Response->{"{DAV:}propstat"}) eq 'ARRAY') {
          $Response->{"{DAV:}propstat"} = [$Response->{"{DAV:}propstat"}];
        }
      }
    }
  }

  return $Xml;

  # }}}
}

=head2 $Self->GetProps($Path, @Props)

perform a propfind on a particular path and get the properties back

=cut

sub GetProps {
  my ($Self, $Path, @Props) = @_;
  my @res = $Self->GetPropsArray($Path, @Props);
  return wantarray ? map { $_->[0] } @res : $res[0][0];
}

=head2 $Self->GetPropsArray($Path, @Props)

perform a propfind on a particular path and get the properties back
as an array of one or more items

=cut

sub GetPropsArray {
  my ($Self, $Path, @Props) = @_;

  # Fetch one or more properties.
  #  Use [ 'prop', 'sub', 'item' ] to dig into result structure

  my $NS_D = $Self->ns('D');

  my $Response = $Self->Request(
    'PROPFIND',
    $Path,
    x('D:propfind', $Self->NS(),
      x('D:prop',
        map { ref $_ ? x($_->[0]): x($_) } @Props,
      ),
    ),
    Depth => 0,
  );

  my @Results;
  foreach my $Response (@{$Response->{"{$NS_D}response"} || []}) {
    foreach my $Propstat (@{$Response->{"{$NS_D}propstat"} || []}) {
      my $PropData = $Propstat->{"{$NS_D}prop"} || next;
      for my $Prop (@Props) {
        my @Values = ($PropData);

        # Array ref means we need to git through structure
        foreach my $Key (ref $Prop ? @$Prop : $Prop) {
          my @New;
          foreach my $Result (@Values) {
            if ($Key =~ m/:/) {
              my ($N, $P) = split /:/, $Key;
              my $NS = $Self->ns($N);
              $Result = $Result->{"{$NS}$P"};
            } else {
              $Result = $Result->{$Key};
            }
            if (ref($Result) eq 'ARRAY') {
              push @New, @$Result;
            }
            elsif (defined $Result) {
              push @New, $Result;
            }
          }
          @Values = @New;
        }

        push @Results, [ map { $_->{content} } @Values ];
      }
    }
  }

  return wantarray ? @Results : $Results[0];
}

=head2 $Self->GetCurrentUserPrincipal()
=head2 $class->GetCurrentUserPrincipal(%Args)

Can be called with the same args as new() as a class method, or
on an existing object.  Either way it will use the .well-known
URI to find the path to the current-user-principal.

Returns a string with the path.

=cut

sub GetCurrentUserPrincipal {
  my ($Class, %Args) = @_;

  if (ref $Class) {
    %Args  = %{$Class};
    $Class = ref $Class;
  }

  my $OriginalURL = $Args{url} || '';
  my $Self        = $Class->new(%Args);
  my $NS_D        = $Self->ns('D');
  my @BasePath    = split '/', $Self->{basepath};

  @BasePath = ('', ".well-known/$Args{wellknown}") unless @BasePath;

  PRINCIPAL: while(1) {
    $Self->SetURL(join '/', @BasePath);

    if (my $Principal = $Self->GetProps('', [ 'D:current-user-principal', 'D:href' ])) {
      $Self->SetURL(uri_unescape($Principal));
      return $Self->{url};
    }

    pop @BasePath;
    last unless @BasePath;
  }

  croak "Error finding current user principal at '$OriginalURL'";
}

=head2 $Self->GetHomeSet
=head2 $class->GetHomeSet(%Args)

Can be called with the same args as new() as a class method, or
on an existing object.  Either way it assumes that the created
object has a 'url' parameter pointing at the current user principal
URL (see GetCurrentUserPrincipal above)

Returns a string with the path to the home set.

=cut

sub GetHomeSet {
  my ($Class, %Args) = @_;

  if (ref $Class) {
    %Args  = %{$Class};
    $Class = ref $Class;
  }

  my $OriginalURL = $Args{url} || '';
  my $Self        = $Class->new(%Args);
  my $NS_D        = $Self->ns('D');
  my $NS_HS       = $Self->ns($Args{homesetns});
  my $HomeSet     = $Args{homeset};

  if (my $Homeset = $Self->GetProps('', [ "$Args{homesetns}:$HomeSet", 'D:href' ])) {
    $Self->SetURL(uri_unescape($Homeset));
    return $Self->{url};
  }

  croak "Error finding $HomeSet home set at '$OriginalURL'";
}

=head2 $Self->genuuid()

Helper to generate a uuid string.  Returns a UUID, e.g.

    my $uuid = $DAVTalk->genuuid(); # 9b9d68af-ad13-46b8-b7ab-30ab70da14ac

=cut

sub genuuid {
  my $Self = shift;
  return "$uuid";
}

=head2 $Self->auth_header()

Generate the authentication header to use on requests:

e.g:

    $Headers{'Authorization'} = $Self->auth_header();

=cut

sub auth_header {
  my $Self = shift;

  if ($Self->{password}) {
    return 'Basic ' . encode_base64("$Self->{user}:$Self->{password}", '');
  }

  if ($Self->{access_token}) {
    return "Bearer $Self->{access_token}";
  }

  croak "Need a method to authenticate user (password or access_token)";
}

=head2 $Self->request_url()

Generate the authentication header to use on requests:

e.g:

    $Headers{'Authorization'} = $Self->auth_header();

=cut

sub request_url {
  my $Self = shift;
  my $Path = shift;

  my $URL = $Self->{url};

  # If a reference, assume absolute
  if (ref $Path) {
    ($URL, $Path) = $$Path =~ m{(^https?://[^/]+)(.*)$};
  }

  if ($Path) {
    $Path = join "/", map { uri_escape $_ } split m{/}, $Path, -1;
    if ($Path =~ m{^/}) {
      $URL =~ s{(^https?://[^/]+)(.*)}{$1$Path};
    }
    else {
      $URL =~ s{/$}{};
      $URL .= "/$Path";
    }
  }

  return $URL;
}

=head2 $Self->NS()

Returns a hashref of the 'xmlns:shortname' => 'full namespace' items for use in XML::Spice body generation, e.g.

    $DAVTalk->Request(
        'MKCALENDAR',
        "$calendarId/",
        x('C:mkcalendar', $Self->NS(),
            x('D:set',
                 x('D:prop', @Properties),
            ),
        ),
    );

    # { 'xmlns:C' => 'urn:ietf:params:xml:ns:caldav', 'xmlns:D' => 'DAV:' }

=cut

sub NS {
  my $Self = shift;

  return {
    map { ( "xmlns:$_" => $Self->ns($_) ) }
      $Self->ns(),
  };
}


=head2 $Self->ns($key, $value)

Get or set namespace aliases, e.g

  $Self->ns(C => 'urn:ietf:params:xml:ns:caldav');
  my $NS_C = $Self->ns('C'); # urn:ietf:params:xml:ns:caldav

=cut

sub ns {
  my $Self = shift;

  # case: keys
  return keys %{$Self->{ns}} unless @_;

  my $key = shift;
  # case read one
  return $Self->{ns}{$key} unless @_;

  # case write
  my $prev = $Self->{ns}{$key};
  $Self->{ns}{$key} = shift;
  return $prev;
}

=head2 function2

=cut

=head1 AUTHOR

Bron Gondwana, C<< <brong at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-davtalk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-DAVTalk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::DAVTalk


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-DAVTalk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-DAVTalk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-DAVTalk>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-DAVTalk/>

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

1; # End of Net::DAVTalk
