package POOF::Example::Key;

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

#-------------------------------------------------------------------------------
# methods

sub UniquePattern : Method Public
{
    my $obj = shift;
    return $obj->{'uniquePattern'};
}

1;
__END__

=head1 NAME

POOF::Example::Key - Sample class to illustrate POOF.

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

