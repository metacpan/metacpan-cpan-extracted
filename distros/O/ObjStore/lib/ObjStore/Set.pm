use strict;
package ObjStore::Set;
use Carp;
use base 'ObjStore::HV';
use vars qw($VERSION);
$VERSION = '0.00';

carp "ObjStore::Set is depreciated";

sub new {
    require ObjStore::SetEmulation;
    my $class = shift;
    bless('ObjStore::SetEmulation'->new(@_), $class);
}

sub POSH_PEEK {
    my ($val, $o, $name) = @_;
    my @S;
    my $x=0;
    for (my $v=$val->first; $v; $v=$val->next) {
	++ $o->{coverage};
	last if $x++ > $o->{width}+1;
	push(@S, $v);
    }
    my $big = @S > $o->{width};
    my $limit = $big ? $o->{summary_width}-1 : @S;
    
    $o->o($name . " [");
    $o->nl;
    ++$o->{level};
    for (my $v=$val->first; $v; $v=$val->next) {
	last if $limit-- <= 0;
	$o->peek_any($v);
	$o->nl;
    }
    if ($big) {
	$o->o("...");
	$o->nl;
    }
    --$o->{level};
    $o->o("],");
    $o->nl;
}

sub a { add(@_) }
sub r { rm($_[0], $_[1]) }
sub STORE { add(@_) }

1;
