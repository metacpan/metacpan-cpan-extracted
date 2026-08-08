package Sim::OPT::Parcoord3d;
# This is Sim::OPT::Parcoord3d, a program that can receive as input the data for a bi-dimensional parallel coordinate plot in cvs format to produce as output an Autolisp file that can be used from Autocad or Intellicad-based 3D CAD programs to obtain 3D parallel coordinate plots.
# Sim::OPT::Parcoord3d is distributed under a dual licence, open-source (GPL v3) and proprietary.
# Copyright (C) 2008-2025 by Gian Luca Brunetti, gianluca.brunetti@gmail.com. This software is distributed under a dual licence, open-source (GPL v3) and proprietary. The present copy is GPL. By consequence, this is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


use Exporter;
our @ISA = qw(Exporter); # our @adamkISA = qw(Exporter);
@EXPORT = qw( parcoord3d ); # our @EXPORT = qw( );
use parent 'Exporter'; # imports and subclasses Exporter
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

use Math::Trig;
use Math::Round;
use Math::Round 'nlowmult';
use List::Util qw[ min max reduce shuffle];
use List::MoreUtils qw(uniq);
use List::AllUtils qw(sum);
use Sim::OPT::Stats qw(:all);
use File::Copy qw( move copy );
use Set::Intersection;
use List::Compare;
use Data::Dumper;
#$Data::Dumper::Indent = 0;
#$Data::Dumper::Useqq  = 1;
#$Data::Dumper::Terse  = 1;
use Data::Dump qw(dump);
use feature 'say';
no strict;
no warnings;
use Switch::Back;

use Sim::OPT;
use Sim::OPT::Morph;
use Sim::OPT::Sim;
use Sim::OPT::Report;
use Sim::OPT::Descend;
use Sim::OPT::Takechance;
use Sim::OPT::Interlinear;

use Sim::OPT::Stats;
eval { use Sim::OPTcue::OPTcue; 1 };
eval { use Sim::OPTcue::Metabridge; 1 };
eval { use Sim::OPTcue::Exogen::PatternSearch; 1 };
eval { use Sim::OPTcue::Exogen::NelderMead; 1 };
eval { use Sim::OPTcue::Exogen::Armijo; 1 };
eval { use Sim::OPTcue::Exogen::NSGAII; 1 };
eval { use Sim::OPTcue::Exogen::ParticleSwarm; 1 };
eval { use Sim::OPTcue::Exogen::SimulatedAnnealing; 1 };
eval { use Sim::OPTcue::Exogen::NSGAIII; 1 };
eval { use Sim::OPTcue::Exogen::MOEAD; 1 };
eval { use Sim::OPTcue::Exogen::SPEA2; 1 };
eval { use Sim::OPTcue::Exogen::ParticleSwarm; 1 };
eval { use Sim::OPTcue::Exogen::RadialBasis; 1 };
eval { use Sim::OPTcue::Exogen::Kriging; 1 };
eval { use Sim::OPTcue::Exogen::DecisionTree; 1 };
eval { use Sim::OPTcue::Exogen::KNN; 1 };
eval { use Sim::OPTcue::Exogen::FFNN; 1 };
eval { use Sim::OPTcue::Exogen::GBDT; 1 };
eval { use Sim::OPTcue::Endogen::DWGN2; 1 };
eval { use Sim::OPTcue::Endogen::NeuralBoltzmann; 1 };

$VERSION = '0.01.5';
$ABSTRACT = 'Sim::OPT::Parcoord3d is a program that can process the CSV data for a bi-dimensional parallel coordinate plot and output an Autolisp file for a 3D parallel coordinate plot.';

#########################################################################################
# HERE FOLLOWS THE CONTENT OF "Parcoord3d.pm", Sim::OPT::Parcoord3d
#########################################################################################

sub parcoord3d
{
	if ( not ( @ARGV ) )
	{
		$tofile = $main::tofile;
		say  "\n#Now in Sim::OPT::Takechance.\n";
		$configfile = $main::configfile;
		@sweeps = @main::sweeps;
		@sourcesweeps = @main::sourcesweeps;
		@varnumbers = @main::varnumbers; say  "dump(\@varnumbers): " . dump(@varnumbers);
		@miditers = @main::miditers;
		@rootnames = @main::rootnames;
		%vals = %main::vals;

		$mypath = $main::mypath;
		$exeonfiles = $main::exeonfiles;
		$generatechance = $main::generatechance;
		$file = $main::file;
		$preventsim = $main::preventsim;
		$fileconfig = $main::fileconfig;
		$outfile = $main::outfile;
		$target = $main::target;

		$convertfile = $main::convertfile;
		$pick = $main::pick;
		$numof_pars = $main::numof_pars;
		$xspacing = $main::xspacing;
		$yspacing = $main::yspacing;
		$zspacing = $main::zspacing;
		$ob_column = $main::ob_column;
		$numof_layers = $main::numof_layers;
		$otherob_column = $main::otherob_column;
		$cut_column = $main::cut_column;
		$writefile = $main::writefile;
		$writefile_pretreated = $main::writefile_pretreated;
		$transitional = $main::transitional;
		$newtransitional = $main::newtransitional;
		$lispfile = $main::lispfile;
		@layercolours = @main::layercolours;
		$offset = $main::offset;
		$brushspacing = $main::brushspacing;
	}
	else
	{
		my $file = $ARGV[0];
		require $file;
	}

	my $scale_xspacing = ( $numof_pars / $xspacing );

	open ( CONVERTFILE, $convertfile ) or die;
	my @lines = <CONVERTFILE>;
	close CONVERTFILE;

	if ($pick)
	{
		$convertedfile = "$convertfile" . "filtered.csv";
		open ( CONVERTEDFILE, ">$convertedfile" ) or die;
		my $countline = 0;
		while ( $countline < $pick )
		{
			print CONVERTEDFILE "$lines[$countline]";
			$countline++;
		}

		$countline = ($#lines - $pick) ;
		while ( $countline  < $#lines )
		{
			print CONVERTEDFILE "$lines[$countline]";
			$countline++;
		}
		close CONVERTEDFILE;

		open ( CONVERTEDFILE, "$convertedfile" );
		@lines = <CONVERTEDFILE>;
		close CONVERTEDFILE;
	}

	my $numof_layerelts = ( scalar(@lines) / $numof_layers ); # scalar(@lines = num of trials

	my @newdata;
	sub makedata
	{
		my $swap = shift; my @lines = @$swap;

		my $countline = 0;
		foreach my $line (@lines)
		{
			my @linedata;
			chomp($line);
			my @rowelts = split(/,/ , $line);
			my $ob_fun;
			if ($ob_column)
			{
				$ob_fun = $rowelts[$ob_column];
			}
			else
			{
				$ob_fun = $rowelts[$#rowelts];
			}

			my $otherob_fun = $rowelts[$otherob_column];
			if ( $otherob_fun =~ /-/ )
			{
				my @thesedata = split( /-/ , $otherob_fun );
				$otherob_fun = $thesedata[1];
			}

			my $countvar = 0;
			foreach my $rowelt (@rowelts)
			{
				if ( $countvar < $numof_pars )
				{
					if ( $rowelt =~ /-/ )
					{
						my @vardata = split( /-/ , $rowelt );

						push ( @linedata, [ @vardata ] );
					}
					else
					{
						push ( @linedata, [ $countvar, $rowelt ] );
					}
					$countvar++;
				}
			}
			push ( @newdata, [ @linedata, $otherob_fun, $ob_fun ] );
			$countline++;
		}
	}
	makedata(\@lines);

	my ( @pars, @obfun, @otherobfun, $maxobfun, $minobfun, @maxpars, @minpars, $othermaxobfun, $otherminobfun, $countmaxobfun, $countminobfun, $countmaxotherobfun, $countminotherobfun ) ;
	sub makestats
	{
		my $swap = shift; my @newdata = @$swap;
		foreach my $line (@newdata)
		{
			chomp($line);
			my @elts = @{$line};

			my $elm1 = pop(@elts);
			push ( @obfun, $elm1 );
			my $elm2 = pop(@elts);
			push ( @otherobfun, $elm2 );

			my $count = 0;
			foreach my $elt (@elts)
			{
				my @pair = @{$elt};
				my $value = $pair[1];
				push ( @{$pars[$count]}, $value );
				$count++;
			}
		}

		$maxobfun = max(@obfun);
		$minobfun = min(@obfun);
		$maxotherobfun = max(@otherobfun);
		$minotherobfun = min(@otherobfun);

		$countel = 0;
		foreach my $e (@obfun)
		{
			if ($e eq $maxobfun )
			{
				$countmaxobfun = $countel;
			}
			if ($e eq $minobfun )
			{
				$countminobfun = $countel;
			}
			$countel++;
		}

		my $countel2 = 0;
		foreach my $e (@otherobfun)
		{
			if ($e eq $maxotherobfun )
			{
				$countmaxotherobfun = $countel2;
			}
			if ($e eq $minotherobfun )
			{
				$countminotherobfun = $countel2;
			}
			$countel2++;
		}

		sub printpar
		{
			foreach my $par (@pars)
			{
				print WRITEFILE "PAR: @$par \n";
			}
		}
	}
	makestats(\@newdata);

	sub writeminmaxpars
	{
		my $swap = shift; my @pars = @$swap;
		my $countpar = 0;
		foreach my $par (@pars)
		{
			my @elts = @$par;
			push ( @maxpars, max(@elts) );
			push ( @minpars, min(@elts) );
			$countpar++;
		}
	}
	writeminmaxpars(\@pars);

	my ( @plotdata, @newplotdata, @newnewdata );
	sub plotdata
	{
		my $case_per_layer = ( scalar(@newdata) / $numof_layers );
		$countcase = 0;
		foreach my $el ( @{$pars[0]} )
		{
			my @provbowl;
			my $scaled_zvalue = ( ( $newdata[$countcase][($#{$newdata[$countcase]}-1)] - $minotherobfun ) / ( $maxotherobfun - $minotherobfun ) );
			my $countvar = 0;
			while ($countvar < $numof_pars)
			{
				my $layer_num = ( int( $countcase / $case_per_layer ) + 1) ;
				my $scaled_xvalue = ( $countvar / $scale_xspacing );
				my $scaled_yvalue = ( ( $pars[$countvar][$countcase] - $minpars[$countvar] ) / ( $maxpars[$countvar] - $minpars[$countvar] ) );
				$scaled_yvalue = ($scaled_yvalue * $yspacing);
				$scaled_zvalue = ($scaled_zvalue * $zspacing);
				if ($otherob_column)
				{
					push (@provbowl, [ $scaled_xvalue, $scaled_yvalue, $scaled_zvalue, $layer_num ] );
				}
				else
				{
					push (@provbowl, [ $scaled_xvalue, $scaled_yvalue, 0, $layer_num ] );
				}
				$countvar++;
			}
			push (@plotdata, [ @provbowl ]);
			$countcase++;
		}
	}
	plotdata;

	sub cutcoordinates
	{
		foreach (@plotdata)
		{
			splice( @{$_}, $cut_column, 1);
		}
	}
	if ($cut_column)
	{
		cutcoordinates; # CUTS SPECIFIED COORDINATES
	}

	sub printplotdata_pretreated
	{
		open ( WRITEFILE_PRETREATED, ">$writefile_pretreated") or die;
		print WRITEFILE_PRETREATED dump(@plotdata); #CONTROL!!!
		close WRITEFILE_PREATREATED;
	}
	printplotdata_pretreated;

	sub solidify
	{print "BEGUN\n";
		my $swap = shift; my @plotdata = @$swap;
		open ( WRITEFILE, ">$writefile") or die;
		my $countgroup = 0;
		foreach my $e (@plotdata)
		{
			my @elts = @{$e};
			my @newnewbag;
			my $counter = 0;
			foreach my $elm (@elts)
			{
				my @elms = @{$elm};
				my @cutelms = @elms[0..2]; # PUT ..2 IF ALSO THE THIRD AXIS HAS TO BE CHECKED FOR NON-REPETITIONS, PUT 1 OTHERWISE.
				my $counthit = -1;
				foreach my $el (@plotdata)
				{
					my @els = @{$el};
					foreach my $elem (@els)
					{
						my @elems = @{$elem};
						my @cutelems = @elems[0..2]; # PUT ..2 IF ALSO THE THIRD AXIS HAS TO BE CHECKED FOR NON-REPETITIONS, PUT 1 OTHERWISE.
						if (@cutelms ~~ @cutelems)
						{

							$counthit++;
							print "COUNTGROUP: $countgroup, HIT! $counthit\n";

							if ($counthit > 0)
							{
								print "COUNTHITNOW: $counthit\n";
								if ( $counthit % 2 == 1) # odd
								{
									$elms[0] = ( $elms[0] - ( $brushspacing * $counthit ) );
								}
								else
								{
									$elms[0] = ( $elms[0] + ( $brushspacing * $counthit ) );
								}
								push ( @newnewbag, [ nlowmult($round, $elms[0]), nlowmult($round, $elms[1]), nlowmult($round, $elms[2]), nlowmult($round, $elms[3]) ]);
							}
							else
							{
								push(@newnewbag, [ nlowmult($round, $elms[0]), nlowmult($round, $elms[1]), nlowmult($round, $elms[2]), nlowmult($round, $elms[3]) ]);
							}
						}
					}
				}

				$counter++
			}
			push( @newplotdata, [ @newnewbag ] );
			$countgroup++;
		}
		print WRITEFILE dump(@newplotdata);
		close WRITEFILE;
	}
	solidify(\@plotdata);


	#my @plotdata = eval `cat $writefile`;

	sub prepare
	{
		open( TRANSITIONAL, ">$transitional" ) or die;
		my $countgroup = 0;
		foreach my $group (@newplotdata)
		{
			my @elts = @{$group};
			my $countpar = 0;
			my ( @newplotdatabottom, @newplotdatafront, @newplotdataback, @newplotdataright, @newplotdataleft );
			foreach my $elt (@elts)
			{
				my @coords = @{$elt};
				my @nextcoords = @{$elts[$countpar+1]};


				my @newcoords;
				push( @newcoords, [ @coords ] );
				push( @newcoords, [ ($coords[0] - ($yspacing * $offset ) ) , $coords[1] , $coords[2], $coords[3] ] );
				push( @newcoords, [ ($coords[0] - ($yspacing * $offset ) ) , $coords[1] , ( $coords[2] - ($yspacing * $offset ) ) , $coords[3] ] );
				push( @newcoords, [ $coords[0], $coords[1] , ( $coords[2] - ($yspacing * $offset ) ) , $coords[3] ] );
				push( @newplotdatabottom, [ @newcoords ] );


				my @newcoords;
				unless ($countpar == $#elts)
				{
					push( @newcoords, [ @coords ] );
					push( @newcoords, [ ($coords[0] - ($yspacing * $offset ) ) , $coords[1] , $coords[2], $coords[3] ] );
					push( @newcoords, [ ($nextcoords[0] - ($yspacing * $offset ) ) , $nextcoords[1] , $nextcoords[2], $nextcoords[3] ] );
					push( @newcoords, [ @nextcoords] );
					push( @newplotdatafront, [ @newcoords ] );
				}


				my @newcoords;
				unless ($countpar == $#elts)
				{
					push( @newcoords, [ ($coords[0] - ($yspacing * $offset ) ) , $coords[1] , $coords[2], $coords[3] ] );
					push( @newcoords, [ ($coords[0] - ($yspacing * $offset ) ) , $coords[1] , ( $coords[2] - ($yspacing * $offset ) ) , $coords[3] ] );
					push( @newcoords, [ ($nextcoords[0] - ($yspacing * $offset ) ) , $nextcoords[1] , ( $nextcoords[2] - ($yspacing * $offset ) ) , $nextcoords[3] ] );
					push( @newcoords, [ ($nextcoords[0] - ($yspacing * $offset ) ) , $nextcoords[1] , $nextcoords[2], $nextcoords[3] ] );
					push( @newplotdataleft, [ @newcoords ] );
				}


				my @newcoords;
				unless ($countpar == $#elts)
				{
					push( @newcoords, [ ($coords[0] - ($yspacing * $offset ) ) , $coords[1] , ( $coords[2] - ($yspacing * $offset ) ) , $coords[3] ] );
					push( @newcoords, [ $coords[0], $coords[1] , ( $coords[2] - ($yspacing * $offset ) ) , $coords[3] ] );
					push( @newcoords, [ $nextcoords[0], $nextcoords[1] , ( $nextcoords[2] - ($yspacing * $offset ) ) , $nextcoords[3] ] );
					push( @newcoords, [ ($nextcoords[0] - ($yspacing * $offset ) ) , $nextcoords[1] , ( $nextcoords[2] - ($yspacing * $offset ) ) , $nextcoords[3] ] );
					push( @newplotdataback, [ @newcoords ] );
				}


				my @newcoords;
				unless ($countpar == $#elts)
				{
					push( @newcoords, [ $coords[0], $coords[1] , ( $coords[2] - ($yspacing * $offset ) ) , $coords[3] ] );
					push( @newcoords, [ @coords ] );
					push( @newcoords, [ @nextcoords ] );
					push( @newcoords, [ $nextcoords[0], $nextcoords[1] , ( $nextcoords[2] - ($yspacing * $offset ) ) , $nextcoords[3] ] );
					push( @newplotdataright, [ @newcoords ] );
				}


				$countpar++;
			}

			if (@newplotdatafront)
			{
				push(@newnewdata, @newplotdatabottom , @newplotdatafront,  @newplotdataleft, @newplotdataback, @newplotdataright );
			}
			else
			{
				push(@newnewdata, @newplotdatabottom );
			}


			$countgroup++;
		}
		print TRANSITIONAL dump(@newnewdata);
		close TRANSITIONAL;
	}
	prepare;


	sub writelisp
	{
		open( LISPFILE, ">$lispfile");
		my $counter = 1;
		foreach my $colour (@layercolours)
		{
			print LISPFILE "\( command \"layer\" \"m\" \"$counter\" \"c\" \"$colour\" \"\" \"\" \)\n";
			$counter++;
		}
		foreach my $series (@newnewdata)
		{
			my @vs = @{$series};
			print LISPFILE "\( command \"layer\" \"s\" \"$vs[0][3]\" \"\" \)\n";
			print LISPFILE "\( command \"3dface\" \"$vs[0][0],$vs[0][2],$vs[0][1]\" \"$vs[1][0],$vs[1][2],$vs[1][1]\" \"$vs[2][0],$vs[2][2],$vs[2][1]\" \"$vs[3][0],$vs[3][2],$vs[3][1]\" \"\" \)\n";
		}
		close LISPFILE;
	}
	writelisp;
}

1;


__END__

=head1 NAME

Sim::OPT::Parcoord3d.

=head1 SYNOPSIS

  use Sim::OPT::Parcoord3d;
  parcoord3d your_configuration_file.pl;

=head1 DESCRIPTION

Sim::OPT::Parcoord3d is a program that can receive as input the data for a bi-dimensional parallel coordinate plot in CVS format and produce as output an Autolisp file (that can be used from inside Autocad or Intellicad-based 3D CAD programs) to obtain a 3D parallel coordinate plot made with surfaces.

The objective function to be represented through colours in the parallel coordinate plot has to be put in the last (right) column in the CVS file.

"Sim::OPT::Parcoord3d" can be called from Sim::OPT or directly from the command line (after issuing < re.pl > and < use Sim::OPT::Parcoord3d >) with the command < parcoord3d your_configuration_file.pl >.

The variables to be specified in the configuration file are described in the comments in the "Sim::OPT" configuration file included in the "examples" folder in this distribution ("des.pl", for instance - then search for "Parcoord3d").

This module is dual-licensed, open-source and proprietary. The open-source distribution is available on CPAN (https://metacpan.org/dist/Sim-OPT ). A proprietary distribution, including additional modules (OPTcue), is available from the author’s website (https://sites.google.com/view/bioclimatic-design/home/software ).

=head2 EXPORT

"parcoord3d".

=head1 SEE ALSO

An example of configuration instructions for Sim::OPT::Parcoord3d is included in the comments in the "esp.pl" file, which is packed in "optw.tar.gz" file in "examples" directory in this distribution. But mostly, reference to the source code should be made.

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2025 by Gian Luca Brunetti, gianluca.brunetti@gmail.com. This software is distributed under a dual licence, open-source (GPL v3) and proprietary. The present copy is GPL. By consequence, this is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.

=cut
