#
# Martin Busik <martin.busik@busik.de>

package Test::C2FIT::ScientificDoubleTypeAdapter;
use base 'Test::C2FIT::TypeAdapter';
use Test::C2FIT::ScientificDouble;

sub parse {
    my $self  = shift;
    my $value = shift;
    return Test::C2FIT::ScientificDouble->new($value);
}

sub toString {
    my ( $self, $value ) = @_;
    return $value->toString;
}

sub equals {
    my ( $self, $a, $b ) = @_;
    return $a->equals($b);
}

1;

__END__

=head1 NAME

Test::C2FIT::ScientificDoubleTypeAdapter - A type adapter capable of checking float numbers


=head1 SYNOPSIS

Typically, you instruct fit to use this TypeAdapter by following (where aColumn is the column heading):

	package MyColumnFixture
	use base 'Test::C2FIT::ColumnFixture';
	use strict;
	
	sub new {
	    my $pkg = shift;
	    return $pkg->SUPER::new( fieldColumnTypeMap => { 'aColumn' => 'Test::C2FIT::ScientificDoubleTypeAdapter' } );
	}


=head1 DESCRIPTION

Better support for equality checking of floats than abs($a - $b) < $threshold


=head1 SEE ALSO

Extensive and up-to-date documentation on FIT can be found at:
http://fit.c2.com/


=cut

