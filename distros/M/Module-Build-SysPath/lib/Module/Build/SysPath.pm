package Module::Build::SysPath;

use warnings;
use strict;

our $VERSION = '0.20';

use base 'Module::Build';
use Sys::Path 0.11;
use List::MoreUtils 'any';
use FindBin '$Bin';
use Digest::MD5 qw(md5_hex);
use Text::Diff 'diff';
use File::Spec;
use File::Temp 'tempfile';
use Path::Tiny 'path';
use IO::Any;
use ExtUtils::Manifest ();
use B 'perlstring';

our $sys_path_config_name = 'SPc';

sub _spc_open_source {
    my ($builder, $filename) = @_;
    open(my $fh, '<', $filename) or die $!;
    return $fh;
}

sub _spc_write {
    my ($builder, $fh, $content) = @_;
    print {$fh} $content or die $!;
    return;
}

sub _spc_close {
    my ($builder, $fh) = @_;
    close($fh) or die $!;
    return;
}

sub _spc_rename {
    my ($builder, $source, $destination) = @_;
    rename($source, $destination) or die $!;
    return;
}

sub _rewrite_spc_accessors {
    my ($content, $path_types, $paths) = @_;

    foreach my $path_type (split(m/\|/, $path_types)) {
        die "invalid SPc path type '$path_type'"
            if $path_type !~ m/\A[A-Za-z_]\w*\z/;

        my $header = qr/^[ \t]*sub[ \t]+\Q$path_type\E\b/m;
        my $header_count = () = $content =~ m/$header/g;
        die "missing SPc accessor '$path_type'\n" if not $header_count;
        die "duplicate SPc accessor '$path_type'\n" if $header_count > 1;

        my $definition = qr{
            ^[ \t]*          # Allow indentation at the start of the line.
            sub [ \t]+       # Require a named subroutine declaration.
            \Q$path_type\E   # Match only the requested accessor name.
            \s*              # Allow the opening brace on a later line.
            \{               # Start the accessor body.
            [^{}]*           # Reject bodies containing nested blocks.
            \}               # End the accessor body.
            [ \t]*           # Allow whitespace before the terminator.
            ;?               # Accept an optional statement terminator.
            [ \t]*           # Allow trailing horizontal whitespace.
            (?: \r?\n | \z ) # Consume the line ending or end of source.
        }xm;
        my $definition_count = () = $content =~ m/$definition/g;
        die "unsupported SPc accessor '$path_type'\n"
            if $definition_count != 1;

        my $literal = perlstring(path($paths->{$path_type})->stringify);
        my $replacement = "sub $path_type { $literal };\n";
        $content =~ s/$definition/$replacement/;
    }

    return $content;
}

sub _rewrite_installed_spc {
    my ($builder, $source, $destination, $path_types) = @_;
    my $mode = (stat($destination))[2];
    die "cannot stat '$destination': $!" if not defined $mode;
    $mode &= oct('7777');

    my ($source_fh, $temporary_fh, $temporary);
    my $rewrite_succeeded = eval {
        $source_fh = $builder->_spc_open_source($source);
        my $content = '';
        local $! = 0;
        while (defined(my $line = <$source_fh>)) {
            next if $line =~ m/# remove after install$/;
            $content .= $line;
        }
        die "cannot read '$source': $!" if $!;
        $builder->_spc_close($source_fh, 'source');
        undef $source_fh;

        $content = _rewrite_spc_accessors(
            $content,
            $path_types,
            $builder->{'properties'}->{'spc'}->{'path'},
        );

        ($temporary_fh, $temporary) = tempfile(
            '.SPc.pm.XXXXXX', DIR => path($destination)->parent, UNLINK => 0,
        );
        $builder->_spc_write($temporary_fh, $content);
        chmod($mode, $temporary)
            or die "cannot chmod '$temporary': $!";
        $builder->_spc_close($temporary_fh, 'destination');
        undef $temporary_fh;
        $builder->_spc_rename($temporary, $destination);
        undef $temporary;
        1;
    };
    my $rewrite_error = $@;
    if (not $rewrite_succeeded) {
        eval { close($source_fh) } if $source_fh;
        eval { close($temporary_fh) } if $temporary_fh;
        unlink($temporary) if defined $temporary and -e $temporary;
        die $rewrite_error;
    }
    return;
}

# Return a callback that is true for files to leave out because a MANIFEST
# exists and does not list them. It warns unless MANIFEST.SKIP excludes the
# file on purpose.
sub _manifest_filter {
    my ($builder, $distribution_root) = @_;

    my $manifest_file = $distribution_root->child('MANIFEST');
    return sub { 0 } if not $manifest_file->is_file;
    my $manifest = ExtUtils::Manifest::maniread("$manifest_file");

    my $manifest_skip_file = $distribution_root->child('MANIFEST.SKIP');
    my $manifest_skip = ExtUtils::Manifest::maniskip(
        $manifest_skip_file->is_file
            ? "$manifest_skip_file"
            : $ExtUtils::Manifest::DEFAULT_MSKIP
    );

    return sub {
        my ($file) = @_;
        return 0 if exists $manifest->{$file};
        $builder->log_warn("'$file' is not listed in MANIFEST and will not be installed\n")
            if not $manifest_skip->($file);
        return 1;
    };
}

# True for files that are installed only when listed in <path_type>_files:
# files in non-persistent folders, in dot folders, and dot files other
# than .exists.
sub _skipped_unless_wanted {
    my ($source_path, $file, $wanted_files, $non_persistant, $ignore_folders) = @_;

    return 0 if exists $wanted_files->{$file};
    return 1 if $non_persistant;
    return 1 if any { $_->subsumes($source_path) } @{$ignore_folders};

    my $basename = $source_path->basename;
    return substr($basename, 0, 1) eq '.' && $basename ne '.exists';
}

sub new {
	my $class = shift;
	my $builder = $class->SUPER::new(@_);
    my $module  = $builder->module_name;

    # normalize module name (some people write - instead of ::) and add config level
    $module =~ s/-/::/g;
    $module .= '::'.$sys_path_config_name;
    
    do {
        unshift @INC, File::Spec->catdir($Bin, 'lib');
        eval "use $module"; die $@ if $@;
    };
    
    my $distribution_root = path(
        Sys::Path->find_distribution_root($builder->module_name)
    )->absolute;
    print 'dist root is ', $distribution_root, "\n";

    my $skip_unlisted = $builder->_manifest_filter($distribution_root);
    
    # map conf files to array of real paths
    my @conffiles = (
        map { ref $_ eq 'ARRAY' ? path(@{$_}) : path($_) }              # convert path arrays to normalized file names
        @{$builder->{'properties'}->{'conffiles'} || []}                # all conffiles
    );
    
    my %spc_properties = (
        'path_types' => [ $module->_path_types ],
    );
    my %configuration_files;
    my %payload_destinations;
    my @writefiles_in_system;
    my @create_folders_in_system;
    foreach my $path_type ($module->_path_types) {
        my $sys_path     = path($module->$path_type)->absolute;
        my $install_path = path(Sys::Path->$path_type)->absolute;
        
        my $wanted_files = $builder->{'properties'}->{$path_type.'_files'} ||= {};

        # store for install time retrieval
        $spc_properties{'path'}->{$path_type} = $install_path;

        # skip prefix and localstatedir those are not really destination paths
        next
            if any { $_ eq $path_type } ('prefix' ,'localstatedir');

        # prepare a list of files to install
        my $non_persistant = (any { $_ eq $path_type} qw(cachedir logdir spooldir rundir lockdir sharedstatedir));
        if (-d $sys_path) {
            my %files;
            my @ignore_folders;
            foreach my $file (@{$builder->rscan_dir($sys_path)}) {
                my $source_path = path($file)->absolute;
                die "'$source_path' is outside distribution root '$distribution_root'"
                    if not $distribution_root->subsumes($source_path);
                die "'$source_path' is outside path-type root '$sys_path'"
                    if not $sys_path->subsumes($source_path);

                my $distribution_file = $source_path->relative($distribution_root);

                # skip folders, but remember folders with . prefix
                if (-d $file) {
                    # ignore folders with . prefix
                    push @ignore_folders, $source_path
                        if substr($source_path->basename, 0, 1) eq '.'
                        and not exists $wanted_files->{"$distribution_file"};

                    next;
                }

                my $path_file = $source_path->relative($sys_path);
                my $dest_file = $install_path->child($path_file);
                my $blib_file = path($path_type)->child($path_file);
                $file = "$distribution_file";
                
                # allow empty directories to be created
                if (path($file)->basename eq '.exists') {
                    next if $skip_unlisted->($file);
                    push @create_folders_in_system, path($dest_file)->parent;
                }

                next if _skipped_unless_wanted(
                    $source_path, $file, $wanted_files,
                    $non_persistant, \@ignore_folders,
                );
                next if $skip_unlisted->($file);
                
                # print 'file>  ', $file, "\n";
                # print 'bfile> ', $blib_file, "\n";
                # print 'dfile> ', $dest_file, "\n\n";
                
                $configuration_files{$dest_file} = $blib_file
                    if (path($file)->basename ne '.exists')
                    and (
                        $path_type eq 'sysconfdir'
                        or any { $_ eq $file } @conffiles
                    );

                # add file the the Build.PL _files list
                $files{$file} = $blib_file;
                $payload_destinations{$file} = "$dest_file"
                    if path($file)->basename ne '.exists';

                # make the conf and state files writable in the system
                push @writefiles_in_system, $dest_file
                    if any { $_ eq $path_type } qw(sharedstatedir sysconfdir);                
            }
            $builder->{'properties'}->{$path_type.'_files'} = \%files;
        }
                
        # set installation paths
        $builder->{'properties'}->{'install_path'}->{$path_type} = $install_path;
        
        # add build elements of the path types
        $builder->add_build_element($path_type);
    }
    $builder->{'properties'}->{'spc'} = \%spc_properties;
    $builder->notes('configuration_files' => \%configuration_files);
    $builder->notes('writefiles_in_system' => \@writefiles_in_system);
    $builder->notes('create_folders_in_system' => \@create_folders_in_system);
    $builder->notes('payload_destinations' => [ sort values %payload_destinations ]);

    $builder->notes('installed_file_modes' =>
        $builder->_installed_file_modes(\%payload_destinations));

    return $builder;
}

# Validate the file_modes property and map it to installed destinations.
sub _installed_file_modes {
    my ($builder, $payload_destinations) = @_;

    my %installed_file_modes;
    return \%installed_file_modes
        if not exists $builder->{'properties'}->{'file_modes'};
    my $file_modes = $builder->{'properties'}->{'file_modes'};
    die "file_modes must be a hash of dist-relative files and integer modes\n"
        if ref($file_modes) ne 'HASH';
    foreach my $file (keys %{$file_modes}) {
        my $mode = $file_modes->{$file};
        die "file_modes key '$file' must be relative to the distribution root\n"
            if File::Spec->file_name_is_absolute($file)
            or any { $_ eq '..' } File::Spec->splitdir($file);
        # A numeric literal never stringifies with a leading zero, so this
        # rejects quoted octal strings such as '0640', which Perl reads as decimal.
        die "file_modes has invalid mode for '$file': use an unquoted"
            ." octal literal in 0000..0777\n"
            if not defined($mode) or ref($mode)
            or $mode !~ /\A[0-9]+\z/ or $mode =~ /\A0[0-9]/
            or $mode > oct('777');
        my $normalized = ''.path($file);
        die "file_modes file '$file' is not a selected payload\n"
            if not exists $payload_destinations->{$normalized};
        my $destination = $payload_destinations->{$normalized};
        die "file_modes declares '$normalized' more than once\n"
            if exists $installed_file_modes{$destination};
        $installed_file_modes{$destination} = 0 + $mode;
    }
    return \%installed_file_modes;
}

sub ACTION_install {
    my $builder = shift;
    my $destdir = $builder->{'properties'}->{'destdir'};

    # Build before deciding so comparisons and checksums use the installed bytes.
    $builder->depends_on('build');
    my %conffiles_in_system;
    my %backup_files;
    my %alternate_files;
    my %declared_modes = %{$builder->notes('installed_file_modes') || {}};
    my %final_modes;
    my $remember_mode = sub {
        my ($destination, $mode) = @_;
        my $target = File::Spec->catfile($destdir || (), $destination);
        if (-e $target) {
            my @stat = stat($target);
            die "cannot stat '$target': $!\n" if not @stat;
            $mode &= $stat[2] & oct('777');
        }
        $final_modes{$target} = $mode;
    };
    # ExtUtils::Install replaces a file with a new one owned by the installing
    # user; remember owners to give replaced files back to them.
    my %owners;
    my $remember_owner = sub {
        my ($destination) = @_;
        my $target = File::Spec->catfile($destdir || (), $destination);
        my @stat = lstat($target);
        $owners{$target} = [ @stat[4, 5] ] if @stat and -f _;
    };
    # Snapshot before the parent installer changes permissions or replaces files.
    foreach my $destination (keys %declared_modes) {
        $remember_mode->($destination, $declared_modes{$destination});
    }
    $remember_owner->($_) foreach @{$builder->notes('payload_destinations') || []};
    my @writefiles_in_system = @{$builder->notes('writefiles_in_system')};
    if (not $destdir) {
        my %configuration_files = %{$builder->notes('configuration_files')};
        while (my ($dest_file, $blib_file) = each %configuration_files) {
            my $file = File::Spec->catfile($builder->blib, $blib_file);
            $conffiles_in_system{$dest_file} = md5_hex(IO::Any->slurp([$file]));
            next unless -f $dest_file
                and diff($file, $dest_file, { STYLE => 'Unified' })
                and Sys::Path->changed_since_install($dest_file);

            if (
                Sys::Path->changed_since_install($dest_file, $file)
                and Sys::Path->prompt_cfg_file_changed(
                    $file, $dest_file, sub { $builder->prompt(@_) },
                )
            ) {
                $backup_files{$dest_file} = $dest_file.'-old';
                $final_modes{$dest_file.'-old'} = $final_modes{$dest_file}
                    if exists $declared_modes{$dest_file};
            }
            else {
                $alternate_files{$file} = $file.'-spc';
                $remember_owner->($dest_file.'-spc');
                $remember_mode->($dest_file.'-spc', $declared_modes{$dest_file})
                    if exists $declared_modes{$dest_file};
                @writefiles_in_system = map {
                    $_ eq $dest_file ? $_.'-spc' : $_
                } @writefiles_in_system;
            }
        }
    }

    # create requested folders
    foreach my $folder (@{$builder->notes('create_folders_in_system')}) {
        $folder = File::Spec->catdir($destdir || (), $folder);
        if (not -d $folder) {
            print 'Creating '.$folder.' folder', "\n";
            path($folder)->mkdir;
        }
    }

    # Restore ordinary build filenames even when the parent installer fails.
    my @renamed_files;
    my @backed_up_files;
    my $installed = eval {
        foreach my $backup (values %backup_files) {
            die "configuration backup '$backup' already exists\n"
                if -e $backup;
        }
        while (my ($file, $backup) = each %backup_files) {
            print 'Moving ', $file, ' -> ', $backup, "\n";
            rename($file, $backup) or die $!;
            push @backed_up_files, $file;
        }
        while (my ($file, $alternate) = each %alternate_files) {
            rename($file, $alternate) or die $!;
            push @renamed_files, $file;
        }
        $builder->SUPER::ACTION_install(@_);
        1;
    };
    my $install_error = $@;
    my @recovery_errors;
    foreach my $file (@renamed_files) {
        rename($alternate_files{$file}, $file)
            or push @recovery_errors, "cannot restore '$file': $!";
    }
    if (not $installed) {
        foreach my $file (reverse @backed_up_files) {
            if (-e $file and not unlink($file)) {
                push @recovery_errors, "cannot remove partial '$file': $!";
                next;
            }
            rename($backup_files{$file}, $file)
                or push @recovery_errors, "cannot restore '$file': $!";
        }
        die join("\n", $install_error, @recovery_errors);
    }
    die join("\n", @recovery_errors) if @recovery_errors;

    my $module  = $builder->module_name;

    my $path_types = join('|', @{$builder->{'properties'}->{'spc'}->{'path_types'}});
    
    # normalize module name (some people write - instead of ::) and add config level
    $module =~ s/-/::/g;
    $module .= '::'.$sys_path_config_name;
    
    # get path to blib and just installed SPc.pm
    my $module_filename = $module.'.pm';
    $module_filename =~ s{::}{/}g;
    my $installed_module_filename = File::Spec->catfile(
        $builder->install_map->{File::Spec->catdir(
            $builder->blib,
            'lib',        
        )},
        $module_filename
    );
    $module_filename = File::Spec->catfile($builder->blib, 'lib', $module_filename);
    
    die 'no such file - '.$module_filename
        if not -f $module_filename;
    die 'no such file - '.$installed_module_filename
        if not -f $installed_module_filename;
    $builder->_rewrite_installed_spc(
        $module_filename, $installed_module_filename, $path_types,
    );

    _restore_owners(\%owners);
    _apply_install_modes($destdir, \@writefiles_in_system, \%final_modes);

    # record md5sum of new distribution conffiles (only when really installing to system)
    Sys::Path->install_checksums(%conffiles_in_system)
        if (not $destdir);
    
    return;
}

# Give installed files that replaced existing ones the owner and group of the
# replaced file. A failed chown only warns, because the files are installed.
sub _restore_owners {
    my ($owners) = @_;

    foreach my $target (sort keys %{$owners}) {
        my @stat = lstat($target);
        next if not @stat or not -f _;
        my ($uid, $gid) = @{$owners->{$target}};
        next if $stat[4] == $uid and $stat[5] == $gid;
        chown(
            ($stat[4] == $uid ? -1 : $uid),
            ($stat[5] == $gid ? -1 : $gid),
            $target,
        ) or warn sprintf("cannot restore owner %d:%d of '%s': %s\n",
            $uid, $gid, $target, $!);
    }
    return;
}

# Set final permissions of installed files: declared modes from %$final_modes,
# 0644 for the other writable system files.
sub _apply_install_modes {
    my ($destdir, $writefiles_in_system, $final_modes) = @_;

    # see https://rt.cpan.org/Ticket/Display.html?id=49579
    # ExtUtils::Install is forcing 0444 so we have to hack write permition after install :-/
    foreach my $writefile (@{$writefiles_in_system}) {
        my $target = File::Spec->catfile($destdir || (), $writefile);
        next if exists $final_modes->{$target};
        chmod 0644, $target or die $!;
    }
    foreach my $target (sort keys %{$final_modes}) {
        my $mode = $final_modes->{$target};
        chmod($mode, $target)
            or die sprintf("cannot chmod '%s' to %04o: %s\n", $target, $mode, $!);
    }
    return;
}

1;


__END__

=encoding utf-8

=head1 NAME

Module::Build::SysPath - install files to system folders according to FHS (or Sys::Path settings)

=head1 SYNOPSIS

    use Module::Build::SysPath;
    my $builder = Module::Build::SysPath->new(
        ...


=head1 DESCRIPTION

A subclass of L<Module::Build> using L<Sys::Path> to determine the system
folders. Help in task of installing files into system folders and keeping
the option to work in local distribution files while developing the module.

See L<Acme::SysPath> for example usage of a module that needs a configuration
and a folder to store templates in.

=head1 USAGE

=head2 module-starter

    module-starter --builder=Module::Build --module=Acme::NewModule --author="Pod" --email=pod@pod
    cd Acme-NewModule/
    perl -lane 's/Module::Build-/Module::Build::SysPath-/; print $_;' -i Build.PL 
    vim Build.PL
    # s/Module::Build-/Module::Build::SysPath-/
    # add "configure_requires => { 'Module::Build::SysPath' => 0.10 },"
    # add "Module::Build::SysPath' => 0.10," to build_requires

=head2 create SPc.pm

copy L<http://github.com/jozef/Sys-Path/blob/master/examples/SPc.pm> and add
it to your source tree. Clean up the paths that you don't need. Local distribution
folder names can be changed to anyones taste. For example:

    sub sysconfdir { File::Spec->catdir(__PACKAGE__->prefix, 'conf') };

'conf' is the name of a folder with C<conffile>s. All file put to this folder
will be installed to L<Sys::Path>->sysconfdir().

=head2 use the SPc.pm

Calling C<< Acme::NewModule::SPc->sysconfdir >> before the distribution is
installed will return path to the 'conf' folder in the distribution root
folder. Calling it after install the distribution will return L<Sys::Path>->sysconfdir().

=head1 EXAMPLE

See L<Acme::SysPath> for a really simple, L<Test::Daily> for a real world example.

=head2 new

Populates:

    $builder->{'properties'}->{$path_type.'_files'} = ...;
    $builder->{'properties'}->{'install_path'}->{$path_type} = ...;
    $builder->add_build_element($path_type);

To install files located in:

	sysconfdir
	datadir
	docdir
	localedir
	webdir
	srvdir

Folders in:

    cachedir
    logdir
    spooldir
    rundir
    lockdir
    sharedstatedir

are skipped during the installation. Add F<.exists> to this folders if you
want them to be created during `./Build install`. The F<.exists> file itself
is not installed.

To install a specific file from a skipped folder, a file from a folder
starting with a dot, or a file starting with a dot, list its path relative
to the distribution root in the C<< <path_type>_files >> property:

    my $builder = Module::Build::SysPath->new(
        ...
        sharedstatedir_files => {
            'var/lib/acme-notes/index.json' => 1,
        },
        webdir_files => {
            'www/.htaccess' => 1,
        },
    );

Every C<./Build install> overwrites such a file with the distribution
version, so runtime changes to it are lost. To keep them, also list the file
in C<conffiles>, or create the file at runtime instead of shipping it.

=head3 MANIFEST

When the distribution root contains a F<MANIFEST>, only files listed in it
are installed. C<perl Build.PL> warns about every other file it would have
installed:

    'etc/acme/secret.pem' is not listed in MANIFEST and will not be installed

Files matching F<MANIFEST.SKIP> (or the default skip list of
L<ExtUtils::Manifest> when there is no F<MANIFEST.SKIP>) are left out on
purpose, so they are not installed and not reported.

B<Files kept out of the tarball by F<MANIFEST.SKIP> are not installed from a
checkout either.> If a checkout install must deploy such files, for example
keys that should not be published, copy them in a custom C<ACTION_install>
or deploy them outside the build.

This keeps editor backups and other stray files in a checkout from being
installed, and makes an install from a checkout match an install from the
distribution tarball. Without a F<MANIFEST>, every file found is installed.

B<Rerun C<perl Build.PL> after adding files.> The file list is collected
from the folders on disk when C<perl Build.PL> runs, not when C<./Build
install> runs.

=head3 Configuration files

Configuration files get a special (Debian like) treatment. All files in
C<sysconfdir> and all files specified as C<< $builder->{'properties'}->{'conffiles'} >>
are configuration files. Using L<Sys::Path/install_checksums> the c<conffile>s
checksums are tracked. Here are the model situations:

=over 4

=item C<conffile> was never installed jet

The file is just copied in place (to sysconfdir) as it is. MD5 is recorded.

=item distribution ships new version, no change in system

The distribution changed the C<conffile> (for example by adding new values),
but the C<conffile> was untouched in the system. Then the new version from
distribution replaces the one in the system.

=item distribution C<conffile> wasn't changed, C<conffile> changed in system

Already installed distribution is getting upgrade. Distribution C<conffile>s form
installed and the new version didn't change. But the C<conffile> was changed in
the system. No prompt and the C<conffile> is kept intact.

=item distribution C<conffile> change, C<conffile> changed in system

Already installed distribution is getting upgrade. When both the distribution
changed the C<conffile> and the C<conffile> was changed in the system. User will
be prompted what to do:

    Installing new version of config file /etc/SOMEFILE ...
    
    Configuration file `/etc/SOMEFILE'
     ==> Modified (by you or by a script) since installation.
     ==> Package distributor has shipped an updated version.
       What would you like to do about it ?  Your options are:
        Y or I  : install the package maintainer's version
        N or O  : keep your currently-installed version
          D     : show the differences between the versions
          Z     : background this process to examine the situation
     The default action is to keep your current version.
    
    *** /etc/SOMEFILE (Y/I/N/O/D/Z) ?

If N or O is selected distribution files is installed with F<-spc>
suffix. If Y or I is selected the system C<conffile> is renamed by adding
suffix F<-old> and distribution C<conffile> is installed. Installation aborts
without changing either file if the F<-old> backup already exists. If the
parent installation fails after the rename, the original C<conffile> is
restored.

Unattended installs take the default answer N: the system C<conffile> is
kept and the distribution version is installed with the F<-spc> suffix. An
install is unattended with C<PERL_MM_USE_DEFAULT=1>, or without a terminal
when standard input is at end of file.

A system C<conffile> without a recorded checksum counts as changed in the
system.

=back

=head3 File modes

Set the permissions of installed files with C<file_modes>. Keys are paths
relative to the distribution root, values are modes written as Perl octal
literals:

    my $builder = Module::Build::SysPath->new(
        ...
        file_modes => {
            'etc/acme/secret.ini' => 0640,
        },
    );

Write the mode unquoted. A quoted C<'0640'> would be read as a decimal
number, so quoted modes with a leading zero are rejected.

Every key must name a single file that is already selected for installation.
C<file_modes> does not select files: it neither bypasses F<MANIFEST> nor
replaces C<< <path_type>_files >>. A C<file_modes> value that is not a hash,
keys naming unselected files, the same file twice (for example F<etc/x>
and F<./etc/x>), directories, globs, F<.exists> markers,
absolute paths or paths leaving the distribution root, and modes outside
C<0000..0777> or non-integer modes make C<perl Build.PL> die.

A declared mode is a ceiling. It never grants access that the file in the
system does not already have:

=over 4

=item new file

Gets the declared mode.

=item existing file

Gets the declared mode combined (bitwise AND) with its current mode. With
C<0640> declared, a C<0644> file becomes C<0640> and a C<0600> file stays
C<0600>. This also applies to a kept C<conffile>, its F<-spc> copy and an
F<-old> backup, whose current mode is the mode of the replaced C<conffile>,
so a C<0644> original becomes a C<0640> backup. A new
F<-spc> copy is limited only by an existing F<-spc>, not by the mode of the
kept C<conffile>.

=item C<--destdir>

The same rules apply to the staged files under the destination directory.
Files in the live system are not touched.

=back

Without a declaration, files installed to C<sysconfdir> and
C<sharedstatedir> are set to C<0644>, and other files keep the mode set by
L<ExtUtils::Install> (C<0444>, or C<0555> for executables).

If setting a declared mode fails, the installation dies with the path and
mode, and no C<conffile> checksums are recorded.

B<The declared mode is guaranteed only after a successful installation.>
L<ExtUtils::Install> first installs every file with mode C<0444> (C<0555>
for executables), and C<ACTION_install> sets the declared mode afterwards. Until then, and after a
failed installation, a secret file can be readable by every local user who
can reach its folder. Deployments that need stronger guarantees should
install through a distribution package that sets permissions while copying.

=head3 Owner and group

Installation never assigns an owner or group of its own. A new file belongs
to the user running the installation. When a file that already exists in the
system is replaced, the new file gets the owner and group of the replaced
file, so a C<chgrp> of a secret C<conffile> to the group of a service
survives upgrades. This covers payload files of every path type, the
F<-spc> copy of a kept C<conffile> and, when the new version of a
C<conffile> is accepted, the newly installed C<conffile>. A kept C<conffile>
and an F<-old> backup are not replaced, so they keep their owner and group.
With C<--destdir>, the same applies to the staged files.

Only root can give a file to another user. If restoring the owner or group
fails, the installation warns with the path and continues.

=head2 ACTION_install

This action is responsible for renaming files, replacing F<SPc.pm> paths
to systems once from L<Sys::Path>. Also restores the owner and group of
replaced files as described in L</Owner and group>, sets undeclared
C<sysconfdir> and
C<sharedstatedir> files to C<0644>, applies C<file_modes> as described in
L</File modes>, and stores the
checksums of C<conffile>s.

=head1 AUTHOR

Jozef Kutej, <jkutej@cpan.org>

=head1 CONTRIBUTORS
 
The following people have contributed to the Sys::Path by commiting their
code, sending patches, reporting bugs, asking questions, suggesting useful
advices, nitpicking, chatting on IRC or commenting on my blog (in no particular
order):

    Lars Dɪᴇᴄᴋᴏᴡ 迪拉斯
    Emmanuel Rodriguez
    Slaven Rezić


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
