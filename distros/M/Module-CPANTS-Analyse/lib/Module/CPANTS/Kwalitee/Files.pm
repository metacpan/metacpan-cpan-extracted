package Module::CPANTS::Kwalitee::Files;
use warnings;
use strict;
use File::Find::Object;
use File::Spec::Functions qw(catfile);
use File::stat;

our $VERSION = '0.96';
$VERSION = eval $VERSION; ## no critic

sub order { 15 }

##################################################################
# Analyse
##################################################################

sub analyse {
    my $class=shift;
    my $me=shift;
    my $distdir=$me->distdir;
    $distdir =~ s|\\|/|g if $^O eq 'MSWin32';

    # Respect no_index if possible
    my $no_index_re = $class->_make_no_index_regex($me);

    my (%files, %dirs);
    my (@files_array, @dirs_array);
    my $size = 0;
    my $latest_mtime = 0;
    my @base_dirs;
    my $finder = File::Find::Object->new({
        depth => 1,
    }, $distdir);
    while(defined(my $name = $finder->next)) {
        $name =~ s|\\|/|g if $^O eq 'MSWin32';
        (my $path = $name) =~ s!^\Q$distdir\E(?:/|$)!! or next;
        next if $path eq '';

        if (-d $name) {
            $dirs{$path} ||= {};
            if (-l $name) {
                $dirs{$path}{symlink} = 1;
            }
            push @dirs_array, $path;
            next;
        }

        if ($me->d->{is_local_distribution}) {
            next if $path =~ m!/\.!;
        }

        if (my $stat = stat($name)) {
            $files{$path}{size} = $stat->size || 0;
            $size += $files{$path}{size};

            my $mtime = $files{$path}{mtime} = $stat->mtime;
            $latest_mtime = $mtime if $mtime > $latest_mtime;
        } else {
            $files{$path}{stat_error} = $!;
            next;
        }

        if (-l $name) {
            $files{$path}{symlink} = 1;
        }

        if (!-r $name) {
            $files{$path}{unreadable} = 1;
            next;
        }

        if ($no_index_re && $path =~ qr/$no_index_re/) {
            $files{$path}{no_index} = 1;
            next;
        }

        # ignore files in dot directories (probably VCS stuff)
        next if $path =~ m!(?:^|/)\.[^/]+/!;

        push @files_array, $path;

        # distribution may have several Makefile.PLs, thus
        # several 'lib' or 't' directories to care
        if ($path =~ m!/Makefile\.PL$! && $path !~ m!(^|/)x?t/!) {
            (my $dir = $path) =~ s|/[^/]+$||;
            push @base_dirs, $dir;
        }
    }

    $me->d->{size_unpacked}=$size;
    $me->d->{latest_mtime}=$latest_mtime;

    my @symlinks = sort {$a cmp $b} (
        grep({ $files{$_}{symlink} } keys %files),
        grep({ $dirs{$_}{symlink} } keys %dirs)
    );

    if (@symlinks) {
        $me->d->{error}{symlinks} = join ',', @symlinks;
    }

    $me->d->{base_dirs} = \@base_dirs if @base_dirs;
    my $base_dirs_re = join '|', '', map {quotemeta "$_/"} @base_dirs;

    # find special files/dirs
    my @special_files=(qw(Makefile.PL Build.PL META.yml META.json MYMETA.yml MYMETA.json dist.ini cpanfile SIGNATURE MANIFEST test.pl LICENSE LICENCE));
    my @special_dirs=(qw(lib t xt));

    my %special_files_re=(
        file_changelog=>qr{^(?:$base_dirs_re)(?:chang|history)}i,
        file_readme=>qr{^(?:$base_dirs_re)readme(?:\.(?:txt|md|pod))?}i,
    );

    for my $base_dir ('', @base_dirs) {
        $base_dir = "$base_dir/" if $base_dir;
        for my $name (@special_files) {
            my $file = "$base_dir$name";
            if (exists $files{$file}) {
                (my $key = "file_".lc $name) =~ s/\./_/;
                $me->d->{$key} = $me->d->{$key} ? "$me->d->{$key},$file" : $file;
            }
        }
        for my $name (@special_dirs) {
            my $dir = "$base_dir$name";
            if (exists $dirs{$dir}) {
                my $key = "dir_$name";
                $me->d->{$key} = $me->d->{$key} ? "$me->d->{$key},$dir" : $dir;
            }
        }
    }

    for my $file (keys %files) {
        next unless $file =~ m!^(?:$base_dirs_re)[^/]+$!;
        while(my ($key, $re) = each %special_files_re) {
            if ($file =~ /$re/) {
                $me->d->{$key} = $me->d->{$key} ? $me->d->{$key}.",$file" : $file;
             }
         }
    }

    # store stuff
    $me->d->{files}=scalar @files_array;
    $me->d->{files_array}=\@files_array;
    $me->d->{files_hash}=\%files;
    $me->d->{dirs}=scalar @dirs_array;
    $me->d->{dirs_array}=\@dirs_array;

    my @ignored = grep {$files{$_}{no_index}} sort keys %files;
    $me->d->{ignored_files_array}=\@ignored if @ignored;

    # check STDIN in Makefile.PL and Build.PL 
    # objective: convince people to use prompt();
    # http://www.perlfoundation.org/perl5/index.cgi?cpan_packaging
    for my $type (qw/makefile_pl build_pl/) {
        for my $path (split ',', $me->d->{"file_$type"} || '') {
            next unless $path;
            my $file = catfile($me->distdir,$path);
            next if not -e $file;
            open my $fh, '<', $file or next;
            my $content = do { local $/; <$fh> } or next;
            $me->d->{"stdin_in_$type"} = 1 if $content =~ /<STDIN>/;
        }
    }

    return;
}

sub _make_no_index_regex {
    my ($class, $me) = @_;

    my $meta = $me->d->{meta_yml};
    return unless $meta && ref $meta eq ref {};

    my $no_index = $meta->{no_index} || $meta->{private};
    return unless $no_index && ref $no_index eq ref {};

    my %map = (
        file => '\z',
        directory => '/',
    );
    my @ignore;
    for my $type (qw/file directory/) {
        next unless $no_index->{$type};
        my $rest = $map{$type};
        my @entries = ref $no_index->{$type} eq ref []
            ? @{ $no_index->{$type} }
            : ( $no_index->{$type} );
        push @ignore, map {"^$_$rest"} @entries;
    }
    return unless @ignore;

    $me->d->{no_index} = join ';', sort @ignore;
    return '(?:' . (join '|', @ignore) . ')';
}

##################################################################
# Kwalitee Indicators
##################################################################

sub kwalitee_indicators {
  return [
    {
        name=>'has_readme',
        error=>q{The file "README" is missing from this distribution. The README provides some basic information to users prior to downloading and unpacking the distribution.},
        remedy=>q{Add a README to the distribution. It should contain a quick description of your module and how to install it.},
        code=>sub { shift->{file_readme} ? 1 : 0 },
        details=>sub {
            my $d = shift;
            return "README was not found.";
        },
    },
    {
        name=>'has_manifest',
        error=>q{The file "MANIFEST" is missing from this distribution. The MANIFEST lists all files included in the distribution.},
        remedy=>q{Add a MANIFEST to the distribution. Your buildtool should be able to autogenerate it (eg "make manifest" or "./Build manifest")},
        code=>sub { shift->{file_manifest} ? 1 : 0 },
        details=>sub {
            my $d = shift;
            return "MANIFEST was not found.";
        },
    },
    {
        name=>'has_meta_yml',
        error=>q{The file "META.yml" is missing from this distribution. META.yml is needed by people maintaining module collections (like CPAN), for people writing installation tools, or just people who want to know some stuff about a distribution before downloading it.},
        remedy=>q{Add a META.yml to the distribution. Your buildtool should be able to autogenerate it.},
        code=>sub {
            my $d = shift;
            return 1 if $d->{file_meta_yml};
            return 1 if $d->{is_local_distribution} && $d->{file_mymeta_yml};
            return 0;
        },
        details=>sub {
            my $d = shift;
            return "META.yml was not found.";
        },
    },
    {
        name=>'has_buildtool',
        error=>q{Makefile.PL and/or Build.PL are missing. This makes installing this distribution hard for humans and impossible for automated tools like CPAN/CPANPLUS/cpanminus.},
        remedy=>q{Add a Makefile.PL (for ExtUtils::MakeMaker/Module::Install) or a Build.PL (for Module::Build and its friends), or use a distribution builder such as Dist::Zilla, Dist::Milla, Minilla.},
        code=>sub {
            my $d=shift;
            return 1 if $d->{file_makefile_pl} || $d->{file_build_pl};
            return 0;
        },
        details=>sub {
            my $d = shift;
            return "Neither Makefile.PL nor Build.PL was found.";
        },
    },
    {
        name=>'has_changelog',
        error=>q{The distribution hasn't got a Changelog (named something like m/^chang(es?|log)|history$/i. A Changelog helps people decide if they want to upgrade to a new version.},
        remedy=>q{Add a Changelog (best named 'Changes') to the distribution. It should list at least major changes implemented in newer versions.},
        code=>sub { shift->{file_changelog} ? 1 : 0 },
        details=>sub {
            my $d = shift;
            return "Any Changelog file was not found.";
        },
    },
    {
        name=>'no_symlinks',
        error=>q{This distribution includes symbolic links (symlinks). This is bad, because there are operating systems that do not handle symlinks.},
        remedy=>q{Remove the symlinks from the distribution.},
        code=>sub {shift->{error}{symlinks} ? 0 : 1},
        details=>sub {
            my $d = shift;
            return "The following symlinks were found: ".$d->{error}{symlinks};
        },
    },
    {
        name=>'has_tests',
        error=>q{This distribution doesn't contain either a file called 'test.pl' or a directory called 't'. This indicates that it doesn't contain even the most basic test-suite. This is really BAD!},
        remedy=>q{Add tests!},
        code=>sub {
            my $d=shift;
            # TODO: make sure if .t files do exist in t/ directory.
            return 1 if $d->{file_test_pl} || $d->{dir_t};
            return 0;
        },
        details=>sub {
            my $d = shift;
            return q{Neither "test.pl" nor "t/" directory was not found.};
        },
    },
    {
        name=>'has_tests_in_t_dir',
        is_extra=>1,
        error=>q{This distribution contains either a file called 'test.pl' (the old test file) or is missing a directory called 't'. This indicates that it uses the old test mechanism or it has no test-suite.},
        remedy=>q{Add tests or move tests.pl to the t/ directory!},
        code=>sub {
            my $d=shift;
            # TODO: make sure if .t files do exist in t/ directory.
            return 1 if !$d->{file_test_pl} && $d->{dir_t};
            return 0;
        },
        details=>sub {
            my $d = shift;
            return q{"test.pl" was found.} if $d->{file_test_pl};
            return q{"t/" directory was not found.};
        },
    },
    {
        name=>'no_stdin_for_prompting',
        error=>q{This distribution is using direct call from STDIN instead of prompt(). Make sure STDIN is not used in Makefile.PL or Build.PL. See http://www.perlfoundation.org/perl5/index.cgi?cpan_packaging},
        is_extra=>1,
        remedy=>q{Use the prompt() method from ExtUtils::MakeMaker/Module::Build.},
        code=>sub {
            my $d=shift;
            if ($d->{stdin_in_makefile_pl}||$d->{stdin_in_build_pl}) {
                return 0;
            }
            return 1;
        },
        details=>sub {
            my $d = shift;
            return "<STDIN> was found in Makefile.PL" if $d->{stdin_in_makefile_pl};
            return "<STDIN> was found in Build.PL" if $d->{stdin_in_build_pl};
        },
    },
];
}


q{Favourite record of the moment:
  Fat Freddys Drop: Based on a true story};


__END__

=encoding UTF-8

=head1 NAME

Module::CPANTS::Kwalitee::Files - Check for various files

=head1 SYNOPSIS

Find various files and directories that should be part of every self-respecting distribution.

=head1 DESCRIPTION

=head2 Methods

=head3 order

Defines the order in which Kwalitee tests should be run.

Returns C<15>, as data generated by C<MCK::Files> is used by all other tests.

=head3 analyse

C<MCK::Files> uses C<File::Find::Object> to get a list of all files and dirs in a dist. It checks if certain crucial files are there, and does some other file-specific stuff.

=head3 kwalitee_indicators

Returns the Kwalitee Indicators datastructure.

=over

=item * has_readme

=item * has_manifest

=item * has_meta_yml

=item * has_buildtool

=item * has_changelog 

=item * no_symlinks

=item * has_tests

=item * has_tests_in_t_dir

=item * no_stdin_for_prompting

=back

=head1 SEE ALSO

L<Module::CPANTS::Analyse>

=head1 AUTHOR

L<Thomas Klausner|https://metacpan.org/author/domm>

=head1 COPYRIGHT AND LICENSE

Copyright © 2003–2006, 2009 L<Thomas Klausner|https://metacpan.org/author/domm>

You may use and distribute this module according to the same terms
that Perl is distributed under.
