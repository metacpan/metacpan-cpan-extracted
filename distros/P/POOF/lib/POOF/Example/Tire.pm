package POOF::Example::Tire;

use strict;
use warnings;

use Carp qw(croak);
use base qw(POOF);


#-------------------------------------------------------------------------------
# init 

#-------------------------------------------------------------------------------
# properties

sub diameter : Property Private
{
    {
        'type' => 'float',
        'default' => 15.5,
        'groups' => [qw(init)]
    }
}

sub width : Property Private
{
    {
        'type' => 'float',
        'defauklt' => 8.5,
        'groups' => [qw(init)]
    }
}

sub height : Property Private
{
    {
        'type' => 'float',
        'default' => 7.25,
        'groups' => [qw(init)]
    }
}

sub threadType : Property Private
{
    {
        'type' => 'string',
        'default' => 'All Terrain THX',
        'groups' => [qw(init)]
    }
}

sub make : Property Private
{
    {
        'type' => 'string',
        'default' => 'GoodYear',
        'groups' => [qw(init)]
    }
}

#-------------------------------------------------------------------------------
# methods

sub Make : Method Public Virtual
{
    my $obj = shift;
    return $obj->{'make'};
}

sub Model : Method Public
{
    my $obj = shift;
    return $obj->Size . qq| : $obj->{'threadType'}|;
}

sub Size : Method Public
{
    my $obj = shift;
    return $obj->RimSize . qq|-$obj->{'height'}|;
}

sub RimSize : Method Public
{
    my $obj = shift;
    return qq|$obj->{'diameter'}/$obj->{'width'}|;
}

1;
__END__

=head1 NAME

POOF::Example::Tire - Sample class to illustrate POOF.

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
