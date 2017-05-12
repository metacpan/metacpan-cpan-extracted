package MyBuild;

use strict;
use warnings;

use base qw/ Module::Build /;

my $version = scalar `caca-config --version` or do {

   warn <<'END';

caca-config not found, is libcaca installed?

If your distribution doesn't provide a package, 
libcaca can be found at http://caca.zoy.org/wiki/libcaca

END

    exit 0;
};

chomp $version;

print "libcaca version $version found\n\n";

sub new {
    my ( $self, %args ) = @_;

    return $self->SUPER::new( 
        extra_compiler_flags => scalar `caca-config --cflags`,
        extra_linker_flags   => scalar `caca-config --libs`,  
        %args );
}

1;
