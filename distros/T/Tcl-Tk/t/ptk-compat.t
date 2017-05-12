BEGIN { $|=1; $^W=1; }
use strict;
use Test;

BEGIN {
   plan test => 7;
};

use Tcl::Tk;

my $mw;
eval {$mw = Tcl::Tk::MainWindow->new();};
ok($@, "", "can't create MainWindow");
ok(Tcl::Tk::Exists($mw), 1, "MainWindow creation failed");

# Menu
my $menubar = $mw->Frame(-relief => 'raised', -borderwidth => 2)
  ->pack(-fill=>'x');

$menubar->Menubutton(qw/-text File -underline 0 -tearoff 0 -menuitems/ => [
    [Button => '~Open ...',     -accelerator => 'Control+o'],
    [Button => '~New',          -accelerator => 'Control+n'],
    [Button => '~Save',         -accelerator => 'Control+s'],
    [Cascade => '~PerlTk manuals', -tearoff=>0, -menuitems =>
       [
         [Button => '~Overview',          ],
         [Button => '~Standard options',  ],
         [Button => 'Option ~handling',   ],
         [Button => 'Tk ~variables',      ],
         [Button => '~Grab manipulation', ],
         [Button => '~Binding',           ],
         [Button => 'Bind ~tags',         ],
         [Button => '~Callbacks',         ],
         [Button => '~Events',            ],
       ]
    ],
    [Button => 'Save ~As ...', ],
    [Separator => ''],
    [Button => '~Properties ...',  ],
    [Separator => ''],
    [Button => '~Quit',         -accelerator => 'ESC', -command=>sub {print "Quit\n"}],
])->pack(-side=>'left');

$menubar->Menubutton(qw/-text Insert -underline 0 -tearoff 0 -menuitems/ => [
    [Button => '~Before',     ],
    [Button => '~After',      ],
    [Button => '~Sub-widget', ],
])->pack(-side=>'left');


my $menu = $mw->Menu(-menuitems=> [
    [Button => '~Open ...',     -accelerator => 'Control+o'],
    [Button => '~New',          -accelerator => 'Control+n'],
    [Button => '~Save',         -accelerator => 'Control+s'],
    [Cascade => '~PerlTk manuals', -tearoff=>0, -menuitems => [
         [Button => '~Overview',          ],
         [Button => '~Standard options',  ],
         [Button => 'Option ~handling',   ],
         [Button => 'Tk ~variables',      ],
         [Button => '~Grab manipulation', ],
         [Button => '~Binding',           ],
         [Button => 'Bind ~tags',         ],
         [Button => '~Callbacks',         ],
         [Button => '~Events',            ],
       ]
    ],
    [Button => 'Save ~As ...', ],
    [Separator => ''],
    [Button => '~Properties ...',  ],
    [Separator => ''],
    [Button => '~Quit',         -accelerator => 'ESC', -command=>sub {print "Quit\n"}],
]);

my $lab = $mw->Label(-text => "Ring the bell!")->pack;
$mw->bell;
ok($lab->cget("-text"), "Ring the bell!");
$mw->deiconify;
$mw->update;
$mw->raise;
my @kids = $mw->children;
ok(@kids, 3);
my $txt = $kids[2]->cget("-text");
ok($txt , "Ring the bell!");

$mw->configure(-title=>'new title',-cursor=>'star');
$mw->geometry("=800x600-0-0");
ok($mw->cget('-title'), 'new title');
ok($mw->cget('-cursor'), 'star');

$mw->config(-menu=>$menu);

$mw->after(3000,sub{$mw->destroy});
Tcl::Tk::MainLoop;
