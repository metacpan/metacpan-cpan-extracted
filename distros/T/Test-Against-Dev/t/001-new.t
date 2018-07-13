# -*- perl -*-
# t/001-new.t - check module loading and create testing directory
use strict;
use warnings;

use Test::More;
use File::Temp ( qw| tempdir |);
#use Data::Dump ( qw| dd pp | );

BEGIN { use_ok( 'Test::Against::Dev' ); }

my $tdir = tempdir(CLEANUP => 1);
my $self;

{
    local $@;
    eval { $self = Test::Against::Dev->new([]); };
    like($@, qr/Argument to constructor must be hashref/,
        "new: Got expected error message for non-hashref argument");
}

{
    local $@;
    eval { $self = Test::Against::Dev->new(); };
    like($@, qr/Argument to constructor must be hashref/,
        "new: Got expected error message for no argument");
}

{
    local $@;
    eval { $self = Test::Against::Dev->new({}); };
    like($@, qr/Hash ref must contain 'application_dir' element/,
        "new: Got expected error message; 'application_dir' element absent");
}

{
    local $@;
    my $phony_dir = '/foo';
    eval { $self = Test::Against::Dev->new({ application_dir => $phony_dir }); };
    like($@, qr/Could not locate $phony_dir/,
        "new: Got expected error message; 'application_dir' not found");
}

$self = Test::Against::Dev->new( {
    application_dir         => $tdir,
} );
isa_ok ($self, 'Test::Against::Dev');

my $top_dir = $self->get_application_dir;
is($top_dir, $tdir, "Located top-level directory $top_dir");

for my $dir ( qw| testing results | ) {
    my $fdir = File::Spec->catdir($top_dir, $dir);
    ok(-d $fdir, "Located $fdir");
}
my $testing_dir = $self->get_testing_dir;
my $results_dir = $self->get_results_dir;
ok(-d $testing_dir, "Got testing directory: $testing_dir");
ok(-d $results_dir, "Got results directory: $results_dir");

can_ok('Test::Against::Dev', 'configure_build_install_perl');
can_ok('Test::Against::Dev', 'fetch_cpanm');

done_testing();
