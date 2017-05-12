package POOF::Example::Vehicle::Automobile::NissanXterra;

use strict;
use warnings;

use base qw(POOF::Example::Vehicle::Automobile);

use POOF::Example::Tire;


#-------------------------------------------------------------------------------
# init

sub _init : Method Protected 
{
    my $obj = shift;
    my ($args) = $obj->SUPER::_init( @_ );
    
    $obj->{'PassengerCapacity'} = 5;
    $obj->{'CargoCapacity'} = 65.7;
    
    # set in the four tires
    map { $obj->{'Wheels'}->[$_]->{'Tire'} = POOF::Example::Tire->new } (0 .. 3);
    
    return (@_);
}

#-------------------------------------------------------------------------------
# properties

sub Trim : Property Public
{
    {
        'type' => 'string',
        'default' => 'Off-road Edition',
        'groups' => [qw(init)]
    }
}

sub Color : Property Public
{
    {
        'type' => 'enum',
        'default' => 'White',
        'options' => [qw(White Black Red Yellow Pink Blue)],
        'groups' => [qw(init)]
    }
}

sub VIN : Property Public
{
    {
        'type' => 'string',
        'default' => 'ABCDE8D-ABD0-DDCMD-002341',
        'groups' => [qw(init)]
    }
}

#-------------------------------------------------------------------------------
# methods

sub PassengerCapacity : Method Public
{
    my $obj = shift;
    return $obj->{'PassengerCapacity'};
}

sub CargoCapacity : Method Public
{
    my $obj = shift;
    return $obj->{'CargoCapacity'};
}


1;
__END__

=head1 NAME

POOF::Example::Vehicle::Automobile::NissanXterra - Sample class to illustrate POOF.

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
