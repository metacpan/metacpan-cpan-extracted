package POOF::Example::Rim;

use strict;
use warnings;

use Carp qw(croak);
use base qw(POOF);


#-------------------------------------------------------------------------------
# init 

#-------------------------------------------------------------------------------
# properties

sub diameter : Property Public
{
    {
        'type' => 'float',
        'default' => 15.5,
        'groups' => [qw(init)]
    }
}

sub width : Property Public
{
    {
        'type' => 'float',
        'default' => 8.5,
        'groups' => [qw(init)]
    }
}

sub alloy : Property Public
{
    {
        'type' => 'string',
        'default' => 'Aluminum',
        'groups' => [qw(init)]
    }
}

sub trim : Property Public
{
    {
        'type' => 'string',
        'default' => 'Trundra Xtreme',
        'groups' => [qw(init)]
        
    }
}

sub make : Property Public
{
    {
        'type' => 'string',
        'default' => 'Rims-R-US',
        'groups' => [qw(init)]
    }
}

#-------------------------------------------------------------------------------
# methods

sub Make : Method Public _virtual
{
    my $obj = shift;
    return $obj->{'make'};
}

sub Model : Method Public
{
    my $obj = shift;
    return $obj->Size . qq| : $obj->{'trim'} ($obj->{'alloy'})|;
}

sub Size : Method Public
{
    my $obj = shift;
    return qq|$obj->{'diameter'}/$obj->{'width'}|;
}

1;
__END__

=head1 NAME

POOF::Example::Rim - Sample class to illustrate POOF.

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
