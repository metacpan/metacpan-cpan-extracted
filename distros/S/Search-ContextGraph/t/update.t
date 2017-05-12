#!/usr/bin/perl -w

# update.t - make sure that document updates work like we
# expect them to.


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

ok( $g->reweight_graph(), "Reweighted graph" );


my %count;
my @new_doc = qw/feet sex garlic ants/;

$count{$_} = $g->doc_count( $_ ) for @new_doc;

is( $g->update( 'doc-1', \@new_doc ), 1, "Updated correctly" );

foreach my $term ( qw/feet sex garlic/ ) {
	is( $g->doc_count( $term ), $count{$term}, "Doc count remained constant for $term" );
}

is( $g->doc_count( 'ants' ), $count{ants}+1, "Doc count rose for 'ants'" );


my $before = $g->doc_count();
ok( !defined( $g->update( 'doc-xx', [ 'foosball' ] )), "update for nonexistent doc returned undef");
is( $g->doc_count(), $before, "Doc count remained the same");
is( $g->doc_count('foosball'), 0, "Term node did not get inserted" );


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
doc-10,dish,fresh black truffles,truffl,dai,bertineau,serving frozen black truffles,regular menu,valentin,black truffles that costs,truffles that costs,cost,day menu,frozen black truffles,dish of cod,menu,black truffles,philipp,payard,chef at payard,philippe bertineau,cod,chef,cod with fresh black truffles,fresh black truffles that costs,truffles cost
doc-11,european black truffles tuber,last fall,tuber,black truffles tuber melanosporum,truffles tuber melanosporum,european black truffles tuber melanosporum,city this week,mr. urbani,black truffles tuber,york,urbani,wine,franc,tuber melanosporum,season,italian truffles,truffles tuber,season for european black truffles,new york,truffl,dai,new york city,fall,weather,valentin,european black truffles,new york city this week,mr,york city this week,citi,itali,york city,week,weather in france,black truffles,melanosporum
doc-12,pico,tuber,record,truffles tuber magnatum pico,tuber magnatum,pound,magnatum,european,record prices,crop,white truffles tuber magnatum pico,januari,an ounce,white truffles tuber magnatum,tuber magnatum pico,price,fetching record,truffles tuber,truffles tuber magnatum,yesterdai,truffl,case,legendary italian white truffles tuber,legendary italian white truffles,italian white truffles tuber,magnatum pico,white truffles,white truffles tuber,european black truffles,italian white truffles,fetching record prices,few truffles,ounc,black truffles,italian white truffles tuber magnatum a pound,an
doc-13,weekend,stop,scene,cannot,restaurants cannot stop,truffl,truffle scene,restaurants cannot,cannot stop,restaur
doc-14,european black truffle,controversial chinese truffle tuber,controversial chinese truffle tuber indicum,truffl,simpson,tuber,himalayan truffle,truffle tuber,simpson wong,chinese truffle tuber indicum,jefferson,himalayan truffle on the menu,leek,wong,chinese truffle tuber,indicum,ginger,ounc,controversial chinese truffle,menu,asiago cheese,an ounce,black truffle,himalayan,chees,asiago,chef,dumpl,chinese truffle,chive,truffle on the menu,an,tuber indicum,truffle tuber indicum
doc-15,curri,love children,results taste,won tons,ton,truffl,children,peopl,tortellini,children of chinese won tons,children of chinese won,taste like the love,cook,wong,mr,won,italian tortellini,taste like the love children,cooks from nepal,nepal,chinese won,results taste like the love,himalaya,love children of chinese won,tast,chinese won tons,meat,love,mr. wong,result
doc-16,chinese truffles as european ones,cultivated chinese truffles,state,on,two things,been several proven cases,exporting truffles,sold cultivated chinese truffles,european ones,numberless unproven ones in france,franc,numberless,asian truffles,unproven ones in france,things the european truffle,real truffles,ones in france,unproven ones,truffl,case,numberless unproven ones,cours,itali,united states,truffles as european ones,import,proven cases,chinese truffles,several proven cases,unit,european truffle,asian,thing,china,two things the european truffle
doc-17,left,brunswick,splurged on some white truffles,truffles in december,peach in new brunswick,fresh ones,truffl,splurg,all-truffle menu,on,new brunswick,peach,white truffles,all-truffle menu into the off-season,chef at the frog,few left,bruce,frog,egg,rice,white truffles in december,off-season,menu,decemb,bruce lefebvre,lefebvr,chef,menu into the off-season,n.j
doc-18,rest,fresh truffles,rest of the truffle,dai,truffl,truffle menu,matter,white truffles,using white truffles,mr,carpaccio,mr. lefebvre,two-month-old truffle,days of harvest,menu,name,oil,harvest,lefebvr,chef,expert,rest of the truffle menu,yup
doc-19,weeks of truffle,white truffle raviolo,egg yolks,domenico,fresh truffle,butter,weeks of truffle season,truffle shavings,halcyon weeks,white truffle,white,long-established temple of the truffle,raviolo off the menu,egg,blanket of white truffle,yolk,halcyon weeks of truffle season,toni,season,manhattan,truffle raviolo,san,pasta,truffle raviolo off the menu,truffle season,san domenico,custom,truffl,halcyon weeks of truffle,lily-gilding blanket of white truffle,signature white truffle,signature white,lily-gilding blanket,signatur,long-established temple,owner,templ,week,blanket,shave,sheet,menu,temple of the truffle,halcyon,signature white truffle raviolo,sheet of pasta,raviolo,truffle in manhattan,fresh truffle shavings
doc-20,dish,many restaurants,truffl,stockpiles during the short season,truffle butter,butter,short season,stockpil,mr,white-truffle-infused butter,single raviolo costs,cost,white-truffle-infused butter that the restaurant,black truffles,raviolo costs,butter that the restaurant,raviolo,declin,restaur,road,year,season,single raviolo
doc-21,da,butter,lawsuit over the urbani,president of urbani,truffle company,compani,york area until rosario safina,lawsuit,own truffle,domenico model,parti,name,prefabricated truffle butters,largest dealer,largest dealer in truffles,new york area,dealer in truffles,order prefabricated truffle butters,area,new york,da rosario,truffl,presid,new york area until rosario,little competition,million lawsuit over the urbani,order prefabricated truffle,essences from a handful,urbani name,dealer,domenico,model,order prefabricated,competition in the new york,competit,prefabricated truffle,order,essenc,own truffle company,lawsuit over the urbani name,two parties,york,urbani,restaur,truffle butters,york area,most restaurants,san,handful of suppliers,rosario,york area until rosario,area until rosario safina,san domenico,world,million lawsuit,prefabr,safina,supplier,area until rosario,san domenico model,oil,rosario safina,truffle products,hand,product
doc-22,new products like truffle honey,competit,truffle chocolates,dean & deluca,new products like truffle,truffle flour,truffle aroma,aroma,trader joe,dean &,products like truffle,joe,competition over new products,other,& deluca,dean,deluca,chocol,truffle honey,truffl,products like truffle honey,furious competition,honei,furious competition over new products,store,purées,trader,truffle oils,new products,oil,product,flour
doc-23,amenable ingredients like olive oil,soy sauce,porcini mushrooms,own juices,truffle butter,butter,surprising ingredients like soy,white truffle flavor,surprising ingredients like soy sauce,white truffle,ingredients like soy sauce,case of urbani,amenable ingredients,shortest ingredients lists,olive oil,truffle into amenable ingredients,flavor,list,juic,surprising ingredients,small amount of truffle,amount of truffle,ingredients like olive,lefebvr,ingredients like soy,urbani,mushroom,ingredients lists,ingredi,purée,truffl,case,amenable ingredients like olive,sauc,small amount,truffle purée,shortest ingredients,mr,synthetic white truffle,mr. lefebvre,soi,porcini,truffle flavor,oil,amount,truffle products,ingredients like olive oil,oliv,product,synthetic white truffle flavor
doc-24,truffle in a bottle,core,bottl,intens,part,fresh truffle,truffl,peopl,fresh truffle in a bottle,on,intensity of the fresh truffle,tube,first truffle,phrase
doc-25,stori,misti,tree,domest,truffl,trained pig,storied locations,roots of trees,dog for company,human nose,ey,twe,piedmont,truffle hunters,compani,other storied,root,pig,human eye,périgord,hunters in tweed,dawn,truffle hunters in tweed,been domesticated,undetectable by the human nose,part,other storied locations,undetect,wild foods,locat,food,misty dawn,mystiqu,nose,dog,prices in part,price,hunter
doc-26,insects as truffle,flies hover,truffl,connecticut-westchester mycological association,flies hover over the ground,newslett,presid,mycological association,truffle hunters,editor,insect,connecticut-westchester mycological,president of the connecticut-westchester mycological,associ,insects as truffle hunters,fli,hover over the ground,ground,mycolog,spore,connecticut-westchester,hover,hunter,president of the connecticut-westchester,david
doc-27,such chancy methods,provinc,market,truffle spores,time for such chancy,time for such chancy methods,north,oper,chanci,chevali,carolina,yunnan province,saplings with truffle,spore,local saplings with truffle spores,yunnan,gérard,span,tasmania,host of operations,cultivated truffles,such chancy,local saplings,time,operations that span,world,truffl,french scientist,operations that span the globe,scientist,north carolina,roots of local saplings,local saplings with truffle,chancy methods,root,method,saplings with truffle spores,host of operations that span,world market,host,gérard chevalier,globe,span the globe,sapl
doc-28,climate in north,tree,today descendants of those trees,north,same truffles,pound,carolina,pounds of black truffles,franklin,reason,garland,an ounce,franklin garland,climat,last year,truffles last year,hillsborough,climate in north carolina,price,today descendants,betti,n.c,yesterdai,truffl,mrs. garland,descend,north carolina,price yesterday,mr,périgord,ounc,descendants of those trees,black truffles,black truffles last year,todai,year,an
doc-29,freshness of local truffles,tobacco companies,farmers into truffle farmers,hope,truffl,local truffles,american consumers,north,north carolina,ms. garland,compani,settlement money,settlem,monei,tobacco farmers into truffle,tobacco farmers,consum,carolina,truffle farmers,garland,m,fresh,import,farmer,tobacco farmers into truffle farmers,tobacco,american,farmers into truffle
doc-30,truffle tuber oregonense,beard tasted the oregon,tuber,white truffle,piedmont,oregon white truffle,white truffle tuber,oregon white truffle tuber,tasted the oregon,tast,beard tasted,james beard,oregon,white truffle tuber oregonense,beard,white truffle in the world,oregon truffles,oregonens,world,hope,truffl,truffle tuber,tuber oregonense,wheeler,daniel wheeler,jame,daniel,tasted the oregon truffles,james beard tasted the oregon,american hopeful,oregon white truffle tuber oregonense,beard tasted the oregon truffles,james beard tasted,only white truffle,truffle in the world
doc-31,day this year,valentin,black truffles,perfect black truffles,dai,truffl,year
doc-32,many new yorkers,overr,restaurateur behind bond street,few months,street,month,zilliax,truffl,soho restaurant,brooklyn,jonathan,restaurateur,ami,student,graduate student,good news,graduat,new,yorker,brooklyn heights,soho restaurant last year,restaurant last year,height,bond,jonathan morr,last year,soho,morr,restaurateur behind bond,bond street,restaur,year,new yorkers,amy zilliax
doc-33,italian chefs,black truffle,enthusiasm,chef,enthusiasm for truffles,truffl,many italian chefs,toni
doc-34,iodin,lover of black truffles,— dirt,black truffles,truffl,taste like iodine,black truffles taste like iodine,black truffles taste,problem,truffles taste like iodine,lover,tast,dirt,truffles taste
