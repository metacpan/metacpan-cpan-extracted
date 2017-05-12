use strict;

package ObjStore::Table3;
use Carp;
use ObjStore ':ADV';
#require ObjStore::AV::Set; #?
use base 'ObjStore::HV';
use vars qw($VERSION);
$VERSION = '1.05';

sub new {
    use attrs 'method';
    my ($class, $where) = @_;
    croak "$class\->new(where)" if @_ != 2;
    my $o = $class->SUPER::new($where);
    $o;
}

sub add_index {
    use attrs 'method';
    my ($o, $name, $index) = @_;
    croak "keys starting with underscore are reserved"
	if $name =~ m/^_/;
    return $o->{$name} if $o->{$name};
    $index = $index->()
	if ref $index eq 'CODE';
    croak "'$index' doesn't look like a real index" if !blessed $index;

    my $any = $o->anyx;
    if ($any) {
	# index must work like an array ref
	for (my $x=0; $x < $any->FETCHSIZE(); $x++) {
	    $index->add($any->[$x]);
	}
    }
    $o->{ $name } = $index;

    $$o{_primary} ||= $index;
    $$o{_allindices} ||= [];
    $$o{_allindices}->PUSH($name);
    $index;
}

sub remove_index {
    use attrs 'method';
    my ($o, $name) = @_;
    die "$o->remove_index($name): is not an index"
	if !exists $o->{ $name };
    delete $o->{ $name };
    @{$$o{_allindices}} = grep($_ ne $name, @{$$o{_allindices}});
    if (@{$$o{_allindices}}) {
	$$o{_primary} = $o->index($$o{_allindices}->[0]);
    } else {
	$$o{_primary} = undef;
    }
}

sub index {
    use attrs 'method';
    $_[0]->{$_[1]};
}

sub fetch {
    use attrs 'method';
    my $t=shift;
    my $iname = shift;
    my $i = $t->{ $iname };
    croak "can't find index '$iname'" if !$i;
    my $c = $i->new_cursor;
    if (!wantarray) {
	return $c->seek(@_)? $c->at : undef;
    } else {
	my $pe = ObjStore::PathExam->new;
	$pe->load_args(@_);
	$c->step(1) if !$c->seek($pe); # exact match not needed
	my @got;
	while (my $e = $c->at) {
	    last if $pe->compare($e) != 0;
	    push @got, $e;
	    $c->step(1);
	}
	@got;
    }
}

sub at {
    my ($o, $iname, $where) = @_;
    my $x = $o->{$iname};
    croak "Can't find index '$iname'" if !$x;
    my $len = @$x;
    return if $len == 0;
    my $c = $x->new_cursor;
    $c->moveto($where eq 'last'? $len-1 : $where);
    $c->at();
}

sub anyx {
    use attrs 'method';
    my ($o) = @_;
    if ($$o{_primary}) {
	return $$o{_primary};
    } else {
	if ($$o{_allindices}) {
	    for my $i (@{$$o{_allindices}}) {
		return $i if @$i;
	    }
	} else {
	    # bend over backwards...!
	    for my $i (values %$o) {
		next unless blessed $i && $i->isa('ObjStore::Index');
		return $i if @$i;
	    }
	}
    }
    undef;
}

sub rows {
    use attrs 'method';
    my ($t) = @_;
    my $i = $t->anyx;
    $i? $i->count : 0;
}

sub map {
    use attrs 'method';
    my ($t, $sub) = @_;
    my $x = $t->anyx;
    return if !$x;
    $x->map($sub);
}

sub all_indices {
    use attrs 'method';
    shift->{_allindices} || []
}

sub map_indices {
    use attrs 'method';
    my ($o, $c) = @_;
    for my $i (@{$$o{_allindices}}) {
	$c->( $$o{$i} );
    }
}

sub add {
    use attrs 'method';
    croak 'ObjStore::Table3->add($)' if @_ != 2;
    my ($t, $o) = @_;
    $o = ObjStore::translate($t->segment_of, $o)
	if !ObjStore::UNIVERSAL::_is_persistent($o);
    $t->map_indices(sub { shift->add($o) });
    defined wantarray ? $o : ();
}
sub remove {
    use attrs 'method';
    croak 'ObjStore::Table3->remove($)' if @_ != 2;
    my ($t, $o) = @_;
    $t->map_indices(sub { shift->remove($o) });
}

sub compress {
    warn "not yet";
}

sub table { $_[0]; }

package ObjStore::Table3::Database;
use Carp;
use ObjStore;
use base 'ObjStore::Database';
use vars qw'$VERSION @ISA';
push(@ISA, 'ObjStore::Table3');
$VERSION = '1.00';

sub new {
    warn "ObjStore::Table3::Database is depreciated; just use ObjStore::HV::Database";
    my $class = shift;
    my $db = $class->SUPER::new(@_);
    begin 'update', sub {
	$db->table; #force root setup
    };
    $db;
}

sub table {
    my ($db) = @_;
    $db->root('ObjStore::Table3', sub { ObjStore::Table3->new($db) } );
}

sub POSH_ENTER { shift->table; }

1;
__END__

=head1 NAME

  ObjStore::Table3 - RDBMS Style Tables

=head1 SYNOPSIS

  my $table = ObjStore::Table3->new($near);
  $table->add_index('name', sub { ObjStore::Index->new($table, path => 'name') }};

=head1 DESCRIPTION

Unstructured perl databases are probably under-constrained for most
applications.  Tables standardize the interface for storing a bunch of
records and their associated indices.

A table is no more than a collection of indices (as opposed to a some
sort of heavy-weight object).  Think of it like an event manager for
indices.

=head2 API

=over 4

=item * $t->anyx

Returns a non-empty index.

=item * $t->add($e)

Adds $e to all table indices.

=item * $t->remove($e)

Removes $e from all table indices.

=item * $t->index($index_name)

Returns the index named $index_name.

=item * $t->fetch($index_name, @keys)

Returns the record resulting from looking up @keys in the index named
$index_name.  Also works in an array context.

=item * $t->at($index_name, $offset)

The $offset should either be numeric or 'last'.

=item * $t->add_index($name, $index)

Adds an index.  The index can be a closure if your not sure if it
already exists.

=item * $t->remove_index($index)

=item * $t->map_indices($coderef)

Calls $coderef->($index) on each index.

=back

=head2 CAVEAT

Be aware that index cursors may only be used by one process/thread at
a time.  Therefore, it is usually not helpful to store pre-created
cursors in a database.

=head1 TODO

I'm fairly satisfied at this point.  Some thing may still be improved.
Ideas welcome!

=cut
