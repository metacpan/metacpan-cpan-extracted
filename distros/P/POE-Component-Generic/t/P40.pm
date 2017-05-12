# $Id: P40.pm 324 2008-01-24 02:47:59Z fil $
package t::P40;
use strict;

sub DEBUG () { 0 }

sub new
{
    my( $package, %args ) = @_;
    DEBUG and warn "new";
    return bless { %args }, $package;
}

sub something
{
    my( $self, $one, $coderef, $two ) = @_;

    $self->{coderef1} = $coderef;
    return $one+$two;
}

sub otherthing
{
    my( $self, $coderef, @other ) = @_;

    $self->{coderef2} = $coderef;
    return scalar @other;
}

sub twothing
{
    my( $self ) = @_;
    
    $self->{coderef1}->( 17 ) if $self->{coderef1};
    $self->{coderef2}->( 42 ) if $self->{coderef2};
    return;
}

sub holder
{
    my( $self, $key, $code ) = @_;
    $self->{code}{$key} = $code;
    return;
}

sub runner
{
    my( $self, $key, @args ) = @_;
    return "Unknown code: $key" unless $self->{code}{$key};
    return $self->{code}{$key}->( @args );
}


1;
__END__

