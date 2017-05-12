use strict;
package ObjStore::REP::Splash;
require ObjStore::PathExam::Path;

use base 'DynaLoader';
__PACKAGE__->bootstrap($ObjStore::VERSION);

$ObjStore::SCHEMA{'ObjStore::REP::Splash'}->
    load($ObjStore::Config::SCHEMA_DBDIR."/REP-Splash-02.adb");

package ObjStore::REP::Splash::Heap;
use Carp;

# [
#   version=0
#   [
#     ['key1','key2'],
#     ...
#   ],
#   descending=0,
# ]

sub configure {
    my $o = shift;
    my $c = ObjStore::REP::Splash::Heap::_conf_slot($o);
    $c ||= (__PACKAGE__.'::Conf')->new($o, [0,[],0]);
    return $c if @_ == 0;
    my @C = ref $_[0] ? %{$_[0]} : @_;
    while (@C) {
	my $k = shift @C;
	croak "$o->configure: no value for '$k'" if !@C;
	my $v = shift @C;
	if ($k eq 'path') {
	    $c->[1] = ObjStore::PathExam::Path->new($c, $v);
	} elsif ($k eq 'descending') {
	    $c->[2] = $v;
	} elsif ($k eq 'ascending') {
	    $c->[2] = !$v;
	} else {
	    carp "$o->configure: unknown parameter '$k'";
	}
    }
    ObjStore::REP::Splash::Heap::_conf_slot($o, $c);
}

sub index_path {
    my ($o) = @_;
    my $c = ObjStore::REP::Splash::Heap::_conf_slot($o);
    return if !$c;
    $c->[1]
}

package ObjStore::REP::Splash::Heap::Conf;
use base 'ObjStore::AV';

sub POSH_PEEK {
    my ($c, $p) = @_;
    # should use method call XXX
    $p->o("(".ObjStore::PathExam::Path::stringify($c->[1]).")");
}

1;
