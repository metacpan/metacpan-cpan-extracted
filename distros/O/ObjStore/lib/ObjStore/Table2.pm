use strict;

package ObjStore::Table2;
use Carp;
use ObjStore ':ADV';
use base 'ObjStore::HV';
use vars qw($VERSION);

$VERSION = '1.02';

sub new {
    my ($class, $where, $size) = @_;
    croak "$class\->new(where, size)" if @_ != 3;
    carp "ObjStore::Table2 is depreciated, use ObjStore::Table3";
    my $o = $class->SUPER::new($where);
    my $seg = $o->database_of->create_segment;
    $seg->set_comment("table $size");
    $o->{_array} = new ObjStore::AV($seg, $size);
    $o->{_index_segments} = 1;
    $o;
}

sub indices { croak "indices method is depreciated in Table2" }

sub index { $_[0]->{$_[1]}; }
#sub at {} #fetch XXX cursor?
sub fetch { my $o=shift; $o->{ shift() }->fetch(@_) }

sub index_segments { $_[0]->{_index_segments} = $_[1] }

sub new_index {
    # this will be more complicated XXX
    my ($o, $type, @REST) = @_;
    carp "ObjStore::Table::Index::* is depreciated, use ObjStore::Index";
    my $class = 'ObjStore::Table::Index::'.$type;  #short-cut
    $o->add_index($class->new($o, @REST));
}

sub add_index {
    my ($o, $index) = @_;
    $o->{ $index->name } = $index;
    $index->build;
}

sub remove_index {
    my ($o, $name) = @_;
    die "$o->remove_index($name): index doesn't exist"
	if !exists $o->{ $name };
    delete $o->{ $name };
}

sub build_indices   { shift->map_indices(sub { shift->build; }); }
sub rebuild_indices { shift->map_indices(sub { shift->rebuild; }); }
sub drop_indices    { shift->map_indices(sub { shift->drop; }); }

sub repair_indices  { 
    my ($o, $rec, $x) = @_;
    $o->map_indices(sub { shift->repair($rec, $x) })
}

sub map_indices {
    my ($o, $c) = @_;
    for my $i (values %$o) {
	next unless ref $i && $i->isa('ObjStore::Table::Index');
	$c->($i);
    }
}

sub add {
    # inefficient stop-gap until tied arrays work
    my ($o, $e) = @_;
    my $ar = $o->array;
    $ar->PUSH($e);
    $o->repair_indices($e, $ar->FETCHSIZE - 1);
    $e;
}

sub remove {
    # inefficient stop-gap until tied arrays work
    my ($o, $e) = @_;
    my $ar = $o->array;
    my $x;
    for (my $z=0; $z < $ar->FETCHSIZE; $z++) {
	my $e2 = $ar->[$z];
	do { $x = $z; last } if $e2 == $e;
    }
    confess "$o->remove($e): can't find element" if !defined $x;
    $ar->[ $x ] = undef;
    $o->repair_indices($e, $x);
    $e;
}

# different per implementation
sub map { shift->array->map(@_); }

sub compress {
    # compress table - use with add/remove
    my ($o) = @_;
    my $ar = $o->array;
    my $data = $ar->FETCHSIZE - 1;
    my $hole = 0;
    while ($hole < $ar->FETCHSIZE) {
	next if defined $ar->[$hole];
	while ($data > $hole) {
	    next unless defined $ar->[$data];
	    my $t = $ar->[$data];
	    $ar->[$data] = undef;
	    $o->repair_indices($t, $data);
	    $ar->[$hole] = $t;
	    $o->repair_indices($t, $hole);
	} continue { --$data };
    } continue { ++$hole };
    
    while ($ar->FETCHSIZE and !defined $ar->[$ar->FETCHSIZE - 1]) {
	$ar->_Pop;
    }
}

sub table { $_[0]; }
sub array { $_[0]->{_array}; }  #depending on representation XXX

sub POSH_PEEK {
    my ($val, $o, $name) = @_;
    $o->o("TABLE ". $name . " {");
    $o->nl;
    $o->indent(sub {
	my $ar = $val->array;
	$o->o("array [".$ar->FETCHSIZE ."] of ");
	$o->peek_any($ar->[0]);
	$o->nl;
	my $table = $val->table;
	my @index;
	my @other;
	while (my ($k,$v) = each %$table) {
	    if (ref $v and $v->isa('ObjStore::Table::Index')) {
		push(@index, $v);
	    } else {
		push(@other, $k);
	    }
	}
	$o->o("indices: ");
	$o->o(join(', ',sort map { $_->is_built? uc($_->name):$_->name } @index));
	$o->o(";");
	$o->nl;
	for my $k (sort @other) {
	    next if $k =~ m/^_/;
	    $o->o("$k => ");
	    my $v = $table->{$k};
	    $o->peek_any($v);
	    $o->nl;
	}
    });
    $o->o("},");
    $o->nl;
}

sub POSH_CD {
    my ($t, $to) = @_;
    return $t->array if $to eq 'array';
    if ($to =~ m/^\d+$/) {
	$t->array->[$to];
    } else {
	$t->table->{$to};
    }
}

sub BLESS {
    return $_[0]->SUPER::BLESS($_[1]) if ref $_[0];
    my ($class, $o) = @_;
    if ($o->isa('ObjStore::Table')) {
	my $t = $o->table;
	$t->{_array} = $t->{'array'};
	delete $t->{'array'};
	my $ix = $t->{'indices'};
	for my $i (keys %$ix) {
	    $t->{$i} = $ix->{$i};
	}
	delete $t->{'indices'};
    }
    $class->SUPER::BLESS($o);
}

package ObjStore::Table2::Database;
use Carp;
use ObjStore;
use base 'ObjStore::Database';
use vars qw'$VERSION @ISA';
push(@ISA, 'ObjStore::Table2');
$VERSION = '0';

sub ROOT() { 'table' } #DO NOT OVERRIDE!  depreciated XXX
sub default_size() { 21 }  #can override

sub new {
    my $class = shift;
    my $db = $class->SUPER::new(@_);
    $db->table; #force root setup
    $db;
}

sub table {
    my ($db) = @_;
    $db->root(&ROOT, sub { ObjStore::Table2->new($db, &default_size) } );
}
sub array { 
    my $db = shift;
    carp "$db->array is depreciated";
    $db->table->array;
}

sub BLESS {
    return $_[0]->SUPER::BLESS($_[1]) if ref $_[0];
    my ($class, $db) = @_;
    if ($db->isa('ObjStore::HV::Database')) {
	warn "[Migrating $db to $class]\n";
	my $o = $db->table;
	my $ar = $o->array;
	my $hash = $db->hash;
	for my $z (values %$hash) { $ar->_Push($z); }
	$db->destroy_root($db->ROOT);  #XXX other package should do it!
    }
    $class->SUPER::BLESS($db);
    bless $db->table, 'ObjStore::Table2';
    $db;
}

sub POSH_ENTER { shift->table; }

# Should be able to build indices all at once or update incrementally.
package ObjStore::Table::Index;
use ObjStore ':ADV';
use base 'ObjStore::HV';
use Carp;
use vars qw($VERSION);
$VERSION = '0';

# An index should be autonomous and do it's own clustering.
sub new {
    my ($class, $table, $name) = @_;
    confess "$class->new(table, name)" if @_ != 3;
    my $o = $class->SUPER::new($table);
    $o->{_table} = $table->new_ref($o, 'unsafe'); #safe-ify? XXX
    $o->{_name} = $name;
    $o->set_index_segment($table) if !$table->{_index_segments};
    $o;
}

sub name { $_[0]->{_name} }

sub table { $_[0]->{_table}->focus }
sub detach { carp 'depreciated & unnecessary'; delete $_[0]->{_table} }

sub build { die(shift()."->build: must override"); }
sub repair { die(shift()."->repair: must override"); }

sub is_built {
    my ($o) = @_;
    return 1 if exists $o->{'map'};
    for my $k (keys %$o) { return 1 if $k !~ m/^_/; }  #depreciated
    0;
}
# someday distinguish between built, stale, and actively-updated XXX
*is_active = \&is_built;

sub drop {
    my ($o) = @_;
    for my $k (keys %$o) {
	next if $k =~ m/^_/;
	delete $o->{$k};
    }
}

sub rebuild { my $o = shift; $o->drop; $o->build(@_); }

# re-think, re-write XXX
sub fetch_key {
    my ($o, $at) = @_;
    confess $o if @_ != 2;
#    warn "$at $o->{_field}";
    my @c = split(m/\-\>/, $o->{_field});
    while (@c) {
	confess "fetch_key broken path $o->{_field}" if !$at;
	if (blessed $at && $at->can("FETCH")) {
	    if ($at->isa('ObjStore::AVHV')) {
		$at = $at->{shift @c};
	    } else {
		$at = $at->FETCH(shift @c);
	    }
	} else {
	    my $t = reftype $at;
	    if ($t eq 'HASH') {
		$at = $at->{shift @c};
	    } elsif ($t eq 'ARRAY') {
		$at = $at->[shift @c];
	    } else {
		confess "fetch_key type '$t' unknown ($at: $o->{_field})";
	    }
	}
    }
    $at;
}

sub set_index_segment {
    my ($o, $s) = @_;
    confess "$o->set_index_segment: already set" if exists $o->{_segment};
    $s ||= $o->segment_of;
    $s = $s->segment_of if ref $s;
    $o->{_segment} = ref $s? $s->get_number : $s;
}

sub index_segment {
    my ($o) = @_;
    if (!exists $o->{_segment}) {
	my $s = $o->database_of->create_segment;
	$s->set_comment($o->name." index");
	$o->{_segment} = $s->get_number;
    }
    $o->database_of->get_segment($o->{_segment});
}

package ObjStore::Table::Index::Field;
use Carp;
use ObjStore;
use base 'ObjStore::Table::Index';
use vars qw($VERSION);
$VERSION = '0';

sub new {
    my ($class, $table, $name, $field) = @_;
    $field ||= $name;
    my $o = $class->SUPER::new($table, $name);
    $o->{_field} = $field;
    $o;
}

sub repair {
    # ignores collisions XXX
    # stop-gap until tied arrays work
    my ($o, $rec, $x) = @_;
    return if !$o->is_built;
    my $inarray = $o->table->array->[$x];
    my $add = $inarray == $rec;
    my $key = $o->fetch_key($rec);
    if ($add) {
	$o->{'map'}{ $key } = $rec;
    } else {
	delete $o->{'map'}{ $key };
    }
}

sub build {
    use integer;
    my ($o, $collision) = @_;
    warn "$o->build: collision support is experimental" if $collision;
    return if $o->is_built;
    my $t = $o->table;
    my $arr = $t->array;
    my $total = $arr->FETCHSIZE();
    my $xx = $o->{ $o->name } = new ObjStore::HV($o->index_segment,
						 $total * .4 || 50);
    $o->{'map'} = $xx;

    for (my $z=0; $z < $total; $z++) {
	my $rec = $arr->[$z];
	next if !defined $rec;
	my $key = $o->fetch_key($rec);
	next if !$key;
	my $old = $xx->{ $key };
	if ($old and $collision) {
	    my $do = $collision->($o, $old, $rec);
	    if ($do eq 'neither') {
		delete $rec->{ $key };
		next;
	    } elsif ($do eq 'old') {
		next;
	    } elsif ($do eq 'new') {
	    } else { croak "$o->build: collision returned '$do'" }
	}
	$xx->{ $key } = $rec;
    }
    $o->{ctime} = time;
}

sub _is_corrupted {
    my ($o, $vlev) = @_;
    my $err=0;
    return $err if !exists $o->{'map'};
    my $t = $o->table;
    my $xx = $o->{'map'};
    my $a = $t->array;
    my $total=0;
    for (my $z=0; $z < $a->FETCHSIZE; $z++) {
	my $rec = $a->[$z];
	next if !defined $rec;
	my $key = $o->fetch_key($rec);
	next if !$key;
	$total++;
	my $old = $xx->{ $key };
	if (!$old || $key ne $o->fetch_key($old)) {
	    $old = 'undef' if !defined $old;
	    warn "$o->is_corrupted: key '$key' != '$old' ($rec)" if $vlev;
	    ++$err;
	}
    }
    if ($total != $xx->FETCHSIZE) {
	warn "$o->is_corrupted: array $total, but index has ".$xx->FETCHSIZE
	    if $vlev;
	++$err;
    }
    $err;
}

sub fetch { 
    my $o = shift; 
    my $map = $o->FETCH('map');
    $map->{ shift() };
}

package ObjStore::Table::Index::GroupBy;
use Carp;
use ObjStore;
use base 'ObjStore::Table::Index';
use vars qw($VERSION);
$VERSION = '0';

sub new {
    my ($class, $table, $name, $field) = @_;
    $field ||= $name;
    my $o = $class->SUPER::new($table, $name);
    $o->{_field} = $field;
    $o;
}

sub build {
    use integer;
    my ($o) = @_;
    return if $o->is_built;
    my $tbl = $o->table();
    my $arr = $tbl->array();
    my $total = $arr->FETCHSIZE();
    my $xx = $o->{ $o->name } = new ObjStore::HV($o->index_segment,
						 $total * .2 || 50);
    $o->{'map'} = $xx;

    for (my $z=0; $z < $total; $z++) {
	my $rec = $arr->[$z];
	next if !defined $rec;
	my $key = $o->fetch_key($rec);
	next if !$key;
	my $old = $xx->{ $key } ||= [];
	$old->_Push($rec);
    }
    $o->{ctime} = time;
}

sub _is_corrupted {
    my ($o, $vlev) = @_;
    warn "$o->is_corrupted: unimplemented!" if $vlev;
}

sub fetch { 
    my $o = shift; 
    my $map = $o->FETCH('map');
    $map->{ shift() };
}

1;
__END__

=head1 NAME

  ObjStore::Table2 - Simulated RDBMS Tables

=head1 SYNOPSIS

  # posh 1.21 (Perl 5.00454 ObjectStore Release 5.0.1.0)
  cd table-test ObjStore::Table2::Database

  my $a = $db->array; for (1..10) { $a->_Push({row => $_}) }

  $db->table->new_index('Field', 'row');
  $db->table->build_indices;

=head1 DESCRIPTION

 $at = TABLE ObjStore::Table2 {
  [10] of ObjStore::HV {
    row => 1,
  },
  indices: ROW;
 },

Unstructured perl databases are probably under-constrained for most
applications.  Tables standardize the interface for storing a bunch of
records and their associated indices.

=head2 Raw Representation

 $at = ObjStore::Table2 {
  _array => ObjStore::AV [
    ObjStore::HV {
      row => 1,
    },
    ObjStore::HV {
      row => 2,
    },
    ObjStore::HV {
      row => 3,
    },
    ...
  ],
  _index_segments => 1,
  row => ObjStore::Table::Index::Field {
    _field => 'row',
    _name => 'row',
    _segment => 6,
    _table => ObjStore::Ref => ObjStore::Table2 ...
    ctime => 882030349,
    map => ObjStore::HV {
      1 => ObjStore::HV ...
      10 => ObjStore::HV ...
      2 => ObjStore::HV ...
      ...
    },
    row => ObjStore::HV ...
  },
 },

=head2 API

=over 4

=item * $t->add($e)

Adds $e to the table and updates indices.

=item * $t->remove($e)

Removes $e from the table and updates indices.

=item * $t->index($index_name)

Returns the index named $index_name.

=item * $t->fetch($index_name, $key)

Returns the record resulting from looking up $key in the index named
$index_name.

=item * $t->index_segments($yes)

Indices can be allocated in their own segments or in the same segment
as the table array.  The default is to use separate segments.

=item * $t->new_index($type, @ARGS)

Creates an index of type $type using @ARGS and adds it to the table.

=item * $t->add_index($index)

Adds the given index to the table.

=item * $t->remove_index($index)

=item * $t->build_indices

=item * $t->rebuild_indices

=item * $t->drop_indices

=item * $t->repair_indices($rec, $array_index)

Attempt to repair all indices after a change at $array_index.  $rec
is the record that was added or deleted at $array_index.

=item * $t->map_indices($coderef)

Invokes $coderef->($index) over each index.

=back

=head2 Representation Independent API

A database can essentially be a table or tables can be stored within
a database.  The implementation is only slightly different in either
case.  To smooth things over, a few accessor methods are provided that
always work consistently.

=over 4

=item * $t->table

Returns the top-level hash.

=back

=head2 C<ObjStore::Table::Index>

Base class for indices.

=over 4

=item * $class->new($table, $name)

Adds an index called $name to the given table.

=item * $i->name

Returns the name of the index.

=item * $i->table

Returns the table to which the index is attached.

=item * $i->build

=item * $i->is_built

=item * $i->drop

Frees the index but preserves enough information to rebuild it.

=item * $i->rebuild

=item * $i->set_index_segment($segment)

Sets the segment where the index will be created.  May only be called
once.  A different API will be available for multisegment indices.

=back

=head2 C<ObjStore::Table::Index::Field> - DEPRECIATED

  $table->new_index('Field', $name, $field)

A basic unique index over all records.  $field is an access path into
the records to be indexed.  For example, if your records looks like
this:

  { f1 => [1,2,3] }

The access path would be C<"f1-E<gt>0"> to index the zeroth element of the
array at hash key f1.

=head2 C<ObjStore::Table::Index::GroupBy> - DEPRECIATED

  $table->new_index('GroupBy', $name, $field);

Groups all records into arrays indexed by $field.  $field is an access
path into the records to be indexed.

=head1 MIGRATION

Both C<ObjStore::HV::Database> and C<ObjStore::Table> are
bless-migratible to C<ObjStore::Table2>.

The old C<ObjStore::Table> stored all indices in a hash under the
top-level.  Table2 stores them directly in the top-level.  This should
make index lookups slightly more efficient.

=head1 BUGS

Usage is a bit more cumbersome than I would like.  The interface will
change slightly as perl supports more overload-type features.

=head1 TODO

=over 4

=item * B-Trees desperately needed!

=item *

A table is essentially a collection of indices over the same elements
whereby the indices are updated to reflect changes in the elements.

Like an event manager!  You submit events when your records change.
There are various ways to repair the table.

You cannot drop all indices because elements are not stored elsewhere.

=item *

Automatic index maintanance: the array will be overloaded so
adds/deletes trigger index updates

=item *

More built-in index types

=back

=cut
