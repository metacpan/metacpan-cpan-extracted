# To make this a shared library, simply remove
# newXS("ObjStore::REP::FatTree::bootstrap",...) from ObjStore.xs
# and let the DynaLoader take care of it.

use strict;
no strict 'refs';
package ObjStore::REP::FatTree;
use vars qw($VERSION);
$VERSION = '1.01';

use base 'DynaLoader';
__PACKAGE__->bootstrap($VERSION);

$ObjStore::SCHEMA{'ObjStore::REP::FatTree'}->
    load($ObjStore::Config::SCHEMA_DBDIR."/REP-FatTree-02.adb");

require ObjStore::REP; # install only if already loaded XXX
ObjStore::REP::install(AV2 => \&ObjStore::REP::FatTree::AV::new,
		       XV1 => \&ObjStore::REP::FatTree::Index::new,
		       XV2 => \&ObjStore::REP::FatTree::KCIndex::new);

package ObjStore::REP::FatTree::Index;
require ObjStore::PathExam::Path;
use Carp;
# We don't want this package in the @ISA because that would break the
# representation abstraction.  The consequence is extra pain to do
# method calls.

# [
#   version=1,
#   is_unique=1,
#   [
#     ['field1','field2'],
#     ...,
#   ],
# ]

my $configure = sub {
    my $o = shift;
    my $rep = $o->rep_class;
    my $c = &{$rep."::_conf_slot"}($o);
    return $c if @_ == 0;
    $c ||= (__PACKAGE__.'::Conf')->new($o, [1,1,[],1]);
    my @conf = ref $_[0] ? %{$_[0]} : @_;
    while (@conf) {
	my $k = shift @conf;
	croak "$o->configure: no value found for key '$k'" if !@conf;
	my $v = shift @conf;
	if ($k eq 'unique') {
	    $c->[1] = $v;
	} elsif ($k eq 'path') {
	    $c->[2] = ObjStore::PathExam::Path->new($c, $v);
	} elsif ($k eq 'size' or $k eq 'type') {
	} elsif ($k =~ m/^excl(usive)?$/) {
	    carp "non-exclusive indices are no longer supported";
	} else {
	    carp "$o->configure: unknown parameter '$k'";
	}
    }
    &{$rep."::_conf_slot"}($o,$c);
};

my $index_path = sub {
    my ($o) = @_;
    my $rep = $o->rep_class;
    my $c = &{$rep."::_conf_slot"}($o);
    return if !$c;
    $c->[2]
};

*configure = $configure;
*index_path = $index_path;

package ObjStore::REP::FatTree::KCIndex;

*configure = $configure;
*index_path = $index_path;

package ObjStore::REP::FatTree::Index::Conf;
use base 'ObjStore::AV';
use vars qw($VERSION);
$VERSION = '1.00';

sub POSH_PEEK {
    my ($c, $p) = @_;
    # should use method call XXX
    $p->o("(".ObjStore::PathExam::Path::stringify($c->[2]).")".
	  ($c->[1] ? ' UNIQUE' : ''));
}

1;
__END__

What makes insert slow?

- keys not copied (could be optimized by hand coding push/unshift)

- relaxed depth recalc

- rotations
