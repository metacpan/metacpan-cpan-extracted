#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);
use lib $FindBin::Bin;
use ANSIMenu;

sub exec_item {
  my $itemnr = shift;

  print "Executing item";
  print " ($itemnr)" if defined $itemnr;
  print "...\n";
  sleep 1;
}

sub help_item {
  my $itemnr = shift;

  print "Item help";
  print " ($itemnr)" if defined $itemnr;
  print "...\n";
  sleep 1;
}

sub standard_help {
  my $itemnr = shift;

  print "Standard help";
  print " ($itemnr)" if defined $itemnr;
  print "...\n";
  sleep 1;
}

my $menu = Term::ANSIMenu->new(width  => 40,
                               help   => [['', \&standard_help],
                                          ['hint 1', \&help_item],
                                          [ '', \&standard_help],
                                          ['hint 3', undef]
                                         ],
                               title  => 'title',
                               items  => [['1', 'First menu item', \&exec_item],
                                          ['2', 'This string is just too long to fit in the normal terminal width and thus it will be clipped.'],
                                          ['3', '', sub { system "man man" }]
                                         ],
                               status => 'status',
                               prompt => 'prompt: ');

$menu->print_menu();
while (my $key = $menu->read_key()) {
  last unless defined $menu->do_key($key);
  $menu->update_status('') if $key eq 'S';
  $menu->update_status('New status') if $key eq 's';
  $menu->update_prompt('') if $key eq 'P';
  $menu->update_prompt('New prompt: ') if $key eq 'p';
}
$menu->pos($menu->line_after_menu() + 1, 1);

