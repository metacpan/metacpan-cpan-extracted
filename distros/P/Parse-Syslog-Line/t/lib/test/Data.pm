package test::Data;

use strict;
use warnings;

use Exporter;
use FindBin;
use Module::Load qw(load);
use Path::Tiny qw(path);
use Storable qw(dclone);
use YAML::XS ();

our @ISA = qw(Exporter);
our @EXPORT = qw(get_test_data);
our @EXPORT_OK = qw(get_test_data);
our %EXPORT_TAGS = ();

my %TESTS;

sub _load_tests {
    return if %TESTS;

    my $has_json = eval { load 'JSON::MaybeXS'; 1; };
    my $bin      = path("$FindBin::Bin");
    my $parent   = $bin->parent();
    my $dir      = $parent->child(t => 'data');

    my %checks = (
        string   => sub { length },
        expected => sub { ref $_ eq 'HASH' },
    );
    # Scan all the tests
    $dir->visit(sub {
        my ($p) = @_;

        # Skip non-yaml files
        return unless $p->is_file and $p->stringify =~ /\.yaml/;

        # Load the Test Data, fatal errors will cause test failures
        eval {
            my $test = YAML::XS::LoadFile( $p->stringify );
            my $name = $p->relative($parent);

            if( $test->{options} and $test->{options}{AutoDetectJSON} ) {
                die "SKIPPED: No JSON::MaybeXS" unless $has_json;
            }
            foreach my $check ( sort keys %checks ) {
                die "Missing required key: $check" unless $test->{$check};
                local $_ = $test->{$check};
                die "Validating $check failed!" unless $checks{$check}->();
            }
            $TESTS{$name} = $test;
            1;
        } or do {
            my $err = $@;
            warn(sprintf "loading YAML in %s failed: %s",
                $p->stringify,
                $err,
            );
        };
    });
}

sub get_test_data {
    _load_tests();
    return dclone(\%TESTS);
}

1;
