package Test::CPANpm;

use 5.006;
use strict;
use warnings;
use Test::CPANpm::Fake;
use Test::More;
use Exporter;
use base q(Exporter);
use Cwd qw(getcwd);

our @EXPORT = qw(cpan_depends_ok cpan_depends_ok_force_missing);
our $VERSION = '0.010';

return 1;

sub cpan_depends_ok {
    my($deps, $test_name) = @_;
    my @actual;
    my @deps = sort @$deps;

    my($out, $in) = change_std();
    run_with_cpan_config {
        my $dist_dir = dist_dir('.');
        @actual = get_prereqs($dist_dir);
        @actual = sort(@actual);
    };
    restore_std($out, $in);

    my $test = Test::More->builder;
    if(eq_array(\@actual, \@deps)) {
        $test->ok(1, $test_name);
    } else {
        diag("Expected dependancies: @deps, Actual: @actual");
        $test->ok(0, $test_name);
    }
}

sub cpan_depends_ok_force_missing {
    my($deps, $missing, $test_name) = @_;
    my @actual;
    my @deps = sort @$deps;

    my($out, $in) = change_std();
    run_with_cpan_config {
        my $dist_dir = dist_dir('.');
        my %missing = map { $_ => 0 } @$missing;
        @actual = run_with_fake_modules { get_prereqs($dist_dir); } %missing;
        @actual = sort(@actual);
    };
    restore_std($out, $in);

    my $test = Test::More->builder;
    if(eq_array(\@actual, \@deps)) {
        $test->ok(1, $test_name);
    } else {
        diag("Expected dependancies: @deps, Actual: @actual");
        $test->ok(0, $test_name);
    }
}

=pod

=head1 NAME

Test::CPANpm - Test a distribution's interaction with CPAN before uploading.

=head1 SYNOPSIS

  use Test::CPANpm;
  use Test::More qw(no_plan);
  
  cpan_depends_ok(
    ['CGI', 'Module::Build', 'Acme::Wabbit'],
    'got the right dependancies'
  );

  cpan_depends_ok_force_missing(
    ['Some::Module::Build::Subclass', 'CGI', 'Module::Build', 'Acme::Wabbit'],
    ['Some::Module::Build::Subclass'],
    'got dependancies even though our Module::Build subclass is missing'
  );
  
=head1 DESCRIPTION

Test::CPANpm fools CPAN.pm into thinking it has downloaded and unpacked your
package, then has it attempt to generate a C<Makefile> or C<Build> script.
After this process completes, it asks your CPAN module what dependancies
it thinks exist.

If you just want to make sure your distribution is packaged in a way that
is good for CPAN, consider using L<Test::Distribution|Test::Distribution> instead. The main
time that C<Test::CPANpm> is useful is when you depend on modules inside your
C<Makefile.PL> or C<Build.PL> script and you want to make sure that you
degrade gracefully if those modules are not available.

=head1 TESTS

=over

=item cpan_depends_ok([modules], $test_name)

Generate a distribution directory and tell CPAN to process it. The test will
pass if your distribution depends on the exact modules listed in [modules].

=item cpan_depends_ok_force_missing([modules], [force-missing], $test_name)

Create a bunch of modules that will fail to load, named in the [force-missing]
array. Preprend this to our C<@INC>, then do the C<cpan_depends_ok()> test
above. This is useful if, say, you have a Module::Build subclass, and you want
to verify that your C<Build.PL> script whines about this subclass missing in
a way that CPAN can understand.

The reason the fake modules are generated, is to prevent the already-installed
modules on your system from interfereing with this test.

Example: Given a C<Build.PL> that contains the following:

  my $build;

  our %opts = (
      module_name         =>  'My::Module::Subclass',
      license             =>  'perl',
      requires            =>  {
          'Test::CPANpm'                    =>  '0',
          # My::Module provides My::Module::Build
          'My::Module'                    =>  '0',
      },
      create_makefile_pl  =>  'passthrough',
  );

  eval { require My::Module::Build; };

  if($@) {
    warn "My::Module::Build is required to build this module!";
    $opts{requires}{'My::Module::Build'} = 0;
    # setting installdirs to an empty hash makes "./Build install" fail,
    # but we'll still get a "Build" script/Makefile that CPAN can use to
    # find prereqs
    $build = Module::Build->new(%opts, installdirs => {});
  } else {
    $build = My::Module::Build->new(%opts);
  }

  $build->create_build_script;

The following tests would be expected to pass:

  cpan_depends_ok(
    ['My::Module', 'Test::CPANpm'],
    'CPAN sees basic dependancies'
  );
  
  cpan_depends_ok_force_missing(
    [
        'My::Module', 'Test::CPANpm', 'My::Module::Build'
    ],
    [
        'My::Module::Build'
    ],
    'CPAN complains if My::Module::Build is missing'
  );

=back

=head1 CAVEAT

You must have a C<Makefile> or C<Build> script in the current working directory
for C<Test::CPANpm> to work. It will call the "distdir" command on that script
in order to build it's test environment. (This also means that your MANIFEST
needs to be up-to-date for the tests to usually pass... but of course your
MANIFEST needs to be up-to-date before you can upload to CPAN anyway, right?)

=head1 TODO

I'm rushing this package out because I have another package whose testability
depends on these functions, but there's more I'd like to see in here:

=over

=item Test that you depend on particular versions of modules


=item Test that a "Makefile" is actually created

This is tacitly, implicitly done already by cpan_depends_ok, since
you won't get any dependancy information out of CPAN without a Makefile,
but an explicit test would still be good.

=item Only generate distdir once for multiple tests


=item Check that the modules you depend on actually are on CPAN

Right now we just test that you depend on certain modules, there is no
check to see if they are actually available.

=item Tests that use CPANPLUS

CPANPLUS is supposed to behave more-or-less the same as CPAN given a
distribution, but it'd be nice to C<prove> it.

=back

=head1 SEE ALSO

L<Test::Distribution>, L<CPAN>, L<ExtUtils::MakeMaker>, L<Module::Build>,
L<Module::Depends>

=head1 AUTHOR

Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

=head1 LICENSE

Copyright 2006 Tyler MacDonald.

This is free software; you may redistribute it under the same terms as perl itself.

=cut
