# $Id: GenericArrayAdapter.pm,v 1.6 2006/06/16 15:20:56 tonyb Exp $
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>
# Modified by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::GenericArrayAdapter;

use strict;
use vars qw(@ISA);
@ISA = qw(Test::C2FIT::TypeAdapter);

sub parse {
    my $self = shift;
    my ($s) = @_;

    return [ split( /,/, $s ) ];
}

sub toString {
    my $self = shift;
    my ($o) = @_;

    return join( ',', @$o );
}

sub equals {
    my $self = shift;
    my ( $a, $b ) = @_;

    return 0 unless ref($a) eq "ARRAY";
    return 0 unless ref($b) eq "ARRAY";

    #DEBUG print "ArrayArrayAdapter::equals ", ref($a), ", ", ref($b), "\n";
    return 0 if scalar @$a != scalar @$b;
    for ( my $i = 0 ; $i < scalar @$a ; ++$i ) {
        return 0 if $$a[$i] ne $$b[$i];
    }
    return 1;
}

1;

__END__

=head1 NAME

Test::C2FIT::GenericArrayAdapter - A type adapter capable of checking equality of two array-refs.


=head1 SYNOPSIS

Typically, you instruct fit to use this TypeAdapter by following (where arrayColumn is the column heading):

	package MyColumnFixture
	use base 'Test::C2FIT::ColumnFixture';
	use strict;
	
	sub new {
	    my $pkg = shift;
	    return $pkg->SUPER::new( fieldColumnTypeMap => { 'arrayColumn' => 'Test::C2FIT::GenericArrayAdapter' } );
	}


=head1 DESCRIPTION


When your data is not stored as string, then you'll propably need an TypeAdapter. Either you 
fill an appropriate hash while instantiating a Fixture, or you overload an appropriate method.

=head1 METHODS

=over 4

=item B<equals($a,$b)>

Checks if the contents of the two given arrays are identical.

=back

=head1 SEE ALSO

Extensive and up-to-date documentation on FIT can be found at:
http://fit.c2.com/


=cut

