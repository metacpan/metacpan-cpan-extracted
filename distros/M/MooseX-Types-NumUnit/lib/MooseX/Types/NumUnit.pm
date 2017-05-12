package MooseX::Types::NumUnit;

=head1 NAME

MooseX::Types::NumUnit - Type(s) for using units in Moose

=head1 SYNOPSIS

 package MyPackage

 use Moose;
 use MooseX::Types::NumUnit qw/NumUnit NumSI num_of_unit/;

 has 'quantity' => ( isa => NumUnit, default => 0 );
 has 'si_quantity' => ( isa => NumSI, required => 1 );
 has 'length' => ( isa => num_of_unit('m'), default => '1 ft' );

=head1 DESCRIPTION

This module provides types (C<NumUnit> and friends) for Moose which represent physical units. More accurately it provides String to Number coercions, so that even if the user inputs a number with an incorrect (but compatible) unit, it will automatically coerce to a number of the correct unit. 

A few things to note: since C<NumUnit> and friends are subtypes of C<Num>, a purely numerical value will not be coerced. This is by design, but should be kept in mind. Also C<NumUnit> and friends are coerced by default (see L</AUTOMATIC COERCION>).

=cut

use strict;
use warnings;

our $VERSION = "0.04";
$VERSION = eval $VERSION;

use Physics::Unit 0.53 qw/InitUnit GetUnit GetTypeUnit $number_re/;
BEGIN { 
  InitUnit( ['mm'] => 'millimeter' ); 
}

use Carp;

use MooseX::Types -declare => [ qw/ NumUnit NumSI / ];
use MooseX::Types::Moose qw/Num Str/;

use Moose::Exporter;
Moose::Exporter->setup_import_methods (
  as_is => [qw/num_of_unit num_of_si_unit_like/, \&NumUnit, \&NumSI],
);

## For AlwaysCoerce only ##
use namespace::autoclean;
use Moose ();
use MooseX::ClassAttribute ();
use Moose::Util::MetaRole;
###########################

=head1 PACKAGE VARIABLES

=head2 C<$MooseX::Types::NumUnit::Verbose>

When set to a true value, a string representing any conversion will be printed to C<STDERR> during coercion.

=cut

our $Verbose;

=head1 TYPE-LIKE FUNCTIONS

Since version 0.02, C<MooseX::Types::NumUnit> does not provide global types. Rather it has exportable type-like function which behave like types but do not pollute the "type namespace". While they behave like types, remember they are functions and they should not be quoted when called. They are null prototyped though, should they shouldn't (usually) need parenthesis. Futher they are not exported by default and must be requested. For more information about this system see L<MooseX::Types>.

=head2 C<NumUnit>

A subtype of C<Num> which accepts a number with a unit, but discards the unit on coercion to a C<Num>. This is the parent unit for all other units provided herein. Of course those have different coercions.

=cut

subtype NumUnit,
  as Num;

coerce NumUnit,
  from Str,
  via { _convert($_, 'strip_unit') };

=head2 C<NumSI>

A subtype of C<NumUnit> which coerces to the SI equivalent of the unit passed in (i.e. a number in feet will be converted to a number in meters). In truth it is not strictly the SI equivalent, but whatever L<Physics::Unit> thinks is the base unit. This should always be SI (I hope!).

=cut

subtype NumSI, 
  as NumUnit;

coerce NumSI,
  from Str,
  via { _convert($_) };

=head1 ANONYMOUS TYPE GENERATORS

This module provides functions which return anonymous types which satisfy certain criteria. These functions may be exported on request, but are not exported by default. As of version 0.04, if a given unit has already been used to create a C<NumUnit> subtype, it will be returned rather than creating a new subtype object.

=head2 C<num_of_unit( $unit )>

Creates an anonymous type which has the given C<$unit>. If a number is passed in which can be converted to the specified unit, it is converted on coercion. If the number cannot be converted, the value of the attribute is set to C<0> and a warning is thrown. 

=cut

sub num_of_unit {
  die "num_of_unit needs an argument\n" unless @_;
  my $unit = GetUnit( shift );
  return _num_of_unit($unit);
}

=head2 C<num_of_si_unit_like( $unit )>

Creates an anonymous type which has the SI equivalent of the given C<$unit>. This is especially handy for composite units when you don't want to work out by hand what the SI base would be. 

As a simple example, if C<$unit> is C<'ft'>, numbers passed in will be converted to meters! You see, the unit only helps specify the type of unit, however the SI unit is used. Another way to think of these types is as a resticted C<NumSI> of a certian quantity, allowing a loose specification. 

As with C<num_of_unit>, if a number is passed in which can be converted to the specified (SI) unit, it is converted on coercion. If the number cannot be converted, the value of the attribute is set to C<0> and a warning is thrown. 

=cut

sub num_of_si_unit_like {
  die "num_of_si_unit_like needs an argument\n" unless @_;
  my $unit = GetTypeUnit( GetUnit( shift )->type );
  return _num_of_unit($unit);
}

# a hash to store (read: cache) the created NumUnit subtypes by unit name
my %types;

sub _num_of_unit {
  my $unit = shift;
  my $unit_string = $unit->expanded;

  # if an equivalent type exists return it
  if ( defined $types{$unit_string} ) {
    return $types{$unit_string};
  }

  my $subtype = subtype as NumUnit;

  coerce $subtype,
    from Str,
    via { _convert($_, $unit) };

  # cache unit for repeated use
  $types{$unit_string} = $subtype;

  return $subtype;
}

## Conversion engine, takes input, and optionally a Physics::Unit object or the special string 'strip_unit'.

sub _convert {
    my ($input, $requested_unit) = @_;
    $requested_unit ||= '';

    my $unit = $input;
    my $val = $1 if $unit =~ s/($number_re)//i;

    return $val if ($requested_unit eq 'strip_unit');

    my $given_unit = GetUnit( $unit );

    unless ($requested_unit) {
      my $base_unit = GetTypeUnit( $given_unit->type );
      $requested_unit = $base_unit;
    }

    my $req_str = ($requested_unit->name || $requested_unit->def) . " [" . $requested_unit->expanded . "]";

    my $conv_error = 0;
    { 
      local $SIG{__WARN__} = sub { $conv_error = 1 };
      $val *= $given_unit->convert( $requested_unit );
    }

    if ($conv_error) {
      warn "Value supplied ($input) is not of type $req_str, using 0 instead.\n";
      $val = 0;
    } else {
      warn "Converted $input => $val $req_str\n" if $Verbose;
    }

    return $val;
}

=head1 AUTOMATIC COERCION

Since the NumUnit types provided by this module are essentially just C<Num> types with special coercions, it doesn't make sense to use them without coercions enabled on the attribute. To that end, this module mimics L<MooseX::AlwaysCoerce>, with the exception that it only enables coercion on C<NumUnit> and its subtypes. To prevent this, manually set C<< coerce => 0 >> for a given attribute and it will be left alone, or better yet, just use C<Num> as the type.

=cut

## The following is stolen almost directly from MooseX::AlwaysCoerce version 0.16

{
    package MooseX::Types::NumUnit::Role::Meta::Attribute;

    our $VERSION = "0.04";
    $VERSION = eval $VERSION;

    use namespace::autoclean;
    use Moose::Role;

    use MooseX::Types::NumUnit qw/ NumUnit /;

    around should_coerce => sub {
        my $orig = shift;
        my $self = shift;

        my $current_val = $self->$orig(@_);

        return $current_val if defined $current_val;

        my $type = $self->type_constraint;
        return 1 if $type && $type->has_coercion && $type->is_a_type_of(NumUnit);

        return 0;
    };

    package MooseX::Types::NumUnit::Role::Meta::Class;

    our $VERSION = "0.04";
    $VERSION = eval $VERSION;

    use namespace::autoclean;
    use Moose::Role;
    use Moose::Util::TypeConstraints;

    use MooseX::Types::NumUnit qw/ NumUnit /;

    around add_class_attribute => sub {
        my $next = shift;
        my $self = shift;
        my ($what, %opts) = @_;

        if (exists $opts{isa}) {
            my $type = Moose::Util::TypeConstraints::find_or_parse_type_constraint($opts{isa});
            $opts{coerce} = 1 if not exists $opts{coerce} and $type->has_coercion and $type->is_a_type_of(NumUnit);
        }

        $self->$next($what, %opts);
    };
}

my (undef, undef, $init_meta) = Moose::Exporter->build_import_methods(

    install => [ qw(import unimport) ],

    class_metaroles => {
        attribute   => ['MooseX::Types::NumUnit::Role::Meta::Attribute'],
        class       => ['MooseX::Types::NumUnit::Role::Meta::Class'],
    },

    role_metaroles => {
        (Moose->VERSION >= 1.9900
            ? (applied_attribute => ['MooseX::Types::NumUnit::Role::Meta::Attribute'])
            : ()),
        role                => ['MooseX::Types::NumUnit::Role::Meta::Class'],
    }
);

sub init_meta {
    my ($class, %options) = @_;
    my $for_class = $options{for_class};

    MooseX::ClassAttribute->import({ into => $for_class });

    # call generated method to do the rest of the work.
    goto $init_meta;
}

=head1 NOTES

This module defines the unit C<mm> (C<millimeter>) which L<Physics::Unit> inexplicably lacks. 

=head1 SEE ALSO

=over 

=item L<Physics::Unit>

=item L<Math::Units::PhysicalValue>

=item L<MooseX::AlwaysCoerce>

=item L<MooseX::Types>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/MooseX-Types-NumUnit>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

