package Sim::OPT::Sim;
# Copyright (C) 2008-2015 by Gian Luca Brunetti and Politecnico di Milano.
# This is the module Sim::OPT::Sim of Sim::OPT, a program for detailed metadesign managing parametric explorations through the ESP-r building performance simulation platform and performing optimization by block coordinate descent.
# This is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.

use v5.14;
# use v5.20;
use Exporter;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
use Math::Trig;
use Math::Round;
use List::Util qw[ min max reduce shuffle];
use List::MoreUtils qw(uniq);
use List::AllUtils qw(sum);
use Statistics::Basic qw(:all);
use Set::Intersection;
use List::Compare;
use IO::Tee;
use File::Copy qw( move copy );
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
use Sim::OPT;
use Sim::OPT::Morph;
use Sim::OPT::Report;
use Sim::OPT::Descend;
use Sim::OPT::Takechance;
#use Parallel::ForkManager;
no strict;
no warnings;
use warnings::unused;
@ISA = qw( Exporter ); # our @adamkISA = qw(Exporter);
#%EXPORT_TAGS = ( DEFAULT => [qw( &opt &prepare )]); # our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
#@EXPORT   = qw(); # our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( sim ); # our @EXPORT = qw( );

$VERSION = '0.067'; # our $VERSION = '';
$ABSTRACT = 'Sim::OPT::Sim is the module used by Sim::OPT to launch simulations once the models have been built.';

#########################################################################################
# HERE FOLLOWS THE CONTENT OF "Sim.pm", Sim::OPT::Sim
##############################################################################

# HERE FOLLOWS THE "sim" FUNCTION, CALLED FROM THE MAIN PROGRAM FILE.
# IT LAUCHES SIMULATIONS AND ALSO RETRIEVES RESULTS.
# THE TWO OPERATIONS ARE CONTROLLED SEPARATELY
# FROM THE OPT CONFIGURATION FILE.

#____________________________________________________________________________
# Activate or deactivate the following function calls depending from your needs


sub sim    # This function launch the simulations in ESP-r
{
  my %vals = %main::vals;
  my $mypath = $main::mypath;
  my $exeonfiles = $main::exeonfiles;
  my $generatechance = $main::generatechance;
  my $file = $main::file;
  my $preventsim = $main::preventsim;
  my $fileconfig = $main::fileconfig;
  my $outfile = $main::outfile;
  my $tofile = $main::tofile;
  my $report = $main::report;
  my $simnetwork = $main::simnetwork;
  my $max_processes = $main::max_processes;

  $tee = new IO::Tee(\*STDOUT, ">>$tofile" ); # GLOBAL ZZZ

  #open( OUTFILE, ">>$outfile" ) or die "Can't open $outfile: $!";
  #open( TOFILE, ">>$tofile" ) or die "Can't open $tofile: $!";
  say $tee "\nNow in Sim::OPT::Sim.\n";

  my %simtitles = %main::simtitles;
  my %retrievedata = %main::retrievedata;
  my @keepcolumns = @main::keepcolumns;
  my @weights = @main::weights;
  my @weightsaim = @main::weightsaim;
  my @varthemes_report = @main::varthemes_report;
  my @varthemes_variations = @vmain::arthemes_variations;
  my @varthemes_steps = @main::varthemes_steps;
  my @rankdata = @main::rankdata; # CUT ZZZ
  my @rankcolumn = @main::rankcolumn;
  my %reportdata = %main::reportdata;
  my @files_to_filter = @main::files_to_filter;
  my @filter_reports = @main::filter_reports;
  my @base_columns = @main::base_columns;
  my @maketabledata = @main::maketabledata;
  my @filter_columns = @main::filter_columns;

  my %dat = %{ $_[0] };
  my @instances = @{ $dat{instances} }; #say $tee "IN SIM \@instances " . dump( @instances );
  my %dirfiles = %{ $dat{dirfiles} };

  my @simcases = @{ $dirfiles{simcases} };
  my @simstruct = @{ $dirfiles{simstruct} };
  my @morphcases = @{ $dirfiles{morphcases} };
  my @morphstruct = @{ $dirfiles{morphstruct} };
  my @retcases = @{ $dirfiles{retcases} };
  my @retstruct = @{ $dirfiles{retstruct} };
  my @repcases = @{ $dirfiles{repcases} };
  my @repstruct = @{ $dirfiles{repstruct} };
  my @mergecases = @{ $dirfiles{mergecases} };
  my @mergestruct = @{ $dirfiles{mergestruct} };
  my @descendcases = @{ $dirfiles{descendcases} };
  my @descendstruct = @{ $dirfiles{descendstruct} };

  my $morphlist = $dirfiles{morphlist};
  my $morphblock = $dirfiles{morphblock};
  my $simlist = $dirfiles{simlist};
  my $simblock = $dirfiles{simblock};
  my $retlist = $dirfiles{retlist};
  my $repfile = $dirfiles{repfile}; #say $tee "IN SIM \$repfile: " . dump($repfile);
  my $retblock = $dirfiles{retblock};
  my $replist = $dirfiles{replist};
  my $repblock = $dirfiles{repblock};
  my $descendlist = $dirfiles{descendlist};
  my $descendblock = $dirfiles{descendblock};

  my %d = %{ $instances[0] }; #say $tee "IN SIM \%d!!! : " . dump( %d );

  my $countcase = $d{countcase}; #say $tee "IN SIM \$countcase : " . dump( $countcase );
  my $countblock = $d{countblock}; #say $tee "IN SIM \$countblock : " . dump( $countblock );
  my %datastruc = %{ $d{datastruc} }; ######
  my @varnumbers = @{ $d{varnumbers} }; #say $tee "IN ENTRY SIM \@varnumbers : " . dump( @varnumbers );
  my @miditers = @{ $d{miditers} }; #say $tee "IN ENTRY SIM \@miditers : " . dump( @miditers );
  my @sweeps = @{ $d{sweeps} };


  if ( $countcase > $#sweeps )# NUMBER OF CASES OF THE CURRENT PROBLEM
  {
    if ( $dirfiles{checksensitivity} eq "yes" )
    {
      Sim::OPT::sense( $dirfiles{ordtot}, $mypath, $sense{objectivecolumn} );
    }
    exit(say $tee "#END RUN.");
  }

  my %dowhat = %{ $d{dowhat} }; #say $tee "DOWHAT IN SIM " . dump( \%dowhat );
  my $skipfile = $vals{skipfile};
	my $skipsim = $vals{skipsim};
	my $skipreport = $vals{skipreport};

  my %notecases;

  #my $getpars = shift;
  #eval( $getpars );

  #if ( fileno (MORPHLIST)

  my ( $resfile, $flfile );
  my @container;
  #my $pm = new Parallel::ForkManager( $max_processes ); #Sets up the possibility of opening child processes
  foreach my $instance (@instances)
  { #say $tee "IN SIM \$instance : " . dump( $instance );
    #my $pid = $pm->start and next; # Begins the child process
    my %dt = %{$instance};
    my @winneritems = @{ $dt{winneritems} }; #say $tee "IN SIM \@winneritems : " . dump( @winneritems );
    my $countvar = $dt{countvar}; #say $tee "IN SIM \$countvar : " . dump( $countvar );
    my $countstep = $dt{countstep}; #say $tee "IN SIM \$countstep : " . dump( $countstep );
    my $c = $dt{c}; #say $tee "IN SIM1 \$c : " . dump( $c );

		my %to = %{ $dt{to} }; #say $tee " IN SIM \%to " . dump( \%to );
		my %inst = %{ $dt{inst} };
    my $instn = $dt{instn}; #say $tee " IN SIM \$instn " . dump( $instn );

		my $from = $dt{from}; #say $tee " IN SIM \$from $from ";
		my $toitem = $dt{toitem}; #say $tee " IN SIM \$toitem $toitem ";

    my @blockelts =$dt{blockelts};
    my @blocks = $dt{blocks};
    my %varnums = $dt{varnums};
    my %mids = $dt{mids};
    my $countinstance = $dt{instn}; #say $tee "IN SIM1 \$countinstance : " . dump( $countinstance );


    my $skip = $dowhat{$countvar}{skip}; #########################################
    my ( $resfile, $flfile );
    #eval($getfly);

    my $varnumber = $countvar;
    my $stepsvar = $varnums{$countvar};

    my @ress;
    my @flfs;
    my $countdir = 0;

    my $numberof_simtools = scalar ( keys %{ $dowhat{simtools} } );
    my $simelt = $to{crypto}; say $tee "IN SIM \$simelt $simelt";


    if ( $dowhat{simulate} eq "y")
    {
      my $counttool = 1;
      while ( $counttool <= $numberof_simtools )
      {
        my $skip = $vals{$countvar}{$counttool}{skip};
        if ( not ( eval ( $skipsim{$counttool} )))
        {
          my $tooltype = $dowhat{simtools}{$counttool};

          if ( $tooltype eq "esp-r" )
          {
            my $launchline = "-file $simelt/cfg/$fileconfig -mode script";



            my $countsim = 0;
            foreach my $simtitle_ref ( @{ $simtitles{$counttool} } )
            {
              my $date_to_sim = $simtitle_ref->[0];
              my $begin = $simtitle_ref->[1];
              my $end = $simtitle_ref->[2];
              my $before = $simtitle_ref->[3];
              my $step = $simtitle_ref->[4];

              if ( ( $simelt ne "") and ( $date_to_sim ne "" ) )
              {
                $resfile = "$simelt-$date_to_sim-$tooltype.res"; say $tee "IN SIM \$resfile $resfile";
                $flfile = "$simelt-$date_to_sim-$tooltype.fl"; #say $tee "IN SIM \$flfile $flfile";
              }

              #if ( fileno (SIMLIST) )
              #if (not (-e $simlist ) )
              #{
              #  if ( $countblock == 0 )
              #  {
                  open( SIMLIST, ">$simlist") or die( "$!" );
              #  }
              #  else
              #  {
              #    open( SIMLIST, ">>$simlist") or die;
              #  }
              #}

              #if ( fileno (SIMBLOCK) )
              if (not (-e $simblock ) )
              {
                if ( $countblock == 0 )
                {
                  open( SIMBLOCK, ">$simblock"); # or die;
                }
                else
                {
                  open( SIMBLOCK, ">$simblock"); # or die;
                }
              }


              push ( @{ $simstruct[ $countcase ][ $countblock ][ $countinstance ][$counttool] }, $resfile );
              print SIMBLOCK "$resfile\n";

              if ( ( not ( $resfile ~~ @simcases ) ) and ( not ( -e $resfile ) ) )
              {
                push ( @simcases, $resfile );
                print SIMLIST "$resfile\n";

                unless ( ( $preventsim eq "y" ) or ( $dowhat{inactivatesim} eq "y" ) or ( $dowhat{simulate} eq "n" ) )
                {
                  if ( $simnetwork eq "y" )
                  {
                    say "#Simulating case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep for tool $tooltype. Instance $countinstance: writing $resfile and $flfile." ;
                    my $printthis =
"bps $launchline<<XXX

c
$resfile
$flfile
$begin
$end
$before
$step
s
$simnetwork
Results for $simelt-$dates_to_sim
y
y
-
-
-
-
-
-
-
XXX
  ";
                    if ($exeonfiles eq "y")
                    {
                      print `$printthis`;
                    }
                    print TOFILE "
        #Simulating case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep. Instance $countinstance.\
        $printthis
        \n";
                    print OUTFILE "TWO, $resfile\n";
                  }
                  else #  if ( $simnetwork eq "n" )
                  {
                    say "#Simulating case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep for tool $tooltype. Instance $countinstance: writing $resfile. " ;
                    my $printthis =
"bps $launchline<<XXX

c
$resfile
$begin
$end
$before
$step
s
$simnetwork
Results for $simelt-$date_to_sim
y
y
-
-
-
-
-
-
-
XXX
";
                    if ($exeonfiles eq "y")
                    {
                      print `$printthis`;
                    }
                    print TOFILE "
$printthis
";
                  }
                }
              }

              $countsim++;
            }


          }
          elsif ( ( $tooltype eq ( "generic" ) ) or ( $tooltype eq ( "energyplus" ) ) )
          {  # TO DO: POSSIBILITY TO SPECIFY LINE AND ELEMENT OF TEXT SUBSTITUTIONS.
            # THIS PART OF PROCEDURE HAS BEEN THOUGHT FOR ENERGYPLUS, THEN GENERALIZED.
            my $countsim = 0;
            foreach my $simtitle_ref ( @{ $simtitles{$counttool} } )
            {
              my $date_to_sim = $simtitle_ref->[0];
              my $begin = $simtitle_ref->[1];
              my $end = $simtitle_ref->[2];
              my $before = $simtitle_ref->[3];
              my $step = $simtitle_ref->[4];

              my $epw = $simtitle_ref->[5]; #say "\$epw $epw ";
              my $epwfile = $mypath . "/" . $epw; #say "\$epwfile $epwfile ";
              my $epdir = $simtitle_ref->[6]; #say "\$epdir $epdir ";
              my $epoldfile = $simtitle_ref->[7]; #say "\$epoldfile $epoldfile ";
              my $epnewfragment = $simtitle_ref->[8]; #say "\$epnewfragment $epnewfragment ";
              my $outputdir = $simtitle_ref->[9]; #say "\$outputdir $outputdir ";
              my $modfiletype = $simtitle_ref->[10]; #say "\$modfiletype $modfiletype ";
              my $resfiletype = $simtitle_ref->[11]; #say "\$resfiletype $resfiletype ";
              my $to = $to{crypto}; ### TAKE CARE!!!
              my $epoldpath = $to . $epdir . "/" . $epoldfile; #say "\$epoldpath $epoldpath ";
              my $tempname = $to; #say "\$tempname $tempname ";
              $tempname =~ s/$mypath\/// ; #say "\$epw $epw "; say "\$tempname $tempname ";
              my $epnewfile = $tempname . $epnewfragment . "$epnewfile"; #say "\$epw $epnewfile ";
              my $epresroot = $tempname . $epnewfragment ; #say "\$epw $epresroot ";

              my $epnewpath;
              $resfile;

              $epnewpath = $to . $epdir . "/" . $epnewfile;

              my @simdos = @{ $simtitle_ref };
              my @changes = @simdos[ 12..$#simdos ];
              if ( $tooltype eq "energyplus" ) # RESTORES DEFAULTS FOR ENERGYPLUS
              {
                $outputdir = "/Output";
                $modfiletype = ".idf";
                unless ( defined( $resfilename ) )
                {
                  $resfilename = ".eso";
                }
              }

              open ( EPOLDPATH, "$epoldpath" ) or die( "$!" );
              my @sourcecontents = <EPOLDPATH>;
              close EPOLDPATH;

              unless ( -e $epnewpath )
              {
                open ( EPNEWPATH, ">$epnewpath" ) or die( "$!" );
                foreach my $row ( @sourcecontents )
                {
                  foreach my $change ( @changes )
                  {
                    my $source = $change->[0];
                    my $target = $change->[1];
                    $row =~ s/$source/$target/ ;
                  }
                  print EPNEWPATH $row;

                }
                close EPNEWPATH;
              }

              my $file_eplus = "$to/$file_eplus";

              my $simelt = $mypath . "$outputdir";


              $resfile = "$simelt/$epresroot$resfiletype";


              unless ( $dowhat{inactivatesim} eq "y" )
              {

                if (not ( -e $simblock ) )
                {
                  if ( $countblock == 0 )
                  {
                    open( SIMBLOCK, ">$simblock"); # or die;
                  }
                  else
                  {
                    open( SIMBLOCK, ">$simblock"); # or die;
                  }
                }

                if (not (-e $retblock ) )
                {
                  if ( $countblock == 0 )
                  {
                    open( RETBLOCK, ">$retblock"); # or die;
                  }
                  else
                  {
                    open( RETBLOCK, ">$retblock"); # or die;
                  }
                }
              }

              push ( @{ $simstruct[ $countcase ][ $countblock ][ $countinstance ][ $counttool ] }, $resfile );
              push ( @{ $retstruct[ $countcase ][ $countblock ][ $countinstance ][ $counttool ] }, $resfile );

              unless ( $dowhat{inactivatesim} eq "y" )
              {
                print SIMBLOCK "$resfile\n";
              }

              if ( ( not ( $resfile ~~ @retcases ) ) and ( not ( -e $resfile ) ) )
              {
                push ( @simcases, $resfile );
                push ( @retcases, $resfile );

                unless ( $dowhat{inactivatesim} eq "y" )
                {
                  print SIMLIST "$resfile\n";
                  print RETLIST "$resfile\n";
                }

                unless ( ( $preventsim eq "y" ) or ( $dowhat{inactivatesim} eq "y" ) )
                {
                  open ( OLDFILEEPLUS, $epoldpath ) or die( "$!" );
                  my @oldlines = <OLDFILEEPLUS>;
                  close OLDFILEEPLUS;
                  unless ( -e $epnewpath )
                  {
                    open ( NEWFILEEPLUS, ">$epnewpath" ) or die( "$!" );
                    foreach my $line ( @oldlines )
                    {
                      foreach my $elt ( @changes )
                      {
                        my $old = $elt->[0];
                        my $new = $elt->[1];
                        $line =~ s/$old/$new/;
                      }
                      print NEWFILEEPLUS $line;
                    }
                    close NEWFILEEPLUS;
                  }

                  my $templaunch;
                  unless ( -e $resfile )
                  {
                    unless ( $exeonfiles eq "n" )
                    {
                      my $tempf = $epnewpath;
                      $tempf =~ s/$to$epdir\///;
                      $templaunch = $mypath . "/" . $tempf;
                      `cp -f $epnewpath $templaunch`;
                      `runenergyplus $templaunch $epwfile`;
                      #`rm -f $templaunch`;
                    }

                    print TOFILE "cp -f $epnewpath $templaunch\n";
                    print TOFILE "runenergyplus $templaunch $epwfile\n";

                    say "#Simulating case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep for tool $tooltype. Instance $countinstance: using $epnewpath (actually $templaunch) to obtain $resfile. " ;
                  }
                }
              }


              $countsim++;
            }
          }
        }
        $counttool++;
      }
      #$pm->finish; # Terminates the child process

    }



    #say $tee "DUE resfile: $resfile!";

    if ( $dowhat{newretrieve} eq "y" )
    {
      #say $tee "INSIM1: countinstance: $countinstance";
      #say $tee "INSIM1: \$resfile: $resfile";
      #say $tee "INSIM1: \$flfile: $flfile";
      my @resultretrieve = Sim::OPT::Report::newretrieve(
      {
        instance => $instance, dirfiles => \%dirfiles,
        resfile => $resfile, flfile => $flfile
      } );
      $dirfiles{retcases} = $resultretrieve[0];
      $dirfiles{retstruct} = $resultretrieve[1];
      $dirfiles{notecases} = $resultretrieve[2];
    }

    if ( $dowhat{newreport} eq "y" )
    {
      #say $tee "INSIM2: countinstance: $countinstance";
      my @resultreport = Sim::OPT::Report::newreport(
      {
        instance => $instance, dirfiles => \%dirfiles,
        resfile => $resfile, flfile => $flfile
      } );
      $dirfiles{repcases} = $resultreport[0];
      $dirfiles{repstruct} = $resultreport[1];
      $dirfiles{mergestruct} = $resultreport[3];
      $dirfiles{mergecases} = $resultreport[4];
    }
  }
  close SIMLIST;
  close SIMBLOCK;

  return( \@simcases, \@simstruct, $dirfiles{repcases}, $dirfiles{repstruct},
    $dirfiles{mergestruct}, $dirfiles{mergecases} );
  close TOFILE;
  close OUTFILE;

}    # END SUB sim;

# END OF THE CONTENT OF Sim::OPT::Sim
##############################################################################
##############################################################################

1;


__END__

=head1 NAME

Sim::OPT::Sim.

=head1 SYNOPSIS

  use Sim::OPT;
  opt;

=head1 DESCRIPTION

Sim::OPT::Sim is the module used by Sim::OPT to launch the simulations once the models have been built. Sim::OPT::Sim's presently existing functionalities can be used to launch simulations in ESP-r and EnergyPlus. The possibility to call simulation programs other than the cited two may be pursued through modifications of the code dedicated to EnergyPlus (which is actually meant as an example of a generic case). This code portion may be actually constituted by the single line launching the simulation program through the shell.

=head2 EXPORT

"sim".

=head1 SEE ALSO

Annotated examples can be found packed in the "optw.tar.gz" file in "examples" directory in this distribution. 

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2015 by Gian Luca Brunetti and Politecnico di Milano. This is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


=cut
