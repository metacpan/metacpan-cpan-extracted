package Neo4j::Cypher::Abstract;
use lib '../../../lib';
use base Exporter;
use Neo4j::Cypher::Pattern qw/pattern ptn/;
use Neo4j::Cypher::Abstract::Peeler;
use Scalar::Util qw/blessed/;
use Carp;
use overload
  '""' => as_string,
  'cmp' => sub { "$_[0]" cmp "$_[1]" };
use strict;
use warnings;


our @EXPORT_OK = qw/cypher pattern ptn/;
our $AUTOLOAD;

sub puke(@);
sub belch(@);

our $VERSION='0.1003';

# let an Abstract object keep its own stacks of clauses
# rather than clearing an existing Abstract object, get
# new objects from a factory = cypher() 

# create, create_unique, match, merge - patterns for args
# where, set - SQL::A like expression for argument (only assignments make
#  sense for set)
# for_each - third arg is a cypher write query

# 'as' - include in the string arguments : "n.name as name"

our %clause_table = (
  read => [qw/match optional_match where start/],
  write => [qw/create merge set delete remove foreach
	       detach_delete
	       on_create on_match
	       create_unique/],
  general => [qw/return order_by limit skip with unwind union
		 return_distinct with_distinct
		 call yield/],
  hint => [qw/using_index using_scan using_join/],
  load => [qw/load_csv load_csv_with_headers
	      using_periodic_commit/],
  schema => [qw/create_constraint drop_constraint
		create_index drop_index/],
  modifier => [qw/skip limit order_by/]
 );
our @all_clauses = ( map { @{$clause_table{$_}} } keys %clause_table );

sub new {
  my $class = shift;
  my $self = {};
  $self->{stack} = [];
  bless $self, $class;
}

sub cypher {
  Neo4j::Cypher::Abstract->new;
}
sub available_clauses {no warnings qw/once/; @__PACKAGE__::all_clauses }

sub bind_values { $_[0]->{bind_values} && @{$_[0]->{bind_values}} }
sub parameters { $_[0]->{parameters} && @{$_[0]->{parameters}} }

# specials

sub where {
  my $self = shift;
  puke "Need arg1 => expression" unless defined $_[0];
  my $arg = $_[0];
  $self->_add_clause('where',$arg);
}

sub union { $_[0]->_add_clause('union') }
sub union_all { $_[0]->_add_clause('union_all') }

sub order_by {
  my $self = shift;
  puke "Need arg1 => identifier" unless defined $_[0];
  my @args;
  while (my $a = shift) {
    if ($_[0] and $_[0] =~ /^(?:de|a)sc$/i) {
      push @args, "$a ".uc(shift());
    }
    else {
      push @args, $a;
    }
  }
  $self->_add_clause('order_by',@args);
}

sub unwind {
  my $self = shift;
  puke "need arg1 => list expr" unless $_[0];
  puke "need arg2 => list variable" unless ($_[1] && !ref($_[1]));
  $self->_add_clause('unwind',$_[0],'AS',$_[1]);
}

sub match {
  my $self = shift;
  # shortcut for a single node identifier, with labels
  if (@_==1 and $_[0] =~ /^[a-z][a-z0-9_:]*$/i) {
    $self->_add_clause('match',"($_[0])");
  }
  else {
    $self->_add_clause('match',@_);
  }
}

sub create {
  my $self = shift;
  # shortcut for a single node identifier, with labels
  if (@_==1 and $_[0] =~ /^[a-z][a-z0-9_:]*$/i) {
    $self->_add_clause('create',"($_[0])");
  }
  else {
    $self->_add_clause('create',@_);
  }
}

sub set {
  my $self = shift;
  # interpret a hashref argument as a set of key = value pairs
  if (ref $_[0] eq 'HASH' && @_ == 1) {
    $self->_add_clause('set', map { { $_ => $_[0]->{$_} } } sort keys %{$_[0]} )
  }
  else {
    $self->_add_clause('set',@_);
  }
}

sub foreach {
  my $self = shift;
  puke "need arg1 => list variable" unless ($_[0] && !ref($_[0]));
  puke "need arg2 => list expr" unless $_[1];
  puke "need arg3 => cypher update stmt" unless $_[2];
  $self->_add_clause('foreach', $_[0],'IN',$_[1],'|',$_[2]);
}

sub load_csv {
  my $self = shift;
  puke "need arg1 => file location" unless $_[0];
  puke "need arg2 => identifier" if (!defined $_[1] || ref $_[1]);
  $self->_add_clause('load_csv','FROM',$_[0],'AS',$_[1]);
}

sub load_csv_with_headers {
  my $self = shift;
  puke "need arg1 => file location" unless $_[0];
  puke "need arg2 => identifier" if (!defined $_[1] || ref $_[1]);
  $self->_add_clause('load_csv_with_headers','FROM',$_[0],'AS',$_[1]);
}

#create_constraint_exist('node', 'label', 'property')

sub create_constraint_exist {
  my $self = shift;
  puke "need arg1 => node/reln pattern" unless defined $_[0];
  puke "need arg2 => label" if (!defined $_[1] || ref $_[1]);
  puke "need arg2 => property" if (!defined $_[2] || ref $_[2]);
  $self->_add_clause('create_constraint_on', "($_[0]:$_[1])", 'ASSERT',"exists($_[0].$_[2])");
}

# create_constraint_unique('node', 'label', 'property')
sub create_constraint_unique {
  my $self = shift;
  puke "need arg1 => node/reln pattern" unless defined $_[0];
  puke "need arg2 => label" if (!defined $_[1] || ref $_[1]);
  puke "need arg2 => property" if (!defined $_[2] || ref $_[2]);
  $self->_add_clause('create_constraint_on', "($_[0]:$_[1])", 'ASSERT',
		     "$_[0].$_[2]", 'IS UNIQUE');
}

# create_index('label' => 'property')
sub create_index {
  my $self = shift;
  puke "need arg1 => node label" if (!defined $_[0] || ref $_[0]);
  puke "need arg2 => node property" if (!defined $_[1] || ref $_[1]);
  $self->_add_clause('create_index','ON',":$_[0]($_[1])");
}

# drop_index('label'=>'property')
sub drop_index {
  my $self = shift;
  puke "need arg1 => node label" if (!defined $_[0] || ref $_[0]);
  puke "need arg2 => node property" if (!defined $_[1] || ref $_[1]);
  $self->_add_clause('drop_index','ON',":$_[0]($_[1])");
}

# using_index('identifier', 'label', 'property')
sub using_index {
  my $self = shift;
  puke "need arg1 => identifier" if (!defined $_[0] || ref $_[0]);
  puke "need arg2 => node label" if (!defined $_[1] || ref $_[1]);
  puke "need arg3 => node property" if (!defined $_[2] || ref $_[2]);
  $self->_add_clause('using_index',"$_[0]:$_[1]($_[2])");
}

# using_scan('identifier' => 'label')
sub using_scan {
  my $self = shift;
  puke "need arg1 => identifier" if (!defined $_[0] || ref $_[0]);
  puke "need arg2 => node label" if (!defined $_[1] || ref $_[1]);
  $self->_add_clause('using_scan',"$_[0]:$_[1]");
}

# using_join('identifier', ...)
sub using_join {
  my $self = shift;
  puke "need arg => identifier" if (!defined $_[0] || ref $_[0]);
  $self->_add_clause('using_join', 'ON', join(',',@_));
}

# everything winds up here
sub _add_clause {
  my $self = shift;
  my $clause = shift;
  $self->{dirty} = 1;
  my @clause;
  push @clause, $clause;
  if ( $clause =~ /^match|create|merge/ and 
	 @_==1 and $_[0] =~ /^[a-z][a-z0-9_:]*$/i) {
    push @clause, "($_[0])";
  }
  else {
    for (@_) {
      if (ref && !blessed($_)) {
	my $plr = Neo4j::Cypher::Abstract::Peeler->new();
	push @clause, $plr->express($_);
	# kludge
	if ($clause =~ /^set/) {
	  # removing enclosing parens from peel
	  $clause[-1] =~ s/^\s*\(//;
	  $clause[-1] =~ s/\)\s*$//;
	}
	push @{$self->{bind_values}}, $plr->bind_values;
	push @{$self->{parameters}}, $plr->parameters;
      }
      else {
	push @clause, $_;
	my @parms = m/(\$[a-z][a-z0-9]*)/ig;
	push @{$self->{parameters}}, @parms;
      }
    }
  }
  if ($clause =~ /^return|with|order|set|remove/) {
    # group args in array so they are separated by commas
    @clause = (shift @clause, [@clause]);
  }
  push @{$self->{stack}}, \@clause;
  return $self;
}

sub as_string {
  my $self = shift;
  return $self->{string} if ($self->{string} && !$self->{dirty});
  undef $self->{dirty};
  my @c;
  for (@{$self->{stack}}) {
    my ($kws, @arg) = @$_;
    $kws =~ s/_/ /g;
    for (@arg) {
      $_ = join(',',@$_) if ref eq 'ARRAY';
    }
    if ($kws =~ /foreach/i) { #kludge for FOREACH
      push @c, uc($kws)." (".join(' ',@arg).")";
    }
    else {
      push @c, join(' ',uc $kws, @arg);
    }
  }
  $self->{string} = join(' ',@c);
  $self->{string} =~ s/(\s)+/$1/g;
  return $self->{string};
}

sub AUTOLOAD {
  my $self = shift;
  my ($method) = $AUTOLOAD =~ /.*::(.*)/;
  unless (grep /$method/, @all_clauses) {
    puke "Unknown clause '$method'";
  }
  $self->_add_clause($method,@_);
}

sub belch (@) {
  my($func) = (caller(1))[3];
  Carp::carp "[$func] Warning: ", @_;
}

sub puke (@) {
  my($func) = (caller(1))[3];
  Carp::croak "[$func] Fatal: ", @_;
}

sub DESTROY {}

=head1 NAME

Neo4j::Cypher::Abstract - Generate Cypher query statements

=head1 SYNOPSIS

=head1 DESCRIPTION

When writing code to automate database queries, sometimes it is
convenient to use a wrapper that generates desired query strings. Then
the user can think conceptually and avoid having to remember precise
syntax or write and debug string manipulations. A good wrapper can
also allow the user to produce query statements dynamically, hide
dialect details, and may include some simple syntax
checking. C<SQL::Abstract> is an example of a widely-used wrapper for
SQL.

The graph database L<Neo4j|https://www.neo4j.com> allows SQL-like
declarative queries through its query language
L<Cypher|https://neo4j.com/docs/developer-manual/current/cypher/>. C<Neo4j::Cypher::Abstract>
is a Cypher wrapper in the spirit of C<SQL::Abstract> that creates
very general Cypher productions in an intuitive, Perly way.

=head2 Basic idea : stringing clauses together with method calls

A clause is a portion of a complete query statement that plays a
specific functional role in the statement and is set off by one or
more reserved words. L<Clauses in
Cypher|https://neo4j.com/docs/developer-manual/current/cypher/clauses/>
include reading (e.g., MATCH), writing (CREATE), importing (LOAD CSV), and
schema (CREATE CONSTRAINT) clauses, among others. They have
arguments that define the clause's scope of action.

L<Cypher::Abstract|Neo4j::Cypher::Abstract> objects possess methods
for every Cypher clause. Each method adds its clause, with arguments,
to the object's internal queue. Every method returns the object
itself. When an object is rendered as a string, it concatenates its
clauses to yield the entire query statement.

These features add up to the following idiom. Suppose we want to
render the Cypher statement

 MATCH (n:Users) WHERE n.name =~ 'Fred.*' RETURN n.manager

In C<Cypher::Abstract>, we do

 $s = Neo4j::Cypher::Abstract->new()->match('n:Users')
      ->where("n.name =~ 'Fred.*'")->return('n.manager');
 print "$s;\n"; # "" is overloaded by $s->as_string()

Because you may create many such statements in a program, a short
alias for the constructor can be imported, and extra variable
assignments can be avoided.

 use Neo4j::Cypher::Abstract qw/cypher/;
 use DBI;

 my $dbh = DBI->connect("dbi:Neo4p:http://127.0.0.1:7474;user=foo;pass=bar");
 my $sth = $dbh->prepare(
   cypher->match('n:Users')->where("n.name =~ 'Fred.*'")->return('n.manager')
   );
 $sth->execute();
 ...

=head2 Patterns

L<Patterns|https://neo4j.com/docs/developer-manual/current/cypher/syntax/patterns/>
are representations of subgraphs with constraints that are key
components of Cypher queries. They have their own syntax and are also
amenable to wrapping.  In the example L<above|/"Basic idea : stringing
clauses together with method calls">, C<match()> uses a simple
built-in shortcut:

 $s->match('n:User') eq $s->match('(n:User)')

where C<(n:User)> is the simple pattern for "all nodes with label
'User'".  The module L<Neo4j::Cypher::Pattern> handles
complex and arbitrary patterns. It is loaded automatically on C<use
Neo4j::Cypher::Abstract>. Abstract patterns are written in a similar
idiom as Cypher statements. They can be used anywhere a string is
allowed. For example:

 use Neo4j::Cypher::Abstract qw/cypher ptn/;

 ptn->N(':Person',{name=>'Oliver Stone'})->R("r>")->N('movie') eq
  '(:Person {name:'Oliver Stone'})-[r]->(movie)'
 $sth = $dbh->prepare(
    cypher->match(ptn->N(':Person',{name=>'Oliver Stone'})->R("r>")->N('movie'))
          ->return('type(r)')
    );

See L<Neo4j::Cypher::Pattern> for a full description of how
to specify patterns.

=head2 WHERE clauses

As in SQL, Cypher has a WHERE clause that is used to filter returned
results.  Rather than having to create custom strings for common WHERE
expressions, L<SQL::Abstract> provides an intuitive system for
constructing valid expressions from Perl data structures made up of
hash, array, and scalar references. L<Neo4j::Cypher::Abstract>
contains a new implementation of the L<SQL::Abstract> expression
"compiler". If the argument to the C<where()> method (or any other
method, in fact) is an array or hash reference, it is interpreted as
an expression in L<SQL::Abstract> style. (The parser is a complete
reimplementation, so some idioms in that style may not result in
exactly the same productions.)

For details on writing expressions, see
L<Neo4j::Cypher::Abstract::Peeler/"Expressing Expressions">.

=head2 Parameters

Parameters in Cypher are named, and given as alphanumeric tokens
prefixed (sadly) with '$'. The C<Cypher::Abstract> object collects
these in the order they appear in the complete statement. The list of
parameters can be recovered with the C<parameters()> method.

 $c = cypher->match('n:Person')->return('n.name')
            ->skip('$s')->limit('$l');
 @p = $c->parameters; # @p is ('$s', '$l') /;

=head1 METHODS

=head2 Reading clauses

=over

=item match(@ptns)

=item optional_match(@ptns)

=item where($expr)

=item start($ptn)

=back 

=head2 Writing clauses

=over

=item create(@ptns), create_unique($ptn)

=item merge(@ptns)

=item foreach($running_var => $list, cypher-><update statement>)

=item set()

=item delete(), detach_delete()

=item on_create(), on_match()

=back

=head2 Modifiers

=over

=item limit($num)

=item skip($num)

=item order_by($identifier)

=back

=head2 General clauses

=over

=item return(@items), return_distinct(@items)

=item with(@identifiers), with_distinct(@identifiers)

=item unwind($list => $identifier)

=item union()

=item call()

=item yield()

=back

=head2 Hinting

=over

=item using_index($index)

=item using_scan()

=item using_join($identifier)

=back

=head2 Loading

=over

=item load_csv($file => $identifier), load_csv_with_headers(...)

=back

=head2 Schema

=over

=item create_constraint_exist($node => $label, $property),create_constraint_unique($node => $label, $property)

=item drop_constraint(...)

=item create_index($label => $property), drop_index($label => $property)

=back

=head2 Utility Methods

=over

=item parameters()

Return a list of statement parameters.

=item as_string()

Render the Cypher statement as a string. Overloads C<"">.

=back

=head1 SEE ALSO

L<Neo4j::Cypher::Pattern>, L<Neo4j::Cypher::Abstract::Peeler/"Expressing Expressions">, L<REST::Neo4p>, L<DBD::Neo4p>, L<SQL::Abstract>

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

