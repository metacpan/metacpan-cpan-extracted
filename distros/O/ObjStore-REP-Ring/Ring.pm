use strict;
package ObjStore::REP::Ring;
use base 'DynaLoader';
use vars qw($VERSION);
$VERSION = '0.02';

__PACKAGE__->bootstrap($VERSION);

$ObjStore::SCHEMA{'ObjStore::REP::Ring'}->
    load($ObjStore::Config::SCHEMA_DBDIR."/REP-Ring-01.adb");

package ObjStore::REP::Ring::Index;
use Carp;
use ObjStore;

# [0] version
# [1] path
# [2] descending

sub configure {
    my $o = shift;
    my $c = _conf_slot($o);
    $c ||= (__PACKAGE__.'::Conf')->new($o, [1,[],0]);
    return $c if @_ == 0;
    my @conf = ref $_[0] ? %{$_[0]} : @_;
    while (@conf) {
	my ($k,$v) = splice @conf, 0, 2;
	if ($k eq 'path') {
	    $c->[1] = ObjStore::PathExam::Path->new($c, $v);
	} elsif ($k eq 'descending') {
	    $c->[2] = $v?1:0;
	} else {
	    carp "$o->configure: unknown parameter '$k' (ignored)";
	}
    }
    _conf_slot($o, $c);
}

sub index_path {
    my ($o) = @_;
    my $c = _conf_slot($o);
    $c? $c->[1] : undef;
}

package ObjStore::REP::Ring::Index::Conf;
use base 'ObjStore::AV';

sub POSH_PEEK {
    my ($c, $p) = @_;
    $p->o("(".$c->[1]->stringify().")");
}

1;
