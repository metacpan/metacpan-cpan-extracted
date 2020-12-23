package STEVEB::Dist::Mgr;

use strict;
use warnings;
use version;

use Carp qw(croak cluck);
use Data::Dumper;
use File::Copy;
use File::Find::Rule;
use PPI;
use Tie::File;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    add_bugtracker
    add_repository
    bump_version
    get_version_info
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = '0.02';

use constant {
    FSTYPE_IS_DIR       => 1,
    FSTYPE_IS_FILE      => 2,

    DEFAULT_DIR         => 'lib/',
};

# Public

#TODO:
# unlink unwanted files & dirs (xt/, ignore.txt, README)
# travis-ci
# appveyor
# MANIFEST.SKIP
# .gitignore

sub add_bugtracker {
    my ($author, $repo, $makefile) = @_;

    if (! defined $author || ! defined $repo) {
        croak("Usage: add_bugtracker(\$author, \$repository_name)\n");
    }

    $makefile //= 'Makefile.PL';

    _makefile_insert_bugtracker($author, $repo, $makefile);
}
sub add_repository {
    my ($author, $repo, $makefile) = @_;

    if (! defined $author || ! defined $repo) {
        croak("Usage: add_repository(\$author, \$repository_name)\n");
    }

    $makefile //= 'Makefile.PL';

    _makefile_insert_repository($author, $repo, $makefile);
}
sub bump_version {
    my ($version, $fs_entry) = @_;

    my $dry_run = 0;

    if (defined $version && $version =~ /^-/) {
        print "\nDry run\n\n";
        $version =~ s/-//;
        $dry_run = 1;
    }

    _validate_version($version);
    _validate_fs_entry($fs_entry);

    my @module_files = _find_module_files($fs_entry);

    my %files;

    for (@module_files) {
        my $current_version = _extract_file_version($_);
        my $version_line    = _extract_file_version_line($_);
        my @file_contents   = _fetch_file_contents($_);

        if (! defined $version_line) {
            next;
        }

        if (! defined $current_version) {
            next;
        }

        my $mem_file;

        open my $wfh, '>', \$mem_file or croak("Can't open mem file!: $!");

        for my $line (@file_contents) {
            chomp $line;

            if ($line eq $version_line) {
                $line =~ s/$current_version/$version/;
            }

            $line .= "\n";

            # Write out the line to the in-memory temp file
            print $wfh $line;

            $files{$_}{from}    = $current_version;
            $files{$_}{to}      = $version;
        }

        close $wfh;

        $files{$_}{dry_run} = $dry_run;
        $files{$_}{content} = $mem_file;

        if (! $dry_run) {
            # Write out the actual file
            _write_module_file($_, $mem_file);
        }
    }
    return \%files;
}
sub get_version_info {
    my ($fs_entry) = @_;

    _validate_fs_entry($fs_entry);

    my @module_files = _find_module_files($fs_entry);

    my %version_info;

    for (@module_files) {
        my $version = _extract_file_version($_);
        $version_info{$_} = $version;
    }

    return \%version_info;
}

# Module related

sub _find_module_files {
    my ($fs_entry) = @_;

    $fs_entry //= DEFAULT_DIR;

    return File::Find::Rule->file()
        ->name('*.pm')
        ->in($fs_entry);
}
sub _fetch_file_contents {
    my ($file) = @_;

    open my $fh, '<', $file
      or croak("Can't open file '$file' for reading!: $!");

    my @contents = <$fh>;
    close $fh;
    return @contents;
}
sub _extract_file_version {
    my ($module_file) = @_;

    my $version_line = _extract_file_version_line($module_file);

    if (defined $version_line) {

        if ($version_line =~ /=(.*)$/) {
            my $ver = $1;

            $ver =~ s/\s+//g;
            $ver =~ s/;//g;
            $ver =~ s/[a-zA-Z]+//g;
            $ver =~ s/"//g;
            $ver =~ s/'//g;

            if (! defined eval { version->parse($ver); 1 }) {
                warn("$_: Can't find a valid version\n");
                return undef;
            }

            return $ver;
        }
    }
    else {
        warn("$_: Can't find a \$VERSION definition\n");
    }
    return undef;
}
sub _extract_file_version_line {
    my ($module_file) = @_;

    my $doc = PPI::Document->new($module_file);

    my $token = $doc->find(
        sub {
            $_[1]->isa("PPI::Statement::Variable")
                and $_[1]->content =~ /\$VERSION/;
        }
    );

    return undef if ref $token ne 'ARRAY';

    my $version_line = $token->[0]->content;

    return $version_line;
}
sub _write_module_file {
    my ($module_file, $content) = @_;

    open my $wfh, '>', $module_file or croak("Can't open '$module_file' for writing!: $!");

    print $wfh $content;

    close $wfh or croak("Can't close the temporary memory module file!: $!");
}

# Makefile related

sub _makefile_load {
    my ($mf) = @_;
    croak("_makefile_load() needs a Makefile name sent in") if ! defined $mf;

    my $tie = tie my @mf, 'Tie::File', $mf;
    return (\@mf, $tie);
}
sub _makefile_insert_meta_merge {
    my ($mf) = @_;

    croak("_makefile_insert_meta_merge() needs a Makefile tie sent in") if ! defined $mf;

    # Check to ensure we're not duplicating
    return if grep /META_MERGE/, @$mf;

    for (0..$#$mf) {
        if ($mf->[$_] =~ /MIN_PERL_VERSION/) {
            splice @$mf, $_+1, 0, _makefile_section_meta_merge();
            last;
        }
    }
}
sub _makefile_insert_bugtracker {
    my ($author, $repo, $makefile) = @_;

    if (! defined $makefile) {
        croak("_makefile_insert_bugtracker() needs author, repo and makefile");
    }

    my ($mf, $tie) = _makefile_load($makefile);

    if (grep ! /META_MERGE/, @$mf) {
        _makefile_insert_meta_merge($mf);
    }

    for (0..$#$mf) {
        if ($mf->[$_] =~ /resources   => \{/) {
            splice @$mf, $_+1, 0, _makefile_section_bugtracker($author, $repo);
            last;
        }
    }
    untie $tie;

    return 0;
}
sub _makefile_insert_repository {
    my ($author, $repo, $makefile) = @_;

    if (! defined $makefile) {
        croak("_makefile_insert_repository() needs author, repo and makefile");
    }

    my ($mf, $tie) = _makefile_load($makefile);

    if (grep ! /META_MERGE/, @$mf) {
        _makefile_insert_meta_merge($mf);
    }

    for (0..$#$mf) {
       if ($mf->[$_] =~ /resources   => \{/) {
           splice @$mf, $_+1, 0, _makefile_section_repo($author, $repo);
           last;
       }
    }
    untie $tie;

    return 0;
}

sub _makefile_section_meta_merge {
    my @merge_section = (
        "    META_MERGE => {",
        "        'meta-spec' => { version => 2 },",
        "        resources   => {",
        "        },",
        "    },"
    );

    return @merge_section;
}
sub _makefile_section_bugtracker {
    my ($author, $repo) = @_;

    return (
        "            bugtracker => {",
        "                web => 'https://github.com/$author/$repo/issues',",
        "            },"
    );

}
sub _makefile_section_repo {
    my ($author, $repo) = @_;

    return (
    "            repository => {",
    "                type => 'git',",
    "                url => 'https://github.com/$author/$repo.git',",
    "                web => 'https://github.com/$author/$repo',",
    "            },"
    );

}

# Validation related

sub _validate_fs_entry {
    my ($fs_entry) = @_;

    cluck("Need name of dir or file!") if ! defined $fs_entry;

    return FSTYPE_IS_DIR    if -d $fs_entry;
    return FSTYPE_IS_FILE   if -f $fs_entry;

    croak("File system entry '$fs_entry' is invalid");
}
sub _validate_version {
    my ($version) = @_;

    croak("version parameter must be supplied!") if ! defined $version;

    if (! defined eval { version->parse($version); 1 }) {
        croak("The version number '$version' specified is invalid");
    }
}

sub __placeholder {}

1;
__END__

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
