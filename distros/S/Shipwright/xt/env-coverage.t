use strict;
use Test::More;
use File::Spec::Functions qw/catfile catdir/;
use File::Basename qw( dirname );
use autodie;

my $manifest = catdir( dirname(__FILE__), '..', 'MANIFEST' );
plan skip_all => 'MANIFEST does not exist' unless -e $manifest;
plan tests => 1;

open my $fh, '<', $manifest;
my @files = map { chomp; $_ } grep m{^(lib/.*\.pm$|t/.*\.t$|bin/)}, <$fh>;
close $fh;


my @we_use;
foreach my $file ( @files ) {
    open my $fh, '<', $file;
    push @we_use, (do { local $/; <$fh> } =~ m/\$ENV{['"]?([A-Z_]+)['"]?}/g);
    close $fh;
}
my %seen = map {$_ => 1} qw(PERLLIB PATH); # skip some
@we_use = grep !$seen{$_}++, @we_use;

diag "we use: ". join ', ', @we_use
    if $ENV{'TEST_VERBOSE'};

my $pod = do {
    open my $fh, '<', 'lib/Shipwright/Manual/ENV.pod';
    local $/; <$fh>;
};

my @not_documented = grep $pod !~ /^=item \Q$_\E\b/m, @we_use;

is scalar @not_documented, 0, "all used ENVs are documented"
    or diag "missing: ". join ', ', @not_documented;
