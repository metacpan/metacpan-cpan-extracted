#!/usr/bin/perl
# ^ to make vim know this is a perl script so I get syntax hilighting.
# $Id: format_identify.pl,v 1.4 2003/05/23 05:02:22 breser Exp $
use strict;
use warnings;
use Irssi;
use Irssi::TextUI;
use Glib;
use POE qw(
	Loop::Glib
);
use POE::Session::Irssi;

our $VERSION = '0.01';
our %IRSSI = (
  authors => 'Martijn van Beers',
  contact => 'martijn@eekeek.org',
  name  => 'clean_backlog',
  description => 'removes everything but MSG_PUBLIC from the backlog',
  license => 'GPL2',
  url   => 'http://example.com/',
);


POE::Session::Irssi->create (
   irssi_signals => {
      "print text" => sub {
	 my $args = $_[ARG1];
	 my $dest = $args->[0];
	 my $window = $dest->{window};

	 return if $window->{refnum} == 1;

	 my $view = $window->view;
	 my $levels = Irssi::settings_get_level('scrollback_levelclear_levels');
	 my $start = my $line = $view->{startline};
	 $line = $line->prev;
	 my $bookmark = $view->get_bookmark('check');
	 my $did_remove;

	 while ($line) {
	    my $line_level = $line->{info}->{level};
	    my $this = $line;
	    $line = $line->prev;
	    if ($levels & $line_level) {
	       $view->remove_line($this);
	       $did_remove = 1;
	    }
	    last if (defined $bookmark and $this->{_irssi} == $bookmark->{_irssi});
	 }
	 $view->set_bookmark('check', $start) if ($did_remove);
      },
   },
);
