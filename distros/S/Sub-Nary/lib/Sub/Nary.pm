package Sub::Nary;

use 5.008001;

use strict;
use warnings;

use Carp qw/croak/;

use B qw/class ppname svref_2object OPf_KIDS/;

=head1 NAME

Sub::Nary - Try to count how many elements a subroutine can return in list context.

=head1 VERSION

Version 0.03

=cut

our $VERSION;
BEGIN {
 $VERSION  = '0.03';
}

=head1 SYNOPSIS

    use Sub::Nary;

    my $sn = Sub::Nary->new();
    my $r  = $sn->nary(\&hlagh);

=head1 DESCRIPTION

This module uses the L<B> framework to walk into subroutines and try to guess how many scalars are likely to be returned in list context. It's not always possible to give a definitive answer to this question at compile time, so the results are given in terms of "probability of return" (to be understood in a sense described below).

=head1 METHODS

=head2 C<new>

The usual constructor. Currently takes no argument.

=head2 C<nary $coderef>

Takes a code reference to a named or anonymous subroutine, and returns a hash reference whose keys are the possible numbers of returning scalars, and the corresponding values the "probability" to get them. The special key C<'list'> is used to denote a possibly infinite number of returned arguments. The return value hence would look at

    { 1 => 0.2, 2 => 0.4, 4 => 0.3, list => 0.1 }

that is, we should get C<1> scalar C<1> time over C<5> and so on. The sum of all values is C<1>. The returned result, and all the results obtained from intermediate subs, are cached into the object.

=head2 C<flush>

Flushes the L<Sub::Nary> object cache. Returns the object itself.

=head1 PROBABILITY OF RETURN

The probability is computed as such :

=over 4

=item * When branching, each branch is considered equally possible.

For example, the subroutine

    sub simple {
     if (rand < 0.1) {
      return 1;
     } else {
      return 2, 3;
     }
    }

is seen returning one or two arguments each with probability C<1/2>.
As for

    sub hlagh {
     my $x = rand;
     if ($x < 0.1) {
      return 1, 2, 3;
     } elsif ($x > 0.9) {
      return 4, 5;
     }
    }

it is considered to return C<3> scalars with probability C<1/2>, C<2> with probability C<1/2 * 1/2 = 1/4> and C<1> (when the two tests fail, the last computed value is returned, which here is C<< $x > 0.9 >> evaluated in the scalar context of the test) with remaining probability C<1/4>.

=item * The total probability law for a given returning point is the convolution product of the probabilities of its list elements.

As such, 

    sub notsosimple {
     return 1, simple(), 2
    }

returns C<3> or C<4> arguments with probability C<1/2> ; and

    sub double {
     return simple(), simple()
    }

never returns C<1> argument but returns C<2> with probability C<1/2 * 1/2 = 1/4>, C<3> with probability C<1/2 * 1/2 + 1/2 * 1/2 = 1/2> and C<4> with probability C<1/4> too.

=item * If a core function may return different numbers of scalars, each kind is considered equally possible.

For example, C<stat> returns C<13> elements on success and C<0> on error. The according probability will then be C<< { 0 => 0.5, 13 => 0.5 } >>.

=item * The C<list> state is absorbing in regard of all the other ones.

This is just a pedantic way to say that "list + fixed length = list".
That's why

    sub listy {
     return 1, simple(), @_
    }

is considered as always returning an unbounded list.

Also, the convolution law does not behave the same when C<list> elements are involved : in the following example,

    sub oneorlist {
     if (rand < 0.1) {
      return 1
     } else {
      return @_
     }
    }

    sub composed {
     return oneorlist(), oneorlist()
    }

C<composed> returns C<2> scalars with probability C<1/2 * 1/2 = 1/4> and a C<list> with probability C<3/4>.

=back

=cut

BEGIN {
 require XSLoader;
 XSLoader::load(__PACKAGE__, $VERSION);
}

sub _check_self {
 croak 'First argument isn\'t a valid ' . __PACKAGE__ . ' object'
  unless ref $_[0] and $_[0]->isa(__PACKAGE__);
}

sub new {
 my $class = shift;
 $class = ref($class) || $class || __PACKAGE__;
 bless { cache => { } }, $class;
}

sub flush {
 my $self = shift;
 _check_self($self);
 $self->{cache} = { };
 $self;
}

sub nary {
 my $self = shift;
 my $sub  = shift;

 $self->{cv} = [ ];
 return ($self->enter(svref_2object($sub)))[1];
}

sub name ($) {
 local $SIG{__DIE__} = \&Carp::confess;
 my $n = $_[0]->name;
 $n eq 'null' ? substr(ppname($_[0]->targ), 3) : $n
}

sub power {
 my ($p, $n, $c) = @_;
 return unless defined $p;
 return { 0 => $c } unless $n;
 if ($n eq 'list') {
  my $z = delete $p->{0};
  return { 'list' => $c } unless $z;
  return { 0      => $c } if $z == 1;
  return { 0 => $c * $z, list => $c * (1 - $z) };
 }
 my $r = combine map { { %$p } } 1 .. $n;
 $r->{$_} *= $c for keys %$r;
 return $r;
}

my %ops;

$ops{$_} = 1      for scalops;
$ops{$_} = 0      for qw/stub nextstate pushmark iter unstack/;
$ops{$_} = 1      for qw/padsv/;
$ops{$_} = 'list' for qw/padav/;
$ops{$_} = 'list' for qw/padhv rv2hv/;
$ops{$_} = 'list' for qw/padany/;
$ops{$_} = 'list' for qw/match entereval readline/;

$ops{each}      = { 0 => 0.5, 2 => 0.5 };
$ops{stat}      = { 0 => 0.5, 13 => 0.5 };

$ops{caller}    = sub { my @a = caller 0; scalar @a }->();
$ops{localtime} = do { my @a = localtime; scalar @a };
$ops{gmtime}    = do { my @a = gmtime; scalar @a };

$ops{$_} = { 0 => 0.5, 10 => 0.5 } for map "gpw$_", qw/nam uid ent/;
$ops{$_} = { 0 => 0.5, 4 => 0.5 }  for map "ggr$_", qw/nam gid ent/;
$ops{$_} = 'list'                  for qw/ghbyname ghbyaddr ghostent/;
$ops{$_} = { 0 => 0.5, 4 => 0.5 }  for qw/gnbyname gnbyaddr gnetent/;
$ops{$_} = { 0 => 0.5, 3 => 0.5 }  for qw/gpbyname gpbynumber gprotoent/;
$ops{$_} = { 0 => 0.5, 4 => 0.5 }  for qw/gsbyname gsbyport gservent/;

sub enter {
 my ($self, $cv) = @_;

 return undef, 'list' if class($cv) ne 'CV';
 my $op  = $cv->ROOT;
 my $tag = tag($op);

 return undef, { %{$self->{cache}->{$tag}} } if exists $self->{cache}->{$tag};

 # Anything can happen with recursion
 for (@{$self->{cv}}) {
  return undef, 'list' if $tag == tag($_->ROOT);
 }

 unshift @{$self->{cv}}, $cv;
 my $r = add $self->inspect($op->first);
 shift @{$self->{cv}};

 $r = { $r => 1 } unless ref $r;
 $self->{cache}->{$tag} = { %$r };
 return undef, $r;
}

sub inspect {
 my ($self, $op) = @_;

 my $n = name($op);
 return add($self->inspect_kids($op)), undef if $n eq 'return';

 my $meth = $self->can('pp_' . $n);
 return $self->$meth($op) if $meth;

 if (exists $ops{$n}) {
  my $l = $ops{$n};
  $l = { %$l } if ref $l;
  return undef, $l;
 }

 if (class($op) eq 'LOGOP' and not null $op->first) {
  my @res;

  my $op = $op->first;
  my ($r1, $l1) = $self->inspect($op);
  return $r1, $l1 if defined $r1 and zero $l1;
  my $c = count $l1;

  $op = $op->sibling;
  my ($r2, $l2) = $self->inspect($op);

  $op = $op->sibling;
  my ($r3, $l3);
  if (null $op) {
   # If the logop has no else branch, it can also return the *scalar* result of
   # the conditional
   $l3 = { 1 => 1 };
  } else {
   ($r3, $l3) = $self->inspect($op);
  }

  my $r = add $r1, scale $c / 2, add $r2, $r3;
  my $l = scale $c / 2, add $l2, $l3;
  return $r, $l
 }

 return $self->inspect_kids($op);
}

sub inspect_kids {
 my ($self, $op) = @_;

 return undef, 0 unless $op->flags & OPf_KIDS;

 $op = $op->first;
 return undef, 0 if null $op;
 if (name($op) eq 'pushmark') {
  $op = $op->sibling;
  return undef, 0 if null $op;
 }

 my ($r, @l);
 my $c = 1;
 for (; not null $op; $op = $op->sibling) {
  my $n = name($op);
  if ($n eq 'nextstate') {
   @l  = ();
   next;
  }
  if ($n eq 'lineseq') {
   @l  = ();
   $op = $op->first;
   redo;
  }
  my ($rc, $lc) = $self->inspect($op);
  $c = 1 - count $r;
  $r = add $r, scale $c, $rc if defined $rc;
  if (not defined $lc) {
   @l = ();
   last;
  }
  push @l, scale $c, $lc;
 }

 my $l = scale +(1 - count $r), normalize combine @l;

 return $r, $l;
}

# Stolen from B::Deparse

sub padval { $_[0]->{cv}->[0]->PADLIST->ARRAYelt(1)->ARRAYelt($_[1]) }

sub gv_or_padgv {
 my ($self, $op) = @_;
 if (class($op) eq 'PADOP') {
  return $self->padval($op->padix)
 } else { # class($op) eq "SVOP"
  return $op->gv;
 }
}

sub const_sv {
 my ($self, $op) = @_;
 my $sv = $op->sv;
 # the constant could be in the pad (under useithreads)
 $sv = $self->padval($op->targ) unless $$sv;
 return $sv;
}

sub pp_entersub {
 my ($self, $op) = @_;

 $op = $op->first while $op->flags & OPf_KIDS;
 return undef, 0 if null $op;
 if (name($op) eq 'pushmark') {
  $op = $op->sibling;
  return undef, 0 if null $op;
 }

 my $r;
 my $c = 1;
 for (; not null $op->sibling; $op = $op->sibling) {
  my ($rc, $lc) = $self->inspect($op);
  return $rc, $lc if defined $rc and not defined $lc;
  $r = add $r, scale $c, $rc;
  $c *= count $lc;
 }

 if (name($op) eq 'rv2cv') {
  my $n;
  do {
   $op = $op->first;
   my $next = $op->sibling;
   while (not null $next) {
    $op   = $next;
    $next = $next->sibling;
   }
   $n  = name($op)
  } while ($op->flags & OPf_KIDS and { map { $_ => 1 } qw/null leave/ }->{$n});
  return 'list', undef unless { map { $_ => 1 } qw/gv refgen/ }->{$n};
  local $self->{sub} = 1;
  my ($rc, $lc) = $self->inspect($op);
  return $r, scale $c, $lc;
 } else {
  # Method call ?
  return $r, { 'list' => $c };
 }
}

sub pp_gv {
 my ($self, $op) = @_;

 return $self->{sub} ? $self->enter($self->gv_or_padgv($op)->CV) : (undef, 1)
}

sub pp_anoncode {
 my ($self, $op) = @_;

 return $self->{sub} ? $self->enter($self->const_sv($op)) : (undef, 1)
}

sub pp_goto {
 my ($self, $op) = @_;

 my $n = name($op);
 while ($op->flags & OPf_KIDS) {
  my $nop = $op->first;
  my $nn  = name($nop);
  if ($nn eq 'pushmark') {
   $nop = $nop->sibling;
   $nn  = name($nop);
  }
  if ($n eq 'rv2cv' and $nn eq 'gv') {
   return $self->enter($self->gv_or_padgv($nop)->CV);
  }
  $op = $nop;
  $n  = $nn;
 }

 return undef, 'list';
}

sub pp_const {
 my ($self, $op) = @_;

 return undef, 0 unless $op->isa('B::SVOP');

 my $sv = $self->const_sv($op);
 my $n  = 1;
 my $c  = class($sv);
 if ($c eq 'AV') {
  $n = $sv->FILL + 1
 } elsif ($c eq 'HV') {
  $n = 2 * $sv->KEYS
 }

 return undef, $n
}

sub pp_aslice { $_[0]->inspect($_[1]->first->sibling) }

sub pp_hslice;
*pp_hslice = *pp_aslice{CODE};

sub pp_lslice { $_[0]->inspect($_[1]->first) }

sub pp_rv2av {
 my ($self, $op) = @_;
 $op = $op->first;

 if (name($op) eq 'gv') {
  return undef, { list => 1 };
 }

 $self->inspect($op);
}

sub pp_aassign {
 my ($self, $op) = @_;

 $op = $op->first;

 # Can't assign to return
 my $l = ($self->inspect($op->sibling))[1];
 return undef, $l if not exists $l->{list};

 $self->inspect($op);
}

sub pp_leaveloop {
 my ($self, $op) = @_;

 $op = $op->first;
 my ($r1, $l1);
 my $for;
 if (name($op) eq 'enteriter') { # for loop ?
  $for = 1;
  ($r1, $l1) = $self->inspect($op);
  return $r1, $l1 if defined $r1 and zero $l1;
 }

 $op = $op->sibling;
 my ($r2, $l2);
 if (name($op->first) eq 'and') {
  ($r2, $l2) = $self->inspect($op->first->first);
  return $r2, $l2 if defined $r2 and zero $l2;
  my $c = count $l2;
  return { list => 1 }, undef if !$for and defined $r2;
  my ($r3, $l3) = $self->inspect($op->first->first->sibling);
  return { list => 1 }, undef if defined $r3 and defined $l3;
  $r2 = add $r2, scale $c, $r3;
 } else {
  ($r2, $l2) = $self->inspect($op);
  return { list => 1 }, undef if defined $r2 and defined $l2;
 }

 my $r = (defined $r1) ? add $r1, scale +(1 - count $r1), $r2
                       : $r2;
 my $c = 1 - count $r;
 return $r, $c ? { 0 => $c } : undef;
}

sub pp_flip {
 my ($self, $op) = @_;

 $op = $op->first;
 return $self->inspect($op) if name($op) ne 'range';

 my ($r, $l);
 my $begin = $op->first;
 if (name($begin) eq 'const') {
  my $end = $begin->sibling;
  if (name($end) eq 'const') {
   $begin = $self->const_sv($begin);
   $end   = $self->const_sv($end);
   {
    no warnings 'numeric';
    $begin = int ${$begin->object_2svref};
    $end   = int ${$end->object_2svref};
   }
   return undef, $end - $begin + 1;
  } else {
   ($r, $l) = $self->inspect($end);
  }
 } else {
  ($r, $l) = $self->inspect($begin);
 }

 my $c = 1 - count $r;
 return $r, $c ? { 'list' => $c } : undef
}

sub pp_grepwhile {
 my ($self, $op) = @_;

 $op = $op->first;
 return $self->inspect($op) if name($op) ne 'grepstart';
 $op = $op->first->sibling;

 my ($r2, $l2) = $self->inspect($op->sibling);
 return $r2, $l2 if defined $r2 and zero $l2;
 my $c2 = count $l2; # First one to happen

 my ($r1, $l1) = $self->inspect($op);
 return (add $r2, scale $c2, $r1), undef if defined $r1 and zero $l1
                                                        and not zero $l2;
 my $c1 = count $l1;

 $l2 = { $l2 => 1 } unless ref $l2;
 my $r = add $r2,
          scale $c2,
            add map { scale $l2->{$_}, cumulate $r1, $_, $c1 } keys %$l2;
 my $c = 1 - count $r;
 return $r, $c ? { ((zero $l2) ? 0 : 'list') => $c } : undef;
}

sub pp_mapwhile {
 my ($self, $op) = @_;

 $op = $op->first;
 return $self->inspect($op) if name($op) ne 'mapstart';
 $op = $op->first->sibling;

 my ($r2, $l2) = $self->inspect($op->sibling);
 return $r2, $l2 if defined $r2 and zero $l2;
 my $c2 = count $l2; # First one to happen

 my ($r1, $l1) = $self->inspect($op);
 return (add $r2, scale $c2, $r1), undef if defined $r1 and zero $l1
                                                        and not zero $l2;
 my $c1 = count $l1;

 $l2 = { $l2 => 1 } unless ref $l2;
 my $r = add $r2,
          scale $c2,
            add map { scale $l2->{$_}, cumulate $r1, $_, $c1 } keys %$l2;
 my $c = 1 - count $r;
 my $l = scale $c, normalize add map { power $l1, $_, $l2->{$_} } keys %$l2;
 return $r, $l;
}

=head1 EXPORT

An object-oriented module shouldn't export any function, and so does this one.

=head1 CAVEATS

The algorithm may be pessimistic (things seen as C<list> while they are of fixed length) but not optimistic (the opposite, duh).

C<wantarray> isn't specialized when encountered in the optree.

=head1 DEPENDENCIES

L<perl> 5.8.1.

L<Carp> (standard since perl 5), L<B> (since perl 5.005) and L<XSLoader> (since perl 5.006).

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on #perl @ FreeNode (vincent or Prof_Vince).

=head1 BUGS

Please report any bugs or feature requests to C<bug-b-nary at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Nary>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Nary

Tests code coverage report is available at L<http://www.profvince.com/perl/cover/Sub-Nary>.

=head1 ACKNOWLEDGEMENTS

Thanks to Sebastien Aperghis-Tramoni for helping to name this module.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Sub::Nary
