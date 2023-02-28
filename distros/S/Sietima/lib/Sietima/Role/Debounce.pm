package Sietima::Role::Debounce;
use Moo::Role;
use Sietima::Policy;
use namespace::clean;

our $VERSION = '1.1.1'; # VERSION
# ABSTRACT: avoid mail loops


my $been_there = 'X-Been-There';

around munge_mail => sub ($orig,$self,$incoming_mail) {
    my $return_path = $self->return_path->address;
    if (my $there = $incoming_mail->header_str($been_there)) {
        return if $there =~ m{\b\Q$return_path\E\b};
    }

    $incoming_mail->header_str_set(
        $been_there => $return_path,
    );

    return $self->$orig($incoming_mail);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Role::Debounce - avoid mail loops

=head1 VERSION

version 1.1.1

=head1 SYNOPSIS

  my $sietima = Sietima->with_traits('Debounce')->new(\%args);

=head1 DESCRIPTION

A L<< C<Sietima> >> list with this role applied will mark each message
with a C<X-Been-There:> header, and will not handle any messages that
have that same header. This prevents messages bounced by other
services from being looped between the mailing list and those other
services.

=head1 MODIFIED METHODS

=head2 C<munge_mail>

If the incoming email contains our C<X-Been-There:> header, this
method will return an empty list (essentially dropping the message).

Otherwise, the header is added, and the email is processed normally.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
