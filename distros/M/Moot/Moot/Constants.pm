package Moot;
use Carp;
use strict;

##=====================================================================
## Constants: TokenType

our (%TokType,@TokType);
BEGIN {
  %TokType = (
	      'unknown' => TokTypeUnknown(),
              'vanilla' => TokTypeVanilla(),
              'libxml'  => TokTypeLibXML(),
              'xmlraw'  => TokTypeXMLRaw(),
              'comment' => TokTypeComment(),
              'eos'     => TokTypeEOS(),
              'eof'     => TokTypeEOF(),
              'sb'      => TokTypeSB(),
              'wb'      => TokTypeWB(),
              'user'    => TokTypeUser(),
             );
  @TokType[values %TokType] = keys %TokType;
}

##=====================================================================
## Constants: vlevel
our (%vlevel,@vlevel);
BEGIN {
  %vlevel = (
	     'silent' => vlSilent(),
	     'errors' => vlErrors(),
	     'warnings'  => vlWarnings(),
	     'progress'  => vlProgress(),
	     'everything' => vlEverything(),
	    );
  @vlevel[values %vlevel] = keys %vlevel;
}

##=====================================================================
## Constants: TokenIOFormat

our (%ioFormat,%ioFormatName);
BEGIN {
  %ioFormat = (
	       'none' => tiofNone(),
	       'unknown' => tiofUnknown(),
	       'null' => tiofNull(),
	       'user' => tiofUser(),
	       'native' => tiofNative(),
	       'xml' => tiofXML(),
	       'conserve' => tiofConserve(),
	       'pretty' => tiofPretty(),
	       'text' => tiofText(),
	       'analyzed' => tiofAnalyzed(),
	       'tagged' => tiofTagged(),
	       'pruned' => tiofPruned(),
	       'location' => tiofLocation(),
	       'cost' => tiofCost(),
	       'trace' => tiofTrace(),
	       'rare' => tiofRare(),
	       'mediumrare' => tiofMediumRare(),
	       'medium' => tiofMedium(),
	       'welldone' => tiofWellDone(),
	      );
  @ioFormatName{values %ioFormat} = keys %ioFormat;

  %ioFormat = (##-- aliases
	       %ioFormat,
	       'r'=>tiofRare(),
	       'mr'=>tiofMediumRare(),
	       'm'=>tiofMedium(),
	       'wd'=>tiofWellDone(),
	      );

  ##-- uk spelling variants
  $ioFormat{'analysed'} = $ioFormat{'analyzed'};
  *tiofAnalsed = \&tiofAnalyzed;
}


1; ##-- be happy

__END__

=pod

=head1 NAME

Moot::Constants - libmoot : constants

=head1 SYNOPSIS

  use Moot;

  ##=====================================================================
  ## Constants

  ##------------------------------------------------------------
  ## version
  $version = Moot::library_version();

  ##------------------------------------------------------------
  ## Token Types

  $i = Moot::TokTypeUnknown();  ##-- alias: $Moot::TokType{unknown}
  $i = Moot::TokTypeVanilla();  ##-- alias: $Moot::TokType{vanilla}
  $i = Moot::TokTypeLibXML();   ##-- alias: $Moot::TokType{libxml}
  $i = Moot::TokTypeXMLRaw();   ##-- alias: $Moot::TokType{xmlraw}
  $i = Moot::TokTypeComment();  ##-- alias: $Moot::TokType{comment}
  $i = Moot::TokTypeEOS();      ##-- alias: $Moot::TokType{eos}
  $i = Moot::TokTypeEOF();      ##-- alias: $Moot::TokType{eof}
  $i = Moot::TokTypeSB();       ##-- alias: $Moot::TokType{sb}
  $i = Moot::TokTypeWB();       ##-- alias: $Moot::TokType{wb}
  $i = Moot::TokTypeUser();     ##-- alias: $Moot::TokType{user}
  $name = $Moot::TokType[$i];   ##-- name by index

  ##------------------------------------------------------------
  ## Verbosity Levels

  $i = Moot::vlSilent();        ##-- alias: $Moot::vlevel{silent}
  $i = Moot::vlErrors();        ##-- alias: $Moot::vlevel{errors}
  $i = Moot::vlWarnings();      ##-- alias: $Moot::vlevel{warnings}
  $i = Moot::vlProgress();      ##-- alias: $Moot::vlevel{progress}
  $i = Moot::vlEverything();    ##-- alias: $Moot::vlevel{everything}
  $name = $Moot::vlevel[$i];    ##-- verbosity levels: names by index

  ##------------------------------------------------------------
  ## I/O Formats

  $i = Moot::tiofNone();	##-- alias: $Moot::ioFormat{none}
  $i = Moot::tiofUnknown();	##-- alias: $Moot::ioFormat{unknown}
  $i = Moot::tiofNull();	##-- alias: $Moot::ioFormat{null}
  $i = Moot::tiofUser();	##-- alias: $Moot::ioFormat{user}
  $i = Moot::tiofNative();	##-- alias: $Moot::ioFormat{native}
  $i = Moot::tiofXML();		##-- alias: $Moot::ioFormat{xml}
  $i = Moot::tiofConserve();	##-- alias: $Moot::ioFormat{conserve}
  $i = Moot::tiofPretty();	##-- alias: $Moot::ioFormat{pretty}
  $i = Moot::tiofText();	##-- alias: $Moot::ioFormat{text}
  $i = Moot::tiofAnalyzed();	##-- alias: $Moot::ioFormat{analyzed}, $Moot::ioFormat{analysed}
  $i = Moot::tiofTagged();	##-- alias: $Moot::ioFormat{tagged}
  $i = Moot::tiofPruned();	##-- alias: $Moot::ioFormat{pruned}
  $i = Moot::tiofLocation();	##-- alias: $Moot::ioFormat{location}
  $i = Moot::tiofCost();	##-- alias: $Moot::ioFormat{cost}
  $i = Moot::tiofTrace();	##-- alias: $Moot::ioFormat{trace}
 
  $i = Moot::tiofRare();	##-- alias: $Moot::ioFormat{rare}
  $i = Moot::tiofMediumRare();	##-- alias: $Moot::ioFormat{mediumrare}
  $i = Moot::tiofMedium();	##-- alias: $Moot::ioFormat{medium}
  $i = Moot::tiofWellDone();	##-- alias: $Moot::ioFormat{welldone}
 
  $name = $Moot::ioFormatName{$i};  ##-- I/O formats: names by index

=head1 DESCRIPTION

The Moot module provides an object-oriented interface to the libmoot library
for Hidden Markov Model part-of-speech tagging.

=head1 SEE ALSO

Moot::constants(3perl),
moot(1),
perl(1).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2013 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

