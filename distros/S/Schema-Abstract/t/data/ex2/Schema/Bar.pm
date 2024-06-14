package Schema::Bar;

use base qw(Schema::Abstract);
use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use IO::Barf qw(barf);

sub _versions_file {
	my $temp_dir = tempdir(CLEANUP => 1);

	my $versions_file = catfile($temp_dir, 'versions.txt');
        barf($versions_file, "0.1.0");

        return $versions_file;
}

1;
