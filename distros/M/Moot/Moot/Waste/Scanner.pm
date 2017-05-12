package Moot::Waste::Scanner;
use Moot::TokenReader;
use Carp;
use strict;

our @ISA = qw(Moot::TokenReader);

sub get_sentence {
  confess(__PACKAGE__, "::get_sentence() method not supported");
}

1; ##-- be happy

__END__

=pod

=head1 NAME

Moot::Waste::Scanner - libmoot : WASTE tokenizer : low-level scanner

=head1 SYNOPSIS

  use Moot::Waste::Scanner;

  ##=====================================================================
  ## Usage

  $ws = Moot::Waste::Scanner->new();  ##-- create a new scanner

  $ws->from_file($filename);	      ##-- open a named file
  $tok = $ws->get_token();            ##-- read next token
  $buf = $ws->get_sentence();         ##-- read all remaining tokens as a list
  $ws->close();                       ##-- close current input source

  $ws->reset();                       ##-- reset scanner data

  #... or (almost) any other Moot::TokenReader method

=head1 DESCRIPTION

The Moot::Waste::Scanner module provides an object-oriented interface to the WASTE tokenization
system's low-level rule-based segment scanner stage.
Moot::Waste::Scanner inherits from
L<Moot::TokenReader|Moot::TokenReader>
and supports all
L<Moot::TokenReader|Moot::TokenReader>
API methods.

=head1 SEE ALSO

Moot::TokenReader(3perl),
Moot::Waste(3perl),
Moot(3perl),
waste(1),
perl(1).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

