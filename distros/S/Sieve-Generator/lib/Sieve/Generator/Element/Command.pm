use v5.36.0;
package Sieve::Generator::Element::Command 0.003;
# ABSTRACT: a single Sieve command statement

use Moo;
with 'Sieve::Generator::Element';

use Params::Util qw(_ARRAY0);

#pod =head1 DESCRIPTION
#pod
#pod A command is a single semicolon-terminated Sieve statement, such as C<stop;>,
#pod C<keep;>, or C<fileinto "Spam";>.  It consists of an identifier followed by
#pod zero or more arguments.
#pod
#pod =attr identifier
#pod
#pod This attribute holds the name of the Sieve command, such as C<stop>,
#pod C<fileinto>, or C<require>.
#pod
#pod =cut

has identifier  => (is => 'ro', required => 1);

#pod =attr semicolon
#pod
#pod This attribute can be set to false during construction to suppress its trailing
#pod semicolon.  This is useful for making tests, which are just commands without
#pod semicolons or blocks after them.
#pod
#pod =cut

has semicolon => (
  is => 'ro',
  default => 1,
);

#pod =attr autowrap
#pod
#pod This attribute can be set false during construction to suppress automatic
#pod multiline formatting if this command runs lone.
#pod
#pod =cut

has autowrap => (
  is => 'ro',
  default => 1,
);

#pod =attr block
#pod
#pod This attribute holds an optional L<Sieve::Generator::Element::Block> to render
#pod after the arguments instead of a semicolon.  This models the Sieve grammar rule
#pod C<command = identifier arguments ( ";" / block )> for commands like
#pod C<foreverypart> that take a block body.  When set, the C<semicolon> attribute
#pod is ignored.
#pod
#pod =cut

has block => (is => 'ro');

#pod =attr tagged_args
#pod
#pod This attribute holds the list of tagged arguments to the command, given as a
#pod hashref.  The values in the hashref will be array references of objects doing
#pod L<Sieve::Generator::Element>, which will follow the tag name.
#pod
#pod The accessor will return a list of pairs.
#pod
#pod =cut

has _tagged_args => (
  is => 'ro',
  default  => sub {  {}  },
  init_arg => 'tagged_args'
);

sub tagged_args ($self) {
  my $tagged_args = $self->_tagged_args;
  return $tagged_args->%{ sort keys %$tagged_args };
}

#pod =attr positional_args
#pod
#pod This attribute holds the list of positional arguments to the command.  Each
#pod argument should be an object doing L<Sieve::Generator::Element>.
#pod
#pod =cut

has _positional_args => (
  is => 'ro',
  default => sub {  []  },
  init_arg => 'positional_args'
);

sub positional_args { $_[0]->_positional_args->@* }

sub children ($self) {
  my @children;

  my @tagged_pairs = $self->tagged_args;
  while (my ($name, $values) = splice @tagged_pairs, 0, 2) {
    push @children, @$values;
  }

  push @children, $self->positional_args;
  push @children, $self->block if $self->block;

  return @children;
}

sub as_sieve ($self, $i = undef) {
  $i //= 0;

  my $oneline = $self->_as_sieve_oneline($i);

  if (!$self->autowrap || length $oneline < 72) {
    return $oneline;
  }

  return $self->_as_sieve_multiline($i);
}

sub _as_sieve_oneline ($self, $i = undef) {
  my $indent = q{  } x ($i // 0);

  my $str = $indent . $self->identifier;

  my @tagged_pairs = $self->tagged_args;
  while (my ($name, $values) = splice @tagged_pairs, 0, 2) {
    $str .= " :$name";
    for my $v (@$values) {
      my $rendered = $v->as_sieve(0);
      $str .= $str =~ /\n\z/ ? $rendered : " $rendered";
    }
  }

  for my $arg ($self->positional_args) {
    my $rendered = $arg->as_sieve(0);
    $str .= $str =~ /\n\z/ ? $rendered : " $rendered";
  }

  if ($self->block) {
    my $blk = $self->block->as_sieve($i // 0);
    $str .= $str =~ /\n\z/ ? $blk : " $blk";
  } elsif ($self->semicolon) {
    $str .= ";";
  }

  return $str;
}

sub _as_sieve_multiline ($self, $i = undef) {
  my $indent  = q{  } x ($i // 0);
  my $indent2 = q{ } x (1 + length $self->identifier);

  my $str = $indent . $self->identifier;
  my $n = 0;

  my @pair_queue = $self->tagged_args;
  for my $i (grep {; $_ % 2 == 0 } keys @pair_queue) {
    $pair_queue[$i] = ":$pair_queue[$i]";
  }

  push @pair_queue, map {; $_->as_sieve(0), [] } $self->positional_args;

  while (my ($name, $values) = splice @pair_queue, 0, 2) {
    $str .= $n++ ? "$indent$indent2" : q{ };
    $str .= "$name";

    if (@$values) {
      $str .= " " . join(q{ }, map {; $_->as_sieve(0) } @$values);
    }

    if (@pair_queue) {
      $str .= "\n";
    } elsif ($self->block) {
      $str .= " " . $self->block->as_sieve($i // 0);
    } elsif ($self->semicolon) {
      $str .= ";";
    }
  }

  return $str;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Element::Command - a single Sieve command statement

=head1 VERSION

version 0.003

=head1 DESCRIPTION

A command is a single semicolon-terminated Sieve statement, such as C<stop;>,
C<keep;>, or C<fileinto "Spam";>.  It consists of an identifier followed by
zero or more arguments.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 ATTRIBUTES

=head2 identifier

This attribute holds the name of the Sieve command, such as C<stop>,
C<fileinto>, or C<require>.

=head2 semicolon

This attribute can be set to false during construction to suppress its trailing
semicolon.  This is useful for making tests, which are just commands without
semicolons or blocks after them.

=head2 autowrap

This attribute can be set false during construction to suppress automatic
multiline formatting if this command runs lone.

=head2 block

This attribute holds an optional L<Sieve::Generator::Element::Block> to render
after the arguments instead of a semicolon.  This models the Sieve grammar rule
C<command = identifier arguments ( ";" / block )> for commands like
C<foreverypart> that take a block body.  When set, the C<semicolon> attribute
is ignored.

=head2 tagged_args

This attribute holds the list of tagged arguments to the command, given as a
hashref.  The values in the hashref will be array references of objects doing
L<Sieve::Generator::Element>, which will follow the tag name.

The accessor will return a list of pairs.

=head2 positional_args

This attribute holds the list of positional arguments to the command.  Each
argument should be an object doing L<Sieve::Generator::Element>.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
