use strict; use warnings;
package TestML::Run::TAP;

use base 'TestML::Run';

use Test::Builder;

# use XXX;

sub run {
  my ($class, $file) = @_;
  $class->new->from_file($file)->test;
  return;
}

sub new {
  my ($class, @params) = @_;
  my $self = $class->SUPER::new(@params);

  $self->{tap} = Test::Builder->new;

  return $self;
}

sub testml_begin {
  my ($self) = @_;

  $self->{checked} = 0;
  $self->{planned} = 0;
}

sub testml_end {
  my ($self) = @_;

  $self->{tap}->done_testing
    unless $self->{planned};
}

sub testml_eq {
  my ($self, $got, $want, $label) = @_;
  $self->check_plan;
  local($SIG{__WARN__}) = sub {$self->{tap}->diag(@_) unless $_[0] =~ /^Wide/};


  if ($got ne $want and
      $want =~ /\n/ and (
        $self->getv('Diff') or
        $self->getp('DIFF')
      )
  ) {
    require Text::Diff;

    $self->{tap}->ok(0, $label ? ($label) : ());

    my $diff = Text::Diff::diff(
      \$want,
      \$got,
      {
        FILENAME_A => 'want',
        FILENAME_B => 'got',
      }
    );

    $self->{tap}->diag($diff);
  }

  else {
    $self->{tap}->is_eq($got, $want, $label ? ($label) : ());
  }
}

sub testml_like {
  my ($self, $got, $want, $label) = @_;
  $self->check_plan;
  local($SIG{__WARN__}) = sub {$self->{tap}->diag(@_) unless $_[0] =~ /^Wide/};

  $self->{tap}->like($got, $want, $label);
}

sub testml_has {
  my ($self, $got, $want, $label) = @_;
  $self->check_plan;
  local($SIG{__WARN__}) = sub {$self->{tap}->diag(@_) unless $_[0] =~ /^Wide/};

  if (index($got, $want) != -1) {
    $self->{tap}->ok(1, $label);
  }
  else {
    $self->{tap}->ok(0, $label);
    $self->{tap}->diag("     this string: $got\n  doesn't contain: $want");
  }
}

sub testml_list_has {
  my ($self, $got, $want, $label) = @_;
  $self->check_plan;
  local($SIG{__WARN__}) = sub {$self->{tap}->diag(@_) unless $_[0] =~ /^Wide/};

  for my $str (@$got) {
    next if ref $str;
    if ($str eq $want) {
      $self->{tap}->ok(1, $label);
      return;
    }
  }
  $self->{tap}->ok(0, $label);
  $self->{tap}->diag("     this list: @$got\n  doesn't contain: $want");
}

sub check_plan {
  my ($self) = @_;

  return if $self->{checked};
  $self->{checked} = 1;

  if (my $plan = $self->{vars}{Plan}) {
    $self->{planned} = 1;
    $self->{tap}->plan(tests => $plan);
  }
}

1;
