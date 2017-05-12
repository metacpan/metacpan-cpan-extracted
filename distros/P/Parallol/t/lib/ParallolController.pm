package ParallolController;
use Mojo::Base 'Mojolicious::Controller';

sub do_index {
  my $self = shift;
  my $a = 0;
  my $b = 0;

  $self->on_parallol(sub { shift->render(text => $a + $b) } );

  $self->one($self->parallol(weaken => 0, sub {
    $a = pop;
  }));

  $self->one($self->parallol(sub {
    $self->req;
    $b = pop;
  }));
}

sub do_stash {
  my $self = shift;
  $self->on_parallol(sub { shift->render('stash') });

  $self->one($self->parallol('a'));
  $self->one($self->parallol('b'));
}

sub do_nested {
  my $self = shift;

  $self->on_parallol(sub { shift->render('stash') });

  $self->one($self->parallol(sub {
    $self->stash(a => pop);
    $self->one($self->parallol('b'));
  }));
}

sub do_instant {
  my $self = shift;

  $self->on_parallol(sub { shift->render('stash') });

  $self->parallol('a')->(1);
  $self->parallol('b')->(1);
}

sub do_error {
  my $self = shift;
  $self->one($self->parallol(weaken => 0, sub {
    die "oh no";
  }));
}

sub do_error_done {
  my $self = shift;
  $self->on_parallol(sub {
    die "oh no";
  });
  $self->one($self->parallol('one'));
}


1;

