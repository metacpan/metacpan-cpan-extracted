#!/usr/local/bin/perl -w

# Script to check for popup menu creation using the menubutton  methods

use Tcl::pTk;

use Test;
plan tests => 4;

$| = 1; # Pipes Hot
my $top = MainWindow->new;
#$top->option('add','*Text.background'=>'white');


my $m = $top->Menu();

my $mb = $m->Menubutton(qw/-text File -underline 0 -tearoff 0 -menuitems/ =>
  [
    [Button => '~Open ...',     -accelerator => 'Control+o'],
    [Button => '~New',          -accelerator => 'Control+n'],
    [Button => '~Save',         -accelerator => 'Control+s'],
    ]
    );

# Check to see if Cascade usage works
my $mb2 = $m->Cascade(qw/-label File-Cascade -underline 0 -tearoff 0 -menuitems/ =>
  [
    [Button => '~Open ...',     -accelerator => 'Control+o'],
    [Button => '~New',          -accelerator => 'Control+n'],
    [Button => '~Save',         -accelerator => 'Control+s'],
    ]
    );


my $noEntries = $m->index('end');
my $type = $m->type(1);
#print "Childs = $noEntries, type = $type\n";
ok($noEntries, 2, "Number of entries in the popup");
ok($type, 'cascade', 'Type of menuitem is cascade');


my $mbmenu = $mb->menu();
#print "MB menu = $mbmenu\n";
$noEntries = $mbmenu->index('end');
my @types = map $mbmenu->type($_), (1..2);
#print "Childs = $noEntries, type = $type\n";
ok($noEntries, 2, "Number of entries in the cascade");
ok(join(", ", @types), 'command, command', 'Types of menuitem is cascade');

#print "types = ".join(", ", @types)."\n";

#$m->Post(100,100); # Posting can't be done for the automated test, because it requires clicking the menu
                    #  to get things to continue.

$top->after(1000,sub{
        $top->destroy});
MainLoop;

