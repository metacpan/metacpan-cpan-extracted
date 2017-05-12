package POOF::Example::SyntaxError;

use strict;
use warnings;

use base qw(POOF);


#-------------------------------------------------------------------------------
# init 

#-------------------------------------------------------------------------------
# properties

sub SomeProperty : Property Public
{
    {
        'type' => 'integer',
        'default' => 0,
    }
}

#-------------------------------------------------------------------------------
# methods

sub SomeMethod : Method Public
{
    my $obj = shift;
    asdf
}


1;
__END__

=head1 NAME

POOF::Example::SyntaxError - Class with syntax error for testing POOF ability
to detect and renter syntax errors correctly.

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
