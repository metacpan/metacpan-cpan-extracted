package Sietima::Role::NoSpoof;
use Moo::Role;
use Sietima::Policy;
use Email::Address;
use namespace::clean;

our $VERSION = '1.1.4'; # VERSION
# ABSTRACT: never sends out messages from subscribers' addresses


with 'Sietima::Role::WithPostAddress';

around munge_mail => sub ($orig,$self,$incoming_mail) {
    my $sender = $self->post_address->address;
    my ($from) = Email::Address->parse($incoming_mail->header_str('From'));

    if ($from->host ne $self->post_address->host) {
        $from->address($sender);

        $incoming_mail->header_str_set(
            From => $from,
        );
    }

    return $self->$orig($incoming_mail);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Role::NoSpoof - never sends out messages from subscribers' addresses

=head1 VERSION

version 1.1.4

=head1 SYNOPSIS

  my $sietima = Sietima->with_traits('NoSpoof')->new(\%args);

=head1 DESCRIPTION

A L<< C<Sietima> >> list with this role applied will replace the
C<From> address with its own L<<
C<post_address>|Sietima::Role::WithPostAddress >> (this is a
"sub-role" of L<< C<WithPostAddress>|Sietima::Role::WithPostAddress
>>) I<if> the C<From> is on a different domain.

This will make the list DMARC-compliant.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
