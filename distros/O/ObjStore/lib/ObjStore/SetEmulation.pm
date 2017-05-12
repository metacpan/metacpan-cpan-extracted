package ObjStore::SetEmulation;  # can you spell 'hack' ?
use Carp;
use ObjStore;
require ObjStore::Set;
use vars qw($VERSION @ISA);
$VERSION = 'You suck!';
@ISA = qw(ObjStore::Set ObjStore::HV);

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    if ($class eq 'ObjStore::SetEmulation') {
	#ok
    } elsif ($class eq 'ObjStore::Set') {
	$class = 'ObjStore::SetEmulation';
    } else {
	for (@{"${class}::ISA"}) {
	    $_ = 'ObjStore::SetEmulation' if $_ eq 'ObjStore::Set';
	}
    }
    my $o = new ObjStore::HV(@_);
    ObjStore::bless $o, $class;
}

sub a { ObjStore::SetEmulation::add(@_) }
sub r { ObjStore::SetEmulation::rm($_[0], $_[1]) }
sub STORE { ObjStore::SetEmulation::add(@_) }

sub add {
    my $o = shift;
    for my $nv (@_) {
	my $class = ref $nv;
	croak "Sets can only hold objects (not $nv)" if !$class;

	if ($class eq 'ARRAY' or $class eq 'HASH' or
	    !$nv->can('get_pointer_numbers')) {
	    $nv = ObjStore::translate($o, $nv);
	}
	my $k = $nv->get_pointer_numbers();
	$o->ObjStore::HV::STORE($k, $nv);
    }
}

sub rm {
    my ($o, $z) = @_;
    delete $o->{$z->get_pointer_numbers()};
}

sub contains {
    my ($o, $z) = @_;
    exists $o->{$z->get_pointer_numbers()};
}

sub first() {
    my $o=shift;
    my $k = $o->ObjStore::HV::FIRSTKEY;
    $k? $o->{$k}:undef;
}

sub next() {
    my $o=shift;
    my $k = $o->ObjStore::HV::NEXTKEY('prev');
    $k? $o->{$k}:undef;
}

sub new_cursor {
    my ($o, $where) = @_;
    bless $o->ObjStore::HV::new_cursor($where), 'ObjStore::SetEmulation::Cursor';
}

package ObjStore::SetEmulation::Cursor;
use ObjStore;
use vars '@ISA';
@ISA = 'ObjStore::Cursor';

sub at {
    my ($o) = @_;
    my @ret = $o->SUPER::at();
    @ret? ($ret[1]) : ();
}

sub next {
    my ($o) = @_;
    my @ret = $o->SUPER::next();
    @ret? ($ret[1]) : ();
}

1;
