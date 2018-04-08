use strict;
use warnings;

use File::Basename qw( dirname );
use File::Spec;
use Test::More tests => 4;

use_ok('Test::PLP');

sub lacks_string($$;$) {
	unlike($_[0], qr/\Q$_[1]/, $_[2]);
}
eval {
	Test::LongString->import('lacks_string');  # set up by Test::PLP
};

chdir File::Spec->catdir(dirname($0), '..', 'eg')
	or BAIL_OUT('cannot change to test directory ../eg/');

for my $file (glob '*.plp') {
	(my $name = $file) =~ s/[.][^.]+$//;
	my $output = plp_is($file, undef, undef, undef, $name);
	lacks_string($output, '"PLPerror"', "$name no errors");
	lacks_string($output, '<warning>', "$name no warnings");
}

