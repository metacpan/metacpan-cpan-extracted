package RogersMine;
use strictures;
use Gtk3;
use RogersMine::App;

BEGIN {
  our $VERSION = 0.1.3;
}

sub main {
  my $window = Gtk3::Window->new('toplevel');
  my $vbox = Gtk3::VBox->new;
  my $rl = Gtk3::Label->new('Rows');
  my $rows = Gtk3::Entry->new;
  $vbox->add($rl);
  $vbox->add($rows);
  my $cl = Gtk3::Label->new('Cols');
  my $cols = Gtk3::Entry->new;
  $vbox->add($cl);
  $vbox->add($cols);
  my $ll = Gtk3::Label->new('Lives');
  my $lives = Gtk3::Entry->new;
  $vbox->add($ll);
  $vbox->add($lives);
  my $rsl = Gtk3::Label->new('Risk');
  my $risk = Gtk3::Entry->new;
  $vbox->add($rsl);
  $vbox->add($risk);
  my $start = Gtk3::Button->new('start');
  $start->signal_connect(clicked => sub { start_game($rows->get_text, $cols->get_text, $lives->get_text, $risk->get_text, @_); });
  $vbox->add($start);
  $window->add($vbox);
  $window->show_all;
}

sub start_game {
  my ($rows, $cols, $lives, $risk, $start) = @_;
  my $app = RogersMine::App->new(rows => $rows, cols => $cols, lives => $lives, risk => $risk);
  $app->window->show_all;
}

1;
