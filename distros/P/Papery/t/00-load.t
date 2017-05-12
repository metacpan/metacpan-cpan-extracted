use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Find;
use YAML::Tiny qw( LoadFile );

# compute the module list
my @modules;
find( sub { push @modules, $File::Find::name if /\.pm$/ }, 'blib/lib' );
@modules = map { s!/!::!g; s/\.pm$//; s/^blib::lib:://; $_ } @modules;

# load the list of prerequisites
my ($prereq) = LoadFile( File::Spec->catfile( 't', 'prereq.yml' ) );

plan tests => scalar @modules;

diag("Testing Papery, Perl $], $^X");

for my $module (@modules) {

SKIP: {
        my $skip;
        for my $prereq ( @{ $prereq->{$module} || [] } ) {
            eval "use $prereq; 1;" or $skip .= "$prereq ";
            no strict 'refs';
            diag "Using $prereq version " . ${"$prereq\::VERSION"};
        }
        skip "$module, missing prereq: $skip", 1 if $skip;
        use_ok($module);
    }
}

