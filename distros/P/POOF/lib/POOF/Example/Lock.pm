package POOF::Example::Lock;

use strict;
use warnings;

use base qw(POOF);

#-------------------------------------------------------------------------------
# init 

sub _init : Method Private
{
    my $obj = shift;
    my $args = $obj->SUPER::_init( @_ );
    
    $obj->{'uniquePattern'} = '1234';
    
    return $args;
}

#-------------------------------------------------------------------------------
# properties

sub uniquePattern : Property Private
{
    {
        'type' => 'string',
        'default' => '',
    }
}

sub state : Property Private
{
    {
        'type' => 'boolean',
        'default' => 1,
    }
}

#-------------------------------------------------------------------------------
# methods

sub Lock : Method Public
{
    my $obj = shift;
    my $key = shift;
    
    if ($obj->validKey($key))
    {
        if ($obj->{'state'} == 0)
        {
            $obj->{'state'} = 1;
            return 1;
        }
        else
        {
            return 0;
        }
    }
    else
    {
        return 0;
    }
}

sub Unlock : Method Public
{
    my $obj = shift;
    my $key = shift;
    
    if ($obj->validKey($key))
    {
        if ($obj->{'state'} == 1)
        {
            $obj->{'state'} = 0;
            return 1;
        }
        else
        {
            return 0;
        }
    }
    else
    {
        return 0;
    }
}

sub validKey : Method Private
{
    my $obj = shift;
    my $key = shift;
    
    if (ref $key eq 'POOF::Example::Key')
    {
        if ($key->UniquePattern eq $obj->{'uniquePattern'})
        {
            return 1;
        }
        else
        {
            return 0;
        }
    }
    else
    {
        return 0;
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

POOF::Example::Lock - Sample class to illustrate POOF.

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
