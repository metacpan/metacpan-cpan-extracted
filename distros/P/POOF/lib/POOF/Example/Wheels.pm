package POOF::Example::Wheels;

use strict;
use warnings;

use base qw(POOF::Collection);


#-------------------------------------------------------------------------------
# init 


#-------------------------------------------------------------------------------
# properties

#-------------------------------------------------------------------------------
# methods

sub Count : Method Public
{
    my ($obj) = @_;
    return @{$obj};
}



1;
__END__

=head1 NAME

POOF::Example::Wheels - Sample class to illustrate POOF::Collection.

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