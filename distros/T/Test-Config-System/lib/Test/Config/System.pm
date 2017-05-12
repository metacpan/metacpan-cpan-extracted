package Test::Config::System;

use warnings;
use strict;

use Carp;

my $CLASS = __PACKAGE__;
use base 'Test::Builder::Module';

=head1 NAME

Test::Config::System - System configuration related unit tests

=head1 VERSION

Version 0.63

=cut

our $VERSION     = '0.63';
our @EXPORT      = qw(check_package check_any_package check_file_contents check_link check_file check_dir plan diag ok skip);
our $AUTOLOAD;

sub AUTOLOAD {
    my $tb = Test::Config::System->builder;
    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    $tb->$name(@_);
}

=head1 SYNOPSIS

    use Test::Config::System tests => 3;
    
    check_package('less', 'package less');
    check_package('emacs21', 'emacs uninstalled', 1);
    check_link('/etc/alternatives/www-browser', '/usr/bin/w3m');
    check_file_contents('Test/Config/System.pm', qr/do {local \$\//);

=head1 DESCRIPTION

Test::Config::System provides functions to help test system configuration,
such as installed packages or config files.  It was built for use in a
cfengine staging environment.  (L<http://www.cfengine.org>.  cfengine is used
for automating and managing system configuration at large sites).

Test::Config::System does not depend on, or interact with cfengine in any way,
however, and can be used on its own or with another configuration management
tool (such as puppet or bcfg2).

This module is a subclass of Test::Builder::Module, and is used like any other
Test::* module.  Instead of directly providing an ok() function, the functions
exported (described below), call ok() themselves, based on the outcome of the
check they preform.

=head1 EXAMPLE

    use Test::Config::System tests => 3;
    # check something we already know:  :)
    check_package('perl', 'perl is installed');
    check_file_contents('/etc/apt/sources.list', qr/apt-proxy/,
        'apt-proxy is not being used', 1); # the apt-proxy is not
                                           # anywhere in sources.list
    check_package('vim');      # Make sure we have the one true editor


=head1 EXPORT

check_package
check_any_package
check_file_contents
check_link
check_dir
check_file

From Test::Builder::Module:

plan
diag
ok
skip

=head1 FUNCTIONS

Each of the functions below use Test::Builder::Module's ok() function to
report test success or failure.  They return the result of ok() upon
normal completion, or a false value (undef in scalar context, an empty
list in list context) on error (eg a required parameter not provided, or
FS doesn't support symlinks).

=head2 check_package( NAME, [DESC, INVERT, PACKAGE_MANAGER] )

NOTE: check_package currently only supports dpkg and rpm.

check_package tests whether or not a package is installed.  If the package
is not installed or if the given package manager does not exist, the test
fails.  Otherwise, the test will pass.  (If the test is inverted, the outcome
is the opposite).

  - NAME: package name
  - DESC: test name (optional, defaults to package name)
  - INVERT: invert test (optional.  Possible values are 0 (default) and 1.)
  - PACKAGE_MANAGER: package manager (optional.  Defaults to 'dpkg'.
                                      Supported values are 'dpkg' and 'rpm'.
                                      If the given package manager is not
                                      supported, returns false)

Examples:

    # Will fail if nethack is not installed
    check_package('nethack-text');
    # This will fail if x11-common is installed:
    check_package('x11-common', 'x11-common is not installed', 1);

=cut

#TODO: version
#FIXME: this needs to be more portable :/
my %_pkgmgrs = ( 'dpkg' => "/usr/bin/dpkg -l %s 2>/dev/null|grep '^ii' > /dev/null",
                 'rpm'  => "/bin/rpm -q %s >/dev/null",
               );

sub check_package {
    my ($pkg, $testname, $invert, $pkgmgr, $res);
    $pkg      = shift;
    unless ($pkg) {
        carp "Package name required";
        return;
    }
    $testname = (shift || $pkg);
    $invert   = (shift || 0);
    $pkgmgr   = (shift || 'dpkg');

    $res = _installedp($pkg, $pkgmgr);
    return $res if !defined($res); # installedp wants us to return false

    my $tb = Test::Config::System->builder;
    $tb->ok($invert ? !$res : $res, $testname)
}

=head2 check_any_package( LIST, [DESC, INVERT, PACKAGE_MANAGER] )

NOTE: check_any_package currently only supports dpkg and rpm.

check_any_package tests if any one in a list of packages is installed.  
Much like Perl's "||" operator, check_any_package will short-circuit (if
the first package is installed, the test will immediately pass without
checking the others).

  - LIST: a list of packages to check
  - DESC: see C<check_package>
  - INVERT: inverts test (A value of 1 will cause the test to fail
                          unless I<none> of the given packages are installed)
  - PACKAGE_MANAGER: see C<check_package>

Examples:

    # Will pass if either of the given packages are installed
    check_any_package(['libtest-config-system-perl',
        'cpan-libtest-config-system-perl'],
        'Test::Config::System is installed');
    # Will fail if either xserver-xorg or xserver-xfree86 is installed
    check_any_package(['xserver-xorg', 'xserver-xfree86',
        'No X11 server installed', 1);

=cut

sub check_any_package {
    my ($list, $testname, $invert, $pkgmgr, $res);
    $list = shift;
    unless (ref($list)) {
        carp "Require a list of package names";
        return;
    }
    $testname = (shift || $list->[0]);
    $invert   = (shift || 0);
    $pkgmgr   = (shift || 'dpkg');

    for my $pkg (@$list) {
        $res = _installedp($pkg, $pkgmgr);
        return $res if !defined($res); # installedp wants us to return false
        last if $res;
    }

    my $tb = Test::Config::System->builder;
    $tb->ok($invert ? !$res : $res, $testname);
}


# used by check_.*package
sub _installedp {
    ## Let's clean up %ENV a bit before we call a shell...
    local %ENV;
    $ENV{PATH}  = '/bin:/usr/bin';
    $ENV{SHELL} = '/bin/sh' if exists $ENV{SHELL};
    delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};


    my $res=0;
    my ($pkg, $pkgmgr) = @_;

    my %cmds = ( 'dpkg' => '/usr/bin/dpkg -l %s 2>/dev/null|grep \'^ii\' > /dev/null',
                 'rpm'  => '/bin/rpm -q %s >/dev/null',
               );

    ## The debian policy is more restrictive.  I can't find any policy
    ## information for redhat, so I'm being a bit more lenient.
    if ($pkg =~ /^([A-Za-z0-9-+._]+)/) {
        $pkg = $1; # This untaints $pkg
    } else {
        carp "Invalid package name.  If this is an error and the package is indeed valid, *please* file a bug.";
        return;
    }

    if (exists($_pkgmgrs{$pkgmgr})) { # Do we support this package manager?
        $res = system(sprintf($cmds{$pkgmgr}, $pkg));
        ## get the actual return value
        $res = $res >> 8;
        $res = !$res;   # shell does 0 on success...
    } else {
        carp "Package manager [$pkgmgr] is not supported";
        return;
    }

    return $res;
}

=head2 check_file_contents( FILENAME, REGEX, [DESC, INVERT] )

check_file_contents tests that a file's contents match a given regex.  It
slurps the contents of the given filename, then matches it against the given
regex.  If the regex matches the contents of the file, ok() is called with a
true value, causing the test to pass.  If the regex does not match, the test
will fail (as in check_package, if the test is inverted, the results are
inverted as well).

If the given file cannot be opened for reading, ok() will be called with a
false value (unless, as always, invert is true).

Note that the entire file is slurped into memory at once.  This has two
concequences.  First, large files will eat up RAM.  Second, ^ and $ do not
work line-by-line, as one might expect.  "\n" (or your system's line-end
sequence) can be used in place of ^ or $ to match the start and end of a
line.

  - FILENAME: file to test
  - REGEX: regex to match (qr//-style regex)
  - DESC: test name (optional, defaults to filename)
  - INVERT: invert test (optional.  Possible values are 0 (default) and 1.)

Examples:

    check_file_contents('/etc/fstab', qr|proc\s+/proc\s+proc\s+defaults\s+0\s+0|,
        'proc is in fstab');
    check_file_contents('/etc/passwd', qr|evilbob:x:\d+:\d+:|,
        'evilbob is not in passwd', 1);

=cut

#TODO: should take, optionally, a hash of files/regexen or something of that
# nature
sub check_file_contents {
    my $tb = Test::Config::System->builder;
    my ($filename, $regex, $testname, $invert, $res);
    $filename   = shift;
    $regex      = shift;
    if (!$filename) {
        carp "Filename required";
        return;
    }
    if (ref($regex) ne 'Regexp') {
        carp "qr// style regex required";
        return;
    }
    $testname   = (shift || $filename);
    $invert     = (shift || 0);

    $res = _match_file($filename,$regex);

    $tb->ok($invert ? !$res : $res, $testname);
}


sub _match_file {
    my ($filename,$regex) = @_;
    my $res = (open my $fh, '<', $filename);
    return unless $res;

    my $text = do {local $/; <$fh>};
    close($fh);

    return ($text =~ /$regex/);
}


=head2 check_link( FILENAME, [TARGET, DESC, INVERT] )

check_link verifies that a symlink exists and, optionally, points to the
correct target.

If no filename is passed, it will return a false value, otherwise a test
will be run and the result of ok() will be returned.

If the filesystem does not support symlinks, the test will be skipped, and
check_link will return false.

  - FILENAME: filename (path to a symlink)
  - TARGET:   path the link should point to.  optional.  If not specified,
              check_link will ignore the target, and just verify that the
              link exists.
  - DESC: test name (optional, defaults to filename)
  - INVERT: invert test (optional.  Possible values are 0 (default) and 1.)    

Examples:

    check_link('/etc/alternatives/rsh', '/usr/bin/ssh');
    check_link('/etc/sudoers', '', 'sudoers is not a symlink', 1);

=cut

sub check_link {
    my ($src, $target, $testname, $invert, $res);
    my $tb = Test::Config::System->builder;

    unless (eval { symlink("",""); 1 }) {
        $tb->skip("symlinks are not supported on this platform");
        return;
    }

    $src = shift;
    if (!$src) {
        carp "Filename required";
        return;
    }

    $target   = shift;
    $testname = (shift || $src);
    $invert   = (shift || 0);

    my $link = readlink($src);
    if (!$link) {       # not a symlink or ENOENT, fail
        $res = 0;
    } elsif ($target) { # valid link and target is asked for
        $res = (($link eq $target) ? 1 : 0);
    } else {            # valid link and don't care about target
        $res = -l $src;
    }

    $tb->ok($invert ? !$res : $res, $testname);
}

=head2 check_file( PATH, [STAT, DESC, INVERT] )

check_file verifies that a directory exists.  Optionally, it can check
various attributes such as owner, group, or permissions.

  - PATH: path of the file to check
  - STAT: a hashref of attributes and their desired values.  Valid keys:
        -uid    owner uid
        -gid    owner gid
        -mode   file permissions
    Each key is optional, as is the entire hash.  Note that the type need
    not be specified in -mode; it is added automatically (ie use 0700
    instead of 010700).

  - DESC: test name (optional, defaults to PATH)
  - INVERT: invert test (optional.  Possible values are 0 (default) and 1.)

Examples:

    check_file('/etc/sudoers', { '-uid' => 0, '-gid' => 0, '-mode' => 0440);

=head2 check_dir( PATH, [STAT, DESC, INVERT] )

check_dir is check_file for directories (they both call the same internal
sub).  Arguments and calling are exactly the same, the only significant
difference is that check_dir verifies that PATH is a directory rather than
a file.

Examples:

    check_dir('/home/ian', { '-uid' => scalar getpwnam('ian') } );
    check_dir('/root/', { '-uid' => 0, '-gid' => 0, '-mode' => 0700 },
        '/root/ has sane permissions');
    check_dir('/home/evilbob', { }, 'Evilbobs homedir does not exist',1);

=cut

sub check_dir {
    my ($path, $stat, $testname, $invert,$res);
    $path = shift;
    if (!$path) {
        carp "Directory name required";
        return;
    }

    $stat     = (shift || { });
    $testname = (shift || $path);
    $invert   = (shift || 0);

    my $tb = Test::Config::System->builder;
    unless (-d $path) {
        return $tb->ok($invert ? 1 : 0, $testname);
    }

    $res = _pathp(oct(40000), $path, $stat);
    $tb->ok($invert ? !$res : $res, $testname);
}

sub check_file {
    my ($path, $stat, $testname, $invert,$res);
    $path = shift;
    if (!$path) {
        carp "Filename required";
        return;
    }
    $stat     = (shift || { });
    $testname = (shift || $path);
    $invert   = (shift || 0);

    my $tb = Test::Config::System->builder;
    unless (-f $path) {
        return $tb->ok($invert ? 1 : 0, $testname);
    }

    $res = _pathp(oct(100000), $path, $stat);
    $tb->ok($invert ? !$res : $res, $testname);

}

sub _pathp {
    my %tbl = ( '-uid'  => 4,
                '-gid'  => 5,
                '-mode' => 2,
              );
    ## Internal function, we can assume args are checked by the caller.
    my ($type, $path, $stat) = @_;
    my $tb = Test::Config::System->builder;

    my $res = 1;

    if (ref($stat) eq 'HASH') {
        my @attrs = stat($path);
        $attrs[2] -= $type; # Already know the type, only matching perms
        ## Loop through each pair or until $res is false
        while ((my ($key, $val) = each(%$stat)) && $res) {
            ## Look up the key's position in the list returned from stat(),
            ##   and compare the return from stat() to the value given.
            if (exists($tbl{$key})) {
                $res = ($attrs[$tbl{$key}] == $val) ? 1 : 0;
            }
            $tb->diag("required: $key->$val, actual: $key->"
                . $attrs[$tbl{$key}]) unless $res;
        }
    }
    return $res; # caller will do the ok()
}

=head1 AUTHOR

Ian Kilgore, C<< <iank at cpan.org> >>

=head1 BUGS

=over 4

=item * Never call check_file_contents with untrusted input.

check_file_contents runs a given regexp, which can contain arbitrary
perl code.

=item * check_package currently only supports dpkg and rpm

=back

Please report any bugs or feature requests to
C<bug-test-config-system at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Config-System>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Config::System

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Config-System>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Config-System>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Config-System>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Config-System>

=back

=head1 ACKNOWLEDGEMENTS

Many thanks to [naikonta] at perlmonks, for reviewing the module before
the release of 0.01.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Ian Kilgore, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Builder::Module>

=cut

1; # End of Test::Config::System
