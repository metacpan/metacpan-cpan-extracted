package Perl::Critic::Policy::Storable::ProhibitStoreOrFreeze;

use strict;
use warnings;

use Perl::Critic::Utils;
use base qw( Perl::Critic::Policy );

our $VERSION = '0.01';

my $DESCRIPTION = q{Use of store or freeze from Storable.pm};
my $EXPLANATION = q{Don't use store or freeze, use nstore or nfreeze instead.};

sub default_severity { return $SEVERITY_MEDIUM   } # What do we think?
sub default_themes   { return qw(storable)       }
sub applies_to       { return 'PPI::Token::Word' }

sub violates {
    my ( $self, $elem, $doc ) = @_;

    return if $elem !~ /^(?:Storable::)?(?:(?:lock_)?store|freeze)$/x;

    return if is_method_call( $elem );
    return if is_hash_key( $elem );
    return if is_subroutine_name( $elem );

    return $self->violation( $DESCRIPTION, $EXPLANATION, $elem );
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::Storable::ProhibitStoreOrFreeze - do not use store or
freeze in Storable.pm

=head1 VERSION

version 0.01

=head1 DESCRIPTION

Imagine the scenario, you've got some Perl code running on a server that uses
Storable's freeze and thaw to serialise Perl data to and from a shared store.
The load on the server increases so you add another one to share the work. The
two of them are happily sharing the workload both reading and writing each
others serialised data, but then you need to add yet another server to handle
the load, but this one is a different hardware platform and bang, your Perl
code breaks.

Why? Because you didn't use the network-aware nfreeze, nstore, or lock_nstore.

=head1 AUTHOR

Matt Dainty <matt@bodgit-n-scarper.com>

=head1 COPYRIGHT

Copyright (c) 2008 Matt Dainty.

This program is free software; you can redistribute is and/or modify it under
the same terms as Perl itself.

=cut
