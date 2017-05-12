#!/usr/bin/perl -w

# has.t - check to see whether the document and term existence tests work

use Test::More qw/no_plan/;
use blib;
use strict;
use Search::ContextGraph;


my $g = Search::ContextGraph->new( auto_reweight => 1);

ok( $g, "Created graph object" );

my %docs;


while ( <DATA> ) {
	chomp;
	next unless /doc/;
	my ( $title, @words ) = split /,/, $_;
	$g->add( $title, \@words);
}

ok( $g->has_doc( 'doc-1'), "Found doc 1" );
ok( $g->has_doc( 'doc-9'), "Found doc 9" );
ok( !defined( $g->has_doc( 'doc-11' )), "Nonexistent document is undefined" );
ok( !defined( $g->has_doc( 'doc-101' )), "Nonexistent document is undefined" );

ok( $g->has_term( 'months-old black truffle'), "Found 'months-old black truffle'" );
ok( $g->has_term( 'ravioli'), "Found 'ravioli'" );
is($g->has_term( 'moustache' ), undef , "Nonexistent term is undefined" );
ok( !defined( $g->has_term( 'snake eyes' )), "Nonexistent term is undefined" );

########

__DATA__

doc-1,feet,sex,garlic
doc-2,white truffle oil,cult of the truffle,today the frenzy,defenseless foods,truffle oil,anyon,white truffle,kinds of defenseless foods,pink truffles,libya,slathered in black truffle cream,truffle cream,roman,indescrib,romans lusted,drizzled with white truffle,slathered in black truffle,black truffle cream,babylon,present-day libya,smell of a truffle,truffl,dai,drizzled with white truffle oil,sauc,kind,cream,cult,slather,valentin,drizzl,romans lusted after pink truffles,lust,cream sauce,lusted after pink truffles,peak every valentine,peak,black truffle,oil,smell,food,frenzi,truffle cream sauce,todai,black truffle cream sauce
doc-3,ravioli,dinner cruises,sauce for the holiday,dinner cruises in new york,cruises in new york,payard bistro truffled ravioli,payard bistro,world yacht,truffled crostini,holidai,making truffled,making truffled omelets,bistro truffled ravioli,yacht,york,dinner,cruis,crostini,payard bistro truffled,truffle sauce for the holiday,saturdai,new york,world,truffl,truffle sauce,sauc,holiday on saturday,steak,cruises in new york harbor,new york harbor,ouest,truffled steak,york harbor,truffled omelets,payard,truffled ravioli,bistro truffled,bistro,omelet,harbor

doc-4,passion for digging,human,hormone secreted,digging truffles that verges,weird foods —,foods — caviar,kitchen,behavior in female pigs,male pigs,passion,source of the truffle,erotic allure,oyster,adult,digging truffles,secreted by humans,adult section,oysters — the truffle,weird foods,concentr,truffles that verges,hormon,foods —,higher concentrations,dig,hunter,sourc,caviar,passion for digging truffles,androstenol,research,— caviar,truffl,section,inspir,find,erot,scientist,truffle hunters,pig,hormone secreted by humans,adult section of the kitchen,verg,allur,much higher concentrations,secret,oysters —,inspires rutting behavior,behavior,instanc,food,section of the kitchen,rutting behavior in female pigs,weird foods — caviar,rutting behavior,female pigs,german researchers,— the truffle

doc-5,busi,family business,certain pop,america,item,usa,restaurant menus,truffle importer,certain pop singers,item on restaurant,largest truffle,abused item on restaurant,urbani,item on restaurant menus,restaur,modern truffle,most abused item,appeal,truffl,erotic appeal through overexposure,richard,erot,largest truffle importer,urbani usa,abused item on restaurant menus,famili,menu,pop singers,most abused item on restaurant,import,erotic appeal,singer,richard urbani,abused item,pop,appeal through overexposure,overexposur
doc-6,new restaurant in the time,martini at mix,modest destinations like luxia,fresh black truffles,hot spot,miniature b.l.t. sandwiches,maki at the hot spot,time warner center,spot geisha,opening party,monei,vodka,tuna maki,warner center,keller,parti,giorgio,domicil,restaurant in the time,miniature b.l.t.,open,york,time warner,days drizzled,modest destinations,restaur,mix in new york,destin,hot spot geisha,time,new york,geisha,dai,truffl,center,destinations like luxia,sandwich,b.l.t. sandwiches,restaurant in the time warner,sandwiches at the opening,luxia,thomas keller,drizzl,gramerci,b.l.t,b.l.t. sandwiches at the opening,martini,black truffles,maki,spot,mix,thoma,warner,tuna,sandwiches at the opening party,new restaurant
doc-7,truffle-impersonators months-old black truffle,canned truffle slices,truffle carpaccio canned truffle,slice,butter,truffle butter,north,canned truffle,carolina,italy —,truffle carpaccio,black truffle butter,franc,truffle-impersonators,truffle-impersonators months-old black truffle butter,months-old black truffle butter,truffle carpaccio canned truffle slices,truffle slices,dai,truffl,host of truffle-impersonators,north carolina,valentin,carpaccio,day menus,itali,menu,months-old black truffle,import,host,black truffle,carpaccio canned truffle slices,carpaccio canned truffle,china
doc-8,most synthetic,white truffle oil,artificial truffle,popular form,form,truffl,truffle oil,such substitutes,synthetic all white truffle oil,white truffle,real product for aroma,aroma,substitut,most popular form,flavor,product for aroma,truffle flavor,oil,most synthetic all white truffle,chef,real product,product,artificial truffle flavor,synthetic all white truffle,synthet
doc-9,truffles in new york,fresh truffles in new york,new york,caviar,fresh truffles,restaurant patrons,foie gras,truffl,dai,budget,wise restaurant patrons,new york these days,redirect,valentin,availability of fresh truffles,day budget into foie gras,foie,day budget,york these days,wise restaurant,day budget into foie,avail,york,gra,budget into foie,restaur,budget into foie gras,patron