package ObjStore::Path::Cursor;
use strict;
use Carp;
use ObjStore;
use base 'ObjStore::Path::Ref';
use vars qw($VERSION);
$VERSION = '0.01';

# Do something reasonable if the stack is made of Cursors.

sub seek_pole {
    my ($o, $side) = @_;
    croak "Cursor unset" if $o->depth == 0;
    croak "Can't seek to end yet" if $side eq 'end';
    my $cs = $o->[$o->depth -1];
    $cs->seek_pole(0);
}

sub at {
    my ($o) = @_;
    croak "Cursor unset" if $o->depth == 0;
    my $cs = $o->[$o->depth -1];
    $cs->at;
}

sub next {
    my ($o) = @_;
    croak "Cursor unset" if $o->depth == 0;
    my $cs = $o->[$o->depth -1];
    $cs->next;
}

1;
