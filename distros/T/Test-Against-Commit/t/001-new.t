# -*- perl -*-
# t/001-new.t - check module loading and create testing directory
use strict;
use warnings;

use Test::More;
use Carp;
use File::Path ( qw| make_path | );
use File::Spec;
use File::Temp ( qw| tempdir |);
use Data::Dump ( qw| dd pp | );

BEGIN { use_ok( 'Test::Against::Commit' ); }

my $tdir = tempdir(CLEANUP => 1);
my $self;

# Error conditions for new() which can be tested by non-author users
{
    local $@;
    eval { $self = Test::Against::Commit->new([]); };
    like($@, qr/Argument to constructor must be hashref/,
        "new: Got expected error message for non-hashref argument");
}

{
    local $@;
    eval { $self = Test::Against::Commit->new(); };
    like($@, qr/Argument to constructor must be hashref/,
        "new: Got expected error message for no argument");
}

{
    local $@;
    eval { $self = Test::Against::Commit->new({ commit => 'blead' }); };
    like($@, qr/Hash ref must contain 'application_dir' element/,
        "new: Got expected error message; 'application_dir' element absent");
}

{
    local $@;
    eval { $self = Test::Against::Commit->new({ application_dir => $tdir }); };
    like($@, qr/Hash ref must contain 'commit' element/,
        "new: Got expected error message; 'commit' element absent");
}

{
    local $@;
    my $phony_dir = '/foo';
    eval { $self = Test::Against::Commit->new({
           application_dir => $phony_dir,
           commit => 'blead',
       });
    };
    like($@, qr/Could not locate application directory $phony_dir/,
        "new: Got expected error message; 'application_dir' not found");
}

{
    my $application_dir = $tdir;
    my $commit = 'blead';
    my %verified = ();
    for my $dir (qw| testing results |) {
        my $fdir = File::Spec->catdir($application_dir, $dir);
        make_path($fdir, { mode => 0755 })
            or croak "Unable to create $fdir for testing";
        $verified{$dir} = $fdir;
    }
    my $commitdir = File::Spec->catdir($verified{testing}, $commit);
    make_path($commitdir, { mode => 0755 })
            or croak "Unable to create $commitdir for testing";
    $verified{commit} = $commitdir;
    #pp \%verified;
    for my $k (sort keys %verified) {
        ok(-d $verified{$k}, "Was able to create directory $verified{$k}");
    }

    $self = Test::Against::Commit->new( {
        application_dir         => $tdir,
        commit                  => $commit,
    } );
    ok($self, "new() returned true value");
    isa_ok ($self, 'Test::Against::Commit');

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

    is($self->get_commit(), $commit, "Got expected commit");

    {
        local $@;
        eval { $self->get_commit_dir(); };
        like($@, qr/commit directory has not yet been defined/,
            "Got exception for premature get_commit_dir()");
    }

    {
        local $@;
        eval { $self->get_bin_dir(); };
        like($@, qr/bin directory has not yet been defined/,
            "Got exception for premature get_bin_dir()");
    }

    {
        local $@;
        eval { $self->get_lib_dir(); };
        like($@, qr/lib directory has not yet been defined/,
            "Got exception for premature get_lib_dir()");
    }

    {
        local $@;
        eval { $self->get_this_perl(); };
        like($@, qr/bin directory has not yet been defined/,
            "No bin dir, hence no possibility of installed perl");
    }

    {
        local $@;
        eval { $self->get_this_cpanm(); };
        like($@, qr/location of cpanm has not yet been defined/,
            "Got exception for premature get_this_cpanm()");
    }

    {
        local $@;
        eval { $self->get_cpanm_dir(); };
        like($@, qr/cpanm directory has not yet been defined/,
            "Got exception for premature get_cpanm_dir()");
    }
}

done_testing();
