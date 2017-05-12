# $Id$
package t::P15;
use strict;

sub DEBUG () { 0 }

sub new
{
    my( $package, %args ) = @_;
    DEBUG and warn "new";
    return bless { %args }, $package;
}

sub say
{
    my( $self, $string ) = @_;
    DEBUG and warn "$self->say";
    print "$string\n";
    return 'response';
}


1;
__END__

