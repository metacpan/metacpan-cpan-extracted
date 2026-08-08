package Sim::OPT::Takechance;
# This is "Sim::OPT::Takechance", a program that can produce efficient search structures for block coordinate descent given some initialization blocks (subspaces).
# Its strategy is based on making a search path more efficient than the average randomly chosen ones, by selecting the search moves
# so that (a) the search wake is fresher than the average random ones and (b) the search moves are more novel than the average random ones.
# The rationale for the selection of the seach path is explained in detail (with algorithms) in my paper at the following web address: http://arxiv.org/abs/1407.5615 .
# Sim::OPT::Takechance is distributed under a dual licence, open-source (GPL v3) and proprietary.
# Copyright (C) 2008-2025 by Gian Luca Brunetti, gianluca.brunetti@gmail.com. This software is distributed under a dual licence, open-source (GPL v3) and proprietary. The present copy is GPL. By consequence, this is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.

use Exporter;
use parent 'Exporter'; # imports and subclasses Exporter
our @ISA = qw(Exporter); # our @adamkISA = qw(Exporter);
@EXPORT = qw( takechance ); # our @EXPORT = qw( );
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

use Math::Trig;
use Math::Round;
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
#use feature qw(postderef);
#no warnings qw(experimental::postderef);
#use Sub::Signatures;
#no warnings qw(Sub::Signatures);
#no strict 'refs';
no strict;
no warnings;
use Switch::Back;

use Sim::OPT;
use Sim::OPT::Morph;
use Sim::OPT::Sim;
use Sim::OPT::Report;
use Sim::OPT::Descend;

use Sim::OPT::Interlinear;
use Sim::OPT::Parcoord3d;
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


$VERSION = '0.06';
$ABSTRACT = 'The "Sim::OPT::Takechance" module can produce efficient block coordinate search structures given some initialization blocks.';

#########################################################################################
# HERE FOLLOWS THE CONTENT OF "Takechance.pm", Sim::OPT::Takechance
#########################################################################################

sub takechance
{
	if ( not ( @ARGV ) )
	{
		$tofile = $main::tofile;
		say  "\n#Now in Sim::OPT::Takechance.\n";
		$configfile = $main::configfile;
		@sweeps = @main::sweeps;
		@sourcesweeps = @main::sourcesweeps;
		@varnumbers = @main::varnumbers;
		@miditers = @main::miditers;
		@rootnames = @main::rootnames;
		%vals = %main::vals;
		@caseseed = @main::caseseed;
		@chanceseed = @main::chanceseed;
		@chancedata = @main::chancedata;
		@pars_tocheck = @main::pars_tocheck;
		$dimchance = $main::dimchance;

		$mypath = $main::mypath;
		$exeonfiles = $main::exeonfiles;
		$generatechance = $main::generatechance;
		$file = $main::file;
		$preventsim = $main::preventsim;
		$fileconfig = $main::fileconfig;
		$outfile = $main::outfile;
		$target = $main::target;

		$report = $main::report;
		$simnetwork = $main::simnetwork;

		#open ( OUTFILE, ">>$outfile" ) or die "Can't open $outfile: $!";
		#open ( TOFILE, ">>$tofile" ) or die "Can't open $tofile: $!";


		%dowhat = %main::dowhat;

		@themereports = @main::themereports;
		@simtitles = @main::simtitles;
		@reporttitles = @main::reporttitles;
		@simdata = @main::simdata;
		@retrievedata = @main::retrievedata;
		@keepcolumns = @main::keepcolumns;
		@weights = @main::weights;
		@weightsaim = @main::weightsaim;
		@varthemes_report = @main::varthemes_report;
		@varthemes_variations = @vmain::arthemes_variations;
		@varthemes_steps = @main::varthemes_steps;
		@rankdata = @main::rankdata; # CUT ZZZ
		@rankcolumn = @main::rankcolumn;
		@reporttempsdata = @main::reporttempsdata;
		@reportcomfortdata = @main::reportcomfortdata;
		@reportradiationenteringdata = @main::reportradiationenteringdata;
		@report_loadsortemps = @main::report_loadsortemps;
		@files_to_filter = @main::files_to_filter;
		@filter_reports = @main::filter_reports;
		@base_columns = @main::base_columns;
		@maketabledata = @main::maketabledata;
		@filter_columns = @main::filter_columns;
		@pars_tocheck = @main::pars_tocheck;
	}
	else
	{
		my $file = $ARGV[0];
		require $file;
	}

	my %res;
	my %lab;
	my $countcase = 0;
	my @caseseed_ = @caseseed;
	my @chanceseed_ = @chanceseed;
	foreach my $case (@caseseed_) # In a $casefile one or more searches are described. Here one or more searches are fabricated.
	{


		my @tempvarnumbers = @varnumbers; ###ZZZ
		foreach my $elt ( keys %{ $varnumbers[$countcase] } ) # THIS STRIPS AWAY THE PARAMETERS THAT ARE NOT CONTAINED IN @pars_tocheck.
		{
			unless ( $elt ~~ @{ $pars_tocheck[$countcase] } )
			{
				delete ${ $tempvarnumbers[$countcase] }{$elt};
			}
		}


		my $testfile = "$mypath/$file-testfile-$countcase.csv";
		open ( TEST, ">>$testfile") or die;
		my @blockrefs = @{$case};
		my (@varnumbers, @newvarnumbers, @chance, @newchance, @shuffledchanceelms);
		my @chancerefs = @{$chanceseed_[$countcase]};

		my %varnums = Sim::OPT::getcase(\@varnumbers, $countcase);
		my @variables;
		if ( not (@{$pars_tocheck->[$countcase]}) )
		{
			@variables = sort { $a <=> $b } keys %varnums;
		}
		else
		{
			@variables = sort { $a <=> $b } @{ $pars_tocheck[$countcase] };
		}
		my $numberof_variables = scalar(@variables);

		my $blocklength = $chancedata[$countcase][0];
		my $blockoverlap = $chancedata[$countcase][1];
		my $numberof_sweepstoadd = $chancedata[$countcase][2];
		my $numberof_seedblocks = scalar(@blockrefs);
		my $totalnumberof_blocks = ( $numberof_seedblocks + $numberof_sweepstoadd );
		my (@caserefs_alias, @chancerefs_alias);
		my $countbuild = 1;
		while ( $countbuild <= $numberof_sweepstoadd )
		{
			say  "#######################################################################
			ADDING \$countbuild $countbuild";

			my $countchance = 1;
			while ($countchance <= $dimchance)
			{
				say "EXPLORING CHANCE, TIME \$countchance $countchance \$countbuild $countbuild";
				my %lab;
				my ($beginning, @shuffledchanceres, @shuffledchanceelms, @overlap);
				my $semaphore = 0;
				my $countshuffle = 1;
				sub _shuffle_
				{
					say  "#######################################################################
					SHUFFLING NUMBER $countshuffle, \$countbuild $countbuild \$countchance $countchance";
					@shuffledchanceelms = ();
					@overlap = ();
					@shuffledchanceres = shuffle(@variables);
					######@shuffledchanceres = ( 1, 2, 3, 4, 5);#####
					push (@shuffledchanceelms, @shuffledchanceres, @shuffledchanceres, @shuffledchanceres );
					$beginning = int(rand($blocklength-1) + $numberof_variables);
					my $endblock = ( $beginninng + $blocklength );
					#my @shuffledchanceslice = sort { $a <=> $b } (uniq(@shuffledchanceelms[$beginninng..$endblock])); say  "dump(INBUILD\@shuffledchanceslice): " . dump(@shuffledchanceslice); # my @shuffledchanceslice = @shuffledchanceelms[$beginning..$endblock] ;
					@caserefs_alias = @blockrefs;
					@chancerefs_alias = @chancerefs;
					my @pastsweepblocks = Sim::OPT::fromopt_tosweep_simple( { casegroup => [@caserefs_alias], chancegroup => [@chancerefs_alias] } ); say  "dumpXX(INBUILD-AFTER\@pastsweepblocks): " . dump(@pastsweepblocks);

					push (@caserefs_alias, [ $beginning, $blocklength ]);
					push (@chancerefs_alias, [ @shuffledchanceelms ]);

					my $pastbeginning = $chancerefs_alias[ $#chancerefs_alias -1 ][ 0] ;
					if ( scalar(@chancerefs_alias) <= 1 )
					{
						$pastbeginning eq "";
					}

					my $pastendblock;
					if ($pastbeginning)
					{
						$pastendblock = ( $pastbeginning + $blocklength );
					}
					else
					{
						$pastendblock eq "";
					}



					my @slice = @{ $chancerefs_alias[$#chancerefs_alias] }[ $beginning..(  $beginning + $blocklength -1  ) ];
					my @pastslice = @{ $chancerefs_alias[ $#chancerefs_alias -1 ] }[ $pastbeginning..( $pastbeginning + $blocklength -1 ) ];
					my $lc = List::Compare->new(\@slice, \@pastslice);
					my @intersection = $lc->get_intersection;

					#my $res = Sim::OPT::checkduplicates( { slice => \@slice, sweepblocks => \@pastsweepblocks } ); say  "dumpXX(INBUILD\$res): " . dump($res);

					if ( scalar( @intersection ) == $blockoverlap ) { $semaphore = 1; }

					if ( not ( $semaphore == 1 ) )
					{
						say  "NOT HIT. \$countshuffle: $countshuffle.";
						$countshuffle++;
						&_shuffle_;
					}
					else
					{
						return (\@shuffledchanceres, \@shuffledchanceelms);
						say  "HIT. \$countshuffle: $countshuffle.";
					}
				}
				my @result = _shuffle_;
				@shuffledchanceres = @{$result[0]};
				@shuffledchanceelms = @{$result[1]};
				say  "EXITING SHUFFLE WITH \@shuffledchanceres: @shuffledchanceres, \@shuffledchanceelms, @shuffledchanceelms";
				$lab{$countcase}{$countbuild}{$countchance}{case} = \@caserefs_alias;
				my @thiscase = @{ $lab{$countcase}{$countbuild}{$countchance}{case} };

				$lab{$countcase}{$countbuild}{$countchance}{chance} = \@chancerefs_alias;
				my @thischance = @{ $lab{$countcase}{$countbuild}{$countchance}{chance} };
				say  "dump(OUTBUILD\%lab): " . dump(%lab);

				################################
				#> HERE THE CODE FOLLOWS FOR THE CALCULATION OF HEURISTIC INDICATORS MEASURING THE EFFECTIVENESS OF A SEARCH STRUCTURE FOR SEARCH.

				my $countfirstline = 0;

				my ( $totalsize, $totaloverlapsize, $totalnetsize, $commonalityflow, $totalcommonalityflow,
				$cumulativecommonalityflow, $localcommonalityflow, $addcommonalityflow, $remembercommonalityflow,
				$cumulativecommonalityflow, $localrecombinationratio, $heritageleft, $heritagecentre,
				$heritageright, $previousblock, $flatoverlapage, $rootexpoverlapage, $expoverlapage,
				$flatweightedoverlapage, $overlap, $iruif, $stdcommonality, $stdrecombination, $stdinformation,
				$stdfatminus, $stdshadow, $localrecombinalityminusratio,
				$localrecombinalityratio, $localrenewalratio, $infminusflow, $cumulativeinfminusflow, $totalinfminusflow, $infflow,
				$cumulativeinfflow, $totalinfflow, $infoflow, $cumulativeinfoflow, $totalinfoflow,
				$refreshment, $refreshmentminus, $n_basketminus, $n_unionminus, $n_basket, $n_union,
				$recombination_ratio, $proportionhike, $iruifflow, $cumulativeiruif, $totaliruif,
				$commonalityflowproduct, $commonalityflowenhanced, $commonalityflowproductenhanced,
				$cumulativecommonalityflowproduct, $cumulativecommonalityflowenhanced, $cumulativecommonalityflowproductenhanced,
				$averageageexport, $cumulativeage, $refreshratio, $flowratio, $cumulativeflowratio, $flowageratio,
				$cumulativeflowageratio, $shadowexport, $modiflow, $cumulativemodiflow, $cumulativehike, $cumulativerefreshment,
				$refreshmentperformance, $refreshmentsize, $cumulativerefreshmentperformance, $refreshmentvolume, $IRUIF, $mmIRUIF, $averageage,
				$otherIRUIF, $othermmIRUIF, $mmresult, $mmregen, $score, $sumnovelty,$urr,$IRUIFnovelty,$IRUIFurr,
				$IRUIFnoveltysquare,$IRUIFurrsquare,$IRUIFnoveltycube,$IRUIFurrcube );

				my ( @commonalities, @commonalitiespe, @recombinations, @informations, @localcommonances, @commonanceratios,
				@groupminus, @unionminus, @group, @union, @basketminusnow, @unionminus, @basketnow, @union, @basketageexport,
				@basketlast, @newbasket, @valuebasket, @otherbasket, @basketcount, @finalbasket, @mmbasketresult, @mmbasketregen,
				@pastjump, @pastbunch, @resbunches, @scores );

				#>
				######################

				my $countblock = 0;
				my $countblk = 0;
				my $countblockplus1 = 1;
				foreach my $blockref (@caserefs_alias)
				{
					say  "################################################################
					NOW DEALING WITH BLOCK $countblockplus1, \$countbuild $countbuild, \$countchance $countchance";
					my @blockelts = @{$blockref};
					my @presentblockelts = @blockelts;
					my $chanceref = $chancerefs_alias[$countblk];
					my @chanceelts = @{$chanceref};

					#############################################
					#>

					my $attachment = @blockelts[0];
					# ANALOGUES OF THE LATTER VARIABLES ARE HERE CALLED @presentslice AND @pastslice.
					my $activeblock = @blockelts[1];
					my $zoneend = ( $numberof_variables - $activeblock );
					my ( $pastattachment, $pastactiveblock, $pastzoneend );
					my $viewextent = $activeblock;
					my ( @zoneoverlaps, @meanoverlaps, @zoneoverlapextent, @meanoverlapextent );
					my $countops = 1;
					my $counter = 0;
					while ($countops > 0)
					{
						my @pastblockelts = @{$blockrefs[$countblk - $countops]};
						if ($countblk == 0) { @pastblockelts = ""; }
						$pastattachment = $pastblockelts[0];
						$pastactiveblock = $pastblockelts[1];
						$pastzoneend = ( $numberof_variables - $pastactiveblock );
						my @presentslice = @chanceelts[ $attachment..($attachment+$activeblock-1) ];
						my @pastslice = @chanceelts[ $pastattachment..($pastattachment+$pastactiveblock-1) ];
						my $lc = List::Compare->new(\@presentslice, \@pastslice);
						my @intersection = $lc->get_intersection;
						my $localoverlap = scalar(@intersection);
						push (@meanoverlapextent, $localoverlap);
						my $overlapsum = 0;
						for ( @meanoverlapextent ) { $overlapsum += $_; }
						$overlap = $overlapsum ;
						if ($countblk == 0) { $overlap = 0; }
						$countops--;
						$counter++;
					}

					#if ("yesgo" eq "yesgo")
					{
						my $countops = 2;
						my $counter = 0;
						my ( @zoneoverlaps, @meanoverlaps, @zoneoverlapextent, @meanoverlapextent, @basketminus );
						while ($countops > 1)
						{
							my @pastblockelts = @{$blockrefs[$countblk - $countops]};
							$pastattachment = $pastblockelts[0];
							$pastactiveblock = $pastblockelts[1];
							$pastzoneend = ( $numberof_variables - $pastactiveblock );
							my @presentslice = @chanceelts[ $attachment..($attachment+$activeblock-1) ];
							my @pastslice = @chanceelts[ $pastattachment..($pastattachment+$pastactiveblock-1) ];
							my $lc = List::Compare->new(\@presentslice, \@pastslice);
							my @intersection = $lc->get_intersection;
							push (@basketminus, @intersection);
							$stdfatminus = stddev(@basketminus);
							my $localoverlap = scalar(@intersection);
							my $localoverlapextent = $localoverlap;
							push (@meanoverlapextent, $localoverlap);
							my $overlapsum = 0;
							for ( @meanoverlapextent ) { $overlapsum += $_; }
							$overlapminus = ($overlapsum );
							@basketminusnow = @basketminus;
							$countops--;
							$counter++;
						}
					}
					@unionminus = uniq(@basketminusnow);
					$n_basketminus = scalar(@basketminusnow);
					$n_unionminus = scalar (@unionminus);
					if ( $n_unionminus == 0) {$n_unionminus = 1;};
					if ( $n_basketminus == 0) {$n_basketminus = 1;};
					$refreshmentminus = ( ( $n_unionminus / $n_basketminus )  );

					#if ("yesgo" eq "yesgo")
					{
						my ( @zoneoverlaps, @meanoverlaps, @zoneoverlapextent, @meanoverlapextent, @zoneoverlapweightedextent, @meanoverlapweightedextent);
						my $countops = 1;
						my ( $flatoverlapsum, $expoverlapsum, $flatweightedoverlapsum, $expweightedoverlapsum, $averageage );
						my $counter = 0;
						my $countage = $numberof_variables;
						my ( @basket, @basketage, @freshbasket, @basketnow );
						while ($countops < $numberof_variables)
						{
							my @pastblockelts = @{$blockrefs[$countblk - $countops]};
							$pastattachment = $pastblockelts[0];
							$pastactiveblock = $pastblockelts[1];
							$pastzoneend = ( $numberof_variables - $pastactiveblock );
							my @pastslice = @chanceelts[ $pastattachment..($pastattachment+$pastactiveblock-1) ];
							#@pastslice = Sim::OPT::_clean_ (\@pastslice); say  "dump(INBLOCK3\@pastslice): " . dump(@pastslice);
							my @otherslice = @pastslice;

							foreach $int (@pastslice)
							{
								if ($int)
								{
									$int = "$int" . "-" . "$countops";
								}
							}

							if ($countops <= $numberof_variables)
							{
								push (@basket, @pastslice);
							}
							#@basket = Sim::OPT::_clean_ (\@basket);
							@basket = sort { $a <=> $b } @basket;


							if ($countops <= $numberof_variables)
							{
								 push (@otherbasket, @otherslice);
							}
							#@otherbasket = Sim::OPT::_clean_ (\@otherbasket);
							@otherbasket = sort { $a <=> $b } @otherbasket;


							@newbasket = @basket;
							@basketnow = @newbasket;
							@transferbasket = @basketnow;
							my @presentslice = @chanceelts[ $attachment..($attachment+$activeblock-1) ];
							@activeblk = @presentslice;
							$countops++;
							$counter++;
							$countage--;
						}
					}

					my @integralslice = @shuffledchanceelms[ ($numberof_variables) .. (($numberof_variables * 2) - 1) ];
					#my @integralslice = sort { $a <=> $b } @integralslice;
					my @valuebasket;
					foreach my $el (@integralslice)
					{
						my @freshbasket;
						foreach my $elm (@transferbasket)
						{
							my $elmo = $elm;
							$elmo =~ s/(.*)-(.*)/$1/;
							if ($el eq $elmo)
							{
								push (@freshbasket, $elm);
							}
						}
						@freshbasket = sort { $a <=> $b } @freshbasket;

						my $winelm = $freshbasket[0];
						push (@valuebasket,$winelm);

						foreach my $elt (@integralslice)
						{
							foreach my $elem (@valuebasket)
							{
								unless ($elem eq "")
								{
									my $elmo = $elem;
									$elmo =~ s/(.*)-(.*)/$1/;
									if ($elmo ~~ @integralslice)
									{
										;
									}
									else
									{
										if ($countblk > $$numberof_variables) { my $eltinsert = "$elmo" . "-" . "$numberof_variables"; }
										else {	my $eltinsert = "$elmo" . "-" . "$countblk";}
										push (@valuebasket, $eltinsert);
									}
								}
							}
						}
					}
					@valuebasket = sort { $a <=> $b } @valuebasket;


					my $sumvalues = 0;
					my @finalbasket;
					foreach my $el (@valuebasket)
					{
						my $elmo = $el;
						$elmo =~ s/(.*)-(.*)/$2/;
						$sumvalues = $sumvalues + $elmo;
						push (@finalbasket, $elmo);

					}

					my ( @presentblockelts, @pastblockelts, @presentslice, @pastslice, @intersection, @presentjump, @presentbunch, @resbunch
					# @pastminusblockelts, @pastminusslice, @intersectionminus,
					);

					if ($countblk > 1)
					{
						@pastblockelts = @{$blockrefs[$countblk - 1]};
						@pastminusblockelts = @{$blockrefs[$countblk - 2]};
						# @presentblockelts = @{$blockrefs[$countblk]}; # THERE IS ALREADY: @blockelts;

						$pastattachment = $pastblockelts[0];
						$pastactiveblock = $pastblockelts[1];
						$pastzoneend = ( $numberof_variables - $pastactiveblock );
						#my $pastminusattachment = $pastminusblockelts[0]; say  "BEYOND1 \$pastminusattachment-->: $pastminusattachment";############ ZZZZ UNNEEDED
						#my $pastminusactiveblock = $pastminusblockelts[1]; say  "BEYOND1 \$pastminusactiveblock $pastminusactiveblock";############ ZZZZ UNNEEDED
						#my $pastminuszoneend = ( $numberof_variables - $pastminusactiveblock ); say  "BEYOND1 \$pastminuszoneend-->: $pastminuszoneend";############ ZZZZ UNNEEDED
						@pastslice = @chanceelts[ $pastattachment..($pastattachment + $pastactiveblock-1) ];
						@pastslice = sort { $a <=> $b } @pastslice;
						#@pastminusslice = = @chanceelts[ $pastminusattachment..($pastminusattachment + $pastminusactiveblock-1) ]; say  "BEYOND1 \@pastsminuslice-->: @pastsminuslice";############ ZZZZ UNNEEDED
						#@pastsminuslice = sort { $a <=> $b } @pastminusslice; say  "BEYOND1-ORDERED \@pastsminuslice-->: @pastsminuslice";############ ZZZZ UNNEEDED
						@presentslice = @chanceelts[ $attachment..($attachment + $activeblock-1) ];
						@presentslice = sort { $a <=> $b } @presentslice;
						my $lc = List::Compare->new(\@presentslice, \@pastslice);
						@intersection = $lc->get_intersection;
						#my $lc2 = List::Compare->new(\@pastslice, @pastminusslice);############ ZZZZ UNNEEDED
						#@intersectionminus = $lc2->get_intersection; say  "dump(INBLOCK2\@intersectionminus): " . dump(@intersectionminus);############ ZZZZ UNNEEDED

						my $counter = 0;
						foreach my $presentelm (@presentslice)
						{
							my $pastelm = $pastslice[$counter];
							my $joint = "$pastelm" . "-" . "$presentelm";
							push (@resbunch, $joint);
							$counter++;
						}

						#@resbunch = Sim::OPT::_clean_ (\@resbunch);
						say  "BEYOND AFTERCLEAN: \@resbunch: @resbunch";

						push (@resbunches, [@resbunch]);

						#@resbunches = Sim::OPT::_clean_ (\@resbunches);
						say  "BEYOND1 AFTERCLEAN  Dumper(\@resbunches:) " . Dumper(@resbunches) ;

						my @presentbunch = @{$resbunches[0]};
						#@presentbunch = Sim::OPT::_clean_ (\@presentbunch);
						say  "BEYOND1 AFTERCLEAN: \@presentbunch: @presentbunch";

						my $countthis = 0;
						foreach my $elm (@resbunches)
						{
							unless ($countthis == 0)
							{
								my @pastbunch = @{$elm};
								my $lc = List::Compare->new(\@presentbunch, \@pastbunch);
								my @intersection = $lc->get_intersection;

								push ( @scores, scalar(@intersection) );
							}
							$countthis++;
						}

						#@scores = Sim::OPT::_clean_ (\@scores);
						say  "BEYOND1 OUTSIDE AFTERCLEAN \@scores: @scores";

						$score = Sim::OPT::max(@scores);
						my $newoccurrences = $activeblock - $score;
						say  "BEYOND1 \$numberof_variables $numberof_variables\n";
						$novelty = $newoccurrences / $numberof_variables ;
						# my $novelty = ($steps ** $newoccurrences) / ($steps ** $numberof_variables );
					}
					my ($averageage, $n1_averageage);
					if ($numberof_variables != 0)
					{
						$averageage = ( $sumvalues / $numberof_variables );
					}
					else { print "IT WAS ZERO AT DENOMINATOR OF \$averageage.\n"; }

					if ($averageage != 0)
					{
						$n1_averageage = 1 / $averageage;
					}

					my $urr = ($n1_averageage * $novelty);
					# my $urr = ($n1_averageage * $sumnovelty ) ** ( 1 / 2 ); # ALTERNATIVE.
					say  "BEYOND2 \$urr-->: $urr"; # URR, Usefulness of Recursive Recombination say  "AFTERZONE \@freshbasket: @freshbasket"; say  "ZONE2OUT: \$countcase: $countcase, \$countbuild: $countbuild, \$countchance: $countchance, \$countblk:$countblk";

					my $stddev = stddev(@finalbasket);
					if ($stddev == 0) {$stddev = 0.0001;}
					my $n1_stddev = 1 / $stddev;
					my $mix = $averageage * $stddev;

					if ($mix != 0)
					{
						$result = 1 / $mix;
					}
					else { print "IT WAS ZERO AT DENOMINATOR OF \$mix."; }

					push (@mmbasketresult, $result);
					$mmresult = mean(@mmbasketresult);
					$regen = $n1_averageage;
					push (@mmbasketregen, $regen);
					$mmregen = mean(@mmbasketregen);


					##################################################################################################################################################

					#say
					#REPORTFILE
					# "sequence:$countcase,\$countblk:$countblk,\@valuebasket:@valuebasket,\@finalbasket:@finalbasket,averageage:$averageage,\$stddev:$stddev,\$mix:$mix,\$result:$result,\$mixsize:$mixsize,\$regen:$regen,\$score:$score,\$novelty:$novelty,\$urr-->: $urr\n\n";

					# END CALCULATION OF THE LOCAL SEARCH AGE.
					#################################################################################################################
					#################################################################################################################

					###my $steps = Sim::OPT::getstepsvar($elt, $countcase, \@varnumbers);

					$varsnum = ( $activeblock + $zoneend);
					$limit = ($attachment + $activeblock + $zoneend);
					$countafter = 0;
					$counterrank = 0;
					$leftcounter = $attachment;
					$rightcounter = ($attachment + $activeblock);




					$countfirstline = 0;

					if ($countblk > 0) { $antesize = Sim::OPT::givesize(\@pastslice, $countcase, \@varnumbers); }

					$postsize = Sim::OPT::givesize(\@presentslice, $countcase, \@varnumbers);
					$localsize = $postsize + $antesize;

					if ($countblk == 0)
					{
						$localsize = $postsize;
						$localsizeproduct = $postsize;
					}

					$localsizeproduct = $postsize * $antesize;

					$overlapsize =  Sim::OPT::givesize(\@intersection, $countcase, \@tempvarnumbers);
					###$overlapsize = ($steps ** $overlap); say  "BEYOND3 \$overlapsize $overlapsize";###DDD

					if ($overlap == 0) {$overlapsize = 1;}

					#if ( ( $countcase == 0) and ($countblk == 0) )
					#{
					#	print
					#	#OUTFILEWRITE #TABLETITLES
					#	 "\$countcase,\$countblk,\$attachment,\$activeblock,\$zoneend,\$pastattachment,\$pastactiveblock,\$pastzoneend,\$antesize,\$postsize,\$overlap,\$overlapsize,\$overlapminus,\$overlapminussize,\$overlapsum,\$overlapsumsize,\$localsize,\$localnetsize,\$totalsize,\$totaloverlapsize,\$totalnetsize,\$commonalityratio,\$commonality_volume,\$commonalityflow,\$recombinationflow,\$informationflow,\$cumulativecommonalityflow,\$cumulativerecombinationflow,\$cumulativeinformationflow,\$totalcommonalityflow,\$totalrecombinationflow,\$totalinformationflow,\$addcommonalityflow,\$addrecombinationflow,\$addinformationflow,\$recombinalityminusflow,\$cumulativerecombinalityminusflow,\$totalrecombinalityminusflow,\$recombinalityflow,\$cumulativerecombinalityflow,\$totalrecombinalityflow,\$renewalflow,\$cumulativerenewalflow,\$totalrenewalflow,\$infoflow,\$cumulativeinfoflow,\$totalinfoflow,\$refreshmentminus,\$recombination_ratio,\$proportionhike,\$hike,\$refreshment,\$infflow,\$cumulativeinfflow,\$totalinfflow,\$iruiflow,\$cumulativeiruif,\$totaliruif,\$averageageexport,\$cumulativeage,\$stdage,\$refreshratio,\$averageagesize,\$flowratio,\$cumulativeflowratio,\$flowageratio,\$cumulativeflowageratio,\$modiflow,\$cumulativemodiflow,\$refreshmentsize,\$refreshmentperformance,\$cumulativerefreshmentperformance,\$refreshmentvolume,\$IRUIF,\$mmIRUIF,\$IRUIFvolume,\$mmIRUIFvolume,\$hikefactor,\$otherIRUIF,\$othermmIRUIF,\$otherIRUIFvolume,\$othermmIRUIFvolume,\$averageage,\$steddev,\$mix,\$result,\$mixsize,\$regen,\$n1_averageage,\$n1_stddev,\$n1_averageagesize,\$mmresult,\$mmregen,\$novelty,\$urr,\$IRUIFnovelty,\$IRUIFurr,\$IRUIFnoveltysquare,\$IRUIFurrsquare,\$IRUIFnoveltycube,\$IRUIFurrcube";
					#}

					if  ($countblk == 0)
					{
						$antesize = 0;
						$overlap = 0;
						$overlapsize = 0;
						#$overlapminus = 0;  ############ ZZZZ UNNEEDED
						#$overlapminussize = 0;  ############ ZZZZ UNNEEDED
					}

					#if ($overlapminussize == 0) {$overlapminussize = 1;} ############ ZZZZ UNNEEDED
					if ($overlapsize == 0){$overlapsize = 1;}
					if ($totaloverlapsize == 0){$totaloverlapsize = 1;} ############ ZZZZ UNNEEDED?


					#$overlapminussize = Sim::OPT::givesize(\@intersectionminus, $countcase, \@varnumbers); say  "BEYOND3 \$overlapsize $overlapsize"; ############ ZZZZ UNNEEDED
					#$overlapminussize = ($steps ** $overlapminus); ############ ZZZZ UNNEEDED

					#if ($overlapminussize == 0){$overlapminussize = 1;}  ############ ZZZZ UNNEEDED
					#$overlapsum = ($overlapsize / $overlapminussize ); ############ ZZZZ UNNEEDED

					#$overlapsumsize = ($steps ** $overlapsum); ########## ZZZZ UNNEEDED


					#if ($countblk == 0) {$overlapsumsize = 1;}  ############ ZZZZ UNNEEDED

					$localnetsizeproduct = ( $localsizeproduct - $overlapsize );
					if ($localnetsizeproduct == 0) {$localnetsizeproduct = 1;}

					if ($totalsize == 0){$totalsize = 1;}

					$localnetsize = ( $localsize - $overlapsize ); # OK
					if ($localnetsize == 0) {$localnetsize = 1;}
					$totalsize = $totalsize + $postsize; # OK

					$totaloverlapsize = $totaloverlapsize + $overlapsize; #OK
					$totalnetsize = ($totalsize - $totaloverlapsize);  # OK
					if ($totalnetsize == 0) { $localcommonalityratio = 0; }

					#$refreshratio = $overlapsize/$overlapminussize; ############ ZZZZ UNNEEDED

					if  ($countblk == 0)
					{

						$localcommonalityratio = 1; #
						$localiruifratio = 1; # THIS IS THE COMMONALITY OF THE SHADOW AT TIME STEP - 2.
					}
					elsif ($countblk > 0)
					{
						if ( ( ( $antesize * $postsize) ** (1/2)) != 0)
						{
							$localcommonalityratio = (  $overlapsize/ ( ( $antesize * $postsize) ** (1/2)));
						}
						else { print  "IT WAS ZERO AT DENOMINATOR OF \$localcommonalityratio.\n"; }

						if ( ( ( $antesize * $postsize) ** (1/2)) != 0)
						{
							$localiruifratio = ( $overlapminussize / ( ( $antesize * $postsize) ** (1/2)) );
						}
						else { print  "IT WAS ZERO AT DENOMINATOR OF \$localiruifratio.\n"; }
					}

					if ($totalnetsize > 0)
					{
						$commonalityratio = ( $totaloverlapsize / $totalnetsize ); #OK
					}
					$commonality_volume = ($totalnetsize * $commonalityratio); #OK

					if  ($countblk == 0)
					{
						$commonalityflow = $postsize  ** (1/3) ; #OK
						$iruiflow = $postsize ** (1/3) ; #OK
					}
					elsif ($countblk > 0)
					{
							$commonalityflow = (  $commonalityflow * $localcommonalityratio  * $postsize)  ** (1/3) ;
							#$iruiflow = ( $iruifflow * (($localiruifratio * $postsize) ** (1/3))); ############ ZZZZ UNNEEDED
					}

					push (@commonalities, $commonalityflow);#
					$stdcommonality = stddev(@commonalities);#
					$cumulativecommonalityflow = ($cumulativecommonalityflow + $commonalityflow );
					$IRUIFurrsquare = $IRUIFurrsquare + ( $totalnetsize * ( ( $urr )  ** 2 ) );
					#$cumulativeiruif = ($cumulativeiruif + $iruifflow ); say "BEYOND4 \$cumulativeiruif: $cumulativeiruif"; # ############ ZZZZ UNNEEDED

					#if ($countblk == 0) { print OUTFILEWRITE "\n"; }


					say  "RESULPLOT: \$countcase:$countcase,\$countblk:$countblk,\$countbuild:$countbuild,\$countchance:$countchance,\$attachment:$attachment,
					\$activeblock:$activeblock,\$zoneend:$zoneend,\$pastattachment:$pastattachment,\$pastactiveblock:$pastactiveblock,\$pastzoneend:$pastzoneend,
					\$antesize:$antesize,\$postsize:$postsize,\$overlap:$overlap,\$overlapsize:$overlapsize,\$overlapminus:$overlapminus,
					\$overlapminussize:$overlapminussize,\$overlapsum:$overlapsum,\$overlapsumsize:$overlapsumsize,\$localsize:$localsize,
					\$localnetsize:$localnetsize,\$totalsize:$totalsize,\$totaloverlapsize:$totaloverlapsize,\$totalnetsize:$totalnetsize,
					\$commonalityratio:$commonalityratio,\$commonality_volume:$commonality_volume,\$commonalityflow:$commonalityflow,
					\$cumulativecommonalityflow:$cumulativecommonalityflow,\$n1_averageage:$n1_averageage,\$novelty:$novelty,\$urr:$urr,
					\$IRUIFurrsquare:$IRUIFurrsquare,\$cumulativeiruif:$cumulativeiruif";

					$res{$countcase}{$countbuild}{$countchance}{$countblk}{IRUIF} = $IRUIFurrsquare;
					$res{$countcase}{$countbuild}{$countchance}{$countblk}{commonality} = $cumulativecommonalityflow;
					$res{$countcase}{$countbuild}{$countchance}{$countblk}{novelty} = $novelty;
					$res{$countcase}{$countbuild}{$countchance}{$countblk}{totalnetsize} = $totalnetsize;
					$res{$countcase}{$countbuild}{$countchance}{$countblk}{freshness} = $n1_averageage;
					$res{$countcase}{$countbuild}{$countchance}{$countblk}{urr} = $urr;
					$res{$countcase}{$countbuild}{$countchance}{$countblk}{newblockrefs} = \@caserefs_alias;
					$res{$countcase}{$countbuild}{$countchance}{$countblk}{newchance} = \@chancerefs_alias;

					#>
					####################################################



					$countblk++;
					$countblock++;
					$countblockplus1++;
				}

				$countchance++;
			}

			sub getmax
			{
				my @IRUIFcontainer;
				my $countc = 1;
				while ( $countc <= $dimchance )
				{
					push (@IRUIFcontainer, $res{$countcase}{$countbuild}{$countc}{$#caserefs_alias}{IRUIF});
					$countc++;
				}
				my $maxvalue = Sim::OPT::max(@IRUIFcontainer);
				return ($maxvalue);
			}
			my $maxvalue = getmax;

			sub pick
			{
				my $maxvalue = shift;
				my ($beststruct, $bestchance);
				my $countc = 1;
				while ( $countc <= $dimchance )
				{


					if( $res{$countcase}{$countbuild}{$countc}{ $#caserefs_alias }{IRUIF} == $maxvalue )
					{
						$beststruct = $res{$countcase}{$countbuild}{$countc}{ $#caserefs_alias }{newblockrefs};
						$bestchance = $res{$countcase}{$countbuild}{$countc}{ $#caserefs_alias }{newchance};
						last;
					}
					$countc++;
				}
				return ($beststruct, $bestchance);
			}
			my @arr = pick($maxvalue);
			$beststruct = $arr[0]; say  "POST\$beststruct " . dump($beststruct);
			$bestchance = $arr[1]; say  "POST\$bestchance " . dump($bestchance);

			say  "PRE\@blockrefs " . dump(@blockrefs);
			@blockrefs = @$beststruct; say  "POST\@blockrefs " . dump(@blockrefs);
			say  "PRE\@chancerefs " . dump(@chancerefs);
			@chancerefs = @$bestchance; say  "POST\@chancerefs " . dump(@chancerefs);
			say  "\$res " . dump(%res);
			$chanceseed_[$countcase] = $bestchance; say  "POST\@chanceseed_ " . Dumper(@chanceseed_);
			$caseseed_[$countcase] = $beststruct; say  "POST\@caseseed_ " . Dumper(@caseseed_);
			@sweeps_ = Sim::OPT::fromopt_tosweep( casegroup => \@caseseed_, chancegroup => \@chanceseed_ ); say  "POST\@sweeps_ " . Dumper(@sweeps_);
			close TEST;
			close CASEFILE_PROV;
			close CHANCEFILE_PROV;

			$countbuild++;
		}
		$countcase++;
	}
	return (\@sweeps_, \@caseseed_, \@chanceseed_ );
}

1;

__END__

=head1 NAME

Sim::OPT::Takechance.

=head1 SYNOPSIS

  use Sim::OPT::Takechance;
  takechance your_configuration_file.pl;

=head1 DESCRIPTION

The "Sim::OPT::Takechance" module can produce efficient search structures for block coordinate descent given some initialization blocks (subspaces). Its strategy is based on measuring the efficiency of alternative search paths to pick the most efficient one. This is done by seeking for the search moves warranting that (1) the search wake is fresher than that of the average random ones and (2) the search moves are more novel than the average random ones. The rationale for the selection of the seach paths is explained in detail (with algorithms) in the paper at the following web address: http://dx.doi.org/10.1016/j.autcon.2016.08.014.

"Sim::OPT::Takechance" can be called from "Sim::OPT" or directly from the command line (after issuing < re.pl > and < use Sim::OPT::Takechance >) with the command < takechance your_configuration_file.pl >.

The variables to be taken into account to describe the initialization blocks of a search in the configuration file are "@chanceseed" (representing the sequence of design variables at each search step) and "@caseseed" (representing the sequence of decompositions to be taken into account). (In place of the "@chaceseed" and "@caseseed" variables, a "@sweepseed" variable can be specified, written with the same criteria of the variable "@sweeps" described in the documentation of the "Sim::OPT" module; but this possibility has not been throughly tested yet.)

How "@chanceseed" and "@caseseed" should be specified is more quickly described with a couple of examples.

1) If brute force optimization is sought for a case composed by 4 parameters, the following settings should be specified: <@chanceseed = ([1, 2, 3, 4]);> and <@caseseed = ( [ [0, 4] ] ) ;>.

2) If optimization is sought for two cases (brute force, again, for instance, with a different and overlapping set of 5 parameters for the two of them), the two sets of parameters in questions has to be specificied as sublists of the general parameter list: <@chanceseed = ([1, 2, 3, 4, 6, 7, 8], [1, 2, 3, 4, 6, 7, 8]);> and <@caseseed = ( [ [0, 5] , [3, 8] ] ) ;>.

3) If a block search is sought on the basis of 5 parameters, with 4 overlapping active blocks composed by 3 parameters each having the leftmost parameters in position 0, 1, 2 and 4, and two search sweeps are to be performed, with the second sweep having the parameters in inverted order and the leftmost parameters in position 2, 4, 3 and 1, the following settings should be specified: <@chanceseed = ( [ [1, 2, 3, 4, 5], [1, 2, 3, 4, 5], [1, 2, 3, 4, 5], [1, 2, 3, 4, 5], [5, 4, 3, 2, 1], [5, 4, 3, 2, 1], [5, 4, 3, 2, 1], [5, 4, 3, 2, 1]] );> and <@caseseed = ( [ [0, 3], [1, 3], [2, 3], [4, 3] ], [2, 3], [4, 3], [3, 3], [1, 3] ] );>.

4) By playing with the order of the parameters' sequence, blocks with non-contiguous parameters can be specified. Example: <@chanceseed = ( [ [1, 2, 3, 4, 5], [1, 2, 3, 4, 5], [1, 2, 3, 4, 5], [1, 2, 3, 4, 5], [5, 2, 4, 1, 3], [2, 4, 1, 5, 2], [5, 1, 4, 2, 3], [5, 1, 4, 2, 3] ] );> and <@caseseed = ( [ [0, 3], [1, 3], [2, 3], [4, 3] ], [2, 3], [4, 3], [3, 3], [1, 3] ] );>.

5) The initialization blocks can be of different size. Example: <@chanceseed = ( [ [1, 2, 3, 4, 5], [1, 2, 3, 4, 5], [1, 2, 3, 4, 5], [1, 2, 3, 4, 5], [5, 2, 4, 1, 3], [2, 4, 1, 5, 2], [5, 1, 4, 2, 3], [5, 1, 4, 2, 3] ] );> and <@caseseed = ( [ [0, 3], [1, 3], [2, 3], [4, 3] ], [2, 2], [4, 2], [3, 4], [1, 4] ] );>.

Other variables which are necessary to define in the configuration file for describing the operations to be performed by the "Sim::OPT::Takechance" module are "@chancedata", "$dimchance", "@pars_tocheck" and "@varnumbers".

"@chancedata" is composed by references to arrays (one for each search path to be taken into account, as in all the other cases), each of which composed by three values: the first specifying the length (how many variables) of the blocks to be added; the second specifying the length of the overlap between blocks; the third specifying the number of sweeps (subsearches, searches in subspaces) to be added. For example, the setting < @chancedata = ([4, 3, 2]); > implies that the blocks to be added to the search path are each 4 parameters long, have each an overlap of 3 parameters with the immediately preceding block, and are 2 in number - that is, 2 sweeps have to be added to the search path.

"$dimchance" tells the program among how many random samples the blocks to be added to the search path have to be chosen. The higher the value, the most efficient the search structure will turn out to be, the higher the required computation time will be. High values are likely to be required by large search structures.

"@varnumbers" is shared with the Sim::OPT module. It specifies the number of iterations to be taken into account for each parameter and each search case. For example, to specifiy that the parameters of a search structure involving 5 parameters (numbered from 1 to 5) for one case are to be tried for 3 values (iterations) each, "@varnumbers" has to be set to "( { 1 => 3, 2 => 3, 3 => 3, 4 => 3, 5 => 3 } )".

"@pars_tocheck" is a variable in which the parameter numbers to be taken into account in the creation of the added search path have to be listed. If it is not defined, all the available parameters will be used.

The response produced by the "Sim::OPT::Takechance" module will be written in a long-name file in the work folder: "./search_structure_that_may_be_adopted.txt".

This module is dual-licensed, open-source and proprietary. The open-source distribution is available on CPAN (https://metacpan.org/dist/Sim-OPT ). A proprietary distribution, including additional modules (OPTcue), is available from the author’s website (https://sites.google.com/view/bioclimatic-design/home/software ).

=head2 EXPORT

"takechance".

=head1 SEE ALSO

An example of configuration instructions for Sim::OPT::Takechance is included in the comments in the "esp.pl" file, which is packed in "optw.tar.gz" file in "examples" directory in this distribution. But mostly, reference to the source code should be made.

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2025 by Gian Luca Brunetti, gianluca.brunetti@gmail.com. This software is distributed under a dual licence, open-source (GPL v3) and proprietary. The present copy is GPL. By consequence, this is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


=cut
