package POOF::MockObj;

use strict;
use warnings;

use base qw(POOF);

#-------------------------------------------------------------------------------
# init 

#-------------------------------------------------------------------------------
# properties

sub Mock : Property Public
{
    {
        'type' => 'enum',
        'options' => [qw(one two three four)],
        'default' => 'five',
    }
}

#-------------------------------------------------------------------------------
# methods

1;
__END__

=head1 NAME

POOF::MockObj - Utility class used by POOF.

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