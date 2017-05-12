package POOF::Exception;

use 5.007;
use strict;
use warnings;
use base qw(POOF);
use Carp qw(confess croak);

our $VERSION = '1.0';

#-------------------------------------------------------------------------------
# Properties: Core

sub code : Property Public Virtual
{
    {
        'type' => 'integer',
        'min' => 1,
        'groups' => [qw(Init)],
    }
}

sub description : Property Public Virtual
{
    {
        'type' => 'string',
        'regex' => qr/\b[^ ]+\b/,
        'groups' => [qw(Init)],
    }
}

sub value : Property Public Virtual
{
    {
        'type' => 'string',
        'default' => undef,
        'null' => 1,
        'groups' => [qw(Init)],
    }
}

#-------------------------------------------------------------------------------
# Methods: initialization

sub _init
{
    my $obj = shift;
    my %args = $obj->SUPER::_init( @_ );

    # poplulate known form properties passed to the constructor if they are defined
    @{$obj}{ $obj->pGroup('Init') } = @args{ $obj->pGroup('Init') };

    return (%args);
}


1;
__END__

=head1 NAME

POOF::Exception - Utility class used by POOF.

=head1 SYNOPSIS

It is not meant to be used directly.
  
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
