package SOOT::SQL2Tree;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.02';

use Carp qw(croak);
use DBI;
use SOOT;
use Scalar::Util qw(blessed);
use File::Temp qw();

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
  sql2tree
);
our @EXPORT_TAGS = (
  'all' => \@EXPORT_OK,
);
our @EXPORT;
if (caller() and (caller())[1] eq '-e') {
  SOOT::Init(1);
  push @EXPORT, @EXPORT_OK;
  SOOT->export_to_level(1, ':all');
}


our %Types = (
  'char' => {
    name => 'char',
    root_type => 'C',
  },
  'int' => {
    name => 'int',
    root_type => 'I',
  },
  'bigint' => {
    name => 'bigint',
    root_type => 'L',
  },
  'uint' => {
    name => 'uint',
    root_type => 'i',
  },
  'ubigint' => {
    name => 'ubigint',
    root_type => 'l',
  },
  'float' => {
    name => 'float',
    root_type => 'F',
  },
  'double' => {
    name => 'double',
    root_type => 'D',
  },
);

our %Typemap = qw(
  char char
  varchar char

  int int
  integer int
  smallint int
  smallinteger int
  tinyint int
  tinyinteger int

  bigint bigint
  biginteger bigint

  float float
  double double
  decimal double
);


use Class::XSAccessor {
  lvalue_accessors => [qw(dbh name title colmaps coltypes)],
};

sub new {
  my $class = shift;
  my %opt = @_;

  foreach my $param (qw(dbh)) {
    ref($opt{$param})
      or croak("Need '$param' parameter");
  }

  my $self = bless {
    colmaps  => {},
    coltypes => {},
    name     => undef,
    title    => undef,
    %opt,
  } => $class;
}

sub make_tree {
  my $self = shift;
  
  my $sql   = shift;
  croak("Need some SQL to make a tree") if not defined $sql;
  my $binds = shift;
  my $attrs = shift;

  my $colmaps  = $self->colmaps;
  my $coltypes = $self->coltypes;

  my $sth = $self->dbh->prepare($sql);
  $sth->execute(@{$binds||[]});

  my $name = $sth->{NAME};

  my @root_names = map {$_ = lc($_); s/[^a-z_0-9]+//g; $_} @$name;

  my @root_types;
  my $type = $sth->{TYPE};
  foreach my $i (0 .. $#{ $type }) {
    if (exists $coltypes->{ $name->[$i] }) {
      push @root_types, $self->_find_root_type($coltypes->{ $name->[$i] });
    }
    elsif (not ref($type->[$i]) and $type->[$i] =~ /^\d+$/) {
      my $typeinfo = $self->dbh->type_info($type->[$i]);
      push @root_types, $self->_find_root_type($typeinfo->{TYPE_NAME});
    }
    else {
      push @root_types, $self->_find_root_type($type->[$i]);
    }
  }

  my @root_cols;
  foreach my $i (0..$#root_names) {
    push @root_cols, $root_names[$i]."/".$root_types[$i]{root_type};
  }
  my $root_header = join(':', @root_cols);
  my $treename  = $self->name;
  my $treetitle = $self->title;
  $treetitle = $treename if not defined $treetitle;

  my @colmaps = map $colmaps->{$_}, @$name;
  @colmaps = () if not grep defined, @colmaps;

  # FIXME This should be possible to stuff into a TTree directly, but my
  # dynamic ROOT/XS/XS++/CInt fu fails me on that at this point.
  # Python must be better at *something*!
  my $tfh = File::Temp->new(CLEANUP => 1);
  if (@colmaps) {
    while (my $row = $sth->fetchrow_arrayref) {
      print $tfh join("\t", @$row), "\n";
    }
  }
  else {
    while (my $row = $sth->fetchrow_arrayref) {
      for (0..$#colmaps) {
        $row->[$_] = $colmaps[$_]->($row->[$_]) if $colmaps[$_];
      }
      print $tfh join("\t", @$row), "\n";
    }
  }
  $tfh->flush;

  my $tree = TTree->new(defined($treename) ? ($treename, $treetitle) : ());
  $tree->ReadFile($tfh->filename, $root_header);
  return $tree;
}

sub _find_root_type {
  my $self = shift;
  my $sqltype = shift;
  lc($sqltype) =~ /^([a-z0-9_]+)/
    or die "Unrecognized type: $sqltype";
  my $clean = $1;
  my $mapped = $Typemap{$clean};
  die "Cannot find ROOT type for SQL type '$sqltype' (canon: $clean)"
    if not defined $mapped;
  return $Types{$mapped};
}


sub sql2tree {
  my $dbh = shift;
  my $sql = shift;
  my $binds = shift||[];
  my $attrs = shift||{};
  my %opt;
  if (not blessed($dbh)) {
    if (ref($dbh)) {
      $dbh = DBI->connect(@$dbh);
    } else {
      $dbh = DBI->connect($dbh, "", "");
    }
  }

  my $obj = SOOT::SQL2Tree->new(
    %opt,
    dbh => $dbh,
  );
  return $obj->make_tree($sql, $binds, $attrs);
}

1;
__END__

=head1 NAME

SOOT::SQL2Tree - Make a TTree from a SQL SELECT

=head1 SYNOPSIS

  use SOOT::SQL2Tree;
  my $dbh = DBI->connect(...);
  my $sql2tree = SOOT::SQL2Tree->new(dbh => $dbh);
  my $tree = $sql2tree->make_tree("SELECT * FROM particles WHERE rapidity IS NOT NULL");
  $tree->Draw("energy:rapidity");

=head1 DESCRIPTION

B<WARNING:> This is highly experimental stuff!

L<SOOT> is a Perl extension for using the ROOT library. It is very similar
to the Ruby-ROOT or PyROOT extensions for their respective languages.
Specifically, SOOT was implemented after the model of Ruby-ROOT.

C<SOOT::SQL2Tree> implements a very simple minded interface
to databases in which you can generate a ROOT C<TTree> from
a SQL C<SELECT> statement.

The main interface is object-oriented, but there is a convenience
function for quick hacks and command line usage (see below).
It can be exported on demand and will be export by default
if the module is loaded in a one-liner.

=head1 METHODS

=head2 new

Constructor. Takes named parameters.
Requires at least a C<dbh> argument that is a C<DBI> database handle.

Optional arguments:

=over 2

=item name, title

Sets the C<TTree> name or title.

=item colmaps

A hash reference associating the SQL column names
with a subroutine reference. Those callbacks
will be called with the column value as argument
for every time the column is encountered in the input.
The column value will be replaced with the
return value of the callback in the output.

Example:

  my $sql2tree = SOOT::SQL2Tree->new(
    dbh => ...,
    colmaps => {
      distance => sub { $_[0]/1000 }, # convert from km to m
      ...
    }
  );
  my $tree = $sql2tree->make_tree("SELECT distance, ... FROM foo");

Any unmapped columns will be inserted into the tree without
modification.

=item coltypes

A hash reference that maps the input SQL type of
a column to another type. Keys must be column names,
values must be SQL types. Mostly only useful for
manually modified columns (see C<colmaps>).

  coltypes => {
    distance => 'double',
  },

=back

=head2 colmaps

Getter/setter for the C<colmaps> attribute.

=head2 coltypes

Getter/setter for the C<coltypes> attribute.

=head2 name

Getter/setter for the C<TTree> name.

=head2 title

Getter/setter for the C<TTree> title. Defaults to the C<TTree> name
or nothing if there is no name.

=head1 FUNCTIONS

=head2 sql2tree

Alternative non-OO interface for quick hacks. Take positional parameters.
Returns a C<TTree> object.

Parameters:

=over 2

=item database handle

Either a DBI object, an array ref containing the arguments to the
DBI C<connect()> method, or just the dsn string.

=item SQL SELECT statement

The SQL to run. Nuff said.

=item binds (optional)

Optional array reference containing bind parameters for
the SQL.

=item attributes (optional)

Optional hash reference containing attributes to pass to the
statement handler C<execute()> call.

=head1 KNOWN SQL TYPES

The module can automatically detect and transform the types of
most basic SQL types and C<char> and C<varchar> strings.

Strings are likely problematic and currently untested.

Check the code for the recognized types or use the C<coltypes>
option to set the type of your column manually.

=head1 SEE ALSO

L<http://root.cern.ch>

L<SOOT>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Steffen Mueller

SOOT, the Perl-ROOT wrapper, is free software and so is
SOOT::SQL2Tree; you can redistribute it and/or modify
it under the same terms as ROOT itself. That is, the GNU Lesser General Public License.
A copy of the full license text is available from the distribution as the F<LICENSE> file.

=cut

