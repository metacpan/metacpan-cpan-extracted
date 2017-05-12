use strict;
package ObjStore::Posh::Remote;
use ObjStore;
use base 'ObjStore::HV';
use vars qw($VERSION);
$VERSION = '0.01';

use ObjStore::notify qw(enter);
sub do_enter {
    my ($o,$k) = @_;
    require ObjStore::Posh::Cursor;
    $$o{$k} ||= ObjStore::Posh::Cursor->new($o);
}

1;
