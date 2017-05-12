package POOF::Example::Vehicle::Bicycle::BMX;

use strict;
use warnings;

use base qw(POOF::Example::Vehicle::Bicycle);


#-------------------------------------------------------------------------------
# init 

sub _init : Method Private
{
    my $obj = shift;
    my ($args) = $obj->SUPER::_init( @_ );
    
    $obj->{'PassengerCapacity'} = 1;
    $obj->{'CargoCapacity'} = 1;
    
    return (@_);
}

#-------------------------------------------------------------------------------
# properties

sub brand : Property Private
{
    {
        'type' => 'string',
        'default' => 'Mongoose',
        'groups' => [qw(init)]
    }
}

sub model : Property Private
{
    {
        'type' => 'string',
        'default' => 'Brawler 20',
        'groups' => [qw(init)]
    }
}

#-------------------------------------------------------------------------------
# methods

sub Brand : Method Public
{
    my $obj = shift;
    return $obj->{'brand'};
}

sub Model : Method Public
{
    my $obj = shift;
    return $obj->{'brand'};
}

1;
__END__

=head1 NAME

POOF::Example::Vehicle::Bicycle::BMX - Sample class to illustrate POOF.

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
