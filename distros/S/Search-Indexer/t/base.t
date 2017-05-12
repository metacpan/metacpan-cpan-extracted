use strict;
use warnings;
use Test::More tests => 8 ;

#use locale;
# (just for these tests, don't use locale so that the results are not
#   platform-dependent). 

BEGIN {use_ok("Search::Indexer");}

my $docs = {

  1 => qq{	Along the city streets
		It is still high tide,
                Yet the garrulous waves of life
		Shrink and divide
		With a thousand incidents
  		Vexed and debated:-
 		This is the hour for which we waited -                },

  2 => qq{	This is the ultimate hour
		When life is justified.
		The seas of experience
		That were so broad and deep
		So immediate and steep,
		Are suddenly still.
		You may say what you will,
		At such peace I am terrified.
		There is nothing else beside.                         },

#===================

  3 => qq{	Within this restless, hurried, modern world
		  We took our hearts' full pleasure - You and I,
  		And now the white sails of our ship are furled,
                  And spent the lading or our argosy.                 },

  4 => qq{ 	Wherefore my cheeks before their time are wan,
                  For very weeping is my gladness fled,
  		Sorrow has paled my young mouth's vermilion,
                  And Ruin draws the curtains of my bed.              },

  5 => qq{	But all this crowded life has been to thee
                  No more than lyre, or lute, or subtle spell
  		Of viols, or the music of the sea
                  That sleeps, a mimic echo, in the shell.            },

#====================

  6 => qq{	Come again:
		That I may cease to mourn
		Through thy unkind disdain
		For now left and forlorn
		I sit, I sigh, I weep, I faint, I die,
		In deadly pain and endless misery.                    },

  7 => qq{	Gentle love,
		Draw forth thy wounding dart,
		Thou canst not pierce her heart
		For I that to approve
		By sights and tears more hot than are thy shafts,
		Did tempt while she for mighty triumph laughs.        },

#====================

  8 => qq{	Rendete agli occhi miei, o fonte, o fiume,
		L'onde della non vostra salda vena,
		Che piu v'innalza e cresce, e con piu lena
		Che non e'l vostro natural costume                    },

  9 => qq{	E tu, folt'aria, che 'l celeste lume
		Porgi ai tristi occhi, dei sospir miei piena,
		Rendi questi al cor lasso, e rasserena
		Tua scura faccia, e'l pur tuo s'allume.               },

  10 => qq{	Renda la terra l'orme alle mie piante,
		L'erba, rigermogliando, che l'e tolta,
		Il suono eco infelice a' miei lamenti;                },

  11 => qq{	Gli sguardi agli occhi miei tue luci sante,
		Ch'io possa altra bellezza un'altra volta
		Amar, se sdegni i miei desiri ardenti                 },

#====================

  12 => qq{	Von Himmel hoch da komm ich her,
		Ich bring' euch gute neue Mähr,
		Der guten Mähr bring ich so viel,
		Davon ich sing'n und sagen will.                      },
 
  13 => qq{	Euch ist ein Kindlein heut' gebor'n 
                Von einer Jungfrau auserkor'n,
		Ein Kindelein so zart und fein,
		Das soll eu'r Freund und Wonne sein.                  },

#====================

  14 => qq{	Oui, ce monde est bien plat; quant à l'autre, sornettes,
		Moi, je vais, résigné, sans espoir, à mon sort
		Et pour tuer le temps, en attendant la mort,
		Je fume, au nez des Dieux, de fines cigarettes.       },

  15 => qq{	Allez, vivants, luttez, pauvres futurs squelettes !
		Moi, le méandre bleu qui vers le ciel se tord
		Me plonge en une extase infinie et m'endort
		Comme aux parfums mourants de mille cassolettes.      },

  16 => qq{	Et j'entre au paradis, fleuri de rêves clairs,
		Où viennent se mêler en valses fantastiques
		Des éléphants en rut à des choeurs de moustiques      },

  17 => qq{	Et puis, quand je m'éveille en songeant à mes vers
		Je contemple, le coeur plein d'une douce joie
		Mon cher pouce rôti comme une cuisse d'oie.           }

};



my $tsts = {

 'life' =>			# just a word
 {'1' => ['...        Yet the garrulous waves of <b>life</b>
		Shrink and divide
		With a thous...'                                      ],
  '2' => ['...	This is the ultimate hour
		When <b>life</b> is justified.
		The seas of experi...'                                ],
  '5' => ['...	But all this crowded <b>life</b> has been to thee
                 ...'                                                 ]},


 'garrulous OR argosy' =>	# did you know those ?
 {'1' => ['...high tide,
                Yet the <b>garrulous</b> waves of life
		Shrink and divide
...'                                                                  ],
  '3' => ['...       And spent the lading or our <b>argosy</b>.                 ...'                                                                 ]},


 '"it is still"' =>		# a sequence of words
 {'1' => ['...	Along the city streets
		<b>It is still</b> high tide,
                Yet the...'                                           ],
  '2' => []},  # wrong; indexer was fooled because 'it' and 'is' are stopwords

 '"occhi miei"' =>		# another sequence
 {'8' => ['...	Rendete agli <b>occhi miei</b>, o fonte, o fiume,
		L\'onde della ...'                                    ],
  '11' => ['...	Gli sguardi agli <b>occhi miei</b> tue luci sante,
		Ch\'io possa altr...'                                 ]},


 '(gute ODER guten) UND Mähr' => # boolean combination
 {'12' => ['...da komm ich her,
		Ich bring\' euch <b>gute</b> neue <b>Mähr</b>,
		Der <b>guten</b> <b>Mähr</b> bring ich so viel,
		Davon ich sin...'                                     ]},


 '+(je j moi) -mon' =>		# booleans through prefixes
 {'16' => ['...	Et <b>j</b>\'entre au paradis, fleuri de rêves ...'   ],
  '15' => ['...tez, pauvres futurs squelettes !
		<b>Moi</b>, le méandre bleu qui vers le ciel ...'     ]}

};


unlink foreach (<*.bdb>);	# remove previous index databases

my $i = new Search::Indexer(	# create indexer

	  writeMode => 1,

# just a couple of examples of stopwords
	  stopwords => [qw(a i o or of it is and are my the)],

# explicit setup of wregex : needed here to be sure to have the same
# results on every platform (the default qr/\w+/ would be locale-dependent).
          wregex => qr/[a-zçáàâäéèêëíìîïóòôöúùûüýÿ]+/i   );

$i->add($_, $docs->{$_}) foreach (keys %$docs);	# index all docs


foreach my $s (keys %$tsts) {
  my $r = $i->search($s);

  my %excerpts;
  foreach (keys %{$r->{scores}}) {
    $excerpts{$_} = $i->excerpts($docs->{$_}, $r->{regex});
  }
  is_deeply(\%excerpts, $tsts->{$s}, $s);
}

my $words_sa = $i->words("sa");
ok(eq_array($words_sa, [qw(sagen sails salda sans sante say)]),
   "words starting with 'sa'");

unlink foreach (<*.bdb>);	# remove index databases
