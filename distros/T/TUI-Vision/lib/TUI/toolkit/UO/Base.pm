package TUI::toolkit::UO::Base;
# ABSTRACT: Derived UNIVERSAL::Object class for TUI::toolkit

use 5.008;
use strict;
use warnings;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:BRICKPOOL';

use Hash::Util ();
use UNIVERSAL::Object;

BEGIN { require Devel::GlobalDestruction unless $] >= 5.014 }
BEGIN { $] >= 5.010 ? require mro : require MRO::Compat }

our @ISA;
BEGIN { @ISA = ( 'UNIVERSAL::Object' ) }

sub DESTROY {
  my $self  = shift;
  my $class = ref $self || $self;

  Hash::Util::unlock_keys( %$self );

  my $in_global_destruction = defined ${^GLOBAL_PHASE}
    ? ${^GLOBAL_PHASE} eq 'DESTRUCT'
    : Devel::GlobalDestruction::in_global_destruction();

  # Call all DEMOLISH methods starting with the derived classes.
  DEMOLISHALL: {
    no strict 'refs';
    map {
      my $demolish = *{ $_ . '::DEMOLISH' }{CODE};
      $demolish->( $self, $in_global_destruction ) if $demolish;
    } @{ mro::get_linear_isa( $class ) };
  }
  return;
}

1

__END__

=head1 NAME

TUI::toolkit::UO::Base - Derived UNIVERSAL::Object class for TUI::toolkit

=head1 VERSION

version 0.02

=head1 DESCRIPTION

This Module override the C<DESTROY> method to unlock the hash, and pass an 
additional argument C<$in_global_destruction> to the C<DEMOLISH> methods. 

This is required to avoid the warning when objects are destroyed during 
global destruction.

=head1 DEPENDENCIES

=over 4

=item * L<Devel::GlobalDestruction> when using perl < v5.14.

=item * L<MRO::Compat> when using perl < v5.10 

=item * L<Hash::Util>

=item * L<UNIVERSAL::Object>

=back

=head1 SEE ALSO

L<UNIVERSAL::Object>

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 CONTRIBUTORS

Stevan Little <stevan@cpan.org>

=head1 LICENSE

Copyright (c) 2016-2023, 2026 the L</AUTHORS> and L</CONTRIBUTORS> as listed 
above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
