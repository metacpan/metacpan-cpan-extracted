package POOF::Example::Vehicle::Bicycle;

use strict;
use warnings;

use base qw(POOF::Example::Vehicle);

use POOF::Example::Wheel;

#-------------------------------------------------------------------------------
# init 

sub _init : Method Private
{
    my $obj = shift;
    my ($args) = $obj->SUPER::_init( @_ );
    
    $obj->{'Wheels'}  = POOF::Example::Wheel->new;
    
    return (@_);
}

#-------------------------------------------------------------------------------
# properties

sub Wheels : Property Protected
{
    {
        'type' => 'POOF::Example::Wheel'
    }
}

sub Frame : Property Protected
{
    {
        'type' => 'string'
    }
}

sub HandleBar : Property Protected
{
    {
        'type' => 'string'
    }
};

sub Seat : Property Protected
{
    {
        'type' => 'string'
    }
};

#-------------------------------------------------------------------------------
# methods

1;
__END__

=head1 NAME

POOF::Example::Vehicle::Bicycle - Sample class to illustrate POOF.

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
