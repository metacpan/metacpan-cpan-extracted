# -*- perl -*-

# This is a empty subclass test on the Menubutton widget

BEGIN { $|=1; $^W=1; }
use strict;
use Test;

BEGIN
  {
   plan test => 8;
  };

use Tcl::pTk;

my $mw;
eval {$mw = MainWindow->new();};
ok($@, "", "can't create MainWindow");
ok(Tcl::pTk::Exists($mw), 1, "MainWindow creation failed");

# Menu
my $menubar = $mw->Frame(-relief => 'raised', -borderwidth => 2, -class => 'menubar')
  ->pack(-fill=>'x');

  $menubar->Menubutton2(qw/-text File -underline 0 -tearoff 0 -menuitems/ =>
  [
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

$menubar->Menubutton(qw/-text Insert -underline 0 -tearoff 0 -menuitems/ =>
  [
    [Button => '~Before',     ],
    [Button => '~After',      ],
    [Button => '~Sub-widget', ],
  ])->pack(-side=>'left');


if (0) { $mw->Menu(-menuitems=>
  [
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
  ]);
}

my $lab = $mw->Label(-text => "Ring the bell!")->pack;
$mw->bell;
ok($lab->cget("-text"), "Ring the bell!");
$mw->deiconify;
$mw->update;
$mw->raise;
my @kids = $mw->children;
ok(@kids, 2);
my $txt = $kids[1]->cget("-text");
ok($txt , "Ring the bell!");

$mw->configure(-title=>'new title',-cursor=>'star');
ok($mw->cget('-title'), 'new title');
ok($mw->cget('-cursor'), 'star');

# Check for mainwindow working
my $mainwindow = $mw->MainWindow();
ok($mw eq $mainwindow);

$mw->after(3000,sub{$mw->destroy});
MainLoop;


BEGIN{
        
#### Empty Menubutton Subclass defined here #####
package Tcl::pTk::Menubutton2;

@Tcl::pTk::Menubutton2::ISA = (qw/ Tcl::pTk::Derived Tcl::pTk::Menubutton/);

Construct Tcl::pTk::Widget 'Menubutton2';

# Options that need to be issued at widget creation
sub CreateOptions
{
 return ( qw/ -menuitems -underline -tearoff -text /);
}


}
