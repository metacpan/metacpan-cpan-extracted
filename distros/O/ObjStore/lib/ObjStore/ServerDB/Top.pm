use strict;
package ObjStore::ServerDB::Top;
use Carp;
use ObjStore;
use base 'ObjStore::HV';
use vars qw($VERSION);
$VERSION = '1.00';

sub DELETE {
    my ($h,$k) = @_;
    warn "$h->DELETE($k)" if $osperlserver::Debug{b};
    if (ref $k) {
	for (keys %$h) { $h->SUPER::DELETE($_) if $h->{$_} == $k; }
    } else {
	$h->SUPER::DELETE($k);
    }
}

sub _install {
    my ($o, $i, $pk) = @_;
    $pk ||= ref $i;
    warn "$o->_install($pk,$i)" if $osperlserver::Debug{b};
    $$o{ $pk } = $i; #overwrite!
    no strict 'refs';
    for my $u (@{"$pk\::ISA"}) {
	$o->_install($i, $u);
    }
}

use ObjStore::notify qw(boot_class);
sub do_boot_class {
    no strict 'refs';
    # flag to override?
    my ($o,$class) = @_;
    warn "$o->boot_class($class)" if $osperlserver::Debug{b};
    unless (defined %{"$class\::"}) {
	my $file = $class;
	$file =~ s,::,/,g;
	require $file.".pm";  #it must be loaded!
    }
    my $i = $o->SUPER::FETCH($class);
    return $i if $i;
    if (!$class->can('new')) {
	eval {
	    require Devel::Symdump;
	    warn Devel::Symdump->isa_tree;
	};
	die "$class->new: Can't locate object method 'new' (\%INC=\n\t".join("\n\t", sort keys %INC).")";
    }
    $i = $class->new($o->create_segment($class));
    die "$class->new(...) returned '$i'" if !ref $i;
    $o->_install($i);
    $i
}

sub boot {
    my $o = shift;
    for (@_) { $o->do_boot_class($_) }
}

1;
