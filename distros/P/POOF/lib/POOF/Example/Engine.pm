package POOF::Example::Engine;

use strict;
use warnings;

use base qw(POOF);


#-------------------------------------------------------------------------------
# init 


#-------------------------------------------------------------------------------
# properties

sub Cylinders : Property Public
{
    {
        'type' => 'integer',
        'default' => 0,
    }
}

sub Displacement : Property Public
{
    {
        'type' => 'float',
        'default' => 0.0,
    }
}

sub state : Property Private
{
    {
        'type' => 'boolean',
        'default' => 0
    }
}

#-------------------------------------------------------------------------------
# methods

sub StartEngine : Method Public
{
    my $obj = shift;
    
    if ($obj->{'state'} == 1)
    {
        return 0;
    }
    else
    {
        $obj->{'state'} = 1;
        return 1;
    }
}

sub StopEngine : Method Public
{
    my $obj = shift;
    
    if ($obj->{'state'} == 0)
    {
        return 0;
    }
    else
    {
        return 1;
    }
}

sub GetState : Method Public
{
    my $obj = shift;
    return $obj->{'state'};
}



1;
__END__

=head1 NAME

POOF::Example::Engine - Sample class to illustrate POOF.

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

