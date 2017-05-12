use strict;

package ObjStore::AV::QSet;
use base 'ObjStore::AV';
use vars qw($VERSION);
use Carp;
use ObjStore ':ADV';

$VERSION = '0.01';

*add = \&ObjStore::AV::PUSH;

sub exists {
    my ($o,$e) = @_;
    defined $o->where($e);
}

sub where {
    my ($o, $e) = @_;
    return if !blessed $e;
    my $x;
    for (my $z=0; $z < $o->FETCHSIZE(); $z++) {
	my $e2 = $o->[$z];
	do { $x = $z; last } if $e2 == $e;
    }
    $x;
}

sub remove {
    my ($o, $e) = @_;
    for (my $z=0; $z < $o->FETCHSIZE(); $z++) {
	while ($e == $o->[$z]) {
	    $o->SPLICE($z,1);
	}
    }
    $e;
}

1;
__END__;

=head1 NAME

  ObjStore::AV::QSet - index-style interface with an array representation

=head1 SYNOPSIS

  my $set = ObjStore::AV::QSet->new($near, $size);

  $set->add($myobject);

  $set->remove($myobject);

=head1 DESCRIPTION

Implements an API very similar to C<ObjStore::Index>, except with an
array implementation.  Elements are unsorted.  Add is the same as
push, but <remove> scans the entire set.

=cut
