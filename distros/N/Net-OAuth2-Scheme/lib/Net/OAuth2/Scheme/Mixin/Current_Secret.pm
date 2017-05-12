use warnings;
use strict;

package Net::OAuth2::Scheme::Mixin::Current_Secret;
BEGIN {
  $Net::OAuth2::Scheme::Mixin::Current_Secret::VERSION = '0.03';
}
# ABSTRACT: the 'current_secret' option group

use Net::OAuth2::Scheme::Option::Defines;
use Net::OAuth2::Scheme::Random;

# INTERFACE current_secret
# DEFINES
#   current_secret => [v_id, secret, expiration, @secret_payload]
#   current_secret_rekey_check => now -> ; (generate new secret if necessary)
# SUMMARY
#   maintain a current secret for use by format_bearer_signed
#
Define_Group current_secret => 'simple',
  qw(current_secret current_secret_rekey_check);

Default_Value current_secret_rekey_interval => 86400*7; # 7 days
Default_Value current_secret_payload => [];

# IMPLEMENTATION current_secret_simple FOR current_secret
#   (current_secret_)rekey_interval
#   (current_secret_)length
#   (current_secret_)payload
# SUMMARY
#   secret lifetime = 2*rekey_interval;
#   change the secret whenever we are within rekey_interval of expiration;
#   prior secrets remain available from the cache until they expire
# REQUIRES
#   v_id_next
#   vtable_insert
#   random
#
# rekey_interval should be set to be at least as long as the
# longest anticipated lifetime for tokens generated using this secret
# as needed, there will generally be 2 secret keys active,
# and, for every token issued from a given key, the secret for it
# will remain available for at least rekey_interval seconds after issuance, so as long as
# is longer the token lifetime, the token will never be prematurely
# expired.
# Note that for reliable repudiation of secrets, you need to be using
# a shared-cache vtable
sub pkg_current_secret_simple {
    my __PACKAGE__ $self = shift;
    $self->parameter_prefix(current_secret_ => @_);
    my ( $random, $vtable_insert,
         $rekey_interval, $length, $payload)
      = $self->uses_all
        (qw(random   vtable_insert
            current_secret_rekey_interval
            current_secret_length
            current_secret_payload));

    my @stashed = (undef, undef, 0, @$payload);

    my $v_id_next = $self->uses('v_id_next');

    $self->install( current_secret => \@stashed );
    $self->install( current_secret_rekey_check => sub {
        my ($now) = @_;
        my (undef, undef, $expiration) = @stashed;
        if ($expiration < $now + $rekey_interval) {
            my ($v_id, $new_secret, $new_expiration) =
              @stashed = ($v_id_next->(),
                          $random->($length),
                          $now + 2 * $rekey_interval,
                          @$payload);
            $vtable_insert->($v_id,
                             $new_expiration, $now, $new_secret,
                             @$payload);
        }
    });
    return $self;
}


1;


__END__
=pod

=head1 NAME

Net::OAuth2::Scheme::Mixin::Current_Secret - the 'current_secret' option group

=head1 VERSION

version 0.03

=head1 SYNOPSIS

=head1 DESCRIPTION

This is an internal module that implements management of
the shared "current secret" needed for C<bearer_signed> token format.

See L<Net::OAuth2::Scheme::Factory> for actual option usage.

=head1 AUTHOR

Roger Crew <crew@cs.stanford.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

