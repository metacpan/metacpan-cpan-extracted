package Physics::Ballistics;
use strict;
use warnings;

# Work in progress; currently useless except for documentation.
# Would like this to become an easy, powerful interface akin to http://www.shooterscalculator.com/ballistic-trajectory-chart.php?t=0c84354b
# Generate graphs from multiple profiles via flight_sim, ebc, lethality, etc.
# Include in output statistics about weight and recoil.

use Math::Trig;

our $VERSION = '1.03';
our $PI = Math::Trig::pi;

sub setundef { ${$_[0]} = $_[1] unless ( defined ( ${$_[0]} ) ); }
sub absolute { $_[0] = 0 - $_[0] if ( $_[0] < 0 ); return $_[0]; }

our %FUNCTION_DEPENDENCIES_H = (
  'ebc' => [
      {label => 'proj_mass',  unit => 'grain'},
      {label => 'proj_diam',  unit => 'mm'},
      [{label => 'proj_shape', unit => ''}, {label => 'proj_form_factor', unit => ''}], # list means one or the other must be defined
      ],
  'flight_simulator' => [
      {label => 'drag_model', unit => ''},
      {label => 'proj_bc', unit => ''},
      {label => 'velocity', unit => 'fps'},
      {label => 'sight_height', unit => 'inch'},
      {label => 'shot_angle', unit => 'degree'},
      {label => 'zero_range', unit => 'yard'}
      ],
  'muzzle_energy' => [
      {label => 'proj_mass', unit => 'grain'},
      {label => 'velocity', unit => 'fps'}
      ],
  'muzzle_velocity_from_energy' => [
      {label => 'proj_mass', unit => 'grain'},
      {label => 'proj_ke', unit => 'ftlb'},
      ],
  'cartridge_capacity' => [
      {label => 'proj_diam', unit => 'mm'},
      {label => 'case_base_diam', unit => 'mm'},
      {label => 'case_len', unit => 'mm'},
      {label => 'pressure', unit => 'psi'}
      ],
  'empty_brass' => [
      {label => 'proj_diam', unit => 'mm'},
      {label => 'case_base_diam', unit => 'mm'},
      {label => 'case_len', unit => 'mm'},
      {label => 'pressure', unit => 'psi'}
      ],
  'gunfire' => [
      {label => 'proj_diam', unit => 'mm'},
      {label => 'case_base_diam', unit => 'mm'},
      {label => 'case_len', unit => 'mm'},
      {label => 'pressure', unit => 'psi'},
      {label => 'proj_mass', unit => 'grain'},
      {label => 'barrel_len', unit => 'inch'}
      ],
  'powley' => [
      {label => 'proj_diam', unit => 'mm'},
      {label => 'case_base_diam', unit => 'mm'},
      {label => 'case_len', unit => 'mm'},
      {label => 'barrel_reference_len', unit => 'inch'},
      {label => 'barrel_len', unit => 'inch'}
      ],
  'ke' => [
      {label => 'velocity', unit => 'mps'},
      {label => 'proj_mass', unit => 'grain'}
      ],
  'penetration_rha' => [ # Physics::Ballistics::Terminal::pc()
      {label => 'proj_mass', unit => 'grain'},
      {label => 'velocity', unit => 'fps'},
      {label => 'proj_diam', unit => 'inch'},
      {label => 'proj_composition', unit => ''}
      ],
  'penetration_flesh' => [ # Physics::Ballistics::Terminal::poncelet()
      {label => 'proj_mass', unit => 'grain'},
      {label => 'velocity', unit => 'fps'},
      {label => 'proj_diam', unit => 'inch'},
      {label => 'proj_composition', unit => ''}
      ]
  );

our %FUNCTION_PRODUCT_H = (
  'ebc' => [
      {label => 'proj_bc',  unit => 'grain'},
      ],
  'flight_simulator' => [
      {label => 'flight_ar', unit => 'list'}
      ],
  'muzzle_energy' => [
      {label => 'proj_ke', unit => 'ftlb'}
      ],
  'muzzle_velocity_from_energy' => [
      {label => 'reference_velocity', unit => 'fps'}
      ],
  'cartridge_capacity' => [
      {label => 'case_volume', unit => 'grain_water'}
      ],
  'empty_brass' => [
      {label => 'case_mass', unit => 'grain'}
      ],
  'gunfire' => [
      {label => '', unit => 'hash', mapping => {
          'N*m' => {label => 'proj_ke', unit => 'joule'},
          'f/s' => {label => 'velocity', unit => 'fps'} # zzapp -- whenever setting velocity, also set reference velocity for 24" barrel
          }}
      ],
  'powley' => [
      # special-case -- multiply by reference velocity to get new velocity -- zzapp
      ],
  'ke' => [
      {label => 'proj_ke', unit => 'joule'}
      ],
  'penetration_rha' => [ # Physics::Ballistics::Terminal::pc()
      {label => 'proj_penetration_rha', unit => 'mm'}
      ],
  'penetration_flesh' => [ # Physics::Ballistics::Terminal::poncelet()
      {label => 'proj_penetration_flesh', unit => 'mm'}
      ]
  );

1;

=head1 NAME

Physics::Ballistics -- Ballistics formulae.

=head1 ABSTRACT

Ballistics is the study of the launching, flight and effects of projectiles.
This distribution provides various formulae producing metrics of internal,
external and terminal ballistics.

These formulae are primarily oriented towards the ballistics of small arms 
bullets between 5mm and 14mm and diameter, and to a lesser extent heavier 
hypervelocity projectiles ("long rod" penetrators) and shaped charges.

More extensive documentation is available in each of these three constituent 
modules.

=head1 MODULES

L<Physics::Ballistics::Internal> - launch mechanics

L<Physics::Ballistics::External> - flight mechanics

L<Physics::Ballistics::Terminal> - terminal effects

=head1 TODO

I would like Physics::Ballistics to provide the integrated functionality of 
these modules in an object-oriented way, someday.

Some rocket physics functions are works in progress.  Those might get integrated here eventually.

The units used and returned by these functions are horribly inconsistent, but at least they are documented.  They might be made more consistent in the future.

See also the individual modules for module-specific to-do lists.

=head1 AUTHOR

TTK Ciar, <ttk[at]ciar[dot]org>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2017 by TTK Ciar

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
