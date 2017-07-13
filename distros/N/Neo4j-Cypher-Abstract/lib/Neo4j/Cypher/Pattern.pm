package Neo4j::Cypher::Pattern;
use base Exporter;
use Carp;
use strict;
use warnings;
use overload '""' => 'as_string';

our $VERSION = '0.1002';
our @EXPORT_OK = qw/pattern ptn/;

sub puke(@);
sub belch(@);

sub new {
  my $class = shift;
  my $self = {};
  $self->{stmt}=[];
  if (@_) {
    my $nq = join('|',@_);
    $self->{no_quote} = qr/$nq/;
  }
  bless $self, $class;
}

sub pattern {
  Neo4j::Cypher::Pattern->new(@_);
}

sub ptn { Neo4j::Cypher::Pattern->new(@_); }

sub path {
  my $self = shift;
  puke("Need arg1 => identifier") if (!defined $_[0] || ref($_[0]));
  return "$_[0] = $self";
}

# alias for path
sub as { shift->path(@_) }

sub node {
  # args:
  # scalar string = varname
  # array ref - array of labels
  # hash ref - hash of props/values
  my $self = shift;
  unless (@_) {
    push @{$self->{stmt}}, '()';
    return $self;
  }
  my ($varname) = grep { !ref } @_;
  my ($lbls) = grep { ref eq 'ARRAY' } @_;
  my ($props) = grep { ref eq 'HASH' } @_;
  # look for labels
  my @l;
  ($varname, @l) = split /:/, $varname;
  if (@l) {
    $lbls //= [];
    push @$lbls, @l;
  }
  my $str = $lbls ? join(':',$varname, @$lbls) : $varname;
  if ($props) {
    my $p;
    while (my($k,$v) = each %$props) {
      push @$p, "$k:".$self->_quote($v);
    }
    $p = join(',',@$p);
    $str .= " {$p}";
  }
  push @{$self->{stmt}}, "($str)";
  return $self;
}

sub N {shift->node(@_);}

sub related_to {
  my $self = shift;
  unless (@_) {
    push @{$self->{stmt}}, '--';
    return $self;
  }
  my ($hops) = grep { ref eq 'ARRAY' } @_;
  my ($props) = grep { ref eq 'HASH' } @_;
  my ($varname,$type) = grep { !ref } @_;
  if ($type) {
    ($varname) = split /:/,$varname;
  } else {
    ($varname, $type) = $varname =~ /^([^:]*):?(.*)/;
  }
  my $dir;
  if ($varname) {
    $varname =~ s/^(<|>)//;
    $dir = $1;
    $varname =~ s/(<|>)$//;
    $dir = $1;
  }
  unless ($dir) {
    if ($type) {
      $type =~ s/^(<|>)//;
      $dir = $1;
      $type =~ s/(<|>)$//;
      $dir = $1;
    }
  }
  my $str = $varname.($type ? ":$type" : "");

  if ($hops) {
    if (@$hops == 0) {
      $str.="*";
    }
    elsif (@$hops==1) {
      $str .= "*$$hops[0]";
    }
    else {
      $str .= "*$$hops[0]..$$hops[1]"
    }
  }
  if ($props) {
    my $p;
    while (my($k,$v) = each %$props) {
      push @$p, "$k:".$self->_quote($v);
    }
    $p = join(',',@$p);
    $str .= " {$p}";
  }
  $str = ($str ? "-[$str]-" : '--');
  $str =~ s/\[ \{/[{/;
  if ($dir) {
    if ($dir eq "<") {
      $str = "<$str";
    }
    elsif ($dir eq ">") {
      $str = "$str>";
    }
    else {
      1; # huh?
    }
  }
  push @{$self->{stmt}}, $str;
  return $self;
}

sub R {shift->related_to(@_)}

# N('a')->toN('b') -> (a)-->(b)
# N('a')->fromN('b') -> (a)<--(b)
sub _N {shift->related_to->node(@_)}
sub to_N {shift->related_to('>')->node(@_)}
sub from_N {shift->related_to('<')->node(@_)}

# 'class' method
# do pattern->C($pat1, $pat2)
sub compound {
  my $self = shift;
  return join(',',@_);
}

sub C {shift->compound(@_)}

sub clear { shift->{stmt}=[],1; }

sub as_string {
  my $self = shift;
  return join('',@{$self->{stmt}});
}

sub _quote {
  return $_[1] if (
    ($_[0]->{no_quote} and $_[1] =~ $_[0]->{no_quote}) or
      $_[1] =~ /(?:^|\s)\$/ # no quote parameters
     );
  return ${$_[1]} if (ref $_[1] eq 'SCALAR');
  # escape single quotes
  my $v = $_[1];
  $v =~ s/'/\\'/g;
  return "'$v'";
}
sub pop { pop @{shift->{stmt}}; }

sub belch (@) {
  my($func) = (caller(1))[3];
  Carp::carp "[$func] Warning: ", @_;
}

sub puke (@) {
  my($func) = (caller(1))[3];
  Carp::croak "[$func] Fatal: ", @_;
}

=head1 NAME

Neo4j::Cypher::Pattern - Generate Cypher pattern strings

=head1 SYNOPSIS

 # express a cypher pattern
 use Neo4j::Cypher::Pattern qw/ptn/;

 ptn->node();
 ptn->N(); #alias
 ptn->N("varname");
 ptn->N("varname",["label"],{prop => "value"});
 ptn->N("varname:label");
 ptn->N(["label"],{prop => "value"});

 ptn->node('a')->related_to()->node('b'); # (a)--(b)
 ptn->N('a')->R()->N('b'); # alias
 # additional forms
 ptn->N('a')->R("varname","typename",[$minhops,$maxhops],{prop => "value"})
    ->N('b'); # (a)-[varname:typename*minhops..maxhops { prop:"value }]-(b)
 ptn->N('a')->R("varname:typename")->N('b'); # (a)-[varname:typename]-(b)
 ptn->N('a')->R(":typename")->N('b'); # (a)-[:typename]-(b)
 ptn->N('a')->R("", "typename")->N('b'); # (a)-[:typename]-(b)
 # directed relns
 ptn->N('a')->R("<:typename")->N('b'); # (a)<-[:typename]-(b)
 ptn->N('a')->R("varname:typename>")->N('b'); # (a)-[varname:typename]->(b)

 # these return strings
 $pattern->path('varname'); # path variable assigned to a pattern
 $pattern->as('varname'); # alias
 ptn->compound($pattern1, $pattern2); # comma separated patterns
 ptn->C($pattern1, $pattern2); # alias

=head1 DESCRIPTION

The L<Cypher|https://neo4j.com/docs/developer-manual/current/cypher/>
query language of the graph database L<Neo4j|https://neo4j.com> uses
L<patterns|https://neo4j.com/docs/developer-manual/current/cypher/syntax/patterns>
to represent graph nodes and their relationships, for selecting and
matching in queries. C<Neo4j::Cypher::Pattern> can be used to create
Cypher pattern productions in Perl in an intuitive way. It is part of
the L<Neo4j::Cypher::Abstract> distribution.

=head2 Basic idea : produce patterns by chaining method calls

C<Neo4j::Cypher::Pattern> objects possess methods to represent nodes
and relationships. Each method adds its portion of the pattern, with
arguments, to the object's internal queue. Every method returns the
object itself. When an object is rendered as a string, it concatenates
nodes and relationship productions to yield the entire query statement
as a string.

These features add up to the following idiom. Suppose we want to
render the Cypher pattern

 (b {name:"Slate"})<-[:WORKS_FOR]-(a {name:"Fred"})-[:KNOWS]->(c {name:"Barney"})

In C<Neo4j::Cypher::Pattern>, we do

 $p = Neo4j::Cypher::Pattern->new()->N('b',{name=>'Slate'})
      ->R('<:WORKS_FOR')->N('a',{name => 'Fred'})
      ->R(':KNOWS>')->N('c',{name=>'Barney'});
 print "$p\n"; # "" is overloaded by $p->as_string()

Because you may create many patterns in a program, a short
alias for the constructor can be imported, and extra variable
assignments can be avoided.

 print ptn->N('b',{name=>'Slate'})
      ->R('<:WORKS_FOR')->N('a',{name => 'Fred'})
      ->R(':KNOWS>')->N('c',{name=>'Barney'}), "\n";

=head2 Quoting

In pattern productions, values for properties will be quoted by
default with single quotes (single quotes that are present will be
escaped) unless the values are numeric.

To prevent quoting Cypher statement list variable names (for example),
make the name an argument to the pattern I<constructor>:

 ptn('event')->N('y')->R("<:IN")->N('e:Event'=> { id => 'event.id' });

 # renders (y)<-[:IN]-(e:Event {id:event.id})
 # rather than (y)<-[:IN]-(e:Event {id:"event.id"})

=head1 METHODS

=over

=item Constructor new()

=item pattern(), ptn()

Exportable aliases for the constructor. Arguments are variable names
that should not be quoted in rendering values of properties.

=item node(), N()

Render a node. Arguments in any order:

 scalar string: variable name or variable:label
 array ref: array of node labels
 hash ref: hash of property => value

=item related_to(), R()

Render a relationship. Arguments in any order:

 scalar string: variable name or variable:type
 array ref: variable-length pattern:
   [$minhops, $maxhops] 
   [] (empty array)- any number of hops
   [$hops] - exactly $hops
 hash ref : hash of property => value

=item path(), as()

Render the pattern set equal to a path variable:

 $p = ptn->N('a')->_N('b');
 print $p->as('pth'); # gives 'pth = (a)--(b)'

=item compound(), C()

Render multiple patterns separated by commas

 ptn->compound( ptn->N('a')->to_N('b'), ptn->N('a')->from_N('c'));
 # (a)-->(b), (a)<--(c)

=item Shortcuts _N, to_N, from_N

 ptn->N('a')->_N('b'); # (a)--(b)
 ptn->N('a')->to_N('b'); # (a)-->(b)
 pth->N('a')->from_N('b'); # (a)<--(b)

=back

=head1 SEE ALSO

L<Neo4j::Cypher::Abstract>

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN
 majensen -at- cpan -dot- org

=head1 LICENSE

This software is provided for use under the terms of Perl itself.

=head1 COPYRIGHT

 (c) 2017 Mark A. Jensen

=cut
1;
