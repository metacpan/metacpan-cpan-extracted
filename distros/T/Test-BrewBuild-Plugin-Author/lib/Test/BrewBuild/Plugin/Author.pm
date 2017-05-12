package Test::BrewBuild::Plugin::Author;

# default exec command set plugin for Test::BrewBuild

our $VERSION = '0.02';

$ENV{RELEASE_TESTING} = 1;

my $state = bless {}, __PACKAGE__;

sub brewbuild_exec{
    shift; # throw away class
    my $log = shift;
    
    if ($log){
        my $package_log = $log->child('Test::BrewBuild::Plugin::Author');
        $package_log->_7("initializing plugin");

        if (! $ENV{RELEASE_TESTING}){
            $package_log->_0(
                "RELEASE_TESTING env var not set... We'll install ".
                "author packages, but won't run them"
            );
        }
    }

    my $clog = $log->child( __PACKAGE__.'::brewbuild_exec' );
    $clog->_6( 'performing plugin duties' );
    return _cmd();
}
sub _cmd {
    my $module = shift;

    #FIXME: we have to do the below nonsense, because DATA can't
    # be opened twice if we get called more than once per run

    if (! defined $state->{raw}){
        @{ $state->{raw} } = <DATA>;
    }

    my @cmd = @{ $state->{raw} };

    return @cmd;
}
1;

=pod

=head1 NAME

Test::BrewBuild::Plugin::Author - Default test run, but installs author test
distributions

=head1 SYNOPSIS

    # install various POD and MANIFEST testing distributions, then
    # run the default tests

    brewbuild --plugin Test::BrewBuild::Plugin::Author

=head1 DESCRIPTION

This distribution/module is exactly the same as the default test execution
plugin that is distributed with L<Test::BrewBuild>, which is
L<Test::BrewBuild::Plugin::DefaultExec>. The only difference is this one will
install author-related distributions that will perform the tests typically run
when under the environment variable C<RELEASE_TESTING=1>.

These installed distributions are:

    Pod::Coverage
    Test::Pod::Coverage
    Test::Manifest

=head1 METHODS

=head2 brewbuild_exec($log)

Is called by C<Test::BrewBuild::exec()>, executes the test commands provided
by this plugin's C<DATA> section.

Optionally takes a C<Test::BrewBuild::log()> object as a parameter.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=cut

__DATA__
cpan App::cpanminus
cpanm Test::CheckManifest
cpanm Pod::Coverage
cpanm Test::Pod::Coverage
cpanm --installdeps .
cpanm -v --test-only .
shit
