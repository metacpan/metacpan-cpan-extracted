package Shipwright::Test;

use warnings;
use strict;
use base qw/Exporter/;

use File::Temp qw/tempdir/;
use IPC::Cmd qw/can_run/;
use File::Spec::Functions qw/catfile catdir/;
use Shipwright::Util;
use Cwd 'getcwd';

our @EXPORT =
  qw/has_svk has_svn skip_svk skip_svn create_fs_repo create_svk_repo
  create_svn_repo devel_cover_enabled test_cmd skip_git create_git_repo/;

=head1 NAME

Shipwright::Test - Test 

=head1 SYNOPSIS

    use Shipwright::Test;

=head2 has_svk

check to see if we have svk or not, also limit the svk version to be 2+.
in fact, it also checks svnadmin since we need that to create repo for svk.

=cut

sub has_svk {
    if (   can_run( $ENV{'SHIPWRIGHT_SVK'} )
        && can_run( $ENV{'SHIPWRIGHT_SVN'} . 'admin' ) )
    {
        my $out =
          run_cmd( [ $ENV{'SHIPWRIGHT_SVK'}, '--version' ], 1 );
        if ( $out && $out =~ /version v(\d)\./i ) {
            return 1 if $1 >= 2;
        }
    }
    return;
}

=head2 has_svn

check to see if we have svn or not, also limit the svn version to be 1.4+.
in fact, it also checks svnadmin since we need that to create repo.

=cut

sub has_svn {
    if (   can_run( $ENV{'SHIPWRIGHT_SVN'} )
        && can_run( $ENV{'SHIPWRIGHT_SVN'} . 'admin' ) )
    {
        my $out =
          run_cmd( [ $ENV{'SHIPWRIGHT_SVN'}, '--version' ], 1 );
        if ( $out && $out =~ /version 1\.(\d)/i ) {
            return 1 if $1 >= 4;
        }
    }
    return;
}

=head2 has_git

check to see if we have git or not

=cut

sub has_git {
    if (   can_run( $ENV{'SHIPWRIGHT_GIT'} ) ) {
        return 1;
    }
    return;
}

=head2 skip_svn

if skip svn when test.
skip test svn unless env SHIPWRIGHT_TEST_SVN is set to true and
the system has svn

=cut

sub skip_svn {
    return if $ENV{'SHIPWRIGHT_TEST_SVN'} && has_svn();
    return 1;
}

=head2 skip_svk

if skip svk when test.
skip test svk unless env SHIPWRIGHT_TEST_SVK is set to true and
the system has svk

=cut

sub skip_svk {
    return if $ENV{'SHIPWRIGHT_TEST_SVK'} && has_svk();
    return 1;
}

=head2 skip_git

if skip git when test.
skip test git unless env SHIPWRIGHT_TEST_GIT is set to true and
the system has git

=cut

sub skip_git {
    return if $ENV{'SHIPWRIGHT_TEST_GIT'} && has_git();
    return 1;
}


=head2 create_fs_repo 

create a repo for fs

=cut

sub create_fs_repo {
    return tempdir( 'shipwright_test_fs_XXXXXX', CLEANUP => 1, TMPDIR => 1 );
}

=head2 create_git_repo 

create a repo for git

=cut

sub create_git_repo {
    my $dir = tempdir( 'shipwright_test_git_XXXXXX', CLEANUP => 1, TMPDIR => 1 );
    my $cwd = getcwd();
    chdir $dir;
    run_cmd( [$ENV{'SHIPWRIGHT_GIT'}, 'init', '--bare' ] );
    chdir $cwd;
    return "file://$dir";
}

=head2 create_svk_repo 

create a repo for svk, will set $ENV{SVKROOT} accordingly.
return $ENV{SVKROOT}

=cut

sub create_svk_repo {
    $ENV{SVKROOT} =
      tempdir( 'shipwright_test_svk_XXXXXX', CLEANUP => 1, TMPDIR => 1 );
    my $svk_root_local = catdir( $ENV{SVKROOT}, 'local' );
    system("$ENV{SHIPWRIGHT_SVN}admin create $svk_root_local");
    system("$ENV{SHIPWRIGHT_SVK} depotmap -i");
    return $ENV{SVKROOT};
}

=head2 create_svn_repo 

create a svn repo.
return the repo's uri, like file:///tmp/foo

=cut

sub create_svn_repo {
    my $repo =
      tempdir( 'shipwright_test_svn_XXXXXX', CLEANUP => 1, TMPDIR => 1 );
    system("$ENV{SHIPWRIGHT_SVN}admin create $repo")
      && confess_or_die "create repo failed: $!";
    return "file://$repo";
}

=head2 init

init something, like log

=cut

sub init {
    require Shipwright::Logger;
    Shipwright::Logger->new( log_level => 'FATAL' );
    $ENV{'SHIPWRIGHT_SVK'} ||= 'svk';
    $ENV{'SHIPWRIGHT_SVN'} ||= 'svn';
    $ENV{'SHIPWRIGHT_GIT'} ||= 'git';
    $ENV{'SHIPWRIGHT_USER_ROOT'} =
      tempdir( 'shipwright_user_root_XXXXXX', CLEANUP => 1, TMPDIR => 1 );
}

=head2 shipwright_bin

return the path of bin/shipwright

=cut

sub shipwright_bin {
    no warnings 'uninitialized';

    # so, we'd better add lib to PERL5LIB before run shipwright.
    # what? you don't want to run shipwright?!!
    # then what did you call this method for?

    $ENV{PERL5LIB} = 'lib:' . $ENV{PERL5LIB} unless $ENV{PERL5LIB} =~ /^lib:/;
    return catfile( 'bin', 'shipwright' );
}

=head2 devel_cover_enabled

return true if -MDevel::Cover

=cut

sub devel_cover_enabled {
    return $INC{'Devel/Cover.pm'};
}

=head2 test_cmd

a simple wrap for test cmd like create, list ...

=cut

sub test_cmd {
    my $cmd     = shift;
    my $exp     = shift;
    my $msg     = shift || "@$cmd out";
    my $exp_err = shift;
    my $msg_err = shift || "@$cmd err";

    unshift @$cmd, $^X, '-MDevel::Cover' if devel_cover_enabled;

    require Test::More;
    my ( $out, $err ) = run_cmd( $cmd, 1 );    # ingnore failure

    _test_cmd( $out, $exp,     $msg )     if defined $exp;
    _test_cmd( $err, $exp_err, $msg_err ) if defined $exp_err;
}

sub _test_cmd {
    my $out = shift;
    my $exp = shift;
    my $msg = shift;

    if ( ref $exp eq 'Regexp' ) {
        Test::More::like( $out, $exp, $msg );
    }
    else {
        Test::More::is( $out, $exp, $msg );
    }
}

1;

__END__

=head1 AUTHORS

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Shipwright is Copyright 2007-2015 Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

