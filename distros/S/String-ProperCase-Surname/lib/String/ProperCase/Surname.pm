package String::ProperCase::Surname;
use strict;
use warnings;
use base qw{Exporter};

our $VERSION   = '0.04';
our @EXPORT    = qw(ProperCase);
our @EXPORT_OK = qw(ProperCase);

=head1 NAME

String::ProperCase::Surname - Converts Surnames to Proper Case

=head1 SYNOPSIS

  use String::ProperCase::Surname;
  print ProperCase($surname);

=head1 DESCRIPTION

The package String::ProperCase::Surname is an L<Exporter> that exports exactly one function called ProperCase.  The ProperCase function is for use on Surnames which handles cases like O'Neal, O'Brien, McLean, etc.

After researching the proper case issues there are three different use cases with a wide variety of loose rules.  This algorithm is customized for surnames.  Other uses such as "TitleCase" and "MenuCase" have different algorithms.  The main difference is that in surnames the letter following an apostrophe is always uppercase (e.g. "O'Brien") in title case and menu case the letter is always lowercase (e.g. "They're").

=head1 USAGE

  use String::ProperCase::Surname;
  print ProperCase($surname);

OR

  require String::ProperCase::Surname;
  print String::ProperCase::Surname::ProperCase($surname);

OR

  use String::ProperCase::Surname qw{};
  *pc=\&String::ProperCase::Surname::ProperCase;
  print pc($surname);

=head1 VARIABLES

=cut

#List of default mixed case surnames (excluding Mc surnames).

our @surname=qw{

AbuArab

DaSilva DeAnda DeAngelo DeBardelaben DeBary DeBaugh DeBeck DeBergh DeBerry
DeBlanc DeBoe DeBoer DeBonis DeBord DeBose DeBostock DeBourge DeBroux DeBruhl
DeBruler DeButts DeCaires DeCamp DeCarolis DeCastro DeCay DeConinck DeCook
DeCoppens DeCorte DeCost DeCosta DeCoste DeCoster DeCouto DeFamio DeFazio DeFee
DeFluri DeFord DeForest DeFraia DeFrange DeFree DeFrees DeGarmo DeGear DeGeare
DeGnath DeGraff DeGraffenreid DeGrange DeGraw DeGrenier DeGroft DeGuaincour
DeHaan DeHaas DeHart DeHass DeHate DeHaven DeHeer DeHerrera DeJarnette DeJean
DeLaet DelAmarre DeLancey DeLara DeLarm DelAshmutt DeLaughter DeLay DeLespine
DelGado DelGaudio DeLong DeLony DeLorenzo DeLozier DelPrincipe DelRosso DeLuca
DeLude DeLuke DeMaio DeMarchi DeMarco DeMarcus DeMarmein DeMars DeMartinis DeMay
DeMello DeMonge DeMont DeMontigny DeMoss DeNunzio DeNure DePalma DePaola
DePasquale DePauli DePerno DePhillips DePoty DePriest DeRatt DeRemer DeRosa
DeRosier DeRossett DeSaegher DeSalme DeShane DeShano DeSilva DeSimencourt
DeSimone DesJardins DeSoto DeSpain DesPlanques DeSplinter DeStefano DesVoigne
DeTurck DeVall DeVane DeVaughan DeVaughn DeVaul DeVault DeVenney DeVilbiss
DeVille DeVillier DeVinney DeVito DeVore DeVorss DeVoto DeVries DeWald DeWall
DeWalt DeWilfond DeWinne DeWitt DeWolf DeYarmett DeYoung DiBenedetto DiCicco
DiClaudio DiClemento DiFrisco DiGiacomo DiGiglio DiGraziano DiGregorio
DiLiberto DiMarco DiMarzo DiPaolo DiPietrantonio DiStefano DoBoto DonSang
DuBois DuBose DuBourg DuCoin DuPre DuPuy

DeVaux DeVoir

EnEarl

FitzJames FitzRandolf

LaBarge LaBarr LaBelle LaBonte LaBounty LaBrue LaCaille LaCasse LaChapelle
LaClair LaCombe LaCount LaCour LaCourse LaCroix LaFarge LaFeuillande LaFlamme
LaFollette LaFontaine LaForge LaForme LaForte LaFosse LaFountain LaFoy LaFrance
LaFuze LaGaisse LaGreca LaGuardia LaHaise LaLande LaLanne LaLiberte LaLonde
LaLone LaMaitre LaMatry LaMay LaMere LaMont LaMotte LaMunyon LaPierre LaPlante
LaPointe LaPorte LaPrade LaPrairie LaQue LaRoche LaRochelle LaRose LaRue
LaSalle LaSance LaSart LaTray LaVallee LaVeau LaVenia LaVigna LeBerth LeBlond
LeBoeuf LeBreton LeCaire LeCapitain LeCesne LeClair LeClaire LeClerc LeCompte
LeConte LeCour LeCrone LeDow LeDuc LeFevre LeFlore LeFors LeFridge LeGrand
LeGras LeGrove LeJeune LeMaster LeMesurier LeMieux LeMoine LePage LeQuire LeRoy
LeStage LeSuer LeVally LeVert LiConti LoManto LoMastro LoRusso

MacAlister MacAlpine MacArthur MacAulay MacAulay MacAuliffe MacBain MacBean
MacBeth MacCallum MacClaine MacCauley MacClelland MacCleery MacCloud MacCord
MacCray MacDonald MacDonnell MacDougall MacDuff MacDuffie MacFadyen MacFarland
MacFarlane MacFie MacGillivray MacGregor MacInnes MacIntyre MacKay MacKenzie
MacKinley MacKinnon Mackintosh MacKinney MacLaine MacLachlan MacLaren
MacLaughlin MacLea MacLean MacLellan MacLeod MacMahon MacMillan MacNab
MacNaught MacNeal MacNeil MacNeill MacNicol MacPhee MacPherson MacQuarrie
MacRae MacShane MacSporran MacTavish MacThomas MacWhirter MacAtee MacCarthy
MacCarty MacCleverty MacCredie MacCue MacCurrach MacEachern MacGilvray MacIvor
MacKechnie MacLennan MacLucas MacManus MacMartin MacNeary MacNevin MacQueen
MacWilliams MaDej MaGaw

SanFillipo SanGalli SantaLucia

TePas

VanArsdale VanBuren VanCamp VanCleave VanDalsem VanderLey VanderNeut VanderTol
VanderWegen VanDerWeyer VanderWilligen VanDevelde VandeWege VanDolah VanDusen
VanDyke VanHee VanHoak VanHook VanHoose VanHouten VanHouwe VanHoven VanKampen
VanKleck VanKleeck VanKuiken VanLanduyt VanLeer VanLiere VanLuven VanMeter
VanOlinda VanOrmer VanPelt VanSchaick VanSciver VanScoy VanScoyk VanSickle
VanTassel VanTuyl VanValkenburg VanVolkenburgh VanWinkle VanWysenberghe
VanZandt VenDerWeyer VonCannon

};

=head2 %surname

You can add or delete custom mixed case surnames to/from this hash. 

Delete

  delete($String::ProperCase::Surname::surname{lc($_)}) foreach qw{MacDonald MacLeod};

Add

  $String::ProperCase::Surname::surname{lc($_)}=$_ foreach qw{DaVis};

Note: All keys are lower case and values are mixed case.

=cut

our %surname=map {lc($_) => $_} @surname;

=head1 FUNCTIONS

=head2 ProperCase

Function returns the correct case given a surname.

  print ProperCase($surname);

Note: All "Mc" last names are assumed to be mixed case.

=cut

sub ProperCase {
  my $string="";
  foreach my $part (split /\b/, shift()) {
    if ($part=~m/^(Mc)([a-z].*)/i) {   #Mc
      $string.=ucfirst(lc($1)) . ucfirst(lc($2));
    } elsif ($surname{lc($part)}) { #MacCleery, DeVaux, etc.
      $string.=$surname{lc($part)};
    } else {
      $string.=ucfirst(lc($part));
    }
  }
  return $string;
}

=head1 LIMITATIONS

Surname default mixed case hash will never be perfect for every implementation.

=head1 AUTHOR

  Michael R. Davis

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Lingua::EN::Titlecase>, L<Spreadsheet::Engine::Function::PROPER>

=cut

1;
