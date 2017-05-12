#!/usr/bin/perl

use Data::Dumper;
use Tree::DAG_Node;
use SVG::Graph;
use SVG::Graph::Data::Tree;


my $lol = 

["START",
[
 "EUBACTERIA",
 [
  "AQUIFEX*",
  [
   "THERMOTOGA*",
   "DEINOCOCCUS*",
   [
    [
     [
      "BACILLUS",
      [
       "BACILLUS"
      ],
      "MYCOPLASMA",
      [
       "MYCOPLASMA_PNEUMONIAE",
       "MYCOPLASMA_GENITALIUM"
      ]
     ],
     "ACTINOBACTERIA",
     [
      "MYCOBACTERIUM*"
     ]
    ],
    [
     "SYNECHOCYSTIS*",
     [
      [
       "SPIROCHAETALES",
       [
        "SPIROCHAETACEAE",
        "TREPONEMA*",
        "BORRELIA*"
       ],
       [
        "CHLAMYDIA",
        "CHLAMYDIA*"
       ]
      ],
      [
       [
        "ALPHA",
        "RICKETTSIA*"
       ],
       [
        "GAMMA",
        [
         "ESCHERICHIA",
         "ESCHERICHIA*",
         "BUCHNERA*"
        ],
        "PSEUDOMONAS*",
        "VIBRIO*",
        "HAEMOPHILUS*",
        "XYLELLA*"
       ],
       [
        "BETA",
        "NEISSERIA*"
       ],
       [
        "EPSILON",
        "HELICOBACTER*",
        "CAMPYLOBACTER*"
       ]
      ]
     ]
    ]
   ]
  ]
 ],
 "ARCHEA+EUKARYA",
 [	
  "ARCHEA",
  [
   [
    "DESULFUROCOCCUS",
    "SULFOLOBUS"
   ],
   [
    [
     "PYROCOCCUS",
     [
      "PYROCOCCUS*"
     ],
     "AEROPYRUM*"
    ],
    [
     "METHANOBACTERIUM*",
     [
      "METHANOCOCCUS*",
      [
       "ARCHAEOGLOBUS*",
       [
        "THERMOPLASMA*",
        "HALOBACTERIUM*"
       ]
      ]
     ]
    ]
   ]
  ],
  "EUKARYA",
  [
  "PROTISTA+PLANT  [DUBIOUS]",
   [
    [
     "GIARDIA",
     "ENTAMOEBA"
    ],
    "PLANTS",
    [
     HUMULUS,
     ORYZA
    ]
   ],
   "FUNGI+ANIMALS",
   [
    "FUNGI",
    [
     "VERTICILLIUM",
     "SACCHAROMYCES"
    ],
    "METAZOAN",
    [
     "SPONGES",
     "EPHYDATIA*",
     "HYDRA*",
     "LYMNAEA*",
     "ARTHROPODA",
     [
      [
       "IXODES*",
       "CALPODES*", 
       "ORNITHODOROS"
      ]
      ,
      "INSECTA",
      [       
       "Lepidoptera",
       [  
        "GALLERIA*",
        "MANDUCA*",
        [
         " BOMBYCOIDEA",
         [
          "BOMBYX_MANDARINA",
          "BOMBYX_MORI",
          "HYALOPHORA*"
         ],
         [
          "ANTHERAEA_PERNYI",
          "ANTHERAEA_YAMAMAI"
         ]
        ]
       ],
       "NILAPARVATA*",
       "DIPTERA",
       [
	"MUSCA",
        [
         ["DROSOPHILA_MELANOGASTER",
          "DROSOPHILA_SIMULANS"],
         "DROSOPHILA_VIRILIS",
         "DROSOPHILA"
        ],     
        "NEMATOCERA",
        [
         "CULICOIDEA",
         [
          "AEDES*",
          "CULEX*",
          "ANOPHELES*"
         ],
         "SCIAROIDEA",
         [
          "RHYNCHOSCIARA*",
          "CHIRONOMUS*"
         ]
        ]
       ]
      ],
      "TIGRIOPUS*",
      "DAPHNIA*",
      "PACIFASTACUS*"
     ],
     "VERTEBRATE+CELEGANS",
     [
      "CAENORHABDITIS*",
      "DEUTEROSTOMA",
      [
       "ECHINODERMS",
       [ 
        "ELEUTHEROZOA".
        [
         "LYTECHINUS*",
         "ECHINIDAE".
         [
          "PARACENTROTUS*",
          "PSAMMECHINUS*"
         ]
        ],
        "ASTEROZOA",
        [
         "PYCNOPODIA*",
         "PISASTER*"
        ]
       ],
      "VERTEBRATES",
      [
       "HYPEROARTIA",
       [
        ["PETROMYZON","LAMPREY"]
       ],
       "GNATHOSTOMATA",
       [
        "SCYLIORHINUS",
        "BONYFISHES",
        [
          "OSTARIOPHYSI",
          [
           ["CATFISH","ICTALURUS*"],
           "CYPRIFORMES",
	   [
            "MISGURNUS*",
            "BARBATULA*",
            "CYPRINIDAE",
            [
             "CATLA*",             
             ["ZEBRAFISH","DANIO*"],
             " CARPS",
             [      
              ["COMMONCARP","CYPRINUS*"],
              ["GRASSCARP","CTENOPHARYNGODON*"],
              "LABEO*"
             ],
	     ["GOLDFISH","CARASSIUS*"]
            ] 
           ]
          ],
          "EUTELEOSTEI",
          [ 
           " SALMONIFORMES",       
           [
            [
             "SALMO*",
             ["TROUT","ONCORHYNCHUS*"]
            ],
            "COREGONUS*"
           ],
          "PERCOMORPHA",
          [
           "PARALICHTHYS*",
          "PERCIFORMES",
           [
            "PERCOIDEI",
            [
             "MORONE*",
             "SERIOLA*",
             "LATES*",
             ["GILTHEADSEABREAM","SPARUS*","PAGRUS*"]
            ],
            ["TILAPIA*","OREOCHROMIS*"],           
            [
             "CHIONODRACO*",
             [
              "NOTOTHENIA_ANGUSTATA",
              "NOTOTHENIA_CORIICEPS"
             ]
            ]
           ],
           [
            ["FUGU","TAKIFUGU*"],
            "TETRAODON*"	    	
           ],
           ["MEDAKA*","ORYZIAS*"]
          ]
         ]
        ],
        "TRETAPODA",
        [
         "AMPHIBIANS",
         [
          [["FROG","XENOPUS*"],"SILURANA*", "RANA"]
         ],
         "AMNIOTA",
         [
          "DABOIA",	
	  "BIRDS",
          [
	   ["SERINUS*","CANARY"],
           [
            ["TURKEY", "MELEAGRIS*"],
	    ["CHICKEN*","GALLUS*"]
           ],
           [
            ["DUCK","ANAS*","CAIRINA*"],
            ["GOOSE","ANSER*"]
           ]
          ],
          "MAMMALS",
          [
           "MONOTREMA",
           [
            "MONOTREMA*"
           ],
           "MARSUPIALS",
           [
            "VOMBATUS*",
            "POSUM"
           ],
           "EUTHERIA",
           [
            "groupIII+groupIV",
            [
             "RODENTS+PRIMATES", "groupIII",
             [
              "RODENT/RABBIT",
              [
               "GLIRES",
               [
                ["RABBIT","LEPUS*","ORYCTOLAGUS*"],
                "RODENTS",
                [
                 [
                  [
                   [
                    [
                     "COTTONRAT",
		     ["RAT","RATTUS*"]
                    ],
                    ["MOUSE","MUS_MUSCULUS"]
                   ],
                   ["MESOCRICETUS*","HAMSTER","CRICETULUS*"]
                  ],
                  [
                   "GLAUCOMYS*",
                   "MARMOT"
                  ]
                 ],
                 "Hystricognathi",
		 [
                  ["PORCUPINE","HYSTRIX*"],
                  ["CAVIA*","GUINEAPIG"]
                 ]                
                ]
               ]
              ],
              "PRIMATES",
              [
               "PRIMATES+SHREWS",
               [
                "SHREWS",
                [
                 "TUPAIA*","SHREW",
                ],
                "PRIMATES",
                [
                 "TARSIUS*",
                 "STREPSIRHINI",
                 ["OTOLEMUR*","PROPITHECUS*"],
                 [
                  "PLATYRRHINI",
                  [
                   [
                    [
                     ["CALLITHRIX*","MARMOSET"],
                     [
                      ["CEBUS*","CAPUCHIN"],
                      ["SQUIRRELMONKEY","SAIMIRI*"]
                     ]
                    ],
                    [
                     "CALLICEBUS*",
                     "AOTUS*"
                    ]
                   ],
                   [
                    [
                     "ATELES_BELZEBUTH",
                     "ATELES_GEOFFROYI"
                    ],
                    [
                     "CACAJO*",
                     "PITHECIA*"
                    ]
                   ],
                   "ALOUATTA*"
                  ],
                  "CATARRHINI",
                  [
     	           ["HYLOBATES*","GIBBON"],
                   [
                    "CERCOPITHECUS*",
                    "CERCOCEBUS*",
                    ["BABOON","PAPIO*"],
                    ["RHESUS","MACACA*"]
                   ],
                   [
                    ["PONGO*","ORANGUTAN"],
                    [
                     "GORILLA*",
                     [
                      ["CHIMP","PAN*"],
                      ["HUMAN","HOMO*"]
                     ]
                    ]
                   ]
                  ]
                 ]
                ]
               ]
              ]
             ],
             "GroupIV",
             [
              "BATS+DERMOPTERA",
              [
               "DERMOPTERA",
               [
                "CYNOCEPHALUS*",
               ],
               "BATS",
               [
                [
                 "CYNOPTERUS*",
                 "PTEROPUS*"
                ],
                [
                 "TAPHOZOUS*",
                 [
                  [
                   "MEGADERMA*",
                   "HIPPOSIDEROS*"
                  ],
                  [
                   "TONATIA*",
                   [
                    "TADARIDA*",
                    "MYOTIS*"
                   ]
                  ]
                 ]
                ]
               ]
              ],
              " DACTYLA+CARNIVORA",
              [
               "CARNIVORA",
               [
                ["SEAL", "HALICHOERUS*"],
                "FISSIPEDIA",
                [
                 "MUSTELA*", 
                 ["CAT","FELIS*"],
                 ["CANIS*","DOG"]
                ]
               ],
               "DACTYLTHINGS",
               [
                "PERISSODACTYLA",
                [
                 ["RHINOCEROS","DICEROS*"],
                 [
                  [
                   "HORSE",
                   "EQUUS_ASINUS",
                   "EQUUS_CABALLUS"
                  ]
                 ]
                ],
                "ARTIODACTYL+CETACEA",
                [
                 "CAMELUS*",
                 "LAMA*",
                 [
		  ["PIG","SUS*"],
                  [
                   "RUMINANTIA", 
	  	   [
                    [
                     [
                      [
                       ["BOS_TAURUS","BOVIN","COW"],
                       "BOS_INDICUS"
                      ],
                      "BOS_GRUNNIENS"
                     ],
                     "BUBALUS*"
                    ],
		    [
                     [
                      ["OVIS*","SHEEP"],
                      ["GOAT","CAPRA*"]
                     ],
                     "DEER",
                     "GAZELLA*"
                    ]
                   ],
                   " HIPPO + CETACEA",
	           [
                    "HIPPOPOTAMUS*",   
                    "CETACEA",
                    [
                     ["DOLPHIN", "TURSIOPS"],
                     [
		      ["SPERMWHALE","PHYSETER*"],
                      ["BLUEWHALE","MEGAPTERA*"]
                     ]
                    ]
                   ]
                  ]
                 ]
                ]
               ]
              ]
             ]
            ]
           ]
          ]
         ]
        ]
       ]
      ]
      ]
     ]
    ]
   ]
  ]
 ]
]
];



my $tree = SVG::Graph::Data::Tree->new;
my $root = $tree->root;

foreach my $node (@$lol){
	if(ref $node){
		descend($node,$root);
	} else {
		$root->name($node);
	}
}

sub descend {
	my($list,$subroot) = @_;

	my $name = '';
	my $c = 0;
	my $d = 0;
	foreach my $node (@$list){
		$c++;
		if(!ref($node)){
			$name = $node;

			if($d + 1 == $c){
				next if ref($list->[$c]);
				my $daughter = $tree->new_node(name=>$list->[$d]);
				$subroot->add_daughter($daughter);
			}

			$d = $c;
			next;
		}


#		$subroot->name($name);

		my $daughter = $tree->new_node(name=>$name);
		$subroot->add_daughter($daughter);
		my $grandchildren = descend($node,$daughter);

	}
}

#warn Dumper($root);

my $tree = SVG::Graph::Data::Tree->new(root=>$root);
my $graph = SVG::Graph->new(width=>1000,height=>800);

my $group = $graph->add_frame;

$group->add_data($tree);
$group->add_glyph('tree');

#print Dumper $graph,"\n";

print $graph->draw;

