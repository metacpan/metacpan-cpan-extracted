package RogersMine::App;
use 5.20.0;
use Moo;
use strictures;
use Gtk3;
use RogersMine::MineField;

has rows => (is => 'ro');
has cols => (is => 'ro');
has lives => (is => 'ro');
has risk => (is => 'ro');

has minefield => (is => 'lazy');

sub _build_minefield {
  my $self = shift;
  RogersMine::MineField->new(rows => $self->rows, cols => $self->cols, risk => $self->risk, lives => $self->lives);
}

has info => (is => 'lazy');
has window => (is => 'lazy');

sub _build_info {
  my $self = shift;
  Gtk3::Label->new($self->minefield->lives);
}

sub _build_window {
  my $self = shift;
  my $window = Gtk3::Window->new('toplevel');
  $window->set_title('Minefield');
  my $vbox = Gtk3::VBox->new;
  $vbox->add($self->info);
  for my $i (0..$self->rows-1) {
    my $hbox = Gtk3::HBox->new;
    for my $j (0..$self->cols-1) {
      my $btn = Gtk3::Button->new(' ');
      $btn->signal_connect(clicked => sub { $self->click_btn($i, $j, @_) });
      $hbox->add($btn);
    }
    $vbox->add($hbox);
  }
  $window->add($vbox);
  $window->signal_connect(delete_event => \&quit_fn);
  $window;
}

sub quit_fn {
  Gtk3->main_quit;
  return 0;
}

sub click_btn {
  my ($self, $i, $j, $btn, $evt) = @_;
  my $safe = $self->minefield->click($i, $j);
  if($self->minefield->complete) {
    if($self->minefield->lives > 0) {
      $self->info->set_text("You won with @{[$self->minefield->lives]} remaining");
    } else {
      $self->info->set_text("You Lost");
    }
    return;
  }
  if($safe) {
    $btn->set_label($safe);
  } else {
    $self->info->set_text($self->minefield->lives);
    $btn->set_label('*');
  }
}

1;
