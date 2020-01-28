use strict; use warnings;
package TestML::Run::TAP;

use base 'TestML::Run';

sub run {
  my ($class, $file) = @_;
  $class->new->from_file($file)->test;
  return;
}

sub new {
  my ($class, @params) = @_;
  my $self = $class->SUPER::new(@params);
  ##### TODO
  $self->{count} = 0;

  return $self;
}

sub testml_begin {
  my ($self) = @_;

  $self->{checked} = 0;
  $self->{planned} = 0;
}

sub testml_end {
  my ($self) = @_;

  $self->tap_done
    unless $self->{planned};
}

sub testml_eq {
  my ($self, $got, $want, $label, $not) = @_;
  $self->check_plan;

  if (not $not and
      $got ne $want and
      $want =~ /\n/ and
      (not defined $self->getv('Diff') or $self->getv('Diff')) and
      not($ENV{TESTML_NO_DIFF}) and
      eval { require Text::Diff }
  ) {
    $self->tap_ok(0, $label ? ($label) : ());

    my $diff = Text::Diff::diff(
      \$want,
      \$got,
      {
        FILENAME_A => 'want',
        FILENAME_B => 'got',
      }
    );

    $self->tap_diag($diff);
  }
  elsif ($not) {
    $self->tap_isnt($got, $want, $label ? ($label) : ());
  }
  else {
    $self->tap_is($got, $want, $label ? ($label) : ());
  }
}

sub testml_like {
  my ($self, $got, $want, $label, $not) = @_;
  $self->check_plan;

  if ($not) {
    $self->tap_unlike($got, $want, $label);
  }
  else {
    $self->tap_like($got, $want, $label);
  }
}

sub testml_has {
  my ($self, $got, $want, $label, $not) = @_;
  $self->check_plan;

  my $index = index($got, $want);
  if ($not ? ($index == -1) : ($index != -1)) {
    $self->tap_ok(1, $label);
  }
  else {
    $self->tap_ok(0, $label);
    my $verb = $not ? '   does' : "doesn't";
    $self->tap_diag("     this string: '$got'\n $verb contain: '$want'");
  }
}

sub testml_list_has {
  my ($self, $got, $want, $label) = @_;
  $self->check_plan;

  for my $str (@$got) {
    next if ref $str;
    if ($str eq $want) {
      $self->tap_ok(1, $label);
      return;
    }
  }
  $self->tap_ok(0, $label);
  $self->tap_diag("     this list: @$got\n  doesn't contain: $want");
}

sub check_plan {
  my ($self) = @_;

  return if $self->{checked};
  $self->{checked} = 1;

  if (my $plan = $self->{vars}{Plan}) {
    $self->{planned} = 1;
    $self->tap_plan($plan);
  }
}

sub tap_plan {
  my ($self, $plan) = @_;
  $self->out("1..$plan");
}

sub tap_pass {
  my ($self, $label) = @_;
  $label = '' unless defined $label;
  $label = " - $label" if $label;
  $self->out("ok ${\ ++$self->{count}}$label");
  return;
}

sub tap_fail {
  my ($self, $label) = @_;
  $label = '' unless defined $label;
  $label = " - $label" if $label;
  $self->out("not ok ${\ ++$self->{count}}$label");
  return;
}

sub tap_ok {
  my ($self, $ok, $label) = @_;
  if ($ok) {
    $self->tap_pass($label);
  }
  else {
    $self->tap_fail($label);
  }
}

sub tap_is {
  my ($self, $got, $want, $label) = @_;
  my $ok = $got eq $want;
  if ($ok) {
    $self->tap_pass($label);
  }
  else {
    $self->tap_fail($label);
    $self->show_error(
      '         got:', $got,
      '    expected:', $want,
      $label,
    );
  }
}

sub tap_isnt {
  my ($self, $got, $want, $label) = @_;
  my $ok = $got ne $want;
  if ($ok) {
    $self->tap_pass($label);
  }
  else {
    $self->tap_fail($label);
    $self->show_error(
      '         got:', $got,
      '    expected:', 'anything else',
      $label,
    );
  }
}

sub tap_like {
  my ($self, $got, $want, $label) = @_;
  if ($got =~ $want) {
    $self->tap_pass($label);
  }
  else {
    $self->tap_fail($label);
  }
}

sub tap_unlike {
  my ($self, $got, $want, $label) = @_;
  if ($got !~ $want) {
    $self->tap_pass($label);
  }
  else {
    $self->tap_fail($label);
  }
}

sub tap_diag {
  my ($self, $msg) = @_;
  my $str = $msg;
  $str =~ s/^/# /mg;
  $self->err($str);
}

sub tap_done {
  my ($self) = @_;
  $self->out("1..${\ $self->{count}}");
}

sub show_error {
  my ($self, $got_prefix, $got, $want_prefix, $want, $label) = @_;
  if ($label) {
    $self->err("#   Failed test '$label'");
  }
  else {
    $self->err("#   Failed test");
  }

  if (not ref $got) {
    $got = "'$got'"
  }
  $self->tap_diag("$got_prefix $got");

  if (not ref $want) {
    $want = "'$want'"
  }
  $self->tap_diag("$want_prefix $want");
}

sub out {
  my ($self, $str) = @_;
  local $| = 1;
  binmode STDOUT, ':utf8';
  print STDOUT "$str$/";
}

sub err {
  my ($self, $str) = @_;
  binmode STDERR, ':utf8';
  print STDERR "$str$/";
}

1;
