######################################################################
# Test suite for Pod::Licensizer
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;

use Test::More;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use File::Copy qw(copy);
use Cwd;

plan tests => 2;

my $tmpdir = tempdir( CLEANUP => 1 );
my $cwd = cwd();
END { chdir $cwd };

my $script = "$Bin/../eg/licensizer";

copy "$Bin/../eg/licensizer.yml", "$tmpdir/.licensizer.yml";
copy "$Bin/eg/no-nothing.pod", "$tmpdir/Sample.pm";

chdir $tmpdir;

system("$^X $script");

open my $fh, "<$tmpdir/Sample.pm" or die $!;
my $data = join '', <$fh>;
close $fh;

like $data, qr/AUTHOR.*Bodo/s, "authors updated";
like $data, qr/LICENSE.*Zulu/s, "license updated";
