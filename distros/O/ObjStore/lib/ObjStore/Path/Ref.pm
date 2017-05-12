package ObjStore::Path::Ref;
use strict;
use Carp;
use ObjStore;
use base 'ObjStore::AV';
use vars qw($VERSION);
$VERSION = '1.00';

sub new {
    my ($this, $where) = @_;
    my $class = ref($this) || $this;
    my $o = $class->SUPER::new($where);
    $o;
}

sub open {
    my ($o, $how) = @_;
    my $cnt = $o->FETCHSIZE();
    for (my $x=0; $x < $cnt; $x++) {
	my $db = $o->[$x]->get_database();
	$db->open($how) if !$db->is_open;
	$o->[$x]->focus();  #must deref to check
    }
}

sub depth {
#    carp "$o->depth is depreciated";
    my ($o) = @_; $o->FETCHSIZE();
}

sub focus {
    my ($o, $xx) = @_;
    return if $o->depth == 0;
    $xx = $o->depth - 1 if !defined $xx;
    $o->[$xx]->focus;
}

1;
