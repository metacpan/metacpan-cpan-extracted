package Sietima::Role::NoSpoof::DMARC;
use Moo::Role;
use Sietima::Policy;
use Email::Address;
use Mail::DMARC::PurePerl;
use namespace::clean;

our $VERSION = '1.1.4'; # VERSION
# ABSTRACT: send out messages from subscribers' addresses only if DMARC allows it


with 'Sietima::Role::WithPostAddress';

# mostly for testing
has dmarc_resolver => ( is => 'ro' );

around munge_mail => sub ($orig,$self,$incoming_mail) {
    my $sender = $self->post_address->address;
    my ($from) = Email::Address->parse($incoming_mail->header_str('From'));
    my $from_domain = $from->host;

    if ($from_domain ne $self->post_address->host) {
        my $dmarc = Mail::DMARC::PurePerl->new(
            resolver => $self->dmarc_resolver,
        );
        $dmarc->header_from($from_domain);

        if (my $policy = $dmarc->discover_policy) {
            # sp applies to sub-domains, defaults to p; p applies to
            # the domain itself, and is required
            my $relevant_value = $dmarc->is_subdomain
                ? ( $policy->sp // $policy->p )
                : $policy->p;

            if ($relevant_value ne 'none') {
                $incoming_mail->header_str_set(
                    'Original-From' => $from,
                );

                $from->address($sender);

                $incoming_mail->header_str_set(
                    From => $from,
                );

                return $self->$orig($incoming_mail);
            }
        }
    }

    $incoming_mail->header_str_set(
        Sender => $sender,
    ) if $sender ne $from->address;

    return $self->$orig($incoming_mail);

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Role::NoSpoof::DMARC - send out messages from subscribers' addresses only if DMARC allows it

=head1 VERSION

version 1.1.4

=head1 SYNOPSIS

  my $sietima = Sietima->with_traits('NoSpoof::DMARC')->new(\%args);

=head1 DESCRIPTION

A L<< C<Sietima> >> list with this role applied will replace the
C<From> address with its own L<<
C<post_address>|Sietima::Role::WithPostAddress >> (this is a
"sub-role" of L<< C<WithPostAddress>|Sietima::Role::WithPostAddress
>>) I<if> the C<From> is on a different domain and the originating
address's DMARC policy requires it.

This will make the list DMARC-compliant while minimising the changes
to the messages.

The original C<From> address will be preserved in the C<Original-From>
header, as required by RFC 5703.

=head2 Some more details

DMARC requires L<"identifier
alignment"|https://datatracker.ietf.org/doc/html/rfc7489#section-3.1>,
essentially the C<MAIL FROM> (envelope) and the header C<From> must
have the same domain (or at least belong to the same "organisational
domain", i.e. be both under a common non-top-level domain, roughly).

Therefore, a mailing list that forwards a message sent from a
DMARC-enabled domain, I<must> rewrite the C<From> header, otherwise
the message will be discarded by recipient servers. If the originating
domain does not publish a DMARC policy (or publishes a C<none>
policy), the mailing list can leave the C<From> as is, but should add
a C<Sender> header with the list's own address.

This role does exactly that.

=for Pod::Coverage dmarc_resolver

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
