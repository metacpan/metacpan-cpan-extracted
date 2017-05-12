#! perl -w

# This test needs to be run under debugger.

use warnings;
use strict;

use File::Spec ();
use Test;
BEGIN { plan tests => 4 }

use ExtUtils::testlib;
use Module::Crypt;
ok eval "require Module::Crypt";

BEGIN {
	chdir 't';
	use lib 'output';
}

our $source_file = File::Spec->rel2abs('Bar.pm');
our $install_base = File::Spec->rel2abs('output');
	
sub print_source {
	local *FH;
	open FH, "> $source_file" or die "Can't create $source_file: $!";
	print FH <<'EOF';
package Foo::Bar;
use strict;
use warnings;
our $VERSION = 1.00;
sub multiply {
	return $_[0] * $_[1];
}
1;
EOF
	close FH;
}

print_source();

ok CryptModule(
    file => $source_file,
    install_base => $install_base,
);

unlink $source_file;

ok eval "use Foo::Bar; 1";
ok eval { (Foo::Bar::multiply(2,3) == 6) };

END {
	system("rm", "-rf", $install_base);
	chdir '..';
}

__END__
