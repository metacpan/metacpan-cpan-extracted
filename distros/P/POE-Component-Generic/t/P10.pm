# $Id: P10.pm 198 2007-02-28 18:45:18Z fil $
package t::P10;
use strict;

sub DEBUG () { 0 }

sub new
{
    my( $package, %args ) = @_;
    DEBUG and warn "new";
    return bless { %args }, $package;
}

sub delay
{
    my( $self ) = @_;
    DEBUG and warn "$self->delay";
    my $before=time;
    sleep( $self->{delay} );
    DEBUG and warn "AFTER";
    return ($before, time);
}

sub set_delay
{
    my( $self, $new ) = @_;
    DEBUG and warn "$self->set_delay( $new )";
    $self->{delay} = $new;
    return;
}

sub get_delay
{
    my( $self ) = @_;
    return $self->{delay};
}

sub die_for_your_country
{
    my( $self, $text ) = @_;
    die $text;
}

sub sing
{
    my( $self, $text ) = @_;
    print STDERR $text, "\n";
}
    
1;
__END__

