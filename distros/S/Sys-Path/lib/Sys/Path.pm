package Sys::Path;

use warnings;
use strict;

our $VERSION = '0.17';

use File::Spec;
use Text::Diff 'diff';
use JSON::Util;
use IO::Any;
use Digest::MD5 qw(md5_hex);
use List::Util 'any', 'none';
use Carp 'croak', 'confess';
use Cwd 'cwd';
use Fcntl 'LOCK_EX';
use Shell::Guess;
use Module::Path qw(module_path);

use base 'Sys::Path::SPc';

sub find_distribution_root {
    my $self        = shift;
    my $module_name = shift;
    
    croak 'pass module_name as argument'
        if not $module_name;
    
    my $module_filename = module_path($module_name);
    
    my @path;
    if ($module_filename) {
        @path = File::Spec->splitdir($module_filename);
        my @package_names = split('::',$module_name);
        # Remove the module filename and its namespace directories.
        @path = splice(@path,0,-1-@package_names);
    }
    else {
        @path = File::Spec->splitdir(cwd);
    }
    
    while (
        (not -f File::Spec->catdir(@path, 'MANIFEST'))
        and (not -f File::Spec->catdir(@path, 'Build.PL'))
        and (not -f File::Spec->catdir(@path, 'Makefile.PL'))
    ) {
        pop @path;
        confess 'failed to find distribution root'
            if not @path;
    }
    return File::Spec->catdir(@path);
}

sub prompt_cfg_file_changed {
    my $self     = shift;
    my $src_file = shift;
    my $dst_file = shift;
    my $prompt_function = shift;

    my $answer = '';
    while (none { $answer eq $_ } qw(Y I N O) ) {
        print qq{
Installing new version of config file $dst_file ...

Configuration file `$dst_file'
 ==> Modified (by you or by a script) since installation.
 ==> Package distributor has shipped an updated version.
   What would you like to do about it ?  Your options are:
    Y or I  : install the package maintainer's version
    N or O  : keep your currently-installed version
      D     : show the differences between the versions
      Z     : background this process to examine the situation
 The default action is to keep your current version.
};
    
        $answer = uc $prompt_function->('*** '.$dst_file.' (Y/I/N/O/D/Z) ?', 'N');
        if ($answer eq 'D') {
            print "\n\n";
            print diff($src_file, $dst_file, { STYLE => 'Unified' });
            print "\n";
        }
        elsif ($answer eq 'Z') {
            print "Type `exit' when you're done.\n";
            system(Shell::Guess->login_shell->default_location);
        }
    }

    return 1 if any { $answer eq $_ } qw(Y I);
    return 0;
}

sub changed_since_install {
    my $self      = shift;
    my $dest_file = shift;
    my $file      = shift || $dest_file;

    my %files_checksums = $self->install_checksums;
    my $checksum = md5_hex(IO::Any->slurp([$file]));
    $files_checksums{$dest_file} ||= '';
    return $files_checksums{$dest_file} ne $checksum;
}

sub install_checksums {
    my $self = shift;
    my @args = @_;
    my $checksums_filename = File::Spec->catfile(
        Sys::Path::SPc->sharedstatedir,
        'syspath',
        'install-checksums.json'
    );
    my $lock_filename = $checksums_filename.'.lock';

    open my $lock_fh, '>>', $lock_filename
        or croak sprintf(
            'failed to open checksum lock file "%s": %s',
            $lock_filename,
            $!,
        );
    flock($lock_fh, LOCK_EX)
        or croak sprintf(
            'failed to lock checksum registry "%s": %s',
            $lock_filename,
            $!,
        );

    my %conffiles_md5 = -f $checksums_filename
        ? %{JSON::Util->decode([ $checksums_filename ])}
        : ();

    if (@args) {
        print 'Updating ', $checksums_filename, "\n";
        %conffiles_md5 = (%conffiles_md5, @args);
        JSON::Util->encode(
            \%conffiles_md5,
            [ $checksums_filename ],
            { atomic => 1 },
        );
        close($lock_fh) or die 'failed to clean lock file';
        return %conffiles_md5;
    }

    # Initialize the registry on first access, including reads.
    JSON::Util->encode({}, [ $checksums_filename ], { atomic => 1 })
        if not -f $checksums_filename;

    close($lock_fh) or die 'failed to clean lock file';
    return %conffiles_md5;
}


1;


__END__

=encoding utf-8

=head1 NAME

Sys::Path - provide autoconf-style installation directories

=head1 SYNOPSIS

Default paths when Perl's installation prefix is F</usr>:

    use Sys::Path;

    print Sys::Path->sysconfdir, "\n";
    # /etc
    print Sys::Path->datadir, "\n";
    # /usr/share
    print Sys::Path->logdir, "\n";
    # /var/log
    print Sys::Path->sharedstatedir, "\n";
    # /var/lib

Default paths when Perl's installation prefix is F</home/daxim/local>:

    print Sys::Path->sysconfdir, "\n";
    # /home/daxim/local/etc
    print Sys::Path->datadir, "\n";
    # /home/daxim/local/share
    print Sys::Path->logdir, "\n";
    # /home/daxim/local/var/log
    print Sys::Path->sharedstatedir, "\n";
    # /home/daxim/local/var/lib

Default paths when Strawberry Perl's installation prefix is F<C:\Strawberry>:

    print Sys::Path->sysconfdir, "\n";
    # C:\Strawberry\etc
    print Sys::Path->datadir, "\n";
    # C:\Strawberry\share
    print Sys::Path->logdir, "\n";
    # C:\Strawberry\var\log
    print Sys::Path->sharedstatedir, "\n";
    # C:\Strawberry\var\lib

=head1 DESCRIPTION

Sys::Path provides a common set of installation-directory accessors. When
Perl's installation prefix is F</usr>, their defaults follow the
L<Filesystem Hierarchy Standard|http://www.pathname.com/fhs/>. Otherwise,
defaults are derived from Perl's own prefix.

C<perl Build.PL> prompts for each path. The build writes the selected values
into C<Sys::Path::SPc>, so installed consumers read the values configured for
this Sys::Path installation.

The module also provides helper methods for distribution builds and
configuration-file installation. L<Module::Build::SysPath> integrates these
methods with L<Module::Build>.

=head1 BUILD TIME CONFIGURATION

    PERL_MM_USE_DEFAULT=1 perl Build.PL \
        --sp-prefix=/usr/local \
        --sp-sysconfdir=/usr/local/etc \
        --sp-localstatedir=/var/local

Each accessor has a canonical C<--sp-E<lt>accessorE<gt>> option. The legacy
C<--sp-cache>, C<--sp-log>, C<--sp-spool>, C<--sp-run>, C<--sp-lock>, and
C<--sp-state> aliases remain available.

=head1 STATUS

Sys::Path was published as an experiment in system-path configuration, build
system integration, and path naming. The original documentation warned that
its interfaces might change and directed discussion to
L<http://lists.meon.sk/mailman/listinfo/sys-path>.

=head2 WHY?

The Filesystem Hierarchy Standard defines shared directory locations for Unix
distributions, packages, and systems. Sys::Path uses those locations when
Perl's prefix is F</usr>. For other installations, including a Perl installed
under a home directory or F<C:\Strawberry>, it derives defaults beneath Perl's
prefix. This keeps a non-system Perl installation self-contained by default.

=head2 PATHS

Each entry lists the default for a Perl prefix of F</usr>, followed by the
default for any other prefix.

=head3 prefix

F</usr> - C<$Config::Config{'prefix'}>

Base path used to derive several other paths. Applications should normally use
the more specific accessors below.

=head3 localstatedir

F</var> - $prefix/var

Base path used for variable data. Applications should normally use the more
specific accessors below.

=head3 sysconfdir

F</etc> - $prefix/etc

Host-specific system configuration.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#ETCHOSTSPECIFICSYSTEMCONFIGURATION>.

=head3 datadir

F</usr/share> - $prefix/share

Read-only, architecture-independent data.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#USRSHAREARCHITECTUREINDEPENDENTDATA>.

=head3 docdir

F</usr/share/doc> - $prefix/share/doc

See L</datadir>

=head3 localedir

F</usr/share/locale> - $prefix/share/locale

See L</datadir>

=head3 cachedir

F</var/cache> - $localstatedir/cache

Application cache data.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#VARCACHEAPPLICATIONCACHEDATA>.

=head3 logdir

F</var/log> - $localstatedir/log

Application log files.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#VARLOGLOGFILESANDDIRECTORIES>.

=head3 spooldir

F</var/spool> - $localstatedir/spool

Data awaiting later processing.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#VARSPOOLAPPLICATIONSPOOLDATA>.

=head3 rundir

F</var/run> - $localstatedir/run

Runtime state describing the system since boot.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#VARRUNRUNTIMEVARIABLEDATA>.

=head3 lockdir

F</var/lock> - $localstatedir/lock

Lock files.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#VARLOCKLOCKFILES>.

=head3 sharedstatedir

F</var/lib> - $localstatedir/lib

Modifiable, architecture-independent application state.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#VARLIBVARIABLESTATEINFORMATION>.

=head3 srvdir

F</srv> - $prefix/srv

Data served by the system.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#SRVDATAFORSERVICESPROVIDEDBYSYSTEM>.

=head3 webdir

F</var/www> - $localstatedir/www

Static web content installed by distributions.

=head2 HOW IT WORKS

Default selection starts with Perl's configured prefix:

    use Config;
    if ($Config::Config{'prefix'} eq '/usr') { ... }

For a prefix of F</usr>, Sys::Path selects the listed FHS defaults. For any
other prefix, C<localstatedir> is F<var> beneath that prefix, and the remaining
defaults are derived from C<prefix> or C<localstatedir> as shown above.
L<Sys::Path::SPc> implements the accessors; the build replaces its temporary
configuration logic with the selected literal values.

=head1 METHODS

    prefix
    localstatedir
    sysconfdir
    datadir
    docdir
    localedir
    cachedir
    logdir
    spooldir
    rundir
    lockdir
    sharedstatedir
    webdir
    srvdir

=head1 BUILD AND INSTALLATION HELPERS

=head2 find_distribution_root(__PACKAGE__)

Load the named module if necessary, then search its parent directories for
F<MANIFEST>, F<Build.PL>, or F<Makefile.PL>. If the module cannot be loaded,
start at the current working directory. Return the first matching directory;
throw an exception if no distribution root is found.

The current-working-directory fallback applies only when the named module is
not installed. Errors raised while compiling or initializing an installed
module are propagated.

C<$module_name> is required. Loading a module can execute its compile-time
code.

=head2 prompt_cfg_file_changed($src_file, $dst_file, $prompt_function)

Ask whether C<$src_file> should replace the modified C<$dst_file>. The callback
receives the prompt text and the default answer, C<N>. Return true for C<Y> or
C<I>, and false for C<N> or C<O>.

C<D> prints a unified diff and prompts again. C<Z> starts the user's login shell
and prompts again after the shell exits. These options write directly to
standard output.

=head2 changed_since_install($dest_file, $file)

Return true when the MD5 checksum of C<$file> differs from the checksum
recorded for C<$dest_file>. C<$file> defaults to C<$dest_file>. A destination
without a recorded checksum is considered changed.

The method reads the entire comparison file and propagates read and decode
errors from its dependencies.

=head2 install_checksums(%filenames_with_checksums)

Return the filename/checksum pairs stored in
F<sharedstatedir/syspath/install-checksums.json>. With arguments, merge the
supplied pairs into the registry and return the resulting pairs.

The parent directory must already exist. Reading a missing registry creates an
empty JSON file and therefore requires write permission. Access is serialized
through a persistent lock file, and C<IO::Any> replaces the registry through
its atomic-output mode. The lock coordinates cooperating callers; lock and
replacement failures from the host platform are propagated.

=head1 SEE ALSO

L<Module::Build::SysPath>

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 CONTRIBUTORS

The following people contributed code, patches, bug reports, questions, and
suggestions (in no particular order):

    Lars Dɪᴇᴄᴋᴏᴡ 迪拉斯
    Emmanuel Rodriguez
    Salve J. Nilsen
    Daniel Perrett
    Jose Luis Perez Diez
    Petr Písař
    Mohammad S Anwar

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
