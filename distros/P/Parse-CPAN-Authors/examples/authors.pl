#!/usr/bin/perl
use warnings;
use strict;

use FindBin qw($Bin);
use Gtk2 -init;
use Gtk2::GladeXML;
use Gtk2::SimpleList;

use constant COLUMN_PAUSEID => 0;
use constant COLUMN_NAME    => 1;
use constant COLUMN_EMAIL   => 2;
use constant NUM_COLUMNS    => 3;

use lib 'lib';
use lib '../lib';
use Parse::CPAN::Authors;
my $p = Parse::CPAN::Authors->new("01mailrc.txt");
my @authors;
foreach my $author (sort { $a->pauseid cmp $b->pauseid } $p->authors) {
  push @authors, {
    pauseid => $author->pauseid,
    name    => $author->name,
    email   => $author->email,
  };
}

my $glade = Gtk2::GladeXML->new($Bin.'/authors.glade');
$glade->signal_autoconnect_from_package('main');

setup();
Gtk2->main;


sub find {
  my $match = $glade->get_widget("entry")->get_text;
  my $treeview = $glade->get_widget('authors');
  $treeview->freeze;
  my $model = create_model($match);
  $treeview->set_model($model);
  $treeview->thaw;
}

sub window_closed {
  exit;
}

sub setup {
  my $treeview = $glade->get_widget('authors');
  add_columns($treeview);
  my $model = create_model();
  $treeview->set_model($model);
}

sub add_columns {
  my $treeview = shift;

  my $column = Gtk2::TreeViewColumn->new_with_attributes(
    "PAUSE id",
    Gtk2::CellRendererText->new,
    text => COLUMN_PAUSEID
  );
  $treeview->append_column($column);

  $column = Gtk2::TreeViewColumn->new_with_attributes(
    "Name",
    Gtk2::CellRendererText->new,
    text => COLUMN_NAME);
  $treeview->append_column($column);

  $column = Gtk2::TreeViewColumn->new_with_attributes(
    "Email",
    Gtk2::CellRendererText->new,
    text => COLUMN_EMAIL
  );
  $treeview->append_column ($column);
}

sub create_model {
  my($match) = @_;
  my $store = Gtk2::ListStore->new (
    'Glib::String',
    'Glib::String',
    'Glib::String',
  );
  foreach my $author (@authors) {
    if ($match) {
      $match = quotemeta $match;
      my $r = qr/$match/i;
      next unless
	($author->{pauseid} =~ $r) ||
	($author->{name} =~ $r) ||
	($author->{email} =~ $r)
	;
    }
    my $iter = $store->append;
    $store->set(
      $iter,
      COLUMN_PAUSEID, $author->{pauseid},
      COLUMN_NAME,    $author->{name},
      COLUMN_EMAIL,   $author->{email},
    );
  }
  return $store;
}
