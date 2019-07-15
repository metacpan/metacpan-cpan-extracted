#!/usr/bin/env perl

package main v0.1.0;

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        require Test::More;

        Test::More::plan( skip_all => 'these tests are for release candidate testing' );
    }
}

use Pcore;
use Test::More;
use Pcore::Lib::File::Tree;

our $TESTS = 52;

plan tests => $TESTS;

my $skip = 0;

# not found dist by path
run_test(
    skip           => undef,
    dist_share_dir => 0,
    cpan_lib       => 'blib/lib',
    cpan_share_dir => 1,
    sub ($t) {
        ok( !defined Pcore::Dist->new( $t->{dist_root} ), $t->{test_id} . '_dist_not_found_1' );

        ok( !defined Pcore::Dist->new( $t->{cpan_lib} ), $t->{test_id} . '_dist_not_found_2' );

        return;
    }
);

# not found dist by module name
run_test(
    skip           => undef,
    dist_share_dir => 0,
    cpan_lib       => 'blib/lib',
    cpan_share_dir => 1,
    sub ($t) {
        ok( !defined Pcore::Dist->new('Fake::Module::Name::XXXXXXXXX'), $t->{test_id} . '_dist_not_found_1' );

        ok( !defined Pcore::Dist->new('Fake/Module/Name/XXXXXXXXX.pm'), $t->{test_id} . '_dist_not_found_2' );

        return;
    }
);

# find dist by path
run_test(
    skip           => undef,
    dist_share_dir => 1,
    cpan_lib       => 'blib/lib',
    cpan_share_dir => 1,
    sub ($t) {
        my $dist = Pcore::Dist->new( $t->{dist_root} );

        test_dist( 'dist', $dist, $t );

        return;
    }
);

# find dist by path
run_test(
    skip           => undef,
    dist_share_dir => 1,
    cpan_lib       => 'blib/lib',
    cpan_share_dir => 1,
    sub ($t) {
        my $dist = Pcore::Dist->new( $t->{cpan_lib} );

        test_dist( 'dist', $dist, $t );

        return;
    }
);

# find dist by module name
# module is not loaded, located in dist lib
run_test(
    skip           => undef,
    dist_share_dir => 1,
    cpan_lib       => 'blib/lib',
    cpan_share_dir => 1,
    sub ($t) {

        # remove CPAN lib from @INC
        my $cpan_lib = shift @INC;

        my $dist = Pcore::Dist->new( $t->{package_name} );

        unshift @INC, $cpan_lib;

        test_dist( 'dist', $dist, $t );

        return;
    }
);

# find dist by module name
# module is not loaded, located in CPAN lib
run_test(
    skip           => undef,
    dist_share_dir => 1,
    cpan_lib       => 'blib/lib',
    cpan_share_dir => 1,
    sub ($t) {
        my $dist = Pcore::Dist->new( $t->{package_name} );

        test_dist( 'cpan', $dist, $t );

        return;
    }
);

# find dist by module name
# module is loaded from dist lib
run_test(
    skip           => undef,
    dist_share_dir => 1,
    cpan_lib       => 'blib/lib',
    cpan_share_dir => 1,
    sub ($t) {

        # remove CPAN lib from @INC
        my $cpan_lib = shift @INC;

        # module loaded from CPAN location
        P->class->load( $t->{package_name} );

        unshift @INC, $cpan_lib;

        my $dist = Pcore::Dist->new( $t->{package_name} );

        test_dist( 'dist', $dist, $t );

        return;
    }
);

# find dist by module name
# module is loaded from CPAN lib
run_test(
    skip           => undef,
    dist_share_dir => 1,
    cpan_lib       => 'blib/lib',
    cpan_share_dir => 1,
    sub ($t) {

        # module loaded from CPAN location
        P->class->load( $t->{package_name} );

        my $dist = Pcore::Dist->new( $t->{package_name} );

        test_dist( 'cpan', $dist, $t );

        return;
    }
);

# PAR
run_test(
    skip => 0,
    par  => 1,
    sub ($t) {
        my $dist = Pcore::Dist->new( $ENV{PAR_TEMP} );

        test_dist( 'par', $dist, $t );

        return;
    }
);

done_testing $TESTS;

sub run_test (@args) {
    my $test = pop @args;

    state $i = 0;

    my $dist_name = 'Pcore-Test-DistXXX' . ++$i;

    my %args = (
        skip           => undef,    # skip test
        par            => 0,        # create PAR test environment
        dist_share_dir => 1,        # generate /dist_root/share/$Pcore::Core::Const::DIST_CFG_FILENAME
        cpan_lib       => undef,    # generate CPAN lib
        cpan_share_dir => 0,        # make CPAM lib dist
        @args,
    );

    return if $args{skip} // $skip;

    if ( $args{par} ) {
        $args{prefix} = 'inc/';

        delete $args{cpan_lib};

        delete $args{cpan_share_dir};
    }
    else {
        $args{prefix} = $EMPTY;
    }

    my $t = generate_test_dir( $dist_name, \%args );

    local $ENV{PAR_TEMP} = $t->{dist_root} if $args{par};

    $t->{test_id} = $i;

    my $temp = delete $t->{temp};

    my @old_inc = @INC;

    unshift @INC, "$t->{dist_lib}";

    unshift @INC, "$t->{cpan_lib}" if $t->{cpan_lib};

    $test->($t);

    # cleanup
    @INC = @old_inc;    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

    delete $INC{ $t->{package_name} };

    return;
}

sub test_dist ( $type, $dist, $t ) {
    if ( $type eq 'cpan' ) {
        ok( !defined $dist->{root}, $t->{test_id} . '_dist_root' );

        ok( $dist->{share_dir} eq $t->{cpan_share_dir}, $t->{test_id} . '_dist_share_dir' );

        ok( $dist->{is_installed}, $t->{test_id} . '_dist_is_installed' );

        ok( $dist->module->name eq $t->{module_name}, $t->{test_id} . '_dist_module_name' );

        ok( $dist->module->path eq $t->{cpan_module_path}, $t->{test_id} . '_dist_module_path' );

        ok( $dist->module->lib eq $t->{cpan_lib}, $t->{test_id} . '_dist_module_lib' );

        ok( $dist->module->is_cpan_module, $t->{test_id} . '_dist_module_is_cpan_module' );
    }
    elsif ( $type eq 'dist' ) {
        ok( $dist->{root} eq $t->{dist_root}, $t->{test_id} . '_dist_root' );

        ok( $dist->{share_dir} eq $t->{dist_share_dir}, $t->{test_id} . '_dist_share_dir' );

        ok( !$dist->{is_installed}, $t->{test_id} . '_dist_is_installed' );

        ok( $dist->module->name eq $t->{module_name}, $t->{test_id} . '_dist_module_name' );

        ok( $dist->module->path eq $t->{dist_module_path}, $t->{test_id} . '_dist_module_path' );

        ok( $dist->module->lib eq $t->{dist_lib}, $t->{test_id} . '_dist_module_lib' );

        ok( !$dist->module->is_cpan_module, $t->{test_id} . '_dist_module_is_cpan_module' );
    }
    elsif ( $type eq 'par' ) {
        ok( !$dist->{root}, $t->{test_id} . '_dist_root' );

        ok( $dist->{share_dir} eq $t->{dist_share_dir}, $t->{test_id} . '_dist_share_dir' );

        ok( $dist->{is_installed}, $t->{test_id} . '_dist_is_installed' );

        ok( $dist->module->name eq $t->{module_name}, $t->{test_id} . '_dist_module_name' );

        ok( $dist->module->path eq $t->{dist_module_path}, $t->{test_id} . '_dist_module_path' );

        ok( $dist->module->lib eq $t->{dist_lib}, $t->{test_id} . '_dist_module_lib' );

        # NOTE not correct, under PAR module->is_cpan_module always should be 1, but this not work under tests because we do not generate lib/auto/ dir
        # ok( $dist->module->is_cpan_module, $t->{test_id} . '_dist_module_is_cpan_module' );
    }
    else {
        die 'unknown dist test type';
    }

    return;
}

sub generate_test_dir ( $dist_name, $args ) {
    my $res = {
        dist_name        => $dist_name,
        package_name     => $dist_name =~ s[-][::]smgr,
        module_name      => $dist_name =~ s[-][/]smgr . '.pm',
        dist_root        => undef,
        dist_lib         => undef,
        dist_module_path => undef,
        dist_share_dir   => undef,
        cpan_lib         => undef,
        cpan_module_path => undef,
        cpan_share_dir   => undef,
    };

    my $tree = Pcore::Lib::File::Tree->new;

    my $dist_cfg = P->data->to_yaml( { name => $dist_name } );

    my $package = <<"PERL";
package $res->{package_name} v0.1.0;

1;
PERL

    # create dist root
    $tree->add_file( "$args->{prefix}/lib/$res->{module_name}", \$package );

    $tree->add_file( "$args->{prefix}/share/dist.yaml", \$dist_cfg ) if $args->{dist_share_dir};

    # create cpan lib
    if ( $args->{cpan_lib} ) {
        $tree->add_file( "$args->{prefix}/$args->{cpan_lib}/$res->{module_name}", \$package );

        $tree->add_file( "$args->{prefix}/$args->{cpan_lib}/auto/share/dist/$dist_name/dist.yaml", \$dist_cfg ) if $args->{cpan_share_dir};
    }

    $res->{temp} = $tree->write_to_temp;

    $res->{dist_root} = $res->{temp};

    $res->{dist_lib} = P->path("$res->{dist_root}/$args->{prefix}/lib");

    $res->{dist_module_path} = P->path("$res->{dist_root}/$args->{prefix}/lib/$res->{module_name}");

    $res->{dist_share_dir} = P->path("$res->{dist_root}/$args->{prefix}/share")->to_abs if $args->{dist_share_dir};

    $res->{cpan_lib} = P->path("$res->{dist_root}/$args->{prefix}/$args->{cpan_lib}") if $args->{cpan_lib};

    $res->{cpan_module_path} = P->path("$res->{dist_root}/$args->{prefix}/$args->{cpan_lib}/$res->{module_name}") if $args->{cpan_lib};

    $res->{cpan_share_dir} = P->path("$res->{dist_root}/$args->{prefix}/$args->{cpan_lib}/auto/share/dist/$dist_name") if $args->{cpan_share_dir};

    return $res;
}

1;
__END__
=pod

=encoding utf8

=cut
