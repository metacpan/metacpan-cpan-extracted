package Sietima::Role::Headers;
use Moo::Role;
use Try::Tiny;
use Sietima::Policy;
use Sietima::HeaderURI;
use Email::Address;
use Types::Standard qw(Str);
use Sietima::Types qw(HeaderUriFromThings);
use namespace::clean;

our $VERSION = '1.0.5'; # VERSION
# ABSTRACT: adds standard list-related headers to messages


has name => (
    isa => Str,
    is => 'ro',
    required => 0,
);

sub _normalise_address($self,$address) {
    my @items = ref($address) eq 'ARRAY' ? $address->@* : $address;

    return map {
        HeaderUriFromThings->coerce($_)
    } @items;
}

sub _set_header($self,$mail,$name,$value) {
    my $header_name = 'List-' . ucfirst($name =~ s{[^[:alnum:]]+}{-}gr);
    my @items = $self->_normalise_address($value);

    $mail->header_raw_set(
        $header_name => join ', ', map { $_->as_header_raw } @items,
    );
}

sub _add_headers_to($self,$message) {
    my $addresses = $self->list_addresses;
    my $mail = $message->mail;

    # see RFC 2919 "List-Id: A Structured Field and Namespace for the
    # Identification of Mailing Lists"
    my $return_path = delete $addresses->{return_path};
    if (my $name = $self->name) {
        $mail->header_raw_set(
            'List-Id',
            sprintf '%s <%s>', $name,$return_path->address =~ s{\@}{.}r,
        );
    }

    # if nobody declared a "post" address, let's guess it's the same
    # as the address we send from
    if (not exists $addresses->{post}) {
        $self->_set_header( $mail, post => $return_path );
    }
    # but if they explicitly set a false value, this list does not
    # allow posting, so we need to set the special value 'NO'
    elsif (not $addresses->{post}) {
        delete $addresses->{post};
        $mail->header_raw_set('List-Post','NO');
    }
    # otherwise we can treat 'post' as normal

    for my $name (sort keys $addresses->%*) {
        $self->_set_header( $mail, $name => $addresses->{$name} );
    }
    return;
}


around munge_mail => sub ($orig,$self,$mail) {
    my @messages = $self->$orig($mail);
    $self->_add_headers_to($_) for @messages;
    return @messages;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Role::Headers - adds standard list-related headers to messages

=head1 VERSION

version 1.0.5

=head1 SYNOPSIS

  my $sietima = Sietima->with_traits('Headers')->new({
   %args,
   name => $name_of_the_list,
  });

=head1 DESCRIPTION

A L<< C<Sietima> >> list with this role applied will add, to each
outgoing message, the set of headers defined in RFC 2919 and RFC 2369.

This role uses the L<< C<list_addresses>|Sietima/list_addresses >>
method to determine what headers to add.

If the C<name> attribute is set, a C<List-Id:> header will be added,
with a value built out of the name and the C<<
$self->list_addresses->{return_path} >> value (which is normally the
same as the L<< C<return_path>|Sietima/return_path >> attribute).

Other C<List-*:> headers are built from the other values in the
C<list_addresses> hashref. Each of those values can be:

=over 4

=item *

an L<< C<Sietima::HeaderURI> >> object

=item *

a thing that can be passed to that class's constructor:

=over 4

=item *

an L<< C<Email::Address> >> object

=item *

a L<< C<URI> >> object

=item *

a string parseable as either

=back

=item *

an arrayref containing any mix of the above

=back

As a special case, if C<< $self->list_addresses->{post} >> exists and
is false, the C<List-Post> header will have the value C<NO> to
indicate that the list does not accept incoming messages (e.g. it's an
announcement list).

=head1 ATTRIBUTES

=head2 C<name>

Optional string, the name of the mailing list. If this attribute is
set, a C<List-Id:> header will be added, with a value built out of the
name and the C<< $self->list_addresses->{return_path} >> value (which
is normally the same as the L<< C<return_path>|Sietima/return_path >>
attribute).

=head1 MODIFIED METHODS

=head2 C<munge_mail>

This method adds list-management headers to each message returned by
the original method.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
