#! /usr/bin/perl -w

# Examples for PostScript::Simple module
# Matthew Newton
# 09 November 2003

use strict;
use lib qw(../lib);
use PostScript::Simple 0.06;

my $ps;
my $eps;
my $directeps;
my $y;

# First, create an EPS file for use later

$ps = new PostScript::Simple(xsize => 100,
                                ysize => 100,
                                colour => 1,
                                eps => 1,
                                reencode => undef);

$ps->setlinewidth(5);
$ps->box(10, 10, 90, 90);
$ps->setlinewidth("thin");
$ps->line(0, 50, 100, 50);
$ps->line(50, 0, 50, 100);
$ps->line(0, 40, 0, 60);
$ps->line(100, 40, 100, 60);
$ps->line(40, 0, 60, 0);
$ps->line(40, 100, 60, 100);
$ps->output("demo-square.eps");

# Let's also create a PostScript::Simple::EPS object directly from it

#$directeps = new PostScript::Simple::EPS(source => $ps->get());
$directeps = $ps->geteps();

undef $ps;

# Now generate the demo document. Start by creating the A4 document.
$ps = new PostScript::Simple(papersize => "a4",
                             units => "mm",
                             colour => 1,
                             eps => 0,
                             reencode => undef);

################################################################################
# PAGE 1
################################################################################

# Create page (EPS import from a file, demo-square.eps)
mynewpage($ps, "EPS import functions (from a file)");
$ps->setfont("Courier", 10);

#-------------------------------------------------------------------------------
# Red example (left)

$ps->setcolour("red");
$ps->box(20, 210, 45, 260);
$ps->importepsfile("demo-square.eps", 20, 210, 45, 260);
$ps->setcolour("darkred");
$ps->text({rotate => -90}, 14, 270, '$ps->importepsfile("demo-square.eps", 20, 210, 45, 260);');

#-------------------------------------------------------------------------------
# Green example (centre)

$ps->setcolour("green");
$ps->box(80, 210, 105, 260);
$ps->importepsfile({stretch => 1}, "demo-square.eps", 80, 210, 105, 260);
$ps->setcolour("darkgreen");
$ps->text({rotate => -90}, 74, 270, '$ps->importepsfile({stretch => 1}, "demo-square.eps", 80, 210, 105, 260);');

#-------------------------------------------------------------------------------
# Blue example (right)

$ps->setcolour("blue");
$ps->box(140, 210, 165, 260);
$ps->importepsfile({overlap => 1}, "demo-square.eps", 140, 210, 165, 260);
$ps->setcolour("darkblue");
$ps->text({rotate => -90}, 134, 270, '$ps->importepsfile({overlap => 1}, "demo-square.eps", 140, 210, 165, 260);');

#-------------------------------------------------------------------------------
# Purple example (bottom)

$ps->setcolour(200, 0, 200);
$ps->box(30, 30, 90, 90);

$eps = new PostScript::Simple::EPS(file => "demo-square.eps", clip => 1);
$eps->scale(60/100);
$eps->translate(50, 50);
$eps->rotate(20);
$eps->translate(-50, -50);
$ps->importeps($eps, 30, 30);
$ps->setfont("Courier", 10);
$y = 90;
$ps->text(100, $y-=5, '$eps = new PostScript::Simple::EPS');
$ps->text(110, $y-=5, '(file => "demo-square.eps");');
$ps->text(100, $y-=5, '$eps->scale(60/100);');
$ps->text(100, $y-=5, '$eps->translate(50, 50);');
$ps->text(100, $y-=5, '$eps->rotate(20);');
$ps->text(100, $y-=5, '$eps->translate(-50, -50);');
$ps->text(100, $y-=5, '$ps->importeps($eps, 30, 30);');


################################################################################
# PAGE 2
################################################################################

# Create page (using generated EPS object)
mynewpage($ps, "EPS import functions (using internal EPS object)");
$ps->setfont("Courier", 10);

$ps->setcolour("red");
$ps->box(20, 210, 45, 260);
#$ps->importepsfile("demo-square.eps", 20, 210, 45, 260);
$directeps->reset();
$directeps->scale(25/$directeps->width());
$ps->importeps($directeps, 20, 210);
$ps->setcolour("darkred");
$ps->text({rotate => -60}, 30, 205, '$directeps->reset();');
$ps->text({rotate => -60}, 25, 205, '$directeps->scale(25/$directeps->width());');
$ps->text({rotate => -60}, 20, 205, '$ps->importeps($directeps, 20, 210);');

$ps->setcolour("green");
$ps->box(80, 210, 105, 260);
#$ps->importepsfile({stretch => 1}, "demo-square.eps", 80, 210, 105, 260);
$directeps->reset();
$directeps->scale(25/$directeps->width(), 50/$directeps->height());
$ps->importeps($directeps, 80, 210);
$ps->setcolour("darkgreen");
$ps->text({rotate => -60}, 90, 205, '$directeps->reset();');
$ps->text({rotate => -60}, 85, 205, '$directeps->scale(25/$directeps->width(), 50/$directeps->height());');
$ps->text({rotate => -60}, 80, 205, '$ps->importeps($directeps, 80, 210);');

$ps->setcolour("blue");
$ps->box(140, 210, 165, 260);
$directeps->reset();
$directeps->scale(50/$directeps->height());
$ps->importeps($directeps, 140, 210);
$ps->setcolour("darkblue");
$ps->text({rotate => -60}, 150, 205, '$directeps->reset();');
$ps->text({rotate => -60}, 145, 205, '$directeps->scale(50/$directeps->height());');
$ps->text({rotate => -60}, 140, 205, '$ps->importeps($directeps, 140, 210);');

$ps->setcolour(200, 0, 200);
$ps->box(30, 30, 90, 90);

$directeps->reset();
$directeps->translate(50, 50);
$directeps->rotate(20);
$directeps->translate(-50, -50);
$eps = new PostScript::Simple(eps => 1, xsize => 100, ysize => 100);
$eps->importeps($directeps, 0, 0);
$directeps = $eps->geteps();
$directeps->scale(60/100);
$ps->importeps($directeps, 30, 30);
$ps->setfont("Courier", 10);
$y = 80;
$ps->text(100, $y-=5, '$directeps->reset();');
$ps->text(100, $y-=5, '$directeps->translate(50, 50);');
$ps->text(100, $y-=5, '$directeps->rotate(20);');
$ps->text(100, $y-=5, '$directeps->translate(-50, -50);');
$ps->text(100, $y-=5, '# round-about way to set clipping path');
$ps->text(100, $y-=5, '$eps = new PostScript::Simple(eps => 1,');
$ps->text(110, $y-=5, 'xsize => 100, ysize => 100);');
$ps->text(100, $y-=5, '$eps->importeps($directeps, 0, 0);');
$ps->text(100, $y-=5, '$directeps = $eps->geteps();');
$ps->text(100, $y-=5, '$directeps->scale(60/100);');
$ps->text(100, $y-=5, '$ps->importeps($directeps, 30, 30);');


################################################################################
# PAGE 3
################################################################################

# Create page (using generated EPS object)
mynewpage($ps, "Using different units");
$ps->setfont("Courier", 10);

$ps->setcolour("red");
$ps->text(20, 268, '$ps->line(20,265, 190,265);  # default units is mm');
$ps->line(20,265, 190,265);

$ps->setcolour("blue");
$ps->text(20, 258, '$ps->setlinewidth("5 pt");');
$ps->text(20, 253, '$ps->line(20,255,  190,255);');
$ps->setlinewidth("5 pt");
$ps->line(20,250, 190,250);

$ps->setcolour("green");
$ps->text(20, 243, '$ps->setlinewidth([0.25, "in");');
$ps->text(20, 238, '$ps->line(20,232,  190,232);');
$ps->setlinewidth([0.25, "in"]);
$ps->line(20,232, 190,232);

$ps->setcolour("purple");
$ps->text(20, 224, '$ps->setlinewidth("thin");  # thin is 0.4 pt');
$ps->text(20, 219, '$ps->line(20,216,  190,216);');
$ps->setlinewidth("thin");
$ps->line(20,216, 190,216);

$y = 210;
for (my $x = 1; $x < 7; $x++) {
  $ps->setlinewidth([8, "dd"]);
  $ps->line([$x, "in"],$y, [$x+1, "in"],$y, 255/$x, 128, 128);
  $ps->setlinewidth("thin");
  $ps->line([$x, "in"],212, [$x, "in"],198, 0,0,0);
  $y -= 2;
}
$ps->line([7, "in"],212, [7, "in"],198, 0,0,0);

$y = 198;
$ps->text(20, $y-=5, '$y = 210;');
$ps->text(20, $y-=5, 'for (my $x = 1; $x < 7; $x++) {');
$ps->text(20, $y-=5, '  $ps->setlinewidth([8, "dd"]);');
$ps->text(20, $y-=5, '  $ps->line([$x, "in"],$y, [$x+1, "in"],$y, 255/$x, 128, 128);  # also set colour');
$ps->text(20, $y-=5, '  $ps->setlinewidth("thin");');
$ps->text(20, $y-=5, '  $ps->line([$x, "in"],212, [$x, "in"],198, 0,0,0);  # set black');
$ps->text(20, $y-=5, '  $y -= 2;');
$ps->text(20, $y-=5, '}');
$ps->text(20, $y-=5, '$ps->line([7, "in"],212, [7, "in"],198, 0,0,0);');


$ps->setlinewidth("15 pt");
$ps->circle(50, "4.5in", "1in");
$ps->setfont("Courier-Bold", 10);
$ps->setcolour("yellow");
$ps->circletext({align => "outside"}, 50, "4.5in", "0.96in", 90, '$ps->setlinewidth("10 pt"); $ps->circle(50, "4.5in", "2in");');
$ps->setcolour("darkred");
$ps->setfont("Courier", 8);
$ps->circletext({align => "outside"}, 50, "4.5in", "0.78in", 90, '$ps->circletext({align => "outside"}, 50, "4.5in", "0.96in", 90, "...");');

# Write out the document.
$ps->output("demo.ps");
                

sub mynewpage
{
  my $ps = shift;
  my $title = shift;

  $ps->newpage;
  $ps->box(10, 10, 200, 287);
  $ps->line(10, 277, 200, 277);
  $ps->setfont("Times-Roman", 14);
  $ps->text(15, 280, "PostScript::Simple example file: $title");
}

