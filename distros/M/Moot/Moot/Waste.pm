package Moot::Waste;
use Moot::Waste::Scanner;
use Moot::Waste::Lexer;
use Moot::Waste::Decoder;
use Moot::Waste::Annotator;
use strict;


1; ##-- be happy

__END__

=pod

=head1 NAME

Moot::Waste - libmoot : WASTE tokenization system

=head1 SYNOPSIS

  use Moot::Waste;

  #... stuff happens ...

=head1 DESCRIPTION

The Moot::Waste module provides an object-oriented interface to the WASTE tokenization
system included in the libmoot library for Hidden Markov Model decoding.
Currently just a wrapper for:

 use Moot::Waste::Scanner;
 use Moot::Waste::Lexer;

=head1 SEE ALSO

Moot(3perl),
Moot::Waste::Scanner(3perl),
Moot::Waste::Lexer(3perl),
moot(1),
perl(1).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

