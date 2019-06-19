# -*- perl -*-

#### This test case was copied/modified from the Tk-804.029 distribution to work with Tcl::pTk
####

use warnings;
use strict;

use Test::More;


plan tests => 22;


use Tcl::pTk;
use_ok("Tcl::pTk::BrowseEntry");

my $mw;
$mw = MainWindow->new();
eval { $mw->geometry('+10+10'); };
is($@, "", "can create MainWindow");
ok(Tcl::pTk::Exists($mw), "MainWindow creation");

my(@listcmd, @browsecmd);
my $listcmd   = sub { @listcmd = @_ };
my $browsecmd = sub { @browsecmd = @_ };

my( $bla, $be );
eval { $be = $mw->BrowseEntry(-listcmd => $listcmd,
			  -browsecmd => $browsecmd,
			  -textvariable => \$bla,
				 )->pack; };
is("$@", "", "can create BrowseEntry");
ok(Tcl::pTk::Exists($be), "BrowseEntry creation");

$be->insert('end', 1, 2, 3);
is($be->get(0), 1, "correct element in listbox");

$be->idletasks;
# this can "fail" if KDE screen save is up, or user is doing something
# else - such snags are what we should expect when calling binding
# methods directly ...
$be->BtnDown;
ok(@listcmd, "-listcmd");
ok($listcmd[0]->isa('Tcl::pTk::BrowseEntry'), "1st argument in -listcmd");

my $listbox = $be->Subwidget('slistbox')->Subwidget('listbox');
ok($listbox->isa('Tcl::pTk::Listbox'), "listbox subwidget");

$listbox->selectionSet(0);
$listbox->idletasks;

is( $listbox->curselection, 0, "Listbox proper selection");

# These coords will be invalid, because the listbox is not visible,
#   Just exercising the bbox 
my($x, $y) = $listbox->bbox($listbox->curselection);
$be->LbChoose(0, 0);
is(@browsecmd, 2, "-browsecmd");
ok($browsecmd[0]->isa('Tcl::pTk::BrowseEntry'),
   "1st argument in -browsecmd");
is($browsecmd[1], 1, "2nd argument in -browsecmd");

my $be2;
eval { $be2 = $mw->BrowseEntry(-choices => [qw/a b c d e/],
			   -textvariable => \$bla,
			   -state => "normal",
				  )->pack; };
is("$@", "", "create BrowseEntry");
ok(Tcl::pTk::Exists($be2), "BrowseEntry creation");


    # Testcase:
    # From: "Puetz Kevin A" <PuetzKevinA AT JohnDeere.com>
    # Message-ID: <0B4BDC724143544EB509F90F7791EB64026EF8E1@edxmb16.jdnet.deere.com>
    my $var = 'val2';
    my $browse = $mw->BrowseEntry
	(-label => 'test',
	 -listcmd => sub { $_[0]->choices([undef, 'val1','val2']) },
	 -variable => \$var,
	)->pack;
    is($var, 'val2');
    $browse->update;
    $browse->BtnDown;
    $browse->update;
    is($var, 'val2');
    $browse->destroy;


{
    # http://perlmonks.org/?node_id=590170
    my $active_text_color = "#000000";
    my $bgcolor = "#FFFFFF";
    my $text_font = 'helvetica 12';
    my $browse = $mw->BrowseEntry(-label=>'Try Me:',
				  -labelPack=>[qw(-side left -anchor w)],
				  -labelFont=>$text_font,
				  -labelForeground=>$active_text_color,
				  -labelBackground=>$bgcolor,
				  -width=>5,
				  -choices=>[qw(A B C)],
				 )->pack(-side=>'left', -expand=>1, -fill=>'x');
    my @children = $browse->children;
    is(scalar(@children), 3, "Auto-creation of Frame label");
    is((scalar grep { $_->isa("Tcl::pTk::LabEntry") } @children), 1, "Has one LabEntry");
    is((scalar grep { $_->isa("Tcl::pTk::Button")   } @children), 1, "Has one Button");
    is((scalar grep { $_->isa("Tcl::pTk::Toplevel") } @children), 1, "Has one Toplevel");
    is((scalar grep { $_->isa("Tcl::pTk::Label")    } @children), 0, "Has no Label");
}

# Prevent bgerror due to destroying window too early
$mw->idletasks;

MainLoop if (@ARGV);

1;
__END__
