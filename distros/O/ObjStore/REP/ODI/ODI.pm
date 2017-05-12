use strict;
package ObjStore::REP::ODI;

use base 'DynaLoader';
__PACKAGE__->bootstrap($ObjStore::VERSION);

$ObjStore::SCHEMA{'ObjStore::REP::ODI'}->
    load($ObjStore::Config::SCHEMA_DBDIR."/REP-ODI-01.adb");

package ObjStore::REP::ODI::HashIndex;
use Carp;

# The HashIndex project has been delayed. XXX

sub configure {
    my $o = shift;
    my $c = $o->ObjStore::REP::ODI::HashIndex::_conf_slot();
    $c ||= [0,1,[]];
    return $c if @_ == 0;
    my @conf = ref $_[0] ? %{$_[0]} : @_;
    while (@conf) {
	my $k = shift @conf;
	croak "$o->configure: no value found for key '$k'" if !@conf;
	my $v = shift @conf;
	if ($k eq 'unique') {
	    croak "$o only supports unique indices" if !$v;
	} elsif ($k eq 'path') {
	    my @comp = split(m",\s*", $v);
	    # maybe do multiple keys by gluing them together with "$;"? XXX
	    croak "$o cannot handle more than one key" if @comp>1;
	    croak("$o->configure(path=>'$v'): invalidate") if @comp==0;
	    $c->[2] = [map {[map {"$_\0"} split(m"\/", $_)]} @comp];
	} elsif ($k eq 'size' or $k eq 'type') {
	} else {
	    carp "$o->configure: unknown parameter '$k'";
	}
    }
    bless $c, __PACKAGE__.'::Conf';
    $o->ObjStore::REP::ODI::HashIndex::_conf_slot($c);
}

package ObjStore::REP::ODI::HashIndex::Conf;
use base 'ObjStore::AV';
use vars qw($VERSION);
$VERSION = '1.00';

#POSH_PEEK

1;
