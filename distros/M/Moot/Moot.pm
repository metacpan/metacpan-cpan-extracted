package Moot;

use 5.008004;
use strict;
use warnings;
use Carp;
#use AutoLoader;
use Exporter;

our @ISA = qw(Exporter);

our $VERSION = '2.0.13';

require XSLoader;
XSLoader::load('Moot', $VERSION);

# Preloaded methods go here.
require Moot::Constants;
require Moot::Lexfreqs;
require Moot::Ngrams;
require Moot::HMM;
require Moot::HMM::Dyn;
require Moot::HMM::DynLex;
require Moot::HMM::Boltzmann;
require Moot::TokenIO;
require Moot::TokPP;
require Moot::Waste;

# Autoload methods go after =cut, and are processed by the autosplit program.

##======================================================================
## Exports
##======================================================================
our @EXPORT = qw();
our %EXPORT_TAGS = qw();

##======================================================================
## Constants
## + see Moot/Constants.pm
##======================================================================


##======================================================================
## Exports: finish
##======================================================================
our @EXPORT_OK = map { @$_ } values(%EXPORT_TAGS);
$EXPORT_TAGS{constants} = \@EXPORT_OK;


1;

__END__
=pod

=head1 NAME

Moot - Perl interface to the libmoot part-of-speech tagging library

=head1 SYNOPSIS

  use Moot;

  ##... stuff happens

=head1 DESCRIPTION

The Moot module provides an object-oriented interface to the libmoot library
for Hidden Markov Model part-of-speech tagging.

=head1 SEE ALSO

Moot::HMM(3perl),
Moot::Constants(3perl),
Moot::Lexfreqs(3perl),
Moot::Ngrams(3perl),
Moot::HMM(3perl),
Moot::TokenIO(3perl),
Moot::Waste(3perl),
moot(1),
perl(1).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2016 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
