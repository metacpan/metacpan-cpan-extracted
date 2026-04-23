package Sietima::Role::StripHeaders;
use Moo::Role;
use Sietima::Policy;
use Types::Standard qw(ArrayRef RegexpRef);
use namespace::clean;

our $VERSION = '1.1.5'; # VERSION
# ABSTRACT: removes headers from incoming messages


has strip_headers => (
    isa => ArrayRef[RegexpRef],
    is => 'ro',
    default => sub { [] },
);

sub _strip_headers_from($self,$message) {
    my $mail = $message->mail;

    my $h = $mail->header_obj;
    for my $name ($h->header_names) {
        for my $rx ($self->strip_headers->@*) {
            if ($name =~ $rx) {
                $h->header_raw_set($name => ());
            }
        }
    }
}


around munge_mail => sub ($orig,$self,$mail) {
    my @messages = $self->$orig($mail);
    $self->_strip_headers_from($_) for @messages;
    return @messages;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Role::StripHeaders - removes headers from incoming messages

=head1 VERSION

version 1.1.5

=head1 SYNOPSIS

  my $sietima = Sietima->with_traits('StripHeaders')->new({
   %args,
   strip_headers => [ qr{^dkim\b}i, qr{^arc\b}i ],
  });

=head1 DESCRIPTION

A L<< C<Sietima> >> list with role applied will remove all headers
that match any of the provided regular expressions. This is useful to
remove DKIM/ARC cryptographic signatures from incoming messages, which
would be broken by the changes that the list makes to the message.

Notice that you I<can break messages> with this: if the regular
expressions match necessary headers (like C<to>), those headers will
be removed! Be careful, and run some tests.

=head1 ATTRIBUTES

=head2 C<strip_headers>

Optional arrayref of regular expressions, defaults to the empty
array. Any header that matches any of these regular expressions will
be removed.

=head1 MODIFIED METHODS

=head2 C<munge_mail>

This method removes matching headers from each message returned by the
original method.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
