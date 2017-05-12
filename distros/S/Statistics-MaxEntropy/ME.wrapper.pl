#! /Utils/bin/perl5.00502
#! /usr/bin/perl

##---------------------------------------------------------------------------##
##  Author: Hugo WL ter Doest       terdoest@cs.utwente.nl
##  Description: Wrapper around Statistics::MaxEntropy
##
##---------------------------------------------------------------------------##
##  Copyright (C) 1998, 1999 Hugo WL ter Doest terdoest@cs.utwente.nl
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program; if not, write to the Free Software
##  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
##---------------------------------------------------------------------------##



##---------------------------------------------------------------------------##
##	Require libraries
##---------------------------------------------------------------------------##
use strict;
use diagnostics -verbose;
use Getopt::Long;
use Statistics::MaxEntropy qw($debug
			      $KL_max_it
			      $NEWTON_max_it
			      $KL_min
			      $NEWTON_min
			      $SAMPLE_size
			      );
use Statistics::Candidates;

use vars qw($PROG
	    $VERSION
	    $help
	    $events
	    $candidates
	    $i_dump_file
	    $o_dump_file
	    $events_file
	    $new_events_file
	    $parameters_file
	    $parameters_with_names_file
	    $new_parameters_file
	    $candidates_file
	    $new_candidates_file
	    $nr_to_add
	    $integer
	    $GIS
	    $IIS
	    $MC
	    $CORPUS
	    $ENUM);
	    


##---------------------------------------------------------------------------##
##	Globals
##---------------------------------------------------------------------------##
($PROG = $0) =~ s/.*\///;
$VERSION = "0.2";


##---------------------------------------------------------------------------##
##	Routines
##---------------------------------------------------------------------------##

# parse command line and read some files
sub prologue {
    my($integerstring);

    print "$0 $VERSION\n";
    GetOptions("help!", \$help,
	       "debug!" , \$debug,
	       "i_events=s" , \$events_file,
	       "i_parameters=s" , \$parameters_file,
	       "i_candidates=s" , \$candidates_file,
	       "o_events=s" , \$new_events_file,
	       "o_candidates=s" , \$new_candidates_file,
	       "o_parameters=s" , \$new_parameters_file,
	       "special=s", \$parameters_with_names_file,
	       "i_dump=s", \$i_dump_file,
	       "o_dump=s", \$o_dump_file,
	       "integer!", \$integer,
	       "KL_max_it=i", \$KL_max_it,
	       "NEWTON_max_it=i", \$NEWTON_max_it,
	       "KL_min=f", \$KL_min,
	       "NEWTON_min=f", \$NEWTON_min,
	       "nr_to_add=i", \$nr_to_add,
	       "GIS!", \$GIS,
	       "IIS!", \$IIS,
	       "MC!", \$MC,
	       "CORPUS!", \$CORPUS,
	       "ENUM!", \$ENUM,
	       "SAMPLE=i", \$SAMPLE_size
	       );

    if ($help) {
	usage();
    }

    $integerstring = "binary";
    if ($integer) {
	$integerstring = "integer";
    }

    if ($events_file) {
	$events = Statistics::MaxEntropy->new($integerstring, $events_file);
    }
    elsif ($i_dump_file) {
	$events = Statistics::MaxEntropy->undump($i_dump_file);
    }
    if ($parameters_file) {
	$events->read_parameters($parameters_file);
    }
    if ($candidates_file) {
	$candidates = Statistics::Candidates->new($candidates_file);
    }
}


sub usage {
    print STDOUT <<EndOfUsage;
$main::PROG -- a wrapper around Statistics::MaxEntropy for easy use

 ME.wrapper.pl --help
	       --debug
               --i_events <filename>
               --i_candidates <filename>
               --i_dump <filename>
               --o_events <filename>
               --o_candidates <filename>
               --o_parameters <filename>
               --special <filename>
               --o_dump <filename>
	       --integer
	       --KL_max_it <integer>
	       --NEWTON_max_it <integer>
	       --KL_min <float>
	       --NEWTON_min <float>
	       --nr_to_add <integer>
	       --SAMPLE <integer>
	       --GIS
	       --IIS
	       --MC
	       --CORPUS
	       --ENUM

Version: $main::VERSION
  Copyright (C) 1998  Hugo WL ter Doest, terdoest\@cs.utwente.nl
  $main::PROG comes with ABSOLUTELY NO WARRANTY and may be copied
  only under the terms of the GNU General Public License (version 2, or
  later), which may be found in the distribution.
EndOfUsage

    exit 0;
}


# run the feature induction algorithm, using either GIS or IIS
sub run {
    my($scale_string,
       $sampling_string);

    $scale_string = "iis"; # default
    if ($GIS) {
	$scale_string = "gis";
    }
    $sampling_string = "corpus"; # default
    if ($MC) {
	$sampling_string = "mc";
    }
    if ($CORPUS) {
	$sampling_string = "corpus";
    }
    if ($ENUM) {
	$sampling_string = "enum";
    }
    if ($nr_to_add && $candidates) {
	$events->fi($scale_string,
		    $candidates,
		    $nr_to_add,
		    $sampling_string);
    }
    elsif ($events) {
	$events->scale($sampling_string, $scale_string);
    }
}


# write some information files
sub epilogue {
    if ($events) {
	if ($parameters_with_names_file) {
	    $events->write_parameters_with_names($parameters_with_names_file);
	}
	if ($new_parameters_file) {
	    $events->write_parameters($new_parameters_file);
	}
	if ($new_events_file) {
	    $events->write($new_events_file);
	}
	if ($o_dump_file) {
	    $events->dump($o_dump_file);
	}
    }
    if ($candidates) {
	if ($new_candidates_file) {
	    $candidates->write($new_candidates_file);
	}
    }
}


##------------[MAIN]---------------------------------------------------------##

prologue();
run();
epilogue();

##------------[MAIN]---------------------------------------------------------##


# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

ME.wrapper.pl - a wrapper around C<Statistics::MaxEntropy> and C<Statistics::Candidates>


=head1 SYNOPSIS

 ME.wrapper.pl --help
	       --debug
               --i_events <filename>
               --i_candidates <filename>
               --i_dump <filename>
               --o_events <filename>
               --o_candidates <filename>
               --o_parameters <filename>
               --special <filename>
               --o_dump <filename>
	       --integer
	       --KL_max_it <integer>
	       --NEWTON_max_it <integer>
	       --KL_min <float>
	       --NEWTON_min <float>
	       --nr_to_add <integer>
	       --SAMPLE <integer>
	       --GIS
	       --IIS
	       --MC
	       --CORPUS
	       --ENUM


=head1 DESCRIPTION

C<ME.wrapper.pl> is a command-line interface to
C<Statistics::MaxEntropy> and C<Statistics::Candidates>. The wrapper
and its command line options provide an easy-to-use and transparent
connection to the MaxEntropy modules. Below we explain the meaning of
the options.


=head1 COMMAND LINE ARGUMENTS

We explain the command line options, and state the at which moment
they are applied or executed. For this we assume the main program of
C<ME.wrapper.pl> to have the following form

 prologue();
 run();
 epilogue();

If both candidates and events are specified, the feature induction
algorithm is called. If only events are specified a scaling algorithm
is called (GIS by default).

=over 4

=item C<--integer>

Specifies whether the feature functions should be interpreted as
binary or integer functions.

=item C<--KL_max_it integer>

(set in prologue) The maximum number of iterations performed by the
scaling algorithms.

=item C<--NEWTON_max_it integer>

(set in prologue) The maximum number of iteration in Newton's method
(IIS only).

=item C<--KL_min integer>

(set in prologue) The minimum difference in Kullback-Leibler
divergence that a new scale iteration should bring. Otherwise Scaling
is stopped.

=item C<--NEWTON_min float>

(set in prologue) The minimum difference between the new x and the old
x in Newton's method (IIS only).

=item C<--nr_to_add integer>

(used in run) Passed to the feature induction algorithm (if
called). It states the number of candidates that should be added.

=item C<--SAMPLE integer>

(used in run) Passed to the feature induction algorithm (if
called). It determines the size of the Monte Carlo sample. Only makes
sense if C<--MC> is set.

=item C<--GIS>

(used in run) Sets the scaling algorithm to to Generalised Iterative
Scaling.

=item C<--IIS>

(used in run) Sets the scaling algorithm to Improved Iterative
Scaling.

=item C<--MC>

(used in run) Sets the sampling method to Monte Carlo. See also the
C<--SAMPLE> option.

=item C<--CORPUS>

(used in run) Tells the scaling algorithm to consider the event space
a good sample (risky: overtraining).

=item C<--ENUM>

(used in run) For scaling the complete event space (all bitvectors)
should be enumerated. This is done in memory, so beware!

=item C<--help>

(done in prologue) Exits after showing the name of the program, and
the list of command line options.

=item C<--debug>

(set in prologue) Tells the C<MaxEntropy> and C<Candidates> modules to
output a lot of text.

=item C<--i_events filename>

(done in prologue) The events are read from <filename>.

=item C<--i_candidates filename>

(done in prologue) The candidates are read from <filename>.

=item C<--i_dump filename>

(done in prologue) An event space read from the dump in
<filename>. This option overrules C<--i_events> option.

=item C<--o_events filename>

(done in epilogue) The events (including candidates that were added)
are written to C<filename>.

=item C<--o_candidates filename>

(done in epilogue) The candidates (if present) are written to
C<filename>. Only candidates that were not added to the event space
are written.

=item C<--o_parameters filename>

(done in epilogue) The parameters are written to C<filename>.

=item C<--special filename>

(done in epilogue) The parameters are written to C<filename> in a
B<special> format I like.

=item C<--o_dump filename>

(done in epilogue) The event space is dumped to C<filename>. It can
be read in again using C<--i_dump> (the next time you use
C<ME.wrapper.pl>).

=back


=head1 BUGS

Options C<--MC>, C<--CORPUS>, C<--ENUM> should be put under one
argument that has a parameter, for instance C<--sample_type [corpus,
enum, mc]>.


=head1 SEE ALSO

L<perl(1)>, L<Statistics::SparseVector(3)>
L<Statistics::Candidates(3)>, L<Statistics::MaxEntropy(3)>.


=head1 VERSION

Version 0.2.


=head1 AUTHOR

=begin roff

Hugo WL ter Doest, terdoest@cs.utwente.nl

=end roff

=begin latex

Hugo WL ter Doest, \texttt{terdoest\symbol{'100}cs.utwente.nl}

=end latex


=head1 COPYRIGHT

=begin roff

Copyright (C) 1998, 1999 Hugo WL ter Doest, terdoest@cs.utwente.nl
Univ. of Twente, Dept. of Comp. Sc., Parlevink Research, Enschede,
The Netherlands.

=end roff

=begin latex

\copyright 1998, 1999 Hugo WL ter Doest, \texttt{terdoest\symbol{'100}cs.utwente.nl}
Univ. of Twente, Dept. of Comp. Sc., Parlevink Research, Enschede,
The Netherlands.

=end latex

C<ME.wrapper.pl> comes with ABSOLUTELY NO WARRANTY and may be copied
only under the terms of the GNU Library General Public License (version 2, or
later), which may be found in the distribution.

=cut
