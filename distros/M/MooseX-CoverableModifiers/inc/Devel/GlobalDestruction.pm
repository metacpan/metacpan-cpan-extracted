#line 1
#!/usr/bin/perl

package Devel::GlobalDestruction;

use strict;
use warnings;

use XSLoader;

our $VERSION = '0.04';

use Sub::Exporter -setup => {
	exports => [ qw(in_global_destruction) ],
	groups  => { default => [ -all ] },
};

if (defined ${^GLOBAL_PHASE}) {
    eval 'sub in_global_destruction () { ${^GLOBAL_PHASE} eq q[DESTRUCT] }';
}
else {
    XSLoader::load(__PACKAGE__, $VERSION);
}

__PACKAGE__

__END__

#line 94


