package Sim::OPT;
# This is Sim::OPT, a program managing building performance simulation programs for performing optimization by overlapping block coordinate descent.
# Sim::OPT is distributed under a dual licence, open-source (GPL v3) and proprietary.
# Copyright (C) 2008-2025 by Gian Luca Brunetti, gianluca.brunetti@gmail.com. This software is distributed under a dual licence, open-source (GPL v3) and proprietary. The present copy is GPL. By consequence, this is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


use Exporter;
use parent 'Exporter';
our @ISA = qw( Exporter );

our @EXPORT = qw( opt $checkoptcue 
odd even _mean_ flattenvariables count_variables fromopt_tosweep fromsweep_toopt convcaseseed
convchanceseed makeflatvarnsnum calcoverlaps calcmiditers definerootcases
callcase callblock deffiles makefilename extractcase setlaunch exe start
_clean_ getblocks getblockelts getrootname definerootcases populatewinners
getitem getline getlines getstepsvar tell wash flattenbox enrichbox filterbox givesize
$configfile $mypath $exeonfiles $generatechance $file $preventsim $fileconfig $outfile $tofile $report
$simnetwork @themereports %simtitles %reporttitles %retrievedata
@keepcolumns @weights @weightsaim @varthemes_report @varthemes_variations @varthemes_steps
@rankdata @rankcolumn @reporttempsdata @reportcomfortdata %reportdata
@report_loadsortemps @files_to_filter @filter_reports @base_columns @maketabledata @filter_columns
@files_to_filter @filter_reports @base_columns @maketabledata @filter_columns %vals
@sweeps @miditers @varnumbers @caseseed @chanceseed @chancedata $dimchance  @pars_tocheck retrieve
report newretrieve newreport washn
$target %dowhat readsweeps $max_processes $computype $calcprocedure %specularratios @totalcases @winneritems
toil genstar solvestar integratebox filterbox__ clean %dowhat @weighttransforms takechance 
);
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

use Math::Trig;
use Math::Round;
use List::Util qw[ min max reduce shuffle];
use List::MoreUtils qw(uniq);
use List::AllUtils qw(sum);
use Sim::OPT::Stats qw( :all );
use Storable qw(store retrieve lock_store lock_nstore lock_retrieve dclone);
use File::Copy qw( move copy );
use Set::Intersection;
use List::Compare;
use Data::Dumper;
use POSIX;
use Data::Dump qw(dump);
use feature 'say';
use Switch::Back;

#use Sub::Signatures;
#no warnings qw(Sub::Signatures);
no strict;
no warnings;
use warnings::unused;

use Sim::OPT::Morph;
use Sim::OPT::Sim;
use Sim::OPT::Report;
use Sim::OPT::Descend;
use Sim::OPT::Interlinear;
use Sim::OPT::Takechance;
use Sim::OPT::Parcoord3d;
use Sim::OPT::Stats;
eval { use Sim::OPTcue::OPTcue; 1 };

$VERSION = '0.885';
$ABSTRACT = 'Sim::OPT is an optimization and parametric exploration program oriented toward problem decomposition. It can be used with simulation programs receiving text files as input and emitting text files as output. It allows a free mix of sequential and parallel block coordinate searches, as well of searches more complely structured in graphs.';

#################################################################################
# Sim::OPT
#################################################################################


our %cryptc;
our $globcount = 0; 



sub getnear
{
	my ( $missing, $carrier_r, $countcase ) = @_;

	my %carrier = %{ $carrier_r };
	my ( @indices, @numfrom, @numto );
	my @missings = split( "_|-", $missing );

	foreach my $key (sort {$a <=> $b} (keys %carrier ) )
	{
	  push( @indices, $key );
		push( @numfrom, $carrier{$key} );
	}

	$c = 0;
	foreach my $el ( @missings )
	{
		if ( Sim::OPT::odd( $c ) )
		{
			push ( @numto, $el );
		}
		$c++;
	}

	my ( @numchanges, @diffchanges );
	my $c = 0;
	foreach my $el ( @numto )
	{
		if ( not ( $el eq "$numfrom[$c]" ) )
		{
			push ( @numchanges,  $el );
		}
		elsif ( $el eq "$numfrom[$c]" )
		{
			push ( @numchanges, "x" );
		}
		$c++;
	}

	my ( @nummix, @countvrs, @countsteps );
	my $c = 0;
  foreach my $el ( @numchanges )
	{
		unless ( $el eq "x" )
		{
			my $cn = 0;
			foreach ( @numfrom )
			{
				splice ( @numfrom, $c, 1, $el );
			}
      push ( @countsteps, $el );
			push ( @nummix, [ @numfrom ] );
			push ( @countvrs, $indices[$c] );
      $cn++
		}
		$c++
	}

	my ( @box );
	foreach my $elt_r ( @nummix )
	{
		my $line = "";
		my @elts = @{ $elt_r };
		my $count = 0;
		foreach my $elt ( @elts )
		{
      $line = $line . $indices[$count] . "-" . $elt . "_";
			$count++;
		}
		chop $line;
    push ( @box, $line );
	}

	return( \@box, \@countvrs, \@countsteps );
}


sub washblockelts
{
  my @blockelts = @{$_[0] };
  my @bag;
  foreach my $elt ( @blockelts )
  {  my ( @bin, $newelt );
     if ( $elt =~ /(>|<|£|§|ì|à|ò|è|ß|ð|æ|đ|ŋ|ħ|ſ|ł|€|°|ø|ŧ|ù)/ )
     {
       @bin = split( ">|<|£|§|ì|à|ò|è|ß|ð|æ|đ|ŋ|ħ|̉ſ|ł|à|°|ø|ŧ|ù", $elt );
       $newelt = $bin[1];
       $newelt =~ s/(ù|ç|ł)// ;
       push( @bag, $newelt );
     }
     else 
     {
       push( @bag, $elt );
     }
  }
  return( \@bag );
}


sub wash_sourcesweeps
{
  my ($sweeps_r) = @_;

  my $sep = qr/[><£§ìàòèßðæđŋħſł€ø°ŧùéç]/u;
  my $wash; $wash = sub
  {
    my ($x) = @_;
    if ( ref($x) eq 'ARRAY' )
    {
      return( [ map { $wash->($_) } @$x ] );
    }

    if ( ref($x) )
    {
      return $x;
    } 
    
    if ( not defined $x )
    {
      return $x;
    }

    my $v = $x;

    if ( $v =~ $sep )
    {
      my @parts = split /$sep+/, $v;
      $v = $parts[-1];
    }

    $v =~ s/^\s+|\s+$//g;

    if ( $v =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/ )
    {
      $v = 0 + $v;
    }
    return( $v );
  };
  return( $wash->($sweeps_r) );
}


sub makeinstance
{
  my ( $newname, $mids_r, $countcase, $baseinsts_r, $dowhat_r, $fire, $instn, $pairs_r ) = @_;

  my %mids      = %{ $mids_r };
  my @baseinsts = @{ $baseinsts_r };
  my %dowhat    = %{ $dowhat_r };

  # Take the last base instance as template (same as setpickinst does with pop)
  my $ins_r = shift( @baseinsts );
  my @pairs = @$pairs_r; say  "IN makeinstance, \@pairs: " . dump( @pairs );

  my %b = %{ $ins_r };

  my $countblock = $b{countblock};
  my $countcase = $b{countcase};
  my @miditers = @{ $b{miditers} };
  my @sweeps = @{ $b{sweeps} };
  my @sourcesweeps = @{ $b{sourcesweeps} };
  my @varnumbers = @{ $b{varnumbers} };
  my @blocks = @{ $b{blocks} };
  my @blockelts = @{ $b{blockelts} };
  my %varnums = %{ $b{varnums} };
  my %carrier = %{ $b{carrier} };
  my $countvar = $b{countvar};  
  my $countstep = $b{countstep};
  my %inst = %{ $b{inst} };

  my @winneritems = @{ $b{winneritems} }      if exists $b{winneritems};
  my %incumbents = %{ $b{incumbents} }        if exists $b{incumbents};
  my %vehicles = %{ $b{vehicles} }         if exists $b{vehicles};
  my $c = $b{c}                     if exists $b{c};
  my $from = $b{from}                  if exists $b{from};

  my $mypath = $dowhat{mypath};
  my $file = $dowhat{file};
   
  my $stamp;

  if ( $dowhat{names} eq "short" )
	{
		$stamp = encrypt1( $newname );
	}
	elsif ( $dowhat{names} eq "medium" )
	{
		$stamp = encrypt0( $newname );
	}

  my ( @vars, @levs );
  foreach $pair ( @pairs )
  {
    my ( $var, $lev ) = split( "-", $pair );
    push( @vars, $var );
    push( @levs, $lev );
  }
  say  "IN makeinstance, \@vars: " . dump( @vars );
  say  "IN makeinstance, \@levs: " . dump( @levs );

  my $varstring = join( "-", @vars ); say  "IN makeinstance, \$varstring: " . dump( $varstring );
  my $levstring = join( "-", @levs ); say  "IN makeinstance, \$varstring: " . dump( $varstring );

  my $origin = giveback( \%mids );

  my ( %to, %orig );
  my @whatto;

  push( @whatto, "end" );

  my $is = $newname;

  # File names & clean names
  $to{to}      = "$mypath/$file" . "_" . "$is";
  $to{cleanto} = $is;

  $orig{to}      = "$mypath/$file" . "_" . "$origin";
  $orig{cleanto} = $origin;

  # Encryption / crypto fields
  if ( $dowhat{names} eq "short" )
  {
    my $crypto  = encrypt1( $is );
    my $cryptor = encrypt1( $origin );

    $to{crypto}        = "$mypath/$file" . "_" . "$crypto";
    $to{cleancrypto}   = $crypto;
    $orig{crypto}      = "$mypath/$file" . "_" . "$cryptor";
    $orig{cleancrypto} = $cryptor;
  }
  elsif ( $dowhat{names} eq "medium" )
  {
    my $crypto  = encrypt0( $is );
    my $cryptor = encrypt0( $origin );

    $to{crypto}        = "$mypath/$file" . "_" . "$crypto";
    $to{cleancrypto}   = $crypto;
    $orig{crypto}      = "$mypath/$file" . "_" . "$cryptor";
    $orig{cleancrypto} = $cryptor;
  }
  else # names == long
  {
    $to{crypto}        = $to{to};
    $to{cleancrypto}   = $to{cleanto};
    $orig{crypto}      = $orig{to};
    $orig{cleancrypto} = $orig{cleanto};
  }


  #my $countvar  = undef;  # you can fill these if you want to track which var/step moved
  #my $countstep = undef;
  my $c        = 0;      # single step

  my @newinstance;

  push( @newinstance,
  {
    countcase     => $countcase,
    countblock    => $countblock,
    miditers      => \@miditers,
    winneritems   => \@winneritems,
    c             => $c,
    from          => $from,

    to            => \%to,
    orig          => \%orig,
    countvar      => $varstring,
    countstep     => $levstring,

    sweeps        => \@sweeps,
    sourcesweeps  => \@sourcesweeps,
    incumbents     => \%incumbents,
    varnumbers    => \@varnumbers,
    blocks        => \@blocks,
    blockelts     => \@blockelts,
    mids          => \%mids,
    varnums       => \%varnums,
    carrier       => \%carrier,        # as in your original

    countinstance => $instn,
    origin        => $origin,
    instn         => $instn,
    is            => $is,
    vehicles      => \%vehicles,

    mypath        => $mypath,
    file          => $file,
    whatto        => \@whatto,
    fire          => $fire,
    stamp         => $stamp,
  } );
  return( \@newinstance, $newinst_r );
}


sub givemyvarnums
{
  my ( $s ) = @_;
  $s = '' unless defined $s;

  my %lvl;
  while ( $s =~ /(?:^|_)(\d+)-(\d+)(?=_|$)/g) 
  {
    my ($v, $l) = ($1, $2);
    $lvl{$v} = $l;
  }
  return( \%lvl );
}


sub idfrompath
{
  my ( $path, $file ) = @_;

  return "" if ( !defined($path) or $path eq "" );

  # normalize slashes
  $path =~ s{\\}{/}g;

  # if you pass $file (e.g. "amtry"), strip everything up to "${file}_"
  if ( defined($file) and $file ne "" )
  {
    # match ".../<anything>/${file}_4-1_5-2/..." or ".../${file}_4-1_5-2..."
    if ( $path =~ m{(?:^|/)\Q$file\E\_([^/]+?)(?:/|$)} )
    {
      return $1;  # "4-1_5-2"
    }
  }

  # fallback: match ".../amtry_4-1_5-2/..." (any prefix ending with "_")
  if ( $path =~ m{(?:^|/)[^/]*_([^/]+?)(?:/|$)} )
  {
    return $1;
  }

  return "";
}


sub cleaninst 
{
  my %inst = @_;
  return %inst;
}


sub giveback
{
  my %mids = %{ $_[0] };

  my $string;
  foreach my $key ( sort { $a <=> $b } ( keys %mids ) )
  {

    $string = $string . $key . "-" . $mids{$key} . "_";
  }
  $string =~ s/_$// ;
  return( $string );
}



sub setpickinst
{
  my ( $missing, $mids_r, $countcase, $baseinsts_r, $dowhat_r ) = @_;
  my %mids = %{ $mids_r };
  my @baseinsts = @{ $baseinsts_r }; say RELATE "IN setpickinst baseinsts " .dump ( @baseinsts );
	my $ins_r = pop( @baseinsts );
	my %b = %{ $ins_r };

	my %dowhat = %{ $dowhat_r }; #say "IN setpickinst \%dowhat " .dump ( %dowhat );

  #my %b = %{ $baseinsts[0] }; say RELATE "IN setpickinst baseinsts " .dump ( \%b );
  my $countblock = $b{countblock};
  my @miditers = @{ $b{miditers} }; say RELATE "IN setpickinst \@miditers " .dump ( @miditers );
  my @sweeps = @{ $b{sweeps} };
  my @sourcesweeps = @{ $b{sourcesweeps} };
  my @varnumbers = @{ $b{varnumbers} };
  my @blocks = @{ $b{blocks} };  say RELATE "IN setpickinst \@blocks " .dump ( @blocks );
  my @blockelts = @{ $b{blockelts} }; say RELATE "IN setpickinst \@blockelts " .dump ( @blockelts );
  my %varnums = %{ $b{varnums} };
  my %carrier = %{ $b{carrier} };

  my $stamp;
  if ( $dowhat{names} eq "short" )
  {
    $stamp = encrypt1( $missing );
  }
  elsif ( $dowhat{names} eq "medium" )
  {
    $stamp = encrypt0( $missing );
  }

  $mypath = $dowhat{mypath}; say RELATE "IN setpickinst \$mypath " .dump ( \$mypath ); say "IN setpickinst \$mypath " .dump ( $mypath );
  $file = $dowhat{file}; say RELATE "IN setpickinst \$file " .dump ( \$file );

	say RELATE "\nMISSING: $missing";
	say RELATE "\%mids: " . dump( \%mids );

	my ( $box_ref, $countvrs_ref, $countsteps_ref  ) = getnear( $missing, \%mids );
	my @addinsts = @{ $box_ref }; say RELATE "in setpickinst PRODUCING \@addinsts" . dump( @addinsts );
	my @countvrs = @{ $countvrs_ref }; say RELATE "in setpickinst PRODUCING \@countvrs" . dump( @countvrs );
	my @countsteps = @{ $countsteps_ref }; say RELATE "in setpickinst PRODUCING \@countsteps" . dump( @countsteps );
  my $countvar;
  my $countstep;


	if ( scalar( @addinsts ) > 0 )
	{
		my $cn = 0;
		foreach $addinst ( @addinsts )
		{
			$countvar = $countvrs[$cn];
			$countstep = $countsteps[$cn];
      my ( $is, %origin, %to, %orig);
			$is = $addinst;

      $to{to} = "$mypath/$file" . "_" . "$is";  say RELATE "A in setpickinst \$to{to} " .dump ( $to{to} );
      $to{cleanto} = "$is"; say RELATE "B in setpickinst \$to{cleanto} " .dump ( $to{cleanto} );

			my ( @whatto );

			if ( $cn == 0 )
			{
				$origin = giveback ( \%mids );
				push ( @whatto, "begin" );
			}

			if ( $cn > 0 )
			{
				push ( @whatto, "transition" );
				$origin = $addinsts[$cn-1];
			}

			if ( $cn == $#addinsts )
			{
				push ( @whatto, "end" );
        $origin = $addinsts[$cn-1];
			}

      $orig{to} = "$mypath/$file" . "_" . "$origin"; say RELATE "C in setpickinst \$orig{to} " .dump ( $orig{to} );
      $orig{cleanto} = "$origin"; say RELATE "D in setpickinst \$orig{cleanto} " .dump ( $orig{cleanto} );

			say RELATE "in setpickinst : \$countinst: $countinst, \$cn $cn, \$addinst: $addinst, \$origin: $origin, \$is: $is, \%to: " . dump( \%to ) . "\%orig: " . dump( \%orig );
      
      my ( $crypto, $cryptor );
      if ( $dowhat{names} eq "short" )
	    {
			  $crypto = encrypt1( $is ); say RELATE "in setpickinst \$crypto " .dump ( \$crypto );
	      $cryptor = encrypt1( $origin ); say RELATE "in setpickinst \$cryptor " .dump ( \$cryptor );
      }
      elsif ( $dowhat{names} eq "medium" )
	    {
	    	$crypto = encrypt0( $is ); say RELATE "in setpickinst \$crypto " .dump ( \$crypto );
	      $cryptor = encrypt0( $origin ); say RELATE "in setpickinst \$cryptor " .dump ( \$cryptor );
      }

	    if ( $dowhat{names} eq "short" )
	    {
	      $to{crypto} = "$mypath/$file" . "_" . "$crypto";  ###DDD!!! FINISH THIS.
	      $to{cleancrypto} = $crypto;  ###DDD!!! FINISH THIS.
	      $orig{crypto} = "$mypath/$file" . "_" . "$cryptor";  ###DDD!!! FINISH THIS.
	      $orig{cleancrypto} = $cryptor; ###DDD!!! FINISH THIS.
	    }
      elsif ( $dowhat{names} eq "medium" )
	    {
	      $to{crypto} = "$mypath/$file" . "_" . "$crypto";  ###DDD!!! FINISH THIS.
	      $to{cleancrypto} = $crypto;  ###DDD!!! FINISH THIS.
	      $orig{crypto} = "$mypath/$file" . "_" . "$cryptor";  ###DDD!!! FINISH THIS.
	      $orig{cleancrypto} = $cryptor; ###DDD!!! FINISH THIS.
	    }
	    else
	    {

	      $to{crypto} = $to{to};  ### TAKE CARE!!! REASSIGNIMENT!!!
	      $to{cleancrypto} = $to{cleanto}; ### TAKE CARE!!! REASSIGNIMENT!!!
	      $orig{crypto} = $orig{to}; ### TAKE CARE!!! REASSIGNIMENT!!!
	      $orig{cleancrypto} = $orig{cleanto}; ### TAKE CARE!!! REASSIGNIMENT!!!
	    }

      if ( $cn < $#addinsts )
      {
				push( @newinstances,
  			{
  				countcase => $countcase, countblock => $countblock,
  				miditers => \@miditers,  winneritems => \@winneritems, c => $c, from => $from,
  				to => \%to, countvar => $countvar, countstep => $countstep,
  				sweeps => \@sweeps, orig => \%orig,
  				sourcesweeps => \@sourcesweeps, incumbents => \%incumbents,
  				varnumbers => \@varnumbers, blocks => \@blocks,
  				blockelts => \@blockelts, mids => \%mids, varnums => \%varnums,
  				countinstance => $cn, carrier => \%carrier, origin => $origin,
  				instn => $cn, is => $is, vehicles => \%vehicles,
  				mypath => $mypath, file => $file, whatto => \@whatto,
          fire => "no", from => $origin, gaproc => "yes", stamp => $stamp,
  			} );
      }
      else
      {
				push( @newinstances,
        {
  				countcase => $countcase, countblock => $countblock,
  				miditers => \@miditers,  winneritems => \@winneritems, c => $c, from => $from,
  				to => \%to, countvar => $countvar, countstep => $countstep,
  				sweeps => \@sweeps, orig => \%orig,
  				sourcesweeps => \@sourcesweeps, incumbents => \%incumbents,
  				varnumbers => \@varnumbers, blocks => \@blocks,
  				blockelts => \@blockelts, mids => \%mids, varnums => \%varnums,
  				countinstance => $cn, carrier => \%mids, origin => $origin,
  				instn => $cn, is => $is, vehicles => \%vehicles,
  				mypath => $mypath, file => $file, whatto => \@whatto,
          fire => "yes", from => $origin, gaproc => "yes", stamp => $stamp,
				} );
      }
			$cn++;
		}
	}
  else
	{
		$countvar = $countvrs[$cn];
		$countstep = $countsteps[$cn];
		$is = $addinst;

		my ( %orig, @whatto );
		$origin = giveback ( \%mids );
    push ( @whatto, "end" );

		say RELATE "in setpickother : \$countinst: $countinst, \$cn $cn, \$addinst: $addinst, \$origin: $origin, \$is: $is, \%to: " . dump( \%to ) . "\%orig: " . dump( \%orig );
    
    my ( $crypto, $cryptor );
    if ( $dowhat{names} eq "short" )
    {
      $crypto = encrypt1( $is ); say RELATE "in setpickinst \$crypto " .dump ( \$crypto );
      $cryptor = encrypt1( $origin ); say RELATE "in setpickinst \$cryptor " .dump ( \$cryptor );
    }
    if ( $dowhat{names} eq "medium" )
    {
    	$crypto = encrypt0( $is ); say RELATE "in setpickinst \$crypto " .dump ( \$crypto );
      $cryptor = encrypt0( $origin ); say RELATE "in setpickinst \$cryptor " .dump ( \$cryptor );
    }

    $to{to} = "$mypath/$file" . "_" . "$is";  say RELATE "A in setpickinst \$to{to} " .dump ( $to{to} );
    $to{cleanto} = "$is"; say RELATE "B in setpickinst \$to{cleanto} " .dump ( $to{cleanto} );
    $orig{to} = "$mypath/$file" . "_" . "$origin"; say RELATE "C in setpickinst \$orig{to} " .dump ( $orig{to} );
    $orig{cleanto} = "$origin"; say RELATE "D in setpickinst \$orig{cleanto} " .dump ( $orig{cleanto} );

    if ( $dowhat{names} eq "short" )
    {
      $to{crypto} = "$mypath/$file" . "_" . "$crypto";  ###DDD!!! FINISH THIS.
      $to{cleancrypto} = $crypto;  ###DDD!!! FINISH THIS.
      $orig{crypto} = "$mypath/$file" . "_" . "$cryptor";  ###DDD!!! FINISH THIS.
      $orig{cleancrypto} = $cryptor; ###DDD!!! FINISH THIS.
    }
    elsif ( $dowhat{names} eq "medium" )
    {
      $to{crypto} = "$mypath/$file" . "_" . "$crypto";  ###DDD!!! FINISH THIS.
      $to{cleancrypto} = $crypto;  ###DDD!!! FINISH THIS.
      $orig{crypto} = "$mypath/$file" . "_" . "$cryptor";  ###DDD!!! FINISH THIS.
      $orig{cleancrypto} = $cryptor; ###DDD!!! FINISH THIS.
    }
    else
    {

      $to{crypto} = $to{to};  ### TAKE CARE!!! REASSIGNIMENT!!!
      $to{cleancrypto} = $to{cleanto}; ### TAKE CARE!!! REASSIGNIMENT!!!
      $orig{crypto} = $orig{to}; ### TAKE CARE!!! REASSIGNIMENT!!!
      $orig{cleancrypto} = $orig{cleanto}; ### TAKE CARE!!! REASSIGNIMENT!!!
    }

    push( @newinstances,
    {
			countcase => $countcase, countblock => $countblock,
			miditers => \@miditers,  winneritems => \@winneritems, c => $c, from => $from,
			to => \%to, countvar => $countvar, countstep => $countstep,
			sweeps => \@sweeps, dowhat => \%dowhat, orig => \%orig,
			sourcesweeps => \@sourcesweeps, incumbents => \%incumbents,
			varnumbers => \@varnumbers, blocks => \@blocks,
			blockelts => \@blockelts, mids => \%mids, varnums => \%varnums,
			countinstance => $cn, carrier => \%mids, origin => $origin,
			instn => $instn, is => $to{cleanto}, vehicles => \%vehicles,
			mypath => $mypath, file => $file, whatto => \@whatto,
      fire => "yes", from => $origin, gaproc => "yes", stamp => $stamp,
		} );
	}
	return ( \@newinstances );
} # SUB SETPICKINST


sub reconstruct
{
	my ( $string ) = @_;
	my %mids = split( "_|-", $string );
  return( \%mids );
}



sub checkdone
{
	my $term = shift;
	my @arr = @{ shift( @_ ) };
	foreach my $elm ( @arr )
	{
		if ( $elm =~ /$term/ )
		{
			return( "y" );
		}
	}
}

sub cleanbag
{
	my @instances = @_;
	my ( @bagnames, @baginst );
	foreach my $inst_r ( @instances )
	{
		my %d = %{ $inst_r };
		my $is = $d{is};

		unless ( $is ~~ @bagnames )
		{
			push( @bagnames, $is );
			push( @baginst, $inst_r );
		}
	}
	return( @baginst );
}

sub washduplicates
{
	my ( $filename ) = @_;
	open( FILENAME, "$filename" ) or die;
	my @lines = <FILENAME>;
	close FILENAME;

	@lines = uniq( @lines );
	open( FILENAME, ">$filename" ) or die;
  foreach my $line ( @lines )
	{
		print FILENAME $line;
	}
	close FILENAME;
}

sub washhash
{
	my %hash = %{ $_[0] };
	my ( @bagnames, %newhash );
	foreach my $key ( keys %hash )
	{
		unless ( $key ~~ @bagnames )
		{
			push( @bagnames, $key );
			$newhash{$key} = $hash{$key};
		}
	}
  return( \%newhash );
}


sub filterinsts_winsts
{
	my ( $fewerinsts_r, $inst_r ) = @_ ;
	my @fewerinsts = @{ $fewerinsts_r };
	my %inst = %{ $inst_r };
	my @fewerinstnames;

	foreach my $instance ( @fewerinsts )
	{
		my %d = %{ $instance };
		unless ( $d{is} ~~ @fewerinstnames )
		{
			push( @fewerinstnames, $d{is} );
		}
	}
	#say  "FEWERINSTNAMES" . dump( @fewerinstnames );

	my %newinst ;
	foreach my $key ( keys %inst )
	{
		foreach $name ( @fewerinstnames )
		{
      #if ( $key =~ /$name/ )
			if ( $key =~ /\Q$name\E/ ) 
			{
				$newinst{$key} = $inst{$key};
			}
		}
	} #say  "NEWINST1" . dump( \%newinst );

	#foreach my $value ( values %newinst )
	#{
	#	if ( $value ~~ ( keys %newinst ) )
	#	{
	#		$newinst{$value} = $value{$value};
	#	}
	#} #say  "NEWINST2" . dump( \%newinst );

  foreach my $value ( values %newinst )
  {
    if ( exists $newinst{$value} )
    {
      $newinst{$value} = $inst{$value};
    }
  }

	return( \@fewerinstnames, \%newinst );
}


sub filterinsts_wnames
{
	my ( $names_r, $inst_r ) = @_ ;
	my @names = @{ $names_r };
	my %inst = %{ $inst_r };
	my %newinst;
	foreach my $key ( keys %inst )
	{
		foreach $name ( @names )
		{
			if ( $key =~ /$name/ )
			{
				$newinst{$key} = $inst{$key};
			}
		}
		#say  "NEWINST3" . dump( \%newinst );
	}

	#foreach my $value ( values %newinst )
	#{
	#	if ( $value ~~ ( keys %newinst ) )
	#	{
	#		$newinst{$value} = $value{$value};
	#	}
	#} #say  "NEWINST4" . dump( \%newinst );

  foreach my $value ( values %newinst )
  {
    if ( exists $newinst{$value} )
    {
      $newinst{$value} = $inst{$value};
    }
  }

	return( \%newinst );
}


sub odd
{
    my $number = shift;
    return !even ($number);
}

sub even
{
    my $number = abs shift;
    return 1 if $number == 0;
    return odd ($number - 1);
}

sub odd__
{
  my ( $number ) = @_;
  if ( $number % 2 == 1 )
  {
    return ( "odd" );
  }
  else
  {
    return ( "even" );
  }
}

sub _mean_ { return @_ ? sum(@_) / @_ : 0 }

sub rotate2d
{
  my ( $x, $y, $angle ) = @_;

  sub deg2rad
  {
		my $degrees = shift;
		return ( ( $degrees / 180 ) * 3.14159265358979 );
  }

  sub rad2deg
  {
		my $radians = shift;
		return ( ( $radians / 3.14159265358979 ) * 180 ) ;
  }

  $angle = deg2rad( $angle );
  my $x_new = cos($angle)*$x - sin($angle)*$y;
  my $y_new = sin($angle)*$x + cos($angle)*$y;
	return ( $x_new, $y_new);
}


#sub genstring {
#    my ( $varnums_r, $blockelts_r, $from ) = @_;
#    my %varnums   = %{ $varnums_r };   # max levels for each parameter
#    my @blockelts = @{ $blockelts_r }; # variables active in this block
#    my @frags = split( "_", $from ); say "\$from: $from"; say "\@frags: " . dump ( @frags );
#    my @bits;
#
#    foreach my $frag ( @frags ) 
#    {
#      my @bits = split( "-", $frag );
#      unless ( $bits[0] ~~ @blockelts )
#      {  
#        push( @bits, "$frag" )
#      }
#      else 
#      {
#      	my $max = $varnums{ $bits[0] };
#        my $lev = 1 + int( rand( $max ) );
#        push( @bits, "$var-$lev" );
#      }
#      my @obtained = ( join "_", @bits );
#    }
#    return @obtained;
#}



#@sub genstring {
#    my ( $varnums_r, $blockelts_r, $from ) = @_;
#
#    my %varnums   = %{ $varnums_r };    # max levels for each parameter
#
#    my %inblock = map { $_ => 1 } @blockelts;
#
#    my @frags    = split /_/, $from;    # e.g. ("v1-2", "v2-3", "v3-1")
#    my @newfrags;
#
#    foreach my $frag ( @frags ) {
#        my ( $var, $oldlev ) = split /-/, $frag, 2;
#
#        # variable not in this block: keep as-is
#        if ( !$inblock{$var} ) {
#            push @newfrags, $frag;
#            next;
#        }
#
#        # variable in this block: pick a new random level between 1 and max
#        my $max = $varnums{$var};
#        $max = 1 if !defined $max || $max < 1;  # defensive
#
#        my $lev = 1 + int( rand($max) );
#        push @newfrags, "$var-$lev";
#    }
#
#    my $obtained = join "_", @newfrags;
#    return $obtained;
#}


sub genstring 
{
  my ( $varnums_r, $blockelts_r, $from ) = @_;
  my %varnums   = %{ $varnums_r }; #say "\%varnums: " . dump ( \%varnums );  # max levels for each parameter
  my @blockelts = @{ $blockelts_r }; #say "\@blockelts: " . dump ( @blockelts ); # variables active in this block
  my @frags = split( "_", $from ); #say "\$from: $from"; say "\@frags: " . dump ( @frags );
  my ( @bowl, @bowlmax );

  foreach my $frag ( @frags ) 
  {
    my @bits = split( "-", $frag ); #say "\@bits: " . dump ( @bits ); say "\$bits[0]: " . dump ( $bits[0] ); 
    unless ( $bits[0] ~~ @blockelts )
    {  
      push( @bowl, "$frag" ); #say  "INSERT \$frag $frag";
    }
    else 
    {
    	my $max = $varnums{ $bits[0] }; #say  "\$max $max";
      my $lev = 1 + int( rand( $max ) ); #say  "\$lev $lev";
      push( @bowl, "$bits[0]-$lev" ); #say  "CALC AND INSERT \$bits[0]-\$lev $bits[0]-$lev";
    }
  }
  my $obtained = ( join "_", @bowl ); #say "\@obtained: " . dump ( @obtained );
  return ( $obtained, \@bowl );
}


sub enumerate
{
  my ( $varnums_r, $blockelts_r, $from ) = @_;
  my %varnums   = %$varnums_r;
  my @blockelts = @$blockelts_r;

  # parse $from into a hash var->level and remember var order as in $from
  my @pairs = split /_/, $from;
  my @vars  = ();
  my %cur   = ();
  for my $p ( @pairs ) 
  {
    my ( $v,$l ) = split /-/, $p, 2;
    push( @vars, $v );
    $cur{$v} = $l;
  }

  my @out;
  my $rec; 
  $rec = sub 
  {
    my ($i) = @_;
    if ($i >= @blockelts) 
    {
      push @out, join("_", map { "$_-$cur{$_}" } @vars);
      return;
    }
    my $v = $blockelts[$i];
    for my $lvl ( 1 .. $varnums{$v} ) 
    {
      $cur{$v} = $lvl;
      $rec->( $i+1 );
    }
  };
  $rec->( 0 );
  return( \@out );
}


sub instid
{
  my ( $line, $file ) = @_;
  my ( $first ) = split /,/, ($line // ""), 2;   # first CSV field
  $first =~ s{/tmp/.*$}{};                     # keep just amtry_4-... part
  $first =~ s{^\Q$file\E\_}{};                 # remove "amtry_" prefix
  $first =~ s/_$//;                 # remove "amtry_" prefix
  $first =~ s/_$//;                 # remove "amtry_" prefix
  return( $first );                               # now "4-1_5-2_6-2"
}


sub countarray
{
	my $c = 1;
	foreach (@_)
	{
		foreach (@$_)
		{
			$c++;
		}
	}
	return ($c);
}

sub cleaninst
{
	my %inst = @_;
	my %pure;
	foreach my $key ( keys %inst )
	{
		unless ( ( $key eq "" ) or ( $inst{$key} eq " ") )
		{
      $pure{$key} = $inst{$key};
		}
	}
	return ( %pure );
}

sub countnetarray
{
	my @bag;
	foreach (@_)
	{
		foreach (@$_)
		{
			push (@bag, $_);
		}
	}
	@bag = uniq( @bag );
	return scalar( @bag );
}


sub distr
{
  my ( $elts_res, $num ) = @_;
  my @elts = @{ $elts_res };

  if ( ( $num eq "" ) or ( $num == 0 ) )
  {
    $num = 100;
  }

  my $min = min( @elts );
  my $max = max( @elts );
  my $ext = ( $max - $min );
  my $incr = ( $ext / $num ); #say  "INCR $incr";

  my $count = 0;
  my $low = $min;
  my $newlow;
  my ( @vals, @ranks, @alls, @allnums, @percnums );
  while ( $count < $num  )
  { #say  "COUNT $count";
    $newlow = ( $low + $incr );
    my $middle = ( ( $low + $newlow ) / 2 );
    push( @vals, $middle );
    push( @ranks, ( $count + 1 ) );

    foreach my $elt ( @elts )
    {
      if ( ( $elt < $max ) and ( ( $elt >= $low ) and ( $elt < $newlow ) ) )
      {
        push ( @{ $alls[$count] }, $elt );
      }
      elsif ( ( $elt == $max ) and ( ( $elt >= $low ) and ( $elt <= $newlow ) ) )
      {
        push ( @{ $alls[$count] }, $elt );
      }
    }



    $low = ( $low + $incr );
    $count++;
  }
  #say  "ALLS: " . dump( @alls );
  #die;


  my $scalaralls = scalar( @alls );
  my $co = 0;
  while ( $co < $scalaralls )
  {
    push( @allnums, scalar( @{ $alls[$co] } ) );
    $co++
  }

  my $total = 0;
  foreach my $allnum ( @allnums )
  {
    $total = $total + $allnum;
  }

  my $reduction = ( 100 / $total );

  foreach my $allnum ( @allnums )
  {
    my $scalednum = ( $allnum * $reduction );
    push ( @percnums, $scalednum );
  }

  return( \@percnums, \@vals, \@ranks)
}


sub addnear
{
  my ( $this_bulkref, $varnums_ref ) = @_;
	my $this = $this_bulkref->[0][0];
	my $pass = dclone($this_bulkref);
	my %varnums = %{ $varnums_ref };
	my @keys = ( keys %varnums );
	my @signs = ( "+", "-" );
	my %thiselts = split( "_|-", $this );

  my $that;
	my $done = "n";
	while ( $done eq "n" )
	{
		my @pars = shuffle( @keys );
		my @signs = shuffle( @signs );
		my $par = $pars[0];
		my $sign = $signs[0];
		my $maxlev = $varnums{$par};
		my $lev = $thiselts{$par};
		my $newlev;
		if ( $sign eq "+" )
		{
			$newlev = ( $lev + 1 );
		}
		elsif ( $sign eq "-" )
		{
			$newlev = ( $lev - 1 );
		}
		my $bit = $par . "-" . $newlev;
		unless( ( $newlev == $lev ) or ( $newlev == 0 ) or ( $newlev > $maxlev ) )
		{
			my $firstbit = $par . "-";
			$that = $this;
			$that =~ s/$firstbit(\d)/$bit/ ;
			$done = "y";
		}
	}
	$pass->[0][0] = $that;
	return( $pass );
}


sub sorttable
{
	my $num = $_[0];
	my @table = @{ $_[1] };
	my @rows;
	foreach my $line (@table)
	{
	    chomp $line;
	    $sth->execute(line);

	    my @row = $sth->fetchrow_array;
	    unshift (@row, $line);
	    push @rows, \@row;
	}
	@rows = sort { $a->[$num] cmp $b->[$num] } @rows;

	foreach my $row (@rows) {
	    foreach (@$row) {
		#print  "$_";
	    }
	    #print  "\n";
	}
	return (@table);
}

sub _clean_
{ # IT CLEANS A BASKET FROM CASES LIKE "-", "1-", "-1", "".
	my $swap = shift;
	my @arraytoclean = @$swap;
	my @storeinfo;
	foreach (@arraytoclean)
	{
		$_ =~ s/ //;
		unless ( !( defined $_) or ($_ =~ /^-/) or ($_ =~ /-$/) or ($_ =~ /^-$/) or ($_ eq "") or ($_ eq "-") )
		{
			push(@storeinfo, $_)
		}
	}
	return  @storeinfo; # IT IS DESTRUCTIVE.
}

sub encrypt0
{
  my ( $thing ) = @_;
  $thing =~ s/.-//g ;
  $thing =~ s/_//g ;
  return( $thing );
}



sub encrypt1 {
    my ( $is, $dirfiles_r ) = @_;

    # already seen: reuse id and keep counters in sync
    if ( exists $cryptc{$is} ) {
        my $id = $cryptc{$is};

        if ( defined $dirfiles_r ) {
            $dirfiles_r->{instcount} = $id
              if !defined $dirfiles_r->{instcount}
              || $dirfiles_r->{instcount} < $id;
        }

        $globcount = $id if $globcount < $id;
        return "$id";   # digits-only string
    }

    my $id;
    if ( defined $dirfiles_r ) {
        $dirfiles_r->{instcount} = 0
          unless defined $dirfiles_r->{instcount};

        # keep per-run counter at least as large as global
        $dirfiles_r->{instcount} = $globcount
          if $dirfiles_r->{instcount} < $globcount;

        $dirfiles_r->{instcount}++;
        $id = $dirfiles_r->{instcount};
    }
    else {
        $globcount++;
        $id = $globcount;
    }

    $cryptc{$is} = $id;
    return ( $id );       # digits-only string
}





sub present
{
	foreach (@_)
	{
		say  "### $_ : " . dump($_);
		say TOFILE "### $_ : " . dump($_);
	}
}


sub flattenvariables # THIS LISTS THE NUMBER OF VARIABLES PLAY IN A LIST OF BLOCK SEARCHES. ONE COUNT FOR EACH LIST ELEMENT.
{
	my @array = @_;
	foreach my $case (@array)
	{
		@casederef = @$case;
		my @basket;
		foreach my $block (@casederef)
		{
			@blockelts = @$block;
			push (@basket, @blockelts);
		}
		my @basket = sort { $a <=> $b } uniq( @basket );
		push ( @flatvarns, \@basket ); ###
		# IT HAS TO BE CALLED WITH: flatten_variables(@treeseed);
	}
}

sub count_variables # IT COUNTS THE FLATTENED VARIABLES
{
	my @flatvarns = @_;
	foreach my $group (@flatvarns)
	{
		my @array = @$group;
		push ( @flatvarnsnum, scalar(@array) );
		# IT HAS TO BE CALLED WITH: count_variables(@flatvarns);
	}
}


sub fromopt_tosweep
{
	my %thishash = %{ $_[0] };
	my @casegroup = @{ $thishash{casegroup} } ;
	my @chancegroup = @{ $thishash{chancegroup} };
	my @sweeps;
	my $countcase = 0;
	foreach my $case (@casegroup)
	{
		my @blockrefs = @$case;
		my @chancerefs = @{ $chancegroup[$countcase] };
		my @sweepblocks;
		my $countblock = 0;
		foreach my $elt (@blockrefs)
		{
			my @blockelts = @$elt;
			my $attachpoint = $blockelts[0];
			my $blocklength = $blockelts[1];
			my @chances = @{ $chancerefs[$countblock] };
			my @sweepblock = @chances[ $attachpoint .. ($attachpoint + $blocklength - 1) ];
			push (@sweepblocks, [@sweepblock]);
			$countblock++;
		}
		push (@sweeps, [ @sweepblocks ] );
		$countcase++;
	}
	# IT HAS TO BE CALLED THIS WAY: fromopt_tosweep( { casegroup => \@caseseed, chancegroup => \@chanceseed } );
	return (@sweeps);
}

sub fromopt_tosweep_simple
{
	my %thishash = @_;
	my $casegroupref = $thishash{casegroup};
	my @blocks = @$casegroupref;
	my $chancegroupref = $thishash{chancegroup};
	my @chances = @$chancegroupref;
	my $countblock = 0;
	foreach my $elt (@blocks)
	{
		my @blockelts = @$elt;
		my $attachpoint = $blockelts[0];
		my $blocklength = $blockelts[1];
		my $chancesref = $chances[$countblock];
		my @chances = @$chancesref;
		my @sweepblock = @chances[ $attachpoint .. ($attachpoint + $blocklength - 1) ];
		push (@sweepblocks, [@sweepblock]);
		$countblock++;
	}
	# IT HAS TO BE CALLED THIS WAY: fromopt_tosweep( casegroup => [@caserefs_alias], chancegroup => [@chancerefs_alias] ); # IT IS NOT RELATIVE TO CASE: JUST ONE CASE, THE CURRENT.
	return (@sweepblocks);
}

sub checkduplicates
{
	my %hash = %{$_[0]};
	my @slice = @{$hash{slice}};
	my @sweepblocks = @{$hash{sweepblocks}};
	my $signal = 0;
	foreach my $blockref (@sweepblocks)
	{
		@block = @$blockref;
		if ( @slice ~~ @block )
		{
			$signal++;
		}
	}
	if ($signal == 0) { return "n"; }
	else { return "y" };
}


sub fromsweep_toopt
{
	my ( @bucket, @secondbucket );
	my $countcase = 0;
	foreach (@_) # CASES
	{
		my ( @blocks, @chances );
		my $countblock = 0;
		foreach(@$_) # BLOCKS
		{

			my $swap = $flatvarns[$countcase];
			my @varns = @$swap;
			my @block = @$_;
			my $blocksize = scalar( @block ); # THE ORIGINAL OPT BLOCKS SEARCH FORMAT IN A TREE BLOCK SEARCH FORMAT.
			my $lc = List::Compare->new( \@varns, \@block );
			my @intersection = $lc->get_intersection;
			my @nonbelonging;
			foreach (@varns)
			{
				my @parlist;
				unless ($_ ~~ @intersection)
				{
					push (@nonbelonging, $_);
				}
			}

			push (@blocks, [@intersection, @nonbelonging] );
			push (@chances, [0, $blocksize] );
			$countblock++;
		}
		push (@bucket, [ @blocks ] );
		push (@secondbucket, [@chances]);
		$countcase++;
	}
	@chanceseed = @bucket; # THE ORIGINAL OPT BLOCKS SEARCH FORMAT IN A TREE BLOCK SEARCH FORMAT.
	@caseseed = @secondbucket;
	return (\@caseseed, \@chanceseed);
}


sub convcaseseed # IT ADEQUATES THE POINT OF ATTACHMENT OF EACH BLOCK TO THE FACT THAT THE LISTS CONSTITUTING THEM ARE THREE, JOINED.
{
	my $ref = shift;
	my %hash = %{$ref};
	my @chanceseed = @{ $hash{ chanceseed } };
	my @caseseed = @{ $hash{ caseseed } };
	my $countcase = 0;
	foreach my $case (@caseseed)
	{
		my $chance = $chanceseed[$countcase];
		my $countblock = 0;
		my @blockrefs = @$case;
		my @chancerefs = @$chance;
		foreach (@blockrefs)
		{
			my $chancelt = scalar ( @{ $chancerefs[$countblock] } );
			my $numofelts = ( $chancelt / 3 );
			${$_}[0] = ${$_}[0] + $numofelts;
			$countblock++;
		}
		$countcase++;
	} # TO BE CALLED WITH: convcaseseed(\@caseseed, \@chanceseed). @caseseed IS global.
	return(@caseseed);
}


sub convchanceseed # IT COUNTS HOW MANY PARAMETERS THERE ARE IN A SEARCH STRUCTURE,
{
	foreach (@_)
	{
		foreach (@$_)
		{
			push (@$_, @$_, @$_);
		}
	} # IT HAS TO BE CALLED WITH convchanceseed(@chanceseed). IT ACTS ON @chanceseed
	return(@_);
}


sub tellnum
{
	@arr = @_;
	my $response = (scalar(@_)/2);
	return($response);
}


sub calcoverlaps
{
	my @sweeps = @_;
	my ( @caseoverlaps );
	my $countcase = 0;
	foreach my $case ( @sweeps )
	{
		my @caseelts = @{ $case };
		my $countblock = 0;
		foreach my $block ( @caseelts )
		{
			my @pasttblock = @{ $block[ $countblock - 1 ]};
			my @presentblock = @{ $block[ $countblock ]};
			my $lc = List::Compare->new( \@pastblock, \@presentblock );
			my @intersection = $lc->get_intersection;
			push ( @caseoverlaps, [ @intersection ] );
			$countblock++;
		}
		$countcase++;
	}
	return( @caseoverlaps );
}


sub calcmiditers
{
	my @varnumbers = @_;
	my $countcase = 0;
	my @mediters;
	foreach ( @varnumbers )
	{
		my $countblock = 0;
		foreach ( keys %$_ )
		{
			unless ( defined $mediumters[$countcase]{$_} )
			{
				$mediters[$countcase]{$_} = ( ceil( $varnumbers[$countcase]{$_} / 2 ) );
			}
		}
		$countcase++;
	}
	return ( @mediters );
}


sub getitersnum
{ # IT GETS THE NUMBER OF ITERATION. UNUSED. CUT
	my $countcase = shift;
	my $varnumber = shift;
	my @varnumbers = @_;
	my $itersnum = $varnumbers[$countcase]{$varnumber};
	return $itersnum;
}


sub clean
{
  my ( $line, $mypath, $file ) = @_;
	$line =~ s/$mypath// ;
	$line =~ s/$file// ;
	$line =~ s/^(\/+)//g ;
	$line =~ s/^$file//g ;
	$line =~ s/^_//g ;
  $line =~ s/(\D+)$//g ;
	$line =~ s/(\D+)$//g ;
	#$line = "$mypath/$file" . "_" . "$line";
  #$line =~ s/^-// ;
  return( $line );
}


sub makefilename # IT DEFINES A FILE NAME GIVEN A %carrier.
{
	my ( $tempc_r, $mypath, $file, $instn, $inst_ref, $dowhat_ref ) = @_;
	my %tempc = %{ $tempc_r };
	my %inst = %{ $inst_ref };
	my %dowhat = %{ $dowhat_ref };
	my $cleanto;
	foreach my $key (sort {$a <=> $b} (keys %tempc) )
	{
		$cleanto = $cleanto . $key . "-" . $tempc{$key} . "_";
	}
	$cleanto =~ s/_$// ;

	my $fullto = "$mypath/$file" . "_" . "$cleanto";

	###my $cleancrypto = $instn . "__"; ###!!!OLD!!!
	my $cleancrypto;

  if ( $dowhat{names} eq "short" )
	{
		$cleancrypto = encrypt1( $cleanto );
	}
	elsif ( $dowhat{names} eq "medium" )
	{
		$cleancrypto = encrypt0( $cleanto );
	}

	my $crypto = "$mypath/$file" . "_" . "$cleancrypto";

	my $it;
	if ( $dowhat{names} eq "short" )
	{
		$it{to} = $fullto;
		$it{cleanto} = $cleanto;
		$it{crypto} = $crypto;
		$it{cleancrypto} = $cleancrypto;
	}
	elsif ( $dowhat{names} eq "medium" )
	{
		$it{to} = $fullto;
		$it{cleanto} = $cleanto;
		$it{crypto} = $crypto;
		$it{cleancrypto} = $cleancrypto;
	}
	else
	{
		$it{to} = $fullto;
		$it{cleanto} = $cleanto;
		$it{crypto} = $fullto;
		$it{cleancrypto} = $cleanto;
	}
	return ( \%it );
}


sub getblocks
{ # IT GETS @blocks. TO BE CALLED WITH getblocks(\@sweeps, $countcase)
	my $swap = shift;
	my @sweeps = @$swap;
	my $countcase = shift;
	my @blocks = @{ $sweeps[$countcase]};
	return (@blocks);
}


sub getblockelts
{ # IT GETS @blockelts. TO BE CALLED WITH getblockelts(\@sweeps, $countcase, $countblock)
	my ( $sweeps_ref, $countcase, $countblock ) = @_;
	my @sweeps = @{ $sweeps_ref };
	my @blockelts = @{ $sweeps[$countcase][$countblock] };
	return ( \@blockelts );
}


sub getrootname
{
	my ( $rootnames_r, $countcase ) = @_;
	my @rootnames = @{ $rootnames_r };
	my $rootname = $rootnames[$countcase];
	return ( $rootname );
}


sub extractcase #  UPDATES THE FILE NAME ON THE BASIS OF A %carrier
{
	my ( $inst_r, $dowhat_ref, $transfile, $carrier_r, $file, $blockelts_r, $mypath, $instn ) = @_;
	my %carrier = %{ $carrier_r };
	my @blockelts = @{ $blockelts_r };
	my $num = scalar( @blockelts );
	my %dowhat = %{ $dowhat_ref };
	my %inst = %{ $inst_r };
	my %provhash;
	$transfile =~ s/^mypath\///;
	$transfile =~ s/^$file//;
	$transfile =~ s/^_//;
	foreach my $parnum ( keys %carrier )
	{
		$transfile =~ /^(\d+)-(\d+)/;

		if ( ($1) and ($2) )
		{
			if ( $1 ~~ @blockelts )
			{
				$provhash{$1} = $2;
			}
		}

		$transfile =~ s/^$1-$2//;
		$transfile =~ s/^_//;
	}
	my %tempc = %{ dclone( \%carrier )};
	foreach my $key ( keys %provhash )
	{
		if ( scalar( @blockelts > 0 ) )
		{
			if ( $key ~~ @blockelts )
			{
				$tempc{$key} = $provhash{$key};
			}
		}
		else
		{
			$tempc{$key} = $provhash{$key};
		}
	}
	my %to = %{ makefilename( \%tempc, $mypath, $file, $instn, \%inst, \%dowhat ) };
	return( \%to );
}


sub definerootcases #### DEFINES THE ROOT-CASE'S NAME.
{
	my @sweeps = @{ $_[0] };
	my @miditers = @{ $_[1] };
	my @rootnames;
	my $countcase = 0;
	foreach my $sweep (@sweeps)
	{
		my $case = $miditers[$countcase];
		my %casetopass;
		my $rootname;
		foreach my $key (sort {$a <=> $b} (keys %$case) )
		{
			$casetopass{$key} = $miditers[$countcase]{$key};
		}
		foreach $key (sort {$a <=> $b} (keys %$case) )
		{
			$rootname = $rootname . $key . "-" . $miditers[$countcase]{$key} . "_";
		}
		$rootname = "$file" . "_" . "$rootname";
		$casetopass{rootname} = $rootname;
		chomp $rootname;
		push ( @rootnames, $rootname);
		$countcase++;
	}
	return (@rootnames);
}


sub populatewinners
{
	my @rootnames = @{ $_[0] };
	my $countcase = $_[1];
	my $countblock = $_[2];
	my @winneritems;
	foreach my $case ( @rootnames )
	{
		push ( @{ $winneritems[$countcase][$countblock] }, $case );
		$countcase++;
	}
	return( @winneritems );
}


sub getitem
{ # IT GETS THE WINNER OR LOSER LINE.
	my $swap = shift;
	my @items = @$swap;
	my $countcase = shift;
	my $countblock = shift;
	my $item = $items[$countcase][$countblock];
	my @arr = @$item;
	my $elt = $arr[0];
	return ($elt);
}


sub getline
{
	my $item = shift;
	my $file = "$mypath/" . "$item";
	return ($file);
}


sub getlines
{
	my $swap = shift;
	my @items = @$swap;
	my @arr;
	my $countcase = 0;
	foreach (@items)
	{
		foreach ( @{ $_ } )
		{
			push ( @{ $arr[$countcase] } , getline($_) );
		}
		$countcase++;
	}
	return (@arr);
}


sub washn
{
	my ( @arr ) = @_;
	if ( ref( @arr[0] ) eq "ARRAY" )
	{
		@arr = @{ $arr[0] };
	}
	return( @arr );
}


sub getcase
{
	my ( $varn_r, $countcase ) = @_;
	my @varnumbers = @{ $varn_r };
	my ( $itemref, %item);
	if ( ref( @varnumbers[0] ) eq "HASH" )
	{
		$itemref = $varnumbers[$countcase];
		%item = %{ $itemref };
	}
	else
	{
		@varnumbers = @{ $varnumbers[$countcase] };
	  $itemref = $varnumbers[$countcase];
	  my %item = %{ $itemref };
	}
	return ( %item );
}


sub getstepsvar
{
	my ( $countvar, $countcase, $varnumbers_r ) = @_;
	my @varnumbers = @{ $varnumbers_r };
	my %varnums = getcase( \@varnumbers, $countcase );
	my $stepsvar = $varnums{$countvar};
	return ( $stepsvar )
}


sub givesize
{	# IT RETURNS THE SEARCH SIZE OF A BLOCK.
	my $sliceref = shift;
	my @slice = @$sliceref;
	my $countcase = shift;
	my $varnumberref = shift;
	my $product = 1;
	foreach my $elt (@slice)
	{
		my $stepsize = Sim::OPT::getstepsvar( $elt, $countcase, $varnumberref );
		$product = $product * $stepsize;
	}
	return ($product); # TO BE CALLED WITH: givesize(\@slice, $countcase, \@varnumbers);, WHERE SLICE MAY BE @blockelts in SIM::OPT OR @presentslice OR @pastslice IN Sim::OPT::Takechance
}

sub flattenbox
{
	my ( $eltss_r ) = @_;
	my @basket;
	foreach my $eltsref ( @{ $eltss_r } )
	{
		my @elts = @$eltsref;
		push (@basket, @elts );
	}
	return( \@basket );
}


sub integratebox
{
	my @arrelts = @{ $_[0] };
	my %carrier = %{ $_[1] };
	my $file = $_[2];
	my @blockelts = @{ $_[3] };
	my $mypath = $_[4];
	my %inst = %{ $_[5] };
	my %dowhat  = %{ $_[6] };
	my $instn = $_[7];
	my @newbox;
	if ( ref( $arrelts[0] ) )
	{
		foreach my $eltref ( @arrelts )
		{
			my @elts = @{ $eltref };
			my $target = $elts[0];
			my %righttarg = %{ extractcase( \%inst, \%dowhat, $target, \%carrier, $file, \@blockelts, $mypath ) };
			my $righttarget = $righttarg{cleanto};
			my $origin = $elts[3];
			my %rightorig = %{ extractcase( \%inst, \%dowhat, $origin, \%carrier, $file, \@blockelts, $mypath ) };
			my $rightorigin = $rightorig{cleanto};
			push ( @newbox, [ $righttarget, $elts[1], $elts[2], $rightorigin, $elts[4] ] );
		}
		return ( \@newbox );
	}
}


sub filterbox
{
	my ( $arr_r ) = @_;
	@arr = @_;
	my @basket;
	my ( @box, @dish );
	foreach my $case ( @arr )
	{
		my $elt = $case->[0];
		if ( not ( $elt ~~ @box ) )
		{
			my @bucket;
			foreach my $caseagain ( @arr )
			{
				my $el = $caseagain->[0];
				if ( $elt ~~ $el )
				{
					push ( @bucket, $case, $case->[4] );
				}
			}
			my $parent = $bucket[0];
			push ( @basket, $parent );
			foreach ( @basket )
			{
				push ( @box, $_->[0], $case->[4] );
			}
		}
	}
	return( @basket );
}


sub filterbox_delete
{
	my ( $arr_r ) = @_;
	@arr = @{ $arr_r };
	my @basket;
	foreach my $case ( @arr )
	{ $case->[0];
		push ( @basket, $case->[0] );
	}
	return( @basket );
}


sub tellstring
{
	my ( $mids_ref, $file ) = @_;
	my %mids = %{ $mids_ref };
	my $starstring;
	foreach my $key ( sort {$a <=> $b} ( keys %mids ) )
	{
		$starstring = "$starstring" . "$key" . "-" . $mids{$key} . "_";
	}
	if ( $starstring ne "" )
	{
		$starstring = $file . "_" . $starstring;
	}
	return( $starstring );
}


sub prunethis
{
	my $aref = shift;
	my @arr = @{ $aref };
	my @newarr = map
	{
		if ( ref( $_ ) )
		{ prunethis( $_ ); }
		elsif ( $_ =~ />/ )
		{
			();
		}
		else
		{
			$_;
		}
	} @arr;
	return ( \@newarr );
}


sub cleansweeps
{
	my @struct = @{ $_[0] };
	my @sourcestruct = @{ dclone( \@struct ) };
	my @outbag;
	foreach my $e ( @struct )
	{
		my @midbag;
		foreach my $el ( @{ $e } )
		{
			my @inbag;
			foreach my $elt ( @{ $el } )
			{
				$elt =~ s/^(\d*)>// ; #
				$elt =~ s/^(\d*)°// ;
				$elt =~ s/^(\d*)<// ;
				$elt =~ s/^(\d*)£// ;
				$elt =~ s/^(\d*)§// ;
				$elt =~ s/^(\d*)\|// ;
				$elt =~ s/^(\d*)ù// ;

        $elt =~ s/^(\d*)ì// ; #
        $elt =~ s/^(\d*)à// ;
        $elt =~ s/^(\d*)ò// ;
        $elt =~ s/^(\d*)è// ;
        $elt =~ s/^(\d*)ß// ;
        $elt =~ s/^(\d*)ð// ;
        $elt =~ s/^(\d*)æ// ;
        $elt =~ s/^(\d*)ŧ// ;

        $elt =~ s/^(\d*)đ// ; #
        $elt =~ s/^(\d*)ŋ// ;
        $elt =~ s/^(\d*)ħ// ;
        $elt =~ s/^(\d*)ſ// ;
        $elt =~ s/^(\d*)ł// ;
        $elt =~ s/^(\d*)€// ;
        $elt =~ s/^(\d*)ø// ;


				$elt =~ s/[A-za-z]*//g ;
				$elt =~ s/^(\d*)ç// ; # ç: push supercycle
				$elt =~ s/^ç// ; # ç: push supercycle
				$elt =~ s/^(\d*)é// ; # é: pop supercycle
				$elt =~ s/^é// ; # é: pop supercycle
				push( @inbag, $elt );
			}
			push( @midbag, [ @inbag ] );
		}
		push( @outbag, [ @midbag ] );
	}
	#say  "CLEANED \@outbag: " . dump( @outbag );
	#say  "CLEANED \@sourcestruct: " . dump( @sourcestruct );
	return ( \@outbag, \@sourcestruct );
}


sub gencen
{
  my @varnums =  @{ $_[0] };
  my @newmids;
  foreach my $hs_ref ( @varnums )
  {
    my %newhs;
    my %hs = %{ $hs_ref };
    foreach my $key ( sort { $a <=> $b } ( keys %hs ) )
    {
      my $newval = ( int( $hs{$key} / 2 ) + 1 );
      $newhs{$key} = $newval;
    }
    push( @newmids, \%newhs );
  }
  return( \@newmids );
}


sub genextremes
{
  my @varnums =  @{ $_[0] };
  my @newmids;
  foreach my $hs_ref ( @varnums )
  {
    my %newhs;
    my %hs = %{ $hs_ref };
    foreach my $key ( sort { $a <=> $b } ( keys %hs ) )
    {
      my $newval = 1 ;
      $newhs{$key} = $newval;
    }
    push( @newmids, \%newhs );
    push( @newmids, \%hs );
  }
  return( \@newmids );
}


sub gencentres
{
  my ( $vars_ref ) =  @_;
  my @vars = @{ $vars_ref };
  my @varcopy = @vars;
  my $numelts = scalar( @vars );
  my $numcases = ( $numelts / 2 );
  my $c = 0;
  while ( $c < ( $numelts - 1 ) )
  {
    my %newhs;
    my @box;
    my %hsmin = %{ $vars[$c] };
    my %hsmax = %{ $vars[$c+1] };
    my $signal = 0;
    my $inv;
    foreach my $key ( sort { $a <=> $b } ( keys %hsmax ) )
    {
      my $newval = ( int( ( $hsmax{$key} - $hsmin{$key} ) / 2 ) + $hsmin{$key} ) ;
      if ( ( $newval == $hsmax{$key} ) or ( $newval == $hsmin{$key} ) )
      {
        my @newpair;
        my $answer = odd__( $signal );
        if ( $answer eq "even" )
        {
          $value = $array[ int(rand( @array + 1 )) ];
          my @ar = ( $hsmax{$key}, $hsmin{$key} );
          $newval = $ar[ int( rand( @ar + 1 ) ) ];
          if ( $hsmax{$key} == $newval )
          {
            $inv = "n";
          }
          else
          {
            $inv = "y";
          }
        }
        else
        {
          if ( $inv == "n" )
          {
            @newpair = ( $hsmin{$key}, $hsmax{$key} ); #say  "newpair 2: " . dump ( @newpair );
          }
          else
          {
            @newpair = ( $hsmax{$key}, $hsmin{$key} ); #say  "newpair 3: " . dump ( @newpair );
          }
					if ( ( $newpair[0] eq "undef" ) or ( $newpair[0] eq "" ) or ( $newpair[1] eq "undef" ) or ( $newpair[1] eq "" ) )
					{
						next;
					}
          $newval = $newpair[0];
					#say  "newpair: " . dump ( @newpair );
        }
        $signal++;
      }
      $newhs{$key} = $newval;
    }
    splice( @varcopy, ( ( $c * 2 ) + 1 ), 0, \%newhs );
    $c++;
  }
  return( \@varcopy );
}


sub starsweep
{
  my ( $varns_r, $sweeps_r ) = @_;
  my %firstvarn = %{ $varns_r->[0] };
  my @firstsweep = @{ shift( @{ $sweeps_r } ) };
	my @restsweeps = @{ $sweeps_r };
	my ( @box );
  foreach $par ( sort { $a <=> $b } ( keys %firstvarn ) )
  {
		push( @box, [ $par ] );
  }
  unshift( @restsweeps, ( [ @box ] ) );
  return( \@restsweeps );
}


sub readsweeps
{
	my @struct = @_;
	my @sourcestruct = @{ dclone( \@struct ) };
	foreach ( @struct )
	{
		foreach ( @$_ )
		{	#prunethis( $_ );
			;
		}
	}
	return ( \@struct, \@sourcestruct );
}


sub stararrange
{
	my ( $sweeps_ref, $blockelts_ref, $varnumbers_ref, $countcase, $countblock, $file ) = @_;
	my @sweeps = @{ $sweeps_ref };
	my @blockelts = @{ $blockelts_ref };
	my @varnumbers = @{ $varnumbers_ref };
	my %varnums = getcase( \@varnumbers, $countcase );
	my @vars = ( keys %varnums );
	my @diffs = Sim::OPT::Interlinear::diff( \@vars, \@blockelts );

	my @newhash;
	foreach my $var ( @blockelts )
	{
		push( @newhash, $var );
		push( @newhash, $varnums{$var} );
	}

	foreach my $diff ( @diffs )
	{
		push( @newhash, $diff );
		push( @newhash, 1 );
	}
	my %temp = @newhash;
	$varnumbers[$countcase] = \%temp;
	return( \@varnumbers );
}



sub star_act
{
	my ( $sweeps_r, $blockelts_r, $countcase, $countblock ) = @_;
	my @sweeps = @{ $sweeps_r };
	my @blockelts = @{ $blockelts_r };

	my @bag;
	foreach my $elt ( @blockelts )
	{
		push( @bag, [ $elt ] );
	}

	my @basket;
	foreach my $sweepcase ( @sweeps )
	{ my @box;
		foreach my $sweep ( @{ $sweepcase } )
		{
			my @diff = Sim::OPT::Interlinear::diff( $sweep, \@blockelts );
			if ( not( scalar( @diff ) == 0 ) )
			{
				push( @box, $sweep )
			}
			else
			{
				push( @box, [ @bag ] );
			}
			push( @basket, [ @box ] );
		}
	}
	return( \@basket, \@bag );
}


sub solvestar
{
	my %d = %{ $_[0] };
	my %dirfiles = %{ $d{dirfiles} };
	my %dowhat = %{ $d{dowhat} };
	my @varnumbers = @{ $d{varnumbers} };
	my %carrier = %{ $d{carrier} };
	my @blockelts = @{ $d{blockelts} };

	$dirfiles{direction} = "star";
	$dirfiles{starorder} = $dowhat{starorder}->[$countcase]->[0];

	my ( @gencetres, @genextremes, @genpoints, $genextremes_ref, $gencentres_ref,
		@starpositions, @dummysweeps );


	if ( $dirfiles{stardivisions} ne "" )
	{
		$dirfiles{starpositions} = genstar( \%dirfiles, \@varnumbers, \%carrier, \@blockelts );

		( $dirfiles{dummysweeps}, $dirfiles{dummyelt} ) = @{ star_act( \@sweeps, \@blockelts, $countcase, $countblock ) };
	}


	$dirfiles{starnumber} = scalar( @{ $dirfiles{starpositions} } );

	if ( not( scalar( @{ $dirfiles{starpositions} } ) == 0 ) )
	{
		$dirfiles{direction} => [ [ "star" ] ],
		$dirfiles{randomsweeps} => "n", # to randomize the order specified in @sweeps.
		$dirfiles{randominit} => "n", # to randomize the init levels specified in @miditers.
		$dirfiles{randomdirs} => "n", # to randomize the directions of descent.
	}
	return( \%dirfiles )
}

###DDD
sub takewinning
{
	my ( $toitem ) = @_;
  

  if ( !defined($toitem) or ( $toitem !~ /-\d/ ) )
  {
  	die "takewinning() expected clear instance string, got '$toitem'";
  }

	my %carrier = split( "_|-", $toitem );
	return( \%carrier );
}


sub prepfactl
{
  my @arr = @{ $_[0] };
  my ( %hash, %hs );

  foreach my $el ( @arr )
  {
		my %hash = split( "-|_", $el );
		foreach my $key ( keys %hash )
		{
			$hs{$key}{$hash{$key}} = "";
		}
  }

	my %ohs;
	my $num = 0;
	foreach my $key ( keys %hs )
	{
		foreach my $item ( sort { $a <=> $b }( keys %{ $hs{$key} } ) )
		{
			push( @{ $ohs{$key} }, $item );
			$num++;
		}
		$ohs{$key} = [ uniq( @{ $ohs{$key} } ) ];
	}
  return( $num, \%ohs );
}


sub callblock # IT CALLS THE SEARCH ON BLOCKS.
{
	my %d = %{ $_[0] };
	my $countcase = $d{countcase};
	my $countblock = $d{countblock};
	my @sweeps = @{ $d{sweeps} };
	my @sourcesweeps = @{ $d{sourcesweeps} };
	my @miditers = @{ $d{miditers} };
	@miditers = Sim::OPT::washn( @miditers );
	my @winneritems = @{ $d{winneritems} };
	my %dirfiles = %{ $d{dirfiles} };
	my %incumbents = %{ $d{incumbents} };
	my %dowhat = %{ $d{dowhat} };
	my @varnumbers = @{ $d{varnumbers} };
	my %inst = %{ $d{inst} };
	my %vehicles = %{ $d{vehicles} };
	@varnumbers = Sim::OPT::washn( @varnumbers );
  say  "IN CALLBLOCK EXE \$dirfiles{randompicknum} $dirfiles{randompicknum}";


	if ( $countcase > $#sweeps )   # NUMBER OF CASES OF THE CURRENT PROBLEM
  {
		if ( ( $dirfiles{checksensitivity} eq "y" ) and ( checkOPTcue ) )
		{
			Sim::OPTcue::sense( $dirfiles{ordtot}, $mypath, $dirfiles{objectivecolumn} );
		}
    elsif ( ( $dirfiles{checksensitivity} eq "y" ) and ( !checkOPTcue ) )
    {
      say  "OPTcue must be installed to check sensitivity analysis ex-post. Skipping"
    }

    exit(
		say    "#END RUN."
		);
  }

	say  "#Beginning a search on case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";

	my @blockelts = @{ getblockelts( \@sweeps, $countcase, $countblock ) };

	my @sourceblockelts = @{ getblockelts( \@sourcesweeps, $countcase, $countblock ) };

  
  if ( $checkOPTcue )
  {
    my ( $sourceblockelts0_r, $dirfiles_r, $dowhat_r, $vehicles_r ) = Sim::OPTcue::direct( $sourceblockelts[0], \%dirfiles, \%dowhat, \%vehicles );
    $sourceblockelts[0] = $sourceblockelts0_r;
    %dirfiles = %$dirfiles_r;
    %dowhat = %$dowhat_r;
    %vehicles = %$vehicles_r;
  }
  elsif ( !$checkOPTcue )
  {
    if ( $sourceblockelts[0] =~ /ø/ )
    {
      $dirfiles{metamodel} = "y";
      $dowhat{metamodel} = "y";
      $sourceblockelts[0] =~ s/ø//;
    }

    if ( $sourceblockelts[0] =~ />/ )
    {
      $dirfiles{starsign} = "y";
      $sourceblockelts[0] =~ /^(\d+)>/ ;
      $dirfiles{stardivisions} = $1;

      if ( $sourceblockelts[0] =~ /ç/ )
      {
        $sourceblockelts[0] =~ /^(\d+)>(\d+)ç/ ;
        $dirfiles{slicenum} = $2;
        $dirfiles{pushsupercycle} = "y";
        $dirfiles{nestclock} = $dirfiles{nestclock} + 1;
        push( @{ $vehicles{nesting}{$dirfiles{nestclock}} }, $countblock );
      }
    }
    else
    {
      $dirfiles{starsign} = "n";
      $dirfiles{stardivisions} = "";
    }


    if ( $sourceblockelts[0] =~ /</ )
    {
      $dirfiles{factorial} = "y";

      if ( $sourceblockelts[0] =~ /ç/ )
      {
        $sourceblockelts[0] =~ /^(\d+)<(\d+)ç/ ;
        $dirfiles{slicenum} = $2;
        $dirfiles{pushsupercycle} = "y";
        $dirfiles{nestclock} = $dirfiles{nestclock} + 1;
        push( @{ $vehicles{nesting}{$dirfiles{nestclock}} }, $countblock );
      }
    }
    else
    {
      $dirfiles{factorial} = "n";
    }


    if ( $sourceblockelts[0] =~ /£/ )
    {
      $dirfiles{facecentered} = "y";
      $dirfiles{factorial} = "y";
      $dirfiles{random} = "y";
      $dirfiles{starsign} = "y";
      $sourceblockelts[0] =~ /^(\d+)£/ ;
      $dirfiles{facecenterednum} = $1;
      $dowhat{starpositions} = "";
      $dirfiles{starpositions} = "";
      $dowhat{stardivisions} = 1;
      $dirfiles{stardivisions} = 1;

      if ( $sourceblockelts[0] =~ /ç/ )
      {
        $sourceblockelts[0] =~ /^(\d+)£(\d+)ç/ ;
        $dirfiles{slicenum} = $2;
        $dirfiles{pushsupercycle} = "y";
        $dirfiles{nestclock} = $dirfiles{nestclock} + 1;
        push( @{ $vehicles{nesting}{$dirfiles{nestclock}} }, $countblock );
      }
    }
    else
    {
      $dirfiles{facecentered} = "n";
    }

  }

  ###...

  @blockelts = @{ washblockelts( \@blockelts ) }; say  "WASHED BLOCKELTS " . dump( @blockelts );
  
  #my %varnums = %{ washvarnums( \%varnums ) };
 
  @sourcesweeps = @{ wash_sourcesweeps(\@sourcesweeps) };

	my @blocks = getblocks( \@sweeps, $countcase );
  ###DDDTHIS
	my $toitem = getitem( \@winneritems, $countcase, $countblock );


	$toitem = clean( $toitem, $mypath, $file );

	if ( ( $dowhat{names} eq "short" ) and ( $toitem =~ /^\d+$/ ) )
	{
	  my $clear = $inst{$toitem};
	  if ( (!defined($clear) ) or ( $clear eq "") )
	  {
	    my $k = "$mypath/$file" . "_" . $toitem;
	    $clear = $inst{$k};
	  }

	  if ( ( !defined($clear) ) or ( $clear eq "" ) )
	  {
	  	die "Cannot map crypto toitem '$toitem' to clear instance (names=short)";
	  }
	    
	  $toitem = $clear;
	}

	my $from = getline($toitem);
	$from = clean( $from, $mypath, $file );

	my %carrier = %{ takewinning( $toitem ) };



	my @tempvarnumbers;
	if ( $dirfiles{starsign} eq "y" )
	{
		my @newvarnumbers = @{ stararrange( \@sweeps, \@blockelts, \@varnumbers, $countcase, $countblock, $file ) };
		$dirfiles{varnumbershold} = dclone( \@varnumbers );
		@varnumbers = @{ dclone( \@newvarnumbers ) };
		@varnumbers = Sim::OPT::washn( @varnumbers );

		%dirfiles = %{ solvestar( { dirfiles => \%dirfiles, dowhat => \%dowhat, varnumbers => \@varnumbers, blockelts => \@blockelts, carrier => \%carrier } ) };

		my @newmiditers = @{ $dirfiles{starpositions} }; # IT CORRECTS THE PART OF @miditers OUTSIDE THE BLOCKS

		$dirfiles{miditershold} = dclone( \@miditers );

		@miditers = @{ dclone( \@newmiditers ) };
	}

	my %mids = getcase( \@miditers, $countcase );
	my %varnums = getcase( \@varnumbers, $countcase );

  ###########################################################

	$dirfiles{simlist} = "$mypath/$file-simlist--$countcase";
	$dirfiles{morphlist} = "$mypath/$file-morphlist--$countcase";
	$dirfiles{retlist} = "$mypath/$file-retlist$sweeps_ref--$countcase";
	$dirfiles{replist} = "$mypath/$file-replist--$countcase"; # # FOR RETRIEVAL
	$dirfiles{descendlist} = "$mypath/$file-descendlist--$countcase"; # UNUSED FOR NOW
	$dirfiles{simblock} = "$mypath/$file-simblock--$countcase-$countblock";
	$dirfiles{morphblock} = "$mypath/$file-morphblock--$countcase-$countblock";
	$dirfiles{retblock} = "$mypath/$file-retblock--$countcase-$countblock";
	$dirfiles{repblock} = "$mypath/$file-repblock--$countcase-$countblock"; # # FOR RETRIEVAL
	$dirfiles{repfile} = "$mypath/$file-report-$countcase-$countblock.csv"; say  "IN OPT ASSIGN \$countblock $countblock \$dirfiles{repblock} $dirfiles{repblock} to DIRFILES.";
	$dirfiles{sortmixed} = "$dirfiles{repfile}" . "_sortm.csv";
	$dirfiles{totres} = "$mypath/$file-$countcase" . "_totres.csv";
	$dirfiles{ordres} = "$mypath/$file-$countcase" . "_ordres.csv";
  

	deffiles( {	countcase => $countcase, countblock => $countblock,
		miditers => \@miditers,  winneritems => \@winneritems,
		dirfiles => \%dirfiles, from => $from,
		sweeps => \@sweeps, sourcesweeps => \@sourcesweeps, incumbents => \%incumbents,
		dowhat => \%dowhat, varnumbers => \@varnumbers,
		mids => \%mids, varnums => \%varnums, carrier => \%carrier,
		carrier => \%carrier, sourceblockelts => \@sourceblockelts,
		blocks => \@blocks, blockelts => \@blockelts, instn => $instn, inst => \%inst, vehicles => \%vehicles } );
}


sub deffiles # IT DEFINED THE FILES TO BE PROCESSED
{
	my %d = %{ $_[0] };

	my $countcase = $d{countcase};
  my $countblock = $d{countblock};
	my @sweeps = @{ $d{sweeps} };
	my @sourcesweeps = @{ $d{sourcesweeps} };
	my @miditers = @{ $d{miditers} };
	my @winneritems = @{ $d{winneritems} };
	my %dirfiles = %{ $d{dirfiles} };
	my %incumbents = %{ $d{incumbents} };
	my @varnumbers = @{ $d{varnumbers} };
	my %dowhat = %{ $d{dowhat} };

	my @blockelts = @{ $d{blockelts} }; say  "IN DEFFILES \@blockelts " . dump( @blockelts );
	my @sourceblockelts = @{ $d{blockelts} };
	my @blocks = @{ $d{blocks} };
	my $from = $d{from};
	my %varnums = %{ $d{varnums} };
	my %mids = %{ $d{mids} };
	my %carrier = %{ $d{carrier} };
	my $instn = $d{instn};
	my %inst = %{ $d{inst} };
	my %vehicles = %{ $d{vehicles} };

	my $file = $dowhat{file};
	my $mypath = $dowhat{mypath};

	my $starstring = tellstring( \%mids, $file );
	$dirfiles{starstring} = $starstring; # FOR THE OUTTER STAR SEARCH

	my $rootitem = "$file" . "_";
	my (@basket, @box);
	push (@basket, [ $rootitem ] );

	sub toil
	{
		my ( $blockelts_r, $varnums_r, $basket_r, $c, $mypath, $file, $dirfiles_ref ) = @_;
		my @blockelts = @{ $blockelts_r };
		my %varnums = %{ $varnums_r };
		my %dirfiles = %{ $dirfiles_ref };

		my @basket = @{ $basket_r };
		if ( ( $c eq "" ) or ( $c == 0 ) )
		{
			@box = ();
		}

    unless ( 
      ( $dirfiles{randompick} eq "y" ) or ( $dirfiles{newrandompick} eq "y" ) 
    or ( $dirfiles{patternsearch} eq "y" ) or ( $dirfiles{neldermead} eq "y" ) 
    or ( $dirfiles{armijo} eq "y" ) or ( $dirfiles{NSGAII} eq "y" ) 
    or ( $dirfiles{pso} eq "y" ) or ( $dirfiles{simulatedannealing} eq "y" ) 
    or ( $dirfiles{NSGAIII} eq "y" ) or ( $dirfiles{MOEAD} eq "y" ) )
    {
      foreach my $var ( @blockelts )
			{
				my ( @bucket );
				my $maxvalue	= $varnums{$var};

				foreach my $elt ( @basket )
				{
					my $root = $elt->[0];
					my @bag;
					my $item;
					my $cnstep = 1;
					while ( $cnstep <= $maxvalue)
					{
						my $olditem = $root;
						$item = "$root" . "$var" . "-" . "$cnstep" . "_" ;
						push ( @bag, [ $item, $var, $cnstep, $olditem, $c ] );
						$cnstep++;
					}
					push ( @bucket, @bag );
				}
				@basket = ();
				@basket = @bucket;

				if ( $c eq "" )
				{
					push ( @box, [ @bucket ] );
				}
				else
				{
					@box = [ @bucket ];
				}
			}
    }
    else 
    {
    	my ( @bucket );
    	@basket = ();
      push (@basket, [ $rootitem ] );
			foreach my $elt ( @basket )
			{
				my $root = $elt->[0];
				my @bag;
				my $item;
				my $cnstep = 1;
				my $var = $blockelts[0];
				my $olditem = $root;
				my $item = $olditem ;
			  push ( @bag, [ $item, $var, $cnstep, $olditem, $c ] );
				push ( @bucket, @bag );
			}
			@basket = ();
			@basket = @bucket;

			if ( $c eq "" )
			{
				push ( @box, [ @bucket ] );
			}
			else
			{
				@box = [ @bucket ];
			}
    }
		return( \@box );
	}

	my ( @bux, @buux );
	if ( 
    ( $dirfiles{starsign} eq "y" ) 
			or ( ( $dirfiles{random} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) 
			or ( ( $dirfiles{latinhypercube} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) 
			or ( ( $dirfiles{factorial} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) 
      or ( ( $dirfiles{facecentered} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) 
			#or ( ( $dirfiles{randompick} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{newrandompick} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{patternsearch} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{neldermead} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{armijo} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{NSGAII} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{NSGAIII} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{pso} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{simulatedannealing} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{MOEAD} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{SPEA2} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) 
    )
	{
		if ( $dirfiles{starsign} eq "y" )
		{
			my $c = 0;
			foreach my $elt ( @blockelts )
			{
				my @dummys = ( $elt );
				my @bix = @{ toil( \@dummys, \%varnums, \@basket, $c, $mypath, $file, \%dirfiles ) };
				@bix = @{ $bix[0] };
				push( @bux, @bix );
				$c++;
			}
		}

		my ( $tmpblankfile, $bit );
		my ( @bag, @fills, @fulls );
		if ( 
      ( ( $dirfiles{random} eq "y" ) and ( $dowhat{metamodel} eq "ys" ) )
		 	or ( ( $dirfiles{latinhypercube} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
			or ( ( $dirfiles{factorial} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
			or ( ( $dirfiles{facecentered} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )	
      or ( ( $dirfiles{factorial} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) 
      #or ( ( $dirfiles{randompick} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{newrandompick} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{patternsearch} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{neldermead} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{armijo} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{NSGAII} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{NSGAIII} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{pso} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{simulatedannealing} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{MOEAD} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
      #or ( ( $dirfiles{SPEA2} eq "y" ) and ( $dowhat{metamodel} eq "y" ) )
    )
		{
			$tmpblankfile = "$mypath/$file" . "_tmp_gen_blank.csv";
			$bit = $file . "_";
			@bag =( $bit );
			@fills = @{ Sim::OPT::Descend::prepareblank( \%varnums, $tmpblankfile, \@blockelts, \@bag, $file, \%carrier ) };
			@fulls = uniq( map { $_->[0] } @fills );
		}##### UPDATE!!!!!

		if ( $dirfiles{random} eq "y" )
		{
			my ( $standard ) = prepfactl( \@fulls );

			my $numitems = $dirfiles{randomnum};
			my @newfulls = shuffle( @fulls );
			my @forebunch = @newfulls[ 0 .. $numitems ];

			foreach $el ( @forebunch )
			{
				push( @buux, [ [ $el, "", "", "", "" ] ] );
			}
		}

		if ( $dirfiles{latinhypercube} eq "y" )
		{
			my ( $standard ) = prepfactl( \@fulls );
			my $numitems = $dirfiles{latinhypercubenum};

			my $totnum = scalar( @fulls );
			my $numeach = int( $totnum / $numitems );

			my @newfulls;
			my $c1 = 0;
			my $c2 = 1;
			foreach $elt ( @fulls )
			{
				push( @{ $newfulls[$c1] }, $elt );
				if ( $c2 == $numeach )
				{
					$c1++;
					$c2 = 0;
				}
				$c2++
			}

			my @forebunch;
			foreach $ref ( @newfulls )
			{
				my @temp = shuffle( @{ $ref } );
				push( @forebunch, $temp[0] );
			}

			foreach $el ( @forebunch )
			{
				push( @buux, [ [ $el, "", "", "", "" ] ] );
			}
		}

		if ( $dirfiles{factorial} eq "y" )
		{
			my ( $standard, $ohs_r ) = prepfactl( \@fulls );
			my %ohs = %{ $ohs_r };

			my %nhs;
			foreach my $key ( keys %ohs )
			{
				my @elts = @{ $ohs{$key} };
				my @prov;
				push( @prov, $elts[0], $elts[-1] );
				@prov = uniq( @prov );
				if ( scalar( @prov ) > 1 )
				{
					$nhs{$key} = [ @prov ];
				}
			}

			my @sack;
			foreach my $key ( sort{ $a <=> $b }( keys %nhs ) )
			{
				my @pairs = @{ $nhs{$key} };
				my $el;
				foreach my $single ( @pairs )
				{
					$el = join( "-", ( $key, $single ) );
					push( @sack, $el );
				}
			}

			my $numelts = scalar( keys %nhs );
			foreach my $series ( @fulls )
			{
				my $count = 0;
				my @divs = split( "_", $series );
				foreach my $bit ( @divs )
				{
					if ( $bit ~~ @sack )
					{
						$count++;
					}
					if ( $count == $numelts )
					{
						push( @buux, [ [ $series, "", "", "", "" ] ] );
					}
				}
			}
		}
	}
	else
	{
		unless ( $dirfiles{ga} eq "y" )
	  {
	    @bux = @{ toil( \@blockelts, \%varnums, \@basket, "", $mypath, $file, \%dirfiles ) };
	  }
	  else
	  {
	    my @subst = (1);
	    @bux = @{ toil( \@subst, \%carrier, \@basket, "", $mypath, $file, \%dirfiles ) };
	  }
	}


	sub cleanduplicates
	{
		my ( $elts_ref, $dowhat_ref ) = @_;
		my @elts = @{ $elts_ref };
		my %dowhat = %{ $dowhat_ref };

		my @sack = map { $_[0] } @elts ;

		my @finals;
		foreach my $elt ( @sack )
		{
			foreach my $e ( @elts )
			{
				if ( $elt eq $e->[0] )
				{
					push( @finals, $e );
					last;
				}
			}
		}
		return( @finals );
	}

	if ( $dowhat{pairpoints} eq "y" )
	{
		my @boox;
		foreach my $el ( @buux )
		{
			my $newel = addnear( $el, \%varnums );
			push( @boox, $el, $newel );
		}
		@buux = @boox;
	}

	my ( @finalbox );
	if ( $dirfiles{starsign} eq "y" )
	{
		my @newbuux;
		foreach my $el ( @buux )
		{
			my $elt = $el->[0];
			push( @newbuux, $elt );
		}
		push( @bux, @newbuux );

		my @bag;
		foreach my $midsurrs_r ( @miditers )
		{
			my %midsurrs = %{ $midsurrs_r };
	 		@bag = uniq( @{ integratebox( \@bux, \%midsurrs, $file, \@blockelts, $mypath, \%inst, \%dowhat, $instn ) } );
			push( @finalbox, @bag );
		}
		my @finalbox = cleanduplicates( \@finalbox, \%dowhat );
	}
	else
	{
		my @bark = @{ flattenbox( \@bux ) };
		@finalbox = uniq( @{ integratebox( \@bark, \%carrier, $file, \@blockelts, $mypath, \%inst, \%dowhat, $instn ) } );
	}

	@finalbox = sort { $a->[0] <=> $b->[0] } @finalbox;

	setlaunch( {
		countcase => $countcase, countblock => $countblock,
		miditers => \@miditers,  winneritems => \@winneritems,
		dirfiles => \%dirfiles, basket => \@finalbox,
		sweeps => \@sweeps, sourcesweeps => \@sourcesweeps,
		incumbents => \%incumbents, dowhat => \%dowhat,
		varnumbers => \@varnumbers,
		mids => \%mids, varnums => \%varnums,
		carrier => \%carrier, instn => $instn, inst => \%inst, vehicles => \%vehicles, blockelts => \@blockelts
	} );
}

sub setlaunch # IT SETS THE DATA FOR THE SEARCH ON THE ACTIVE BLOCK.
{
	my %d = %{ $_[0] };
	my $countcase = $d{countcase};
	my $countblock = $d{countblock};
	my @sweeps = @{ $d{sweeps} };
	my @sourcesweeps = @{ $d{sourcesweeps} };
	my @miditers = @{ $d{miditers} };
	my @winneritems = @{ $d{winneritems} };
	my %dirfiles = %{ $d{dirfiles} };
	my @basket = @{ $d{basket} };
	my %incumbents = %{ $d{incumbents} };
	my @varnumbers = @{ $d{varnumbers} };
	my %dowhat = %{ $d{dowhat} };
  my @blockelts = @{ $d{blockelts} };

	my $instn = $d{instn};
  if ( !$instn )
  {
    $instn = $dirfiles{countinst};
  }

	my %inst = %{ $d{inst} };
	my %vehicles = %{ $d{vehicles} };

	#my @blockelts = @{ getblockelts( \@sweeps, $countcase, $countblock ) };
	my @blocks = getblocks( \@sweeps, $countcase );

	my %varnums = %{ $d{varnums} };
	my %mids = %{ $d{mids} };
	my %carrier = %{ $d{carrier} };

	my ( @instances, @precedents );
	my %starters = %{ extractcase( \%inst, \%dowhat, "", \%carrier, $file, \@blockelts, $mypath, "" ) };

	$dirfiles{starter}{cleanto} = $starters{cleanto};
	$dirfiles{starter}{cleancrypto} = $starters{cleancrypto};

	my $count = 0;
	foreach my $elt ( @basket )
	{
		my $newpars = $$elt[0];
		my $countvar = $$elt[1];
		my $countstep = $$elt[2];
		my $oldpars = $$elt[3];
    
    $dirfiles{countinst} = $instn ;
    
		my %to = %{ extractcase( \%inst, \%dowhat, $newpars, \%carrier, $file, \@blockelts, $mypath, $instn ) };

		my %orig = %{ extractcase( \%inst, \%dowhat, $oldpars, \%carrier, $file, \@blockelts, $mypath ) }; #say  "obtained \$instn: $instn, countinstance: $count, from: $from, \$to: $to, \%orig: " . dump( \%orig ) . ", \%carrier: " . dump( \%carrier );
		my $origin = $orig{cleanto};
		my $from = $origin;
  	my $c = $$elt[4];

		$inst{$to{cleanto}} = $to{cleancrypto};
	  $inst{$to{crypto}} = $to{to};
	  $inst{$to{cleancrypto}} = $to{cleanto};
	  $inst{$to{to}} = $to{crypto};
	  $inst{$orig{cleanto}} = $orig{cleancrypto};
	  $inst{$orig{crypto}} = $orig{to};
	  $inst{$orig{cleancrypto}} = $orig{cleanto};
	  $inst{$orig{to}} = $orig{crypto};

		%inst = cleaninst( %inst );
		#unless ( $dirfiles{ga} eq "y" )
		#{
			#
      if ( not ( $to{cleanto} ~~ @{ $dirfiles{dones} } ) )
			{
				unless ( ( $dirfiles{randompick} eq "y" ) or ( $dirfiles{newrandompick} eq "y" ) 
        or ( $dirfiles{patternsearch} eq "y" ) or ( $dirfiles{neldermead} eq "y" ) 
        or ( $dirfiles{armijo} eq "y" ) or ( $dirfiles{NSGAII} eq "y" ) 
        or ( $dirfiles{pso} eq "y" ) or ( $dirfiles{simulatedannealing} eq "y" ) 
        or ( $dirfiles{NSGAIII} eq "y" ) or ( $dirfiles{MOEAD} eq "y" ) )
				{
					push( @{ $dirfiles{dones} }, $to{cleanto} );
				}

				push( @instances,
				{
					countcase => $countcase, countblock => $countblock,
					miditers => \@miditers,  winneritems => \@winneritems, c => $c, from => $from,
					to => \%to, countvar => $countvar, countstep => $countstep, orig => \%orig,
					sweeps => \@sweeps, dowhat => \%dowhat,
					sourcesweeps => \@sourcesweeps, incumbents => \%incumbents,
					varnumbers => \@varnumbers, blocks => \@blocks,
					blockelts => \@blockelts, mids => \%mids, varnums => \%varnums,
					countinstance => $instn, carrier => \%carrier, origin => $origin,
					instn => $instn, is => $to{cleanto}, vehicles => \%vehicles, dirfiles => \%dirfiles,
				} );
			}
      else
			{
				push( @precedents,
				{
					countcase => $countcase, countblock => $countblock,
					miditers => \@miditers,  winneritems => \@winneritems, c => $c, from => $from,
					to => \%to, countvar => $countvar, countstep => $countstep, orig => \%orig,
					sweeps => \@sweeps, dowhat => \%dowhat,
					sourcesweeps => \@sourcesweeps, incumbents => \%incumbents,
					varnumbers => \@varnumbers, blocks => \@blocks,
					blockelts => \@blockelts, mids => \%mids, varnums => \%varnums,
					countinstance => $instn, carrier => \%carrier, origin => $origin,
					instn => $instn, is => $to{cleanto}, vehicles => \%vehicles, dirfiles => \%dirfiles,
				} );
			}
		#}
    $instn++;
		$count++;
	}
	exe( { instances => \@instances, dirfiles => \%dirfiles, inst => \%inst, precedents => \@precedents, mypath => $mypath, file => $file,
         countcase => $countcase, countblock => $countblock, varnumbers => \@varnumbers, miditers => \@miditers, sweeps => \@sweeps,
				 sourcesweeps => \@sourcesweeps, winneritems => \@winneritems, dowhat => \%dowhat, mids => \%mids,
			   carrier => \%carriers, varnums => \%varnums } );
}

sub exe
{
	my %dat = %{ $_[0] };
	my @instances = @{ $dat{instances} }; say  "\@instances at the beginning of sub exe: " . dump( @instances );
	my %dirfiles = %{ $dat{dirfiles} };
	my %inst = %{ $dat{inst} };
	my @precedents = @{ $dat{precedents} };
	my $mypath = $dat{mypath};
	my $file = $dat{file};
	my $countcase = $dat{countcase};
	my $countblock = $dat{countblock}; #say "\$countblock " . dump( $countblock);
	my @varnumbers = @{ $dat{varnumbers} };
	my @miditers = $dat{miditers};
	my @sweeps = @{ $dat{sweeps} };
	my @sourcesweeps = @{ $dat{sourcesweeps} };
	my @winneritems =  @{ $dat{winneritems} };
  my %dowhat = %{ $dat{dowhat} };
	my %mids = %{ $dat{mids} }; ##say "MIDS " . dump( \%mids );
	my %carrier = %{ $dat{carrier} };
	my %varnums = %{ $dat{varnums} };

	my %d = %{ $instances[0] };
	my %incumbents = %{ $d{incumbents} };
	my $from = $d{from};
	my %to = %{ $d{to} };
	my %orig = %{ $d{orig} };
	my $countvar = $d{countvar};
	my $countstep = $d{countstep};
  my $origin = $d{origin};
  
	my @blockelts = @{ $d{blockelts} };
	my @sourceblockelts = @{ $d{blockelts} };
	my @blocks = @{ $d{blocks} };
	my $instn = $d{instn};
	my %vehicles = %{ $d{vehicles} };

	my $precomputed = $dowhat{precomputed};
  my @takecolumns = @{ $dowhat{takecolumns} };
	my ( @packet, @unsuiteds );
	say  "#Performing a search on case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";

  #say  "NOW!!! ENTERING EXE \%inst: " . dump (\%inst);

	

	my ( @reds, %winning, $csim );

	if ( $dirfiles{nestclock} > 0 )
	{
		push( @{ $vehicles{cumulateall} }, @instances );
	}
	
	###################################################################################################
	elsif ( ( $dirfiles{randompick} eq "y" ) or ( $dirfiles{newrandompick} eq "y" ) 
  or ( $dirfiles{patternsearch} eq "y" ) or ( $dirfiles{neldermead} eq "y" ) 
  or ( $dirfiles{armijo} eq "y" ) or ( $dirfiles{NSGAII} eq "y" ) or ( $dirfiles{ga} eq "y" ) 
  or ( $dirfiles{pso} eq "y" ) or ( $dirfiles{simulatedannealing} eq "y" ) 
  or ( $dirfiles{NSGAIII} eq "y" ) or ( $dirfiles{MOEAD} eq "y" ) )
	{
    if ( checkOPTcue() )
    {
      ( $inst_r, $instances_r ) = Sim::OPTcue::expand(
      {
        configfile => $configfile,
        precious   => $precious,

        instances  => \@instances,
        dirfiles   => \%dirfiles,
        inst       => \%inst,
        precedents => \@precedents,

        dowhat     => \%dowhat,
        vehicles   => \%vehicles,
        mids       => \%mids,
        varnums    => \%varnums,
        carrier    => \%carrier,

        blockelts  => \@blockelts,
        from       => $from,
        origin   => $d{origin}, 
        mypath     => $mypath,
        file       => $file,
        countcase  => $countcase,
        countblock => $countblock,
      }, \%inst );
      @instances = @$instances_r;
    }
    else 
    {
      say  "OPTcue is not installed and this operation is not possible without it.";
    }
	}

	else
	{
		if ( $dowhat{morph} eq "y" )
		{
			say  "#Calling morphing operations for case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
			my ( $dirfiles_r, $unsuiteds_r ) = Sim::OPT::Morph::morph( $configfile, \@instances, \%dirfiles, \%dowhat, \%vehicles, \%inst, \@precedents );
      %dirfiles = %$dirfiles_r;
      @unsuiteds = @$unsuiteds_r;
			#%inst = %{ $result[2] };
		}
    
    my $postlast = "y";
    my ( $packet_r, $dirfiles_r, $csim, $instant ); say  "IN DESCENT FROM DIRFILES, \$countblock $countblock, \$repfile $repfile";
		if ( ( $dowhat{simulate} eq "y" ) or ( $dowhat{newreport} eq "y" ) )
		{
			say  "#Calling simulations, reporting and retrieving for case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
			( $packet_r, $dirfiles_r, $csim,  ) = Sim::OPT::Sim::sim(
					{ instances => \@instances, dowhat => \%dowhat, dirfiles => \%dirfiles,
					  vehicles => \%vehicles, inst => \%inst, precedents => \@precedents, 
            #bomb => \@instances,
            last => $last, 
            postlast => $postlast,
             #onlyrep => "y" ,
            precious => $precious, 
          } );
      @packet = uniq( @$packet_r ); say  "RECEIVED PACKET " . dump( @packet );
      %dirfiles = %$dirfiles_r;
			say  "#Performed simulations, reporting and retrieving for case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
		}

    
    say "!!!!!NOW EXITEDIN EXE FROM SIM WITH \@packet: " . dump( @packet );
 


    my $cryptolinks;
    unless ( $dirfiles{ga} eq "y" )
    {
      $cryptolinks = "$mypath/$file" . "_" . "$countcase" . "_cryptolinks.pl"; #say  "CRYPTOLINKS $cryptolinks";
      open ( CRYPTOLINKS, ">$cryptolinks" ) or die;
      say CRYPTOLINKS "" . dump( \%inst );
      close CRYPTOLINKS;
     }
	}

	#say "NOW ON THE BRINK";
	#say  "\$dowhat{descend} $dowhat{descend}";
	if ( $dowhat{descend} eq "y" )
	{
		say  "#Calling descent for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ".";
		Sim::OPT::Descend::descend(	{ instances => \@instances, dowhat => \%dowhat,
		 dirfiles => \%dirfiles, vehicles => \%vehicles, inst => \%inst, precedents => \@precedents, packet => \@packet } );
		say  "#Performed descent for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ".";
	}

	if ( $dowhat{substitutenames} eq "y" )
	{
		 Sim::OPT::Report::filter_reports( { instances => \@instances, dowhat => \%dowhat, dirfiles => \%dirfiles, vehicles => \%vehicles, inst => \%inst } );
	}

	if ( $dowhat{filterconverted} eq "y" )
	{
		 Sim::OPT::Report::convert_filtered_reports(
		{
			  instances => \@instances, dowhat => \%dowhat, dirfiles => \%dirfiles, vehicles => \%vehicles, inst => \%inst } );
	}

	if ( $dowhat{make3dtable} eq "y" )
	{
		 Sim::OPT::Report::maketable(
		{
			  instances => \@instances, dowhat => \%dowhat, dirfiles => \%dirfiles, vehicles => \%vehicles, inst => \%inst } );
	}
} # END SUB exe


sub genstar
{
	my ( $dowhat_ref, $varnumbers_ref, $carrier_ref, $blockelts_ref ) = @_;
	my %dowhat = %{ $dowhat_ref };
	my %carrier = %{ $carrier_ref };
	my @blockelts = @{ $blockelts_ref };

	my @varnumbers = @{ $varnumbers_ref };

	my (  @genextremes, @gencentres, @starpositions );
	if ( $dowhat{stardivisions} == 1 )
	{
		$gencentres_ref = gencen( \@varnumbers);
		@gencentres = @{ $gencentres_ref };
		push( @starpositions, @gencentres );
	}
	elsif ( $dowhat{stardivisions} > 1 )
	{
		$genextremes_ref = genextremes( \@varnumbers );
		my $i = 1;
		while ( $i < $dowhat{stardivisions} )
		{
			$genextremes_ref = gencentres( $genextremes_ref );
			@genpoints = @{ $genextremes_ref };
			$i++;
		}
		push( @starpositions, @genpoints );
	}

	my @bag;
	if ( scalar( @blockelts > 0) )
	{
		foreach my $el ( @starpositions )
		{
			my %hs = %{ $el };
			foreach my $key ( sort( keys( %hs ) ) )
			{
				if ( not ( $key ~~ @blockelts ) )
				{
					$hs{$key} = $carrier{$key};
				}
			}
			push( @bag, \%hs );
		}
		@starpositions = @bag;
	}
	return( \@starpositions );
}


sub start
{
###########################################
say "\nThis is Sim::OPT, version $VERSION.
Please insert the name of a configuration file (Unix path).\n";
###########################################
	$configfile = <STDIN>;
	chomp $configfile;
	if (-e $configfile )
	{
		return( $configfile );
	}
	else { start; }
}



###########################################################################################

sub opt
{
	my $configfile = start;
	#eval `cat $configfile`; # The file where the program data are
	my ( @miditers, @varnumbers, %dirfiles );

  require $configfile;
	

	my $instn = 1;
  our %inst;
  $dirfiles{countinst} = $instn;

	if ( $dowhat{mypath} eq "" )
	{
		$dowhat{mypath} = $mypath;
	}


  sub checkOPTcue 
  {
     if( defined( $checkOPTcue ) )
     {
        return( $checkOPTcue );
     }

    my $checkOPTcue = eval 
    {
      use Sim::OPTcue;
      1;
    } ? 1 : 0;
    return( $checkOPTcue );
  }

  our $checkoptcue = checkOPTcue();


	if ( scalar( @miditers == 0 ) )
	{
		@miditers = @mediumiters;
	}

	if ( scalar( @varnumbers == 0 ) )
	{
		@varnumbers = @varinumbers;
	}

	if ( $dowhat{tofile} eq "" )
	{
		$tofile = "$mypath/$file-tofile.txt";
	}
	else
	{
		$tofile = $dowhat{tofile};
	}

	if ( $dowhat{randomfraction} eq "" )
	{
		$dowhat{randomfraction} = 1;
	}

	if ( $dowhat{hypercubefraction} eq "" )
	{
		$dowhat{hypercubefraction} = 1;
	}


	say  "\nNow in Sim::OPT. \n";
	$dowhat{file} = $file;

  if ( !checkOPTcue() )
  {
    say  "THERE IS NO OPTCUE INSTALLED. SO, HALTING.";
    die;
  }
  else 
  {
    {
    say "OPTCUE OK.";
    }
  }



	if ( ( $dowhat{justchecksensitivity} ne "" ) and ( checkOPTcue ) )
	{
		#say  "RECEIVED.";
		Sim::OPTcue::sense( $dowhat{justchecksensitivity}, $mypath, $dowhat{objectivecolumn}, "stop" );
	}
  elsif ( ( $dowhat{justchecksensitivity} ne "" ) and ( !checkOPTcue ) )
  {
    say  "To perform sensitivity analysis ex-post, OPTcue must be installed. Skipping. "
  }

  if ( $dowhat{randomsweeps} eq "y" ) #IT SHUFFLES  @sweeps UNDER REQUESTED SETTING.
  {
    my @newsweeps;
    foreach my $arrayref ( @sweeps )
    {
        my @newarr;
        my @array = @{ $arrayref };
        @array = shuffle( @array );
        foreach my $arefref ( @array )
        {
          my @arrayy = @{ $arefref };
          @arrayy = shuffle( @arrayy );
          push ( @newarr, [ @arrayy ] );
        }
        push ( @newsweeps, [ @newarr ] );
      }
      @sweeps = @newsweeps;
  }

  my $i = 0;
  my @newarr;
  if ( $dowhat{randomdirs} eq "y" )
  { #IT SHUFFLES  $dowhat{direction} UNDER REQUESTED SETTINGS.
    foreach my $directionref ( @{ $dowhat{direction} } )
    {
      my @varnumber = %{ $varnumbers[$i] };
      my $numcases = ( scalar( @varnumber ) / 2 ) ;
      my @directions;
      my $x = 0;
      foreach ( @{ $directionref } )
      {
        while ( $x < $numcases )
        {
          my @bag = ( ">", "<", "=" );
          @bag = shuffle( @bag );
          push ( @directions, $bag[0] );
          $x++;
        }
      }
      push ( @newarr, [ @directions ] );
      $i++;
    }
    $dowhat{direction} = [ @newarr ];
    say  "NEW RANDOMIZED DIRECTIONS: " . dump( $dowhat{direction} );
  }


  { #IT FILLS THE MISSING $dowhat{direction} UNDER REQUESTED SETTINGS.
    my @newarr;
		my $i = 0;
    foreach my $dirref ( @{ $dowhat{direction} } )
    {
      my @thesesweeps = @{ $sweeps[$i] };
      my $numcases =  scalar( @thesesweeps );

      my @directions;
      my $itemsnum = scalar( @{ $dirref } );
      my $c = 0;
      while ( ( $itemsnum + $c ) <= $numcases )
      {
        push ( @directions, ${ $dirref }[0] );
        $c++;
      }
      push ( @newarr, [ @directions ] );
      $i++;
    }
    $dowhat{direction} = [ @newarr ];
  }

	{ #IT FILLS THE MISSING $dowhat{starorder} UNDER APPROPRIATE SETTINGS.
    my @newarr;
		my $i = 0;
    foreach my $dirref ( @{ $dowhat{starorder} } )
    {
			my @thesesweeps = @{ $sweeps[$i] };
      my $numcases =  scalar( @thesesweeps );

      my @starorders;
      my $itemsnum = scalar( @{ $dirref } );
      my $c = 0;
      while ( ( $itemsnum + $c ) <= $numcases )
      {
        push ( @starorders, ${ $dirref }[0] );
        $c++;
      }
      push ( @newarr, [ @starorders ] );
      $i++;
    }
    $dowhat{starorder} = [ @newarr ];
  }

  if ( $dowhat{randominit} eq "y" )
  {
    my %i = 0;
    foreach $arr ( @varnumbers )
    {
      my %hash = %{ $arr };
      foreach my $elt ( sort {$a <=> $b} ( keys %hash ) )
      {
        my $num = $hash{$elt};
        my $newnum = ( 1+ int( rand( $num ) ) );
        ${ $miditers[i] }{$elt} = $newnum;
      }
      $i++;
    }
    say  "NEW INIT LEVELS: " . dump( @miditers );
  }

	if ( not ( $target ) ) { $target = "opt"; }

	#####################################################################################
	# INSTRUCTIONS THAT LAUNCH OPT AT EACH SWEEP (SUBSPACE SEARCH) CYCLE

	if ( not ( ( @chanceseed ) and ( @caseseed ) and ( @chancedata ) ) )
	{
		if ( ( @sweepseed ) and ( @chancedata ) ) # IF THIS VALUE IS DEFINED. TO BE FIXED.
		{
			my $yield = fromsweep_toopt( @sweeps );
			@caseseed = @{ $yield[0] };
			@chanceseed = @{ $yield[1] };
		}
	}

	@chanceseed = convchanceseed(@chanceseed);
	@caseseed = convcaseseed( { caseseed => \@caseseed, chanceseed => \@chanceseed } );

	my (@sweeps_);

	if ( ( $target eq "takechance" ) and (@chancedata) and ( $dimchance ) )
	{
		my @obt = Sim::OPT::Takechance::takechance( \@caseseed, \@chanceseed, \@chancedata, $dimchance );
		@sweeps_ = @{ $obt[0] };
		@caseseed_ = @{ $obt[1] };
		@chanceseed_ = @{ $obt[2] };
		open( MESSAGE, ">./search_structure_that_may_be_adopted.txt" );
		say MESSAGE "\@sweeps_ " . Dumper(@sweeps_);
		say MESSAGE "\THESE VALUES OF \@sweeps IS EQUIVALENT TO THE FOLLOWING VALUES OF \@caseseed AND \@chanceseed: ";
		say MESSAGE "\n\@caseseed " . Dumper(@caseseed_);
		say MESSAGE "\n\@chanceseed_ " . Dumper(@chanceseed_);
		close MESSAGE;

		if ( not (@sweeps) ) # CONSERVATIVE CONDITION. IT MAY BE CHANCED.
		{
			@sweeps = @sweeps_ ;
		}
	}
	elsif ( $target eq "opt" )
	{

		if ( scalar( @miditers ) == 0 ) { calcmiditers( @varnumbers ); }

		@rootnames = definerootcases( \@sweeps, \@miditers );

		my $countcase = 0;
		my $countblock = 0;
		my %incumbents;

		my @winneritems = populatewinners( \@rootnames, $countcase, $countblock );

		my $count = 0;
		my @arr;
		foreach ( @varnumbers )
		{
			my $elt = getitem( \@winneritems, $count, 0 );
			push ( @arr, $elt );
			$count++;
		}
		$incumbents{pinwinneritem} = [ @arr ];

		my ( @gencentres, @genextremes, @genpoints, $genextremes_ref, $gencentres_ref );

		if ( $dowhat{outstarmode} eq "y" )
		{
			if ( ( $dowhat{stardivisions} ne "" ) and ( $dowhat{starpositions} eq "" ) )
			{
				$dowhat{starpositions} = genstar( \%dowhat, \@varnumbers, $miditers[$countcase] );
			}

			$dowhat{starnumber} = scalar( @{ $dowhat{starpositions} } );

			if ( not( scalar( @{ $dowhat{starpositions} } ) == 0 ) )
			{
				$dowhat{direction} => [ [ "star" ] ];
				$dowhat{randomsweeps} => "n"; # to randomize the order specified in @sweeps.
				$dowhat{randominit} => "n"; # to randomize the init levels specified in @miditers.
				$dowhat{randomdirs} => "n"; # to randomize the directions of descent.

				my @sweeps = @{ starsweep( \@varnumbers, \@sweeps ) };

				my $number = scalar( @varnumbers );

				my ( @addition, @addition2, @addition3, @sweepaddition );
				my $cn = 0;
				while ( $cn < $dowhat{starnumber} )
				{
					push( @addition, $varnumbers[0] );
					push( @addition2, $dowhat{direction}[0] );
					push( @addition3, $dowhat{starorder}[0] );
					push( @sweepaddition, $sweeps[0] );
					$cn++;
				}

				@varnumbers = @addition;
				$dowhat{direction} = \@addition2;
				$dowhat{starorder} = \@addition3;
				my @sweeps = @sweepaddition;

				my @bag;
				my @miditers = @miditers[1 ... $#miditers];
				push( @bag, @{ $dowhat{starpositions} }, @miditers );
				my @miditers = @bag;

				$countstring = 1;

				my ( $sweepz_ref, $sourcesweeps_ref ) = readsweeps( @sweeps );
				my @sweepz = @$sweepz_ref;
				my @sourcesweeps = @$sourcesweeps_ref;
				if ( @sweepz )
				{
					@sweeps = @sweepz;
				}

				@calcoverlaps = calcoverlaps( @sweeps );

				$dirfiles{countstring} = $countstring;
				$dirfiles{nestclock} = 0;

				$dirfiles{tottot} = "$mypath/$file-$countcase" . "-tottot.csv";
				$dirfiles{ordtot} = "$mypath/$file-$countcase" . "-ordtot.csv";


				callblock( { countcase => $countcase, countblock => $countblock,
					miditers => \@miditers, varnumbers => \@varnumbers, winneritems => \@winneritems, sweeps => \@sweeps,
					sourcesweeps => \@sourcesweeps, incumbents => \%incumbents, dirfiles => \%dirfiles,
					dowhat => \%dowhat, instn => $instn, inst => \%inst, vehicles => \%vehicles } );
					$countstring++;
					$dirfiles{countstring} = $countstring;
			}
		}
		else
		{
			my ( $sweepz_ref, $sourcesweeps_ref ) = cleansweeps( \@sweeps );
			my @sweepz = @{ $sweepz_ref };
			my @sourcesweeps = @{ $sourcesweeps_ref };
			if ( @sweepz )
			{
				@sweeps = @sweepz;
			}

			#@calcoverlaps = calcoverlaps( @sweeps );
			$dirfiles{tottot} = "$mypath/$file-$countcase" . "-tottot.csv";
			$dirfiles{ordtot} = "$mypath/$file-$countcase" . "-ordtot.csv";
			#@miditers = @pinmiditers;
			#say  "miditers: " . dump ( @miditers );

			if ( scalar( @miditers ) == 0 ) { calcmiditers( @varnumbers ); }

			@rootnames = definerootcases( \@sweeps, \@miditers );

			my $countcase = 0;
			my $countblock = 0;
			my %incumbents;

			my @winneritems = populatewinners( \@rootnames, $countcase, $countblock );

			my $count = 0;
			my @arr;
			foreach ( @varnumbers )
			{
				my $elt = getitem(\@winneritems, $count, 0);
				push ( @arr, $elt );
				$count++;
			}
			$incumbents = [ @arr ];

			$dirfiles{nestclock} = 0;
			callblock
			(	{ countcase => $countcase, countblock => $countblock,
					miditers => \@miditers, varnumbers => \@varnumbers, winneritems => \@winneritems,
					sweeps => \@sweeps, sourcesweeps => \@sourcesweeps,
					incumbents => \%incumbents, dowhat => \%dowhat,
					dirfiles => \%dirfiles, instn => $instn, inst => \%inst, vehicles => \%vehicles } );
		}
	}
	elsif ( ( $target eq "parcoord3d" ) and (@chancedata) and ( $dimchance ) )
	{
		Sim::OPT::Parcoord3d::parcoord3d;
	}

	close(OUTFILE);
	close(TOFILE);
	exit;
} # END

#############################################################################

1;

__END__

=head1 NAME

Sim::OPT.

=head1 SYNOPSIS

  use Sim::OPT;
  opt;

=head1 DESCRIPTION

OPT is an optimization and parametric exploration program favouring problem decomposition. It can be used with simulation programs receiving text files as input and emitting text files as output. Sim::OPT's optimization modules (Sim::OPT, Sim::OPT::Descent) pursue optimization through block search, allowing blocks (subspaces) to overlap, and allowing a free intermix of sequential searches (inexact Gauss-Seidel method) and parallell ones (inexact Jacobi method). The Sim::OPT::Takechange module can seek for the least explored search paths when exploring new search spaces sequentially (following rules presented in: L<Gian Luca Brunetti (2016). “Cyclic overlapping block coordinate search for optimizing building design”. Automation in Construction, 71(2), pp. 242-261, DOI: 10.1016/j.autcon.2016.08.014|http://dx.doi.org/10.1016/j.autcon.2016.08.014>. Sim::OPT::Morph, the morphing module, can manipulate parameters of simulation models.
Other modules under the Sim::OPT namespace are Sim::OPT::Parcoord3d, a module which can convert 2D parallel coordinates plots into Autolisp instructions for obtaining 3D plots as Autocad drawings; and Sim::OPT::Interlinear, which can build metamodels from sparse multidimensional data, and the module Sim::OPT::Modish, capable of altering the shading values calculated with the L<ESP-r buildjng performance simulation platform|http://www.esru.strath.ac.uk/Programs/ESP-r.htm>.
The Sim::OPT's morphing and reporting modules contain several additional functions specifically targeting the ESP-r building performance simulation platform.

To install Sim::OPT, the command <cpanm Sim::OPT> has to be issued as a superuser. Sim::OPT can then be loaded through the command <use Sim::OPT> in a Perl repl. But to ease the launch, the batch file "opt" (which can be found packed in the "optw.tar.gz" file in "examples" folder in this distribution) can be copied in a work directory and the command <opt> may be issued. That command will launch Sim::OPT with the settings specified in the configuration file. When launched, OPT will ask the path to that file, which has to contain a suitable description of the operations to be accomplished and point to an existing simulation model.

The "$mypath" variable in the configuration file must be set to the work directory where the base model reside.

Besides an OPT configuration file, separate configuration files for propagation of constraints may be created. Those files can give the morphing operations greater flexibility. Propagation of constraints can regard the geometry of a model, solar shadings, mass/flow network, controls, and generic text files descripting a simulation model.

The simulation model folders and the result files that will be created in a parametric search will assigned a unique name base on a sequence, but within the program each instance will be assigned a name consituted by numbers describing the position of the instance in the multidimensional matrix (tensor). For example, within the program, the instance produced in the first iteration for a root model named "model" in a search constituted by 3 morphing phases and 5 iteration steps each would be named "model_1-1_2-1_3-1"; and the last one, "model_1-5_2-5_3-5"; while the file may be named "model_1__" and "model_128__". After each program's run, the correspondence between the file names and the instance names is recorded in a file ending with "_cryptolinks.pl"; and there is also an option to keep the file names unencrypted (which can be done if they are not too long).

The structure of the block searches in the configuration file is described through the variable "@sweeps". Each case is listed inside square brackets; and each search subspace (block) in each case is listed inside square brakets. For example: a sequence constituted by two sequential full-factorial force searches, one regarding parameters 1, 2, 3 and the other regarding parameters 1, 4, 5, 7, would be described with: @sweeps = ( [ [ 1, 2, 3 ] ] , [ [ 1, 4, 5, 7 ] ] ) . And a sequential block search with the first subspace regarding parameters 1, 2, 3 and the second regarding parameters 3, 4, 5, 6 would be described with: @sweeps = ( [ [ 1, 2, 3 ] , [ 3, 4, 5, 6 ] ] ).

The number of iterations to be taken into account for each parameter for each case is specified in the "@varnumbers" variable. To specifiy that the parameters of the last example are to be tried for three values (iterations) each, @varnumbers has to be set to ( { 1 => 3, 2 => 3, 3 => 3, 4 => 3, 5 => 3, 6 => 3 } ).

The instance number that has to trated as the basic instance, corresponding to the root case, is specified by the variable "@miditers". "@miditers" for the last example may be for instance set to ( { 1 => 2, 2 => 2, 3 => 2, 4 => 2, 5 => 2, 6 => 2 } ).

OPT can work on a given set of pre-simulated results without launching new simulations, and it can randomize both the sequence of the  search and the initialization level of the parameters (see the included examples).

By default the behaviour of the program is sequential.

OPT can perform star searches (Jacoby method of course, but also Gauss-Seidel) within blocks in place of multilevel full-factorial searches. To ask for that in a configuration file, the first number in a block has to be preceded by a ">" sign, which in its turn has to be preceded by a number specifying how many star points there have to be in the block. A block, in that case, should be declared with something like this: ( "2>1", 2, 3). When operating with pre-simulated dataseries or metamodels, OPT can also perform: factorial searches (to set that, the first number in the concerned block of @sweeps in the configuration file has to be preceded by a "<" sign); and face-centered composite design searches of the DOE type (in that case, that first number has to be preceded by a "£").

For specifying in a Sim::OPT configuration file that a certain block has to be searched by the means of a metamodel derived from star searches or other "positions" instead of a multilevel full-factorial search, it is necessary to assign the value "y" to the variable $dowhat{metamodel}, or to precede the first iteam of a block with the letter "ø".

Sim::OPT is dual-licensed: open-source and proprietary, with the exception of Modish, which is only open-source (GPL v3). The open-source distribution is available on CPAN (https://metacpan.org/dist/Sim-OPT ). The closed-source distribution, including additional modules (OPTcue and related), is available from the author’s website (https://sites.google.com/view/bioclimatic-design/home/software).
Sim::OPT works under Linux. 
=head2 EXPORT

"opt".

=head1 SEE ALSO

Annotated examples (which include "esp.pl" for ESP-r, "ep.pl" for EnergyPlus - the two perform the same morphing operations on models describing the same building -, "des.pl" about block search, and "f.pl" about a search in a pre-simulated dataset, and other) can be found packed in the "optw.tar.gz" file in "examples" directory in this distribution. They constitute all the available documentation besides these pages and the source code. A full example related to ESP-r complete with ESP-r models can be found at the address: L<https://figshare.com/articles/software/greenhouse_archetypes/19664415|https://figshare.com/articles/software/greenhouse_archetypes/19664415>.

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2025 by Gian Luca Brunetti, gianluca.brunetti@gmail.com. This software is distributed under a dual licence, open-source (GPL v3) and proprietary. The present copy is GPL. By consequence, this is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


=cut
