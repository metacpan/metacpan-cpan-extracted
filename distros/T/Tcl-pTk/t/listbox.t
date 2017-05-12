#!/usr/local/bin/perl -w

use Tcl::pTk;
#use Tk;
use Test;
use strict;

plan tests => 7;

my @data = (qw/ Line1 Line2 Line3 ExcessBogosity Huh?/);

my $top = MainWindow->new();
# $top->optionAdd('*Scrollbar.width' => '3.5m');


my $lb  = $top->Listbox();
$lb->insert('end',@data);
$lb->pack(-side => 'left', -expand => 1, -fill => 'both'  );



my @currentValues = $lb->get(0,'end');
#print "current Values = ".join(", ", @currentValues)."\n";

ok(join(" ", @currentValues), 'Line1 Line2 Line3 ExcessBogosity Huh?', 'listbox get check');

my @listVar = (qw/a b c d e f/);

$lb->configure(-listvariable => \@listVar);

@currentValues = $lb->get(0,'end');
#print "current Values = ".join(", ", @currentValues)."\n";

ok(join(" ", @currentValues), 'a b c d e f', 'listbox listvariable set check1');

$listVar[2] = 'JJ';

@currentValues = $lb->get(0,'end');
#print "current Values = ".join(", ", @currentValues)."\n";

ok(join(" ", @currentValues), 'a b JJ d e f', 'listbox listvariable set check2');

# Check for -listvariable having the correct values
my $listVar = $lb->cget(-listvariable);
ok(join(" ", @$listVar), 'a b JJ d e f', 'listbox listvariable return check');


######## Tie Variables to the whole widget Check #####
#### ( As specified in the Tk::Listbox docs      #####

$lb->configure(-listvariable => undef);

my @listVar2 = ();

tie @listVar2, 'Tcl::pTk::Listbox', $lb;

@listVar2 = (qw/a b c d e f/);

@currentValues = $lb->get(0,'end');
#print "current Values = ".join(", ", @currentValues)."\n";

ok(join(" ", @currentValues), 'a b c d e f', 'listbox listvariable set check1');

$listVar2[2] = 'JJ';

@currentValues = $lb->get(0,'end');
#print "current Values = ".join(", ", @currentValues)."\n";
ok(join(" ", @currentValues), 'a b JJ d e f', 'listbox listvariable set check2');

$top->after(1000,sub{$top->destroy});

MainLoop;


ok(1, 1, "Listbox Widget Creation");


