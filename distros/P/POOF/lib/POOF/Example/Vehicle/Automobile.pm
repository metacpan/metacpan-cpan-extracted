package POOF::Example::Vehicle::Automobile;

use strict;
use warnings;

use base qw(POOF::Example::Vehicle);

use POOF::Example::Lock;
use POOF::Example::Engine;
use POOF::Example::Wheels;

#-------------------------------------------------------------------------------
# init 

sub _init : Method Protected Virtual
{
    my $obj = shift;
    my ($args) = $obj->SUPER::_init( @_ );
    
    $obj->{'Engine'} = POOF::Example::Engine->new;
    #$obj->{'Wheels'} = POOF::Example::Wheel->new;
    
    return (@_);
}

#-------------------------------------------------------------------------------
# properties

sub Engine : Property Protected
{
    {
        'type' => 'POOF::Example::Engine'
    }
}

sub Wheels : Property Public
{
    {
        'type' => 'POOF::Example::Wheels',
        'ofilter' => sub
        {
            my ($obj,$val) = @_;
            unless($val)
            {
                my $wheels = POOF::Example::Wheels->new(
                    'name'      => 'Wheels',
                    'access'    => 'Public',
                    'otype'     => 'POOF::Example::Wheel',
                    'maxsize'   => 4,
                );
                $obj->{'Wheels'} = $wheels;
                return $wheels;
            }
            return $val;
        }
    }
}

sub lock : Property Private
{
    {
        'type' => 'POOF::Example::Lock',
        'ofilter' => sub
        {
            my ($obj,$val) = @_;
            unless($val)
            {
                #warn "Trying ton instantiate lock\n";
                $obj->{'lock'} = POOF::Example::Lock->new;
                return $obj->{'lock'};
            }
            return $val;
        }
    }
}

sub state : Property Private
{
    {
        'type' => 'string'
    }
};

#-------------------------------------------------------------------------------
# methods
    
sub StartEngine : Method Public
{
    my $obj = shift;
    my $key = shift;
    
    if ($obj->{'lock'}->Unlock($key))
    {
        my $result = $obj->{'Engine'}->StartEngine;
        my $engineState = $obj->{'Engine'}->GetState;
        
        $obj->{'state'} =
            $engineState
                ? 'running'
                : 'stoped';
                
        return $result;
    }
    else
    {
        return 0;
    }
}

sub StopEngine : Method Public
{
    my $obj = shift;
    my $key = shift;
    
    if ($obj->{'lock'}->Lock($key))
    {
        my $result = $obj->{'Engine'}->StopEngine;
        my $engineState = $obj->{'Engine'}->GetState;
        
        $obj->{'state'} =
            $engineState
                ? 'running'
                : 'stoped';
                
        return $result;
    }
    else
    {
        return 0;
    }
}


1;
__END__

=head1 NAME

POOF::Example::Vehicle::Automobile - Sample class to illustrate POOF.

=head1 SYNOPSIS

Todo
  
=head1 SEE ALSO

POOF man page.

=head1 AUTHOR

Benny Millares <bmillares@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Benny Millares

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
