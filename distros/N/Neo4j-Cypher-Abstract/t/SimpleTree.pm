package t::SimpleTree;
use Carp qw/croak/;
use List::Util qw/all/;
use overload
  '==' => sub { $_[0]->hash eq $_[1]->hash },
  '!=' => sub { $_[0]->hash ne $_[1]->hash };
use strict;
use warnings;

my $commop = qr{^[*+]|and|x?or$}i;
my $unary_ops = qr/^not$/;
my $norm = { 'is not null' => 'is_not_null',
 	     'is null' => 'is_null' };
my %match = (
  ')' => '(', ']' => '[', '}' => '{'
 );
my $SIMP_LIMIT=10;

my @preced = (
  qr/[+\/%*-]|\bin\b/, # infix
  qr/(?:[!=><]?=)|(?:<>)/, #cmp
  qr/not/, # negate
  qr/\b(?:and)\b|\b(?:x?or)\b/, #logical
  qr/[,]/, # list separator
 );

my $ops = join('|',@preced,'[]{()}[]','[a-z]+\(');

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
}

sub parse {
  # lispify
  my ($self, $s) = @_;
  # normalize
  $s = lc $s;
  while (my ($from,$to) = each %$norm) {
    $s =~ s/$from/$to/g;
  }
  my @tok = split /\s*($ops)\s*/, ($s);
  @tok = grep { !/^\s*$/ } @tok;
  my @stack;
  while ( my $t = shift @tok ) {
    if ($t =~ /^[({[]$/) {
      push @stack, $t;
    }
    elsif ($t =~ /^[])}]$/) {
      my ($a,@r);
      while (@stack) {
	$a = pop @stack;
	last if $a eq $match{$t};
	unshift @r, $a;
      }
      croak "Mismatched parens" unless (@stack or $a eq $match{$t});
      my $x = _xpr(@r);
      if (@stack and $stack[-1] =~ /([a-z]+)\(/) {
	pop @stack;
	push @stack, [$1, $x];
      }
      else {
	push @stack, $x;
      }
    }
    elsif ($t =~ /[a-z]+\(/) {
       push @stack, $t, '(';
    }
    else {
	push @stack, $t;
    }
  }

  my $ret = (_xpr(@stack))[0];
  _simp($ret);
  $self->{tree} = $ret;
}

sub _xpr { # no groups
  my (@tok) = @_;
  my @stack;
  for my $op (@preced) {
    while (1) {
      my $n = @tok;
      while ( my $t = shift @tok ) {
	if (!ref($t) and $t =~ /$ops/) {
	  push @stack, $t;
	}
	else {
	  if (@stack and $stack[-1] =~ /$op/) {
	    if ($stack[-1] =~ /$unary_ops/) {
	      push @stack, [pop @stack, $t];
	    }
	    else { 
	      push @stack, [pop @stack,  pop @stack, $t];
	    }
	  }
	  else {
	    push @stack, $t;
	  }
	}
      }
      last if ($n == @stack);
      @tok = @stack; @stack = ();
    }
    @tok = @stack;
    last if @tok == 1;
    @stack = ();
  }
  croak "Could not completely reduce" unless @tok == 1;
  return $tok[0];
}

sub _simp {
  # simplify
  my ($tree) = @_;
  my $do;
  my $simp=0;
  $do = sub {
    my ($a) = @_;
    if (!ref $a) {
      return;
    }
    else {
      my $op = $$a[0];
      my @r;
      for my $e (@{$a}[1..$#$a]) {
	if (ref $e and $op eq $$e[0] and $op ne 'not') {
	  $simp=1;
	  push @$a, splice @$e,1;
	  pop @$e; # now empty
	}
      }
      @$a = grep { ref() ? @$_ : $_ } @$a;
      for my $e (@{$a}[1..$#$a]) {
	$do->($e);
      }
    }
  };
  $do->($tree);
  my $i = 0;
  while ($simp and (++$i < $SIMP_LIMIT)) {
    $simp = 0;
    $do->($tree);
  }
  warn "re-simp limit hit" if ($i == $SIMP_LIMIT);
  1;
}

sub hash {
  my $self = shift;
  $self->{tree} or die "No tree!";
  my $do;
  $do = sub {
    my $a = shift;
    if (ref $a eq 'ARRAY') {
      if (!scalar @$a) {
	return '.';
      }
      if ( all { ref eq '' } @$a ) {
	return $$a[0] =~ /$commop/ ?
	  join('',$$a[0],sort @{$a}[1..$#$a]) :
	  join('',@$a);
      }
      else {
	return $$a[0] =~ /$commop/ ?
	  join('',$$a[0],sort map { $do->($_) } @{$a}[1..$#$a]) :
	  join('',$$a[0], map { $do->($_) } @{$a}[1..$#$a]) ;
      }
    }
    else {
      return $a;
    }
  };

  $self->{hash} = $do->($self->{tree});
}

1;

=head1 NAME

t::SimpleTree : simple syntax tree for comparing simple expressions

=head1 SYNOPSIS

 use t::SimpleTree;
 my $p = t::SimpleTree->new;
 my $q = t::SimpleTree->new();
 my $expr1 = 'a + b + exp(c) and ( ( m <> ln(2) ) or ( max(l,m,q) ) )';
 my $expr2 = '(((a + b + exp(c) and ( (( m <> ln(2)) ) or ( max(l,m,q) ) ))))';
 $p->parse($expr1);
 $q->parse($expr2);
 if ($p == $q) {
  print "Equivalent";
 }

=head1 METHODS

=over

=item new()

=item parse()

Parse an expression and store the tree in the object. Tree is also returned
as a lisp-like nested array structure.

=item hash()

Create a string that captures the structure but sorts arguments of 
commutative operations. The hashes of two trees can be string-compared
to infer equivalence of the underlying expressions.

=item $t eq $s, $t ne $s

eq and ne are overloaded to compare the hashes of two trees.

=back

=head1 AUTHOR
 Mark A. Jensen
 CPAN: MAJENSEN
 majensen -at- cpan -dot- org

=head1 COPYRIGHT

 (c) 2017 Mark A. Jensen

=cut
