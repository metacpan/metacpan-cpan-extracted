package Petrophysics::Units;

# The following POSC (c) products were used in the creation of this work:
#    - epsgUnits.xml
#    - poscUnits.xml
# These files can be downloaded from http://www.posc.org.  Please see
# http://www.posc.org/ebiz/pefxml/patternsobjects.html#units
#
# Due to the POSC Product License Agreement, these files are not
# distributed in their original form.  This derivative work converted
# those files to perl objects, and added unit conversion functionality
# to the objects.

#    This file is part of the "OSPetro" project.  Please see
#    http://OSPetro.sourceforge.net for further details.
#
#    Copyright (C) 2003  Bjarne Steinsbo
#
#    This library is free software; you can redistribute it and/or modify
#    it under the same terms as Perl itself. 
#
#    The author can be contacted at "steinsbo@users.sourceforge.net"

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Nothing exported
our @EXPORT_OK = ();
our @EXPORT = ();
our $VERSION = '0.01';

# Read pre-formatted units database to class variable "@objects".
our @objects;
require 'units_database.inc';
# printf STDERR "%d objects in file\n", scalar @objects;

# Make a lookup table by id
our %by_id = map { $_->id => $_ } @objects;
# And a similar one by short name (annotation)
our %by_annotation = map { $_->annotation => $_ } @objects;


# Lookup a unit by id
sub lookup {
    my ($class, $id) = @_;
    return $by_id{$id};
}

# Lookup a unit by annotation.  Please note that annotation is not
# guaranteed to be unique, so the result is an arbitrary unit with the
# given annotation
sub lookup_annotation {
    my ($class, $annotation) = @_;
    return $by_annotation{$annotation};
}

# Generic search
sub grep {
    my ($class, $expr) = @_;
    # Shift to package main namespace
    package main;
    no strict 'refs';
    return grep (&$expr, @{"${class}::objects"});
}

# Return entire list
sub all_units {
    return \@objects;
}

# Are two units compatible?
sub is_compatible {
    my ($self, $other) = @_;
    my $b1 = $self->is_base_unit ? $self->id : $self->base_unit->id;
    my $b2 = $other->is_base_unit ? $other->id : $other->base_unit->id;
    return $b1 eq $b2;
}

# Convert to base unit
sub convert_to_base {
    my ($self, $nr) = @_;
    return $self->is_base_unit ? $nr : (
	($self->A + $self->B * $nr) / ($self->C + $self->D * $nr)
    );
}

# Convert from one unit to another.  Just one scalar value converted.
sub scalar_convert {
    my ($self, $other, $nr) = @_;
    return undef unless $self->is_compatible ($other);
    $nr = $self->convert_to_base ($nr);
    return $other->is_base_unit ? $nr : (
	($other->C * $nr - $other->A) / ($other->B - $other->D * $nr)
    );
}

# Convert from one unit to another.  Convert an array of values.
# The user is probably using the array version for performance reasons,
# so take some care to reduce number of method invocations.
sub vector_convert {
    my ($self, $other, $vec) = @_;
    my @out;
    return undef unless $self->is_compatible ($other);
    if ($self->is_base_unit) {
	@out = @$vec;
    } else {
	my ($A, $B, $C, $D) = ($self->A, $self->B, $self->C, $self->D);
	@out = map { ($A + $B * $_) / ($C + $D * $_) } @$vec;
    }
    unless ($other->is_base_unit) {
	my ($A, $B, $C, $D) = ($other->A, $other->B, $other->C, $other->D);
	$_ = ($C * $_ - $A) / ($B - $D * $_) foreach (@out);
    }
    return \@out;
}

# Accessor routines
sub id { shift->{id} };
sub name { shift->{name} };
sub annotation { shift->{annotation} };
sub quantity_type { shift->{quantity_type} };
sub catalog_name { shift->{catalog_name} };
sub catalog_symbol { shift->{catalog_symbol} };
sub description { shift->{description} };
sub base_unit { shift->{base_unit} };
sub display { shift->{display} };
sub A { shift->{A} };
sub B { shift->{B} };
sub C { shift->{C} };
sub D { shift->{D} };
sub is_base_unit { exists shift->{is_base} };

1;
__END__

=head1 NAME

Petrophysics::Units - Perl extension for a "database" of units of measurement,
and methods to search/lookup units and do conversion.

=head1 SYNOPSIS

 use Petrophysics::Units;
 
 # Lookup unit by unique id
 my $m = Petrophysics::Units->lookup ('m');
 
 # Or by annotation.
 # There is no guarantee that the annotation is unique.
 # So treat with care..
 my $ft = Petrophysics::Units->lookup_annotation ('ft');
 
 # Are the two units compatible?
 printf "They are%s compatible\n", $m->is_compatible ($ft) ? '' : ' not';
 
 # Convert 1000 meters to feet
 my $number = $m->scalar_convert ($ft, 1000.0);
 
 # Convert an array of values from meters to feet
 my $numbers = $m->vector_convert (
        $ft, [ 1000.0, 2000.0, 3000.0 ]
 );
 
 for my $u ($m, $ft) {
   printf "Unit unique id = '%s' is%s a base unit\n",
        $u->id, $u->is_base_unit ? '' : ' not';
   printf "Unit long name = '%s'\n", $u->name;
   printf "Unit short name (annotation) = '%s'\n", $u->annotation;
   printf "Unit quantity type = '%s'\n",
        ($u->quantity_type || 'unknown');
   printf "Unit display = '%s'\n", ($u->display || 'unknown');
   printf "Unit catalog name = '%s'\n", $u->catalog_name;
   printf "Unit catalog symbol = '%s'\n", $u->catalog_symbol;
   if ($u->is_base_unit) {
     printf "Unit description = '%s'\n", $u->description;
   } else {
     printf "Unit base unit = '%s'\n", $u->base_unit->id;
     print "Unit conversion to base = (A + Bx)/(C + Dx)\n";
     printf "  A = %.6f, B = %.6f, C = %.6f, D = %.6f\n",
        $u->A, $u->B, $u->C, $u->D;
   }
 }
 
 # Generic search
 my @units = Petrophysics::Units->grep (
        sub { $_->annotation =~ /ft/ }
 );
 
 # Return all defined units
 my @all_units = Petrophysics::Units->all_units;
 

=head1 ABSTRACT

A "database" of units of measurement, and methods to lookup/search this
database and to convert numbers from one unit to another.

=head1 POSC

The following POSC (c) products were used in the creation of this work:

=over 3

=item *

epsgUnits.xml

=item *

poscUnits.xml

=back

These files can be downloaded from L<http://www.posc.org>.  Please see
L<http://www.posc.org/ebiz/pefxml/patternsobjects.html#units>.

POSC's license does not allow redistribution of unchanged files, nor using
POSC in the name of a derived product.  POSC will not guarantee the accuracy
of this data, nor will I.

=head1 DESCRIPTION

The "database" is provided in a file ("units_database.inc") which "happens"
to contain text directly parsable by perl.  The original databases were
written in xml.

The database is included by this module, all objects in the database "happen"
to be blessed into the correct class, and the class then includes methods to
lookup units from the database, to search for units in the database, and to
convert numbers from one unit to another.

Please note: Only the id of a unit is guaranteed to be unique.  The
annotation is almost unique, and is probably unique enough for
normal use (and also far more readable).

The utility to convert the original database (xml files) to perl is included
(but not installed) for reference.

=head1 EXPORT

None by default.

=head1 SEE ALSO

The following modules can be found on CPAN.  Please check if any of those
could satisfy your unit conversion needs better than this module.

=over 3

=item *

Math::Unit

=item *

Physics::Unit

=back


This file is part of the "OSPetro" project.  Please see
L<http://OSPetro.sourceforge.net> for further details.

=head1 AUTHOR

Bjarne Steinsbo, E<lt>steinsbo@users.sourceforge.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Bjarne Steinsbo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

