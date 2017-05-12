use strict;
require ObjStore::Table2; #new version

package ObjStore::Table;
use Carp;
use ObjStore;
use base 'ObjStore::HV';
use vars qw($VERSION);
$VERSION = '0';

Carp::cluck "ObjStore::Table is depreciated";

sub new {
    my ($class, $where, $size) = @_;
    croak "$class\->new(where, size)" if @_ != 3;
    my $o = $class->SUPER::new($where);
    my $seg = $o->database_of->create_segment("table cluster");
    $o->{array} = new ObjStore::AV($seg, $size);
    $o->{indices} = {};
    $o;
}

# works as database or not
sub table { $_[0]; }
sub array { $_[0]->{array}; }
sub indices { $_[0]->{'indices'}; }
sub index { $_[0]->{'indices'}{$_[1]}; }
sub fetch { my $o=shift; $o->index(shift)->fetch(@_) }

sub new_index {
    my ($o, $type, @REST) = @_;
    my $class = 'ObjStore::Table::Index::'.$type;
    $o->add_index($class->new($o, @REST));
}

sub add_index {
    my ($o, $index) = @_;
    $o->indices->{ $index->name } = $index;
}

sub remove_index {
    my ($o, $name) = @_;
    die "$o->remove_index($name): index doesn't exist"
	if !exists $o->indices->{ $name };
    delete $o->indices->{ $name };
}

sub build_indices {
    my ($o) = @_;
    for my $i (values %{ $o->indices }) { $i->build unless $i->is_built; }
}

sub rebuild_indices {
    my ($o) = @_;
    for my $i (values %{ $o->indices }) { $i->rebuild; }
}

sub drop_indices {
    my ($o) = @_;
    for my $i (values %{ $o->indices }) { $i->drop; }
}

sub NOREFS {
    # arg will never be a database
    my $o = shift;
    delete $o->{'indices'};
}

sub POSH_PEEK {
    my ($val, $o, $name) = @_;
    $o->o("TABLE ". $name . " {");
    $o->nl;
    $o->indent(sub {
	my $ar = $val->array;
	$o->o("array[".$ar->_count ."] of ");
	$o->peek_any($ar->[0]);
	$o->nl;
	$o->o("indices: ");
	$o->o(join(', ', sort map { $_->is_built ? uc($_->name) : $_->name }
		   values %{ $val->indices }), ";");
	$o->nl;
	my $table = $val->table;
	for my $k (sort keys %{ $table }) {
	    next if ($k eq 'array' or $k eq 'indices');
	    $o->o("$k => ");
	    my $v = $table->{$k};
	    if (ref $v) { $o->o("..."); }
	    else { $o->peek_any($v); }
	    $o->nl;
	}
    });
    $o->o("},");
    $o->nl;
}

sub POSH_CD {
    my ($t, $to) = @_;
    if ($to =~ m/^\d+$/) {
	$t->array->[$to];
    } else {
	$t->index->{$to};
    }
}

package ObjStore::Table::Database;
use ObjStore;
use base 'ObjStore::Database';
use vars qw($VERSION @ISA);
push(@ISA, 'ObjStore::Table');
$VERSION = '0';

sub ROOT() { 'table' }
sub default_size() { 21 }  #can override

sub new {
    my $class = shift;
    my $db = $class->SUPER::new(@_);
    $db->table; #set root
    $db;
}

sub table {
    my ($db) = @_;
    $db->root(&ROOT, sub { ObjStore::Table->new($db, &default_size) } );
}
sub array { $_[0]->root(&ROOT)->{array}; }
sub indices { $_[0]->root(&ROOT)->{'indices'}; }
sub index { $_[0]->root(&ROOT)->{'indices'}{$_[1]}; }

sub BLESS {
    return $_[0]->SUPER::BLESS($_[1]) if ref $_[0];
    my ($class, $db) = @_;
    if ($db->isa('ObjStore::HV::Database')) {
	warn 'convert';
	my $o = $db->table;
	my $ar = $o->array;
	my $hash = $db->hash;
	for my $z (values %$hash) {
	    warn "push $z";
	    $ar->_Push($z);
	}
	$db->destroy_root($db->ROOT);
    }
    $class->SUPER::BLESS($db);
}

sub POSH_ENTER { shift->table; }

1;
