#! perl -w

use warnings;
use strict;

use File::Spec ();
use Test;
BEGIN { plan tests => 3 }

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

my $password = '83cdaf8b';

ok CryptModule(
	file         => $source_file,
	install_base => $install_base,
    allow_debug  => 1,
    addl_code    => q{croak "Whoa!"},
);

unlink $source_file;

eval "use Foo::Bar; 1";

ok $@ =~ /Whoa!/;

END {
	system("rm", "-rf", $install_base);
	chdir '..';
}

__END__
