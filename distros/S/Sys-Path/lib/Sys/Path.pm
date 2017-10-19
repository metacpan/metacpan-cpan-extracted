package Sys::Path;

use warnings;
use strict;

our $VERSION = '0.16';

use File::Spec;
use Text::Diff 'diff';
use JSON::Util;
use Digest::MD5 qw(md5_hex);
use List::MoreUtils 'any', 'none';
use Carp 'croak', 'confess';
use Cwd 'cwd';

use base 'Sys::Path::SPc';

sub find_distribution_root {
    my $self        = shift;
    my $module_name = shift;
    
    croak 'pass module_name as argument'
        if not $module_name;
    
    my $module_filename = $module_name.'.pm';
    $module_filename =~ s{::}{/}g;
    eval 'use '.$module_name
        unless $INC{$module_filename};
    
    my @path;
    if ($INC{$module_filename}) {
        $module_filename = File::Spec->rel2abs($INC{$module_filename});
        
        @path = File::Spec->splitdir($module_filename);
        my @package_names = split('::',$module_name);
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
            system('bash');
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

    if (@args) {
        print 'Updating ', $checksums_filename, "\n";
        my %conffiles_md5 = (
            $self->install_checksums,
            @args,
        );
        JSON::Util->encode(\%conffiles_md5, [ $checksums_filename ]);
        return %conffiles_md5;
    }
    
    # create empty json file if non available
    JSON::Util->encode({}, [ $checksums_filename ])
        if not -f $checksums_filename;
    
    return %{JSON::Util->decode([ $checksums_filename ])};
}


1;


__END__

=encoding utf-8

=head1 NAME

Sys::Path - supply autoconf style installation directories

=head1 SYNOPSIS

Paths for basic Unix installation when Perl is in /usr/bin:

    use Sys::Path;

    print Sys::Path->sysconfdir, "\n";
    # /etc
    print Sys::Path->datadir, "\n";
    # /usr/share
    print Sys::Path->logdir, "\n";
    # /var/log
    print Sys::Path->sharedstatedir, "\n";
    # /var/lib

Paths for Unix when Perl is in home folder /home/daxim/local/bin:

    print Sys::Path->sysconfdir, "\n";
    # /home/daxim/local/etc
    print Sys::Path->datadir, "\n";
    # /home/daxim/local/share
    print Sys::Path->logdir, "\n";
    # /home/daxim/local/log
    print Sys::Path->sharedstatedir, "\n";
    # /home/daxim/local/lib

Paths for MS Windows Strawberry Perl when installed to C:\Strawberry\

    print Sys::Path->sysconfdir, "\n";
    # C:\Strawberry\etc
    print Sys::Path->datadir, "\n";
    # C:\Strawberry\share
    print Sys::Path->logdir, "\n";
    # C:\Strawberry\log
    print Sys::Path->sharedstatedir, "\n";
    # C:\Strawberry\lib

=head1 DESCRIPTION

The goal is that Sys::Path provides autoconf style system paths.

The default paths for file locations are based on L<http://www.pathname.com/fhs/>
(Filesystem Hierarchy Standard) if the Perl was installed in F</usr>. For
all other non-standard Perl installations or systems the default prefix is
the prefix of Perl it self. Still those are just defaults and can be changed
during C<perl Build.PL> prompting. After L<Sys::Path> is configured and installed
all programs using it can just read/use the paths.

In addition L<Sys::Path> includes some functions that are related to modules
build or installation. For now there is only L<Module::Build> based L<Module::Build::SysPath>
that uses L<Sys::Path>.

=head1 BUILD TIME CONFIGURATION

    PERL_MM_USE_DEFAULT=1 perl Build.PL \
        --sp-prefix=/usr/local \
        --sp-sysconfdir=/usr/local/etc \
        --sp-localstatedir=/var/local

=head1 NOTE

This is an experiment and lot of questions and concerns can come out about
the paths configuration. Distributions build systems integration and the naming.
And as this is early version things may change. For these purposes there
is a mailing list L<http://lists.meon.sk/mailman/listinfo/sys-path>.

=head2 WHY?

The filesystem standard has been designed to be used by Unix distribution developers,
package developers, and system implementors. However, it is primarily intended
to be a reference and is not a tutorial on how to manage a Unix filesystem or directory
hierarchy.

L<Sys::Path> follows this standard when it is possible. Or when Perl follows.
Perl can be installed in many places. Most Linux distributions place Perl
in F</usr/bin/perl> where FHS suggest. In this case the FHS folders are
suggested in prompt when doing `C<perl Build.PL>`. In other cases for
other folders or home-folder Perl distributions L<Sys::Path> will suggest
folders under Perl install prefix. (ex. F<c:\strawerry\> for the ones using
Windows).

=head2 PATHS

Here is the list of paths. First the default FHS path, then (to compare)
a suggested path when Perl is not installed in F</usr>.

=head3 prefix

F</usr> - C<$Config::Config{'prefix'}>

Is a helper function and should not be used directly.

=head3 localstatedir

F</var> - C<$Config::Config{'prefix'}>

Is a helper function and should not be used directly.

=head3 sysconfdir

F</etc> - $prefix/etc

The /etc hierarchy contains configuration files.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#ETCHOSTSPECIFICSYSTEMCONFIGURATION>.

=head3 datadir

F</usr/share> - $prefix/share

The /usr/share hierarchy is for all read-only architecture independent data files.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#USRSHAREARCHITECTUREINDEPENDENTDATA>.

=head3 docdir

F</usr/share/doc> - $prefix/share/doc

See L</datadir>

=head3 localedir

F</usr/share/locale> - $prefix/share/locale

See L</datadir>

=head3 cachedir

F</var/cache> - $localstatedir/cache

/var/cache is intended for cached data from applications.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#VARCACHEAPPLICATIONCACHEDATA>.

=head3 logdir

F</var/log> - $localstatedir/logdir

This directory contains miscellaneous log files. Most logs must be written to this directory or an appropriate subdirectory.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#VARLOGLOGFILESANDDIRECTORIES>.

=head3 spooldir

F</var/spool> - $localstatedir/spool

Contains data which is awaiting some kind of later processing.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#VARSPOOLAPPLICATIONSPOOLDATA>.

=head3 rundir

F</var/run> - $localstatedir/rundir

This directory contains system information data describing the system since it was booted.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#VARRUNRUNTIMEVARIABLEDATA>.

=head3 lockdir

F</var/lock> - $localstatedir/lock

Lock files folder.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#VARLOCKLOCKFILES>.

=head3 sharedstatedir

F</var/lib> - $localstatedir/lib

The directory for installing modifiable architecture-independent data.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#VARLIBVARIABLESTATEINFORMATION>.

=head3 srvdir

F</srv> - $prefix/srv

Data for services provided by system.
See L<http://www.pathname.com/fhs/pub/fhs-2.3.html#SRVDATAFORSERVICESPROVIDEDBYSYSTEM>.

=head3 webdir

F</var/www> - $localstatedir/www

Directory where distribution put static web files.

=head2 HOW IT WORKS

The heart of L<Sys::Path> is just:

    use Config;
    if ($Config::Config{'prefix'} eq '/usr') { ... do stuff ... }

The idea is that if the Perl was installed to F</usr> it is FHS type
installation and all path defaults are made based on FHS. For the
rest of the installations C<prefix> and C<localstatedir> is set exactly
to C<$Config::Config{'prefix'}> which is the prefix of Perl that was used
to install. In this case C<sysconfdir> is set to C<prefix+'etc'>.
See L<Sys::Path::SPc> for the implementation.

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

=head1 BUILDERS/INSTALLERS helper methods

=head2 find_distribution_root(__PACKAGE__)

Find the root folder of a modules distribution by going up the
folder structure.

=head2 prompt_cfg_file_changed($src_file, $dst_file, $prompt_function)

Will prompt if to overwrite C<$dst_file> with C<$src_file>. Returns
true for "yes" and false for "no".

=head2 changed_since_install($dest_file, $file)

Return if C<$dest_file> changed since install. If optional C<$file> is
set then this one is compared against install C<$dest_file> checksum.

=head2 install_checksums(%filenames_with_checksums)

Getter and setter for files checksums recording.

=head1 SEE ALSO

L<Module::Build::SysPath>

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 CONTRIBUTORS
 
The following people have contributed to the Sys::Path by committing their
code, sending patches, reporting bugs, asking questions, suggesting useful
advises, nitpicking, chatting on IRC or commenting on my blog (in no particular
order):

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
