#!perl

use strict;
use warnings;

use autodie;
use version;

use Archive::Extract;
use Cwd;
use File::Fetch;
use File::Spec;
use File::Temp 0.19;
use Getopt::Std;
use List::Util;
use Parse::CPAN::Meta;

use File::HomeDir;
use Parse::CPAN::Packages::Fast;

my $target_dist = 'Devel-Cover';
my $first_year  = 2012;
my $cpan_mirror = 'http://www.cpan.org';
my %prereq_skip = (
 'run' => {
  'Perl::Tidy'        => 1,
  'Test::Differences' => 1,
 },
);
my %prereq_desc = (
 'PPI::HTML' => 'Devel::Cover lets you optionally pick between L<PPI::HTML> and L<Perl::Tidy>, but it will only use the former if both are installed.',
);

my %opts;
getopts 'n' => \%opts;

sub get_latest_dist {
 my $dist = shift;

 my $home = File::HomeDir->my_home;
 my $pkgs = File::Spec->catfile($home, qw<.cpanplus 02packages.details.txt.gz>);
 my $pcp  = Parse::CPAN::Packages::Fast->new($pkgs);

 my $d = $pcp->latest_distribution($dist);
 die "Could not find distribution '$dist' on the CPAN" unless $d;

 return $d;
}

sub get_dist_meta {
 my $d = shift;

 $cpan_mirror =~s{/+$}{}g;
 my $cpanid   = $d->cpanid;
 my ($cp, $c) = $cpanid =~ /^((.).)/;
 my $uri      = join '/', $cpan_mirror, 'authors', 'id', $c, $cp, $cpanid,
                          $d->filename;

 my $tmp_dir     = File::Temp->newdir;
 # Force symlinks resolution
 my $tmp_dirname = Cwd::abs_path($tmp_dir->dirname);

 my $ff      = File::Fetch->new(uri => $uri);
 my $archive = $ff->fetch(to => $tmp_dirname);
 die $ff->error unless $archive;

 my $ae = Archive::Extract->new(archive => $archive);
 $ae->extract(to => $tmp_dirname) or die $ae->error;

 my $files = {
  map { File::Spec->catfile($tmp_dirname, $_) => 1 }
   @{$ae->files}
 };
 my $abs_extract_path = Cwd::abs_path($ae->extract_path);
 my @meta_candidates  = map File::Spec->catfile($abs_extract_path, $_),
                         qw<META.json META.yml>;
 my $meta_file;
 for my $file (@meta_candidates) {
  if ($files->{$file}) {
   $meta_file = $file;
   last;
  }
 }
 die 'No META file for ' . $d->distvname . "\n" unless $meta_file;

 return Parse::CPAN::Meta->load_file($meta_file);
}

my $latest_target  = get_latest_dist($target_dist);
my $target_version = $latest_target->version;
my $meta           = get_dist_meta($latest_target);

my %eumm_phases = (
 configure => [ qw<configure>  ],
 build     => [ qw<build test> ],
 run       => [ qw<runtime>    ],
);
my %meta_phase_relationships = (
 configure => [ qw<requires>                     ],
 build     => [ qw<requires>                     ],
 test      => [ qw<requires>                     ],
 runtime   => [ qw<requires recommends suggests> ],
);

my %prereqs = (
 configure => {
  'ExtUtils::MakeMaker' => '0',
 },
 build => {
  'ExtUtils::MakeMaker' => '0',
  'Test::More'          => '0',
 },
 perl => '5',
);

for my $eumm_phase (keys %eumm_phases) {
 my $prereqs = $prereqs{$eumm_phase} ||= { };
 my $skip    = $prereq_skip{$eumm_phase};

 for my $meta_phase (@{$eumm_phases{$eumm_phase}}) {

  for my $type (@{$meta_phase_relationships{$meta_phase}}) {
   my $phase_prereqs = $meta->{prereqs}{$meta_phase}{$type};
   next unless $phase_prereqs;

   while (my ($module, $version) = each %$phase_prereqs) {
    next if $skip->{$module};

    if ($module eq 'perl') {
     if (not $prereqs{perl} or $prereqs{perl} < $version) {
      $prereqs{perl} = $version;
     }
    } elsif (not exists $prereqs->{$module} or
             version->parse($prereqs->{$module}) < version->parse($version)) {
     $prereqs->{$module} = $version;
    }
   }
  }
 }
}

(my $target_pkg = $target_dist) =~ s/-/::/g;
my $task_pkg    = "Task::${target_pkg}::Recommended";
(my $task_file  = "lib/$task_pkg.pm") =~ s{::}{/}g;
my $years       = join ',', $first_year .. ((gmtime)[5] + 1900);

my $old_task_version = '0.0.0';
if (-e $task_file) {
 open my $old_fh, '<', $task_file;
 while (<$old_fh>) {
  if (/our\s*\$VERSION\s*=\s*(.*);/) {
   $old_task_version = $1;
   $old_task_version =~ s/^(['"])(.*)\1$/$2/;
  }
 }
 close $old_fh;
}

my $new_task_version;

if ($opts{n}) {
 $new_task_version = $old_task_version;
} else {
 my ($old_target_version, $old_task_revision)
                                       = $old_task_version =~ /(.*)\.([0-9]+)$/;
 my $new_task_revision;
 if (version->parse($target_version) > version->parse($old_target_version)) {
  $new_task_revision = 0;
 } else {
  $new_task_revision = $old_task_revision + 1;
 }
 $new_task_version = version->parse($target_version)->normal;
 if (($target_version =~ tr/.//) < 2) {
  my @components     = split /\./, $new_task_version;
  $components[2]     = $new_task_revision;
  $new_task_version  = join '.', @components;
 } else {
  $new_task_version .= ".$new_task_revision";
 }
}

(my $bug_queue = $task_pkg) =~ s/::/-/g;
my $bug_email  = "bug-\L$bug_queue\E at rt.cpan.org";
$bug_queue     = "http://rt.cpan.org/NoAuth/ReportBug.html?Queue=$bug_queue";

sub deplist_to_pod {
 my @deplist = @_;
 return 'None.' unless @deplist;

 my $pod = "=over 4\n\n";
 while (@deplist) {
  my ($module, $version) = splice @deplist, 0, 2;
  my $X = $module eq 'perl' ? 'C' : 'L';
  $pod .= "=item *\n\n$X<$module>";
  $pod .= " $version" if $version;
  $pod .= "\n\n";
  if (my $desc = $prereq_desc{$module}) {
   1 while chomp $desc;
   $pod .= "$desc\n\n";
  }
 }
 $pod .= '=back';

 return $pod;
}

sub deplist_to_perl {
 my @deplist = @_;
 return '{ }' unless @deplist;

 my $len = List::Util::max(
  map length, @deplist[grep not($_ % 2), 0 .. $#deplist]
 );

 my $perl = "{\n";
 while (@deplist) {
  my ($module, $version) = splice @deplist, 0, 2;
  my $pad = $len + 1 - length $module;
  $perl  .= sprintf " '%s'%*s=> '%s',\n", $module, $pad, ' ', $version;
 }
 $perl .= '}';

 return $perl;
}

sub sorthr ($) {
 my $hr = shift;
 map { $_ => $hr->{$_} } sort keys %$hr;
}

# Make sure no package FOO statement appears in this file.
my $package_statement = join ' ', 'package',
                                   $task_pkg;

my %vars = (
 TARGET_PKG             => $target_pkg,
 TARGET_VERSION         => $target_version,
 TASK_PKG               => $task_pkg,
 PACKAGE_TASK_PKG       => $package_statement,
 TASK_VERSION           => $new_task_version,
 PERL_PREREQ            => $prereqs{perl},
 CONFIGURE_PREREQS_POD  => deplist_to_pod(sorthr $prereqs{configure}),
 BUILD_PREREQS_POD      => deplist_to_pod(sorthr $prereqs{build}),
 RUN_PREREQS_POD        => deplist_to_pod(
  $target_pkg => $target_version,
  'perl'      => $prereqs{perl},
  sorthr $prereqs{run}
 ),
 CONFIGURE_PREREQS_PERL => deplist_to_perl(sorthr $prereqs{configure}),
 BUILD_PREREQS_PERL     => deplist_to_perl(sorthr $prereqs{build}),
 RUN_PREREQS_PERL       => deplist_to_perl(
  sorthr $prereqs{run},
  $target_pkg => $target_version,
 ),
 TESTED_PREREQS         => deplist_to_perl(sorthr $prereqs{run}),
 BUG_EMAIL              => $bug_email,
 BUG_QUEUE              => $bug_queue,
 YEARS                  => $years,
);

my %templates = (
 $task_file => <<'TEMPLATE',
__PACKAGE_TASK_PKG__;

use strict;
use warnings;

\=head1 NAME

__TASK_PKG__ - Install __TARGET_PKG__ and its recommended dependencies.

\=head1 VERSION

Version __TASK_VERSION__

\=cut

our $VERSION = '__TASK_VERSION__';

\=head1 SYNOPSIS

    $ cpan __TASK_PKG__
    $ cpanp -i __TASK_PKG__
    $ cpanm __TASK_PKG__

\=head1 DESCRIPTION

This task module lets you easily install L<__TARGET_PKG__> __TARGET_VERSION__ and all its recommended dependencies.

\=head1 DEPENDENCIES

\=head2 Configure-time dependencies

__CONFIGURE_PREREQS_POD__

\=head2 Build-time and test-time dependencies

__BUILD_PREREQS_POD__

\=head2 Run-time dependencies

__RUN_PREREQS_POD__

\=head1 CAVEATS

Note that run-time dependencies that are only recommended by __TARGET_PKG__ may not yet be installed at the time __TARGET_PKG__ is tested, as there is no explicit dependency link between them and in that case most CPAN clients default to install prerequisites in alphabetic order.
However, they will be installed when __TASK_PKG__ is, thus will be available when you actually use __TARGET_PKG__.

\=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

\=head1 BUGS

Please report any bugs or feature requests to C<__BUG_EMAIL__>, or through the web interface at L<__BUG_QUEUE__>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

\=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc __TASK_PKG__

\=head1 COPYRIGHT & LICENSE

Copyright __YEARS__ Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

\=cut

1; # End of __TASK_PKG__
TEMPLATE
 # ----------------------------------------------------------------------------
 'Makefile.PL' => <<'TEMPLATE',
use __PERL_PREREQ__;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = 'Task-Devel-Cover-Recommended';

(my $name = $dist) =~ s{-}{::}g;

(my $file = $dist) =~ s{-}{/}g;
$file = "lib/$file.pm";

my $CONFIGURE_PREREQS = __CONFIGURE_PREREQS_PERL__;

my $BUILD_PREREQS = __BUILD_PREREQS_PERL__;

my $RUN_PREREQS = __RUN_PREREQS_PERL__;

my %META = (
 configure_requires => $CONFIGURE_PREREQS,
 build_requires     => $BUILD_PREREQS,
 dynamic_config     => 0,
 resources          => {
  bugtracker => "http://rt.cpan.org/Dist/Display.html?Name=$dist",
  homepage   => "http://search.cpan.org/dist/$dist/",
  license    => 'http://dev.perl.org/licenses/',
  repository => "http://git.profvince.com/?p=perl%2Fmodules%2F$dist.git",
 },
);

WriteMakefile(
 NAME             => $name,
 AUTHOR           => 'Vincent Pit <perl@profvince.com>',
 LICENSE          => 'perl',
 VERSION_FROM     => $file,
 ABSTRACT_FROM    => $file,
 PL_FILES         => {},
 BUILD_REQUIRES   => $BUILD_PREREQS,
 PREREQ_PM        => $RUN_PREREQS,
 MIN_PERL_VERSION => '__PERL_PREREQ__',
 META_MERGE       => \%META,
 dist             => {
  PREOP    => "pod2text -u $file > \$(DISTVNAME)/README",
  COMPRESS => 'gzip -9f', SUFFIX => 'gz'
 },
 clean            => {
  FILES => "$dist-* *.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt*"
 }
);
TEMPLATE
 # ----------------------------------------------------------------------------
 't/01-deps.t' => <<'TEMPLATE',
#!perl

use strict;
use warnings;

use Test::More;

my $TESTED_PREREQS = __TESTED_PREREQS__;

plan tests => keys(%$TESTED_PREREQS) + 1;

my @tests = map [ $_ => $TESTED_PREREQS->{$_} ], keys %$TESTED_PREREQS;
push @tests, [ '__TARGET_PKG__' => '__TARGET_VERSION__' ];

for my $test (@tests) {
 my ($module, $version) = @$test;
 local $@;
 if ($version && $version !~ /^[0._]*$/) {
  eval "use $module $version ()";
  is $@, '', "$module v$version is available";
 } else {
  eval "use $module ()";
  is $@, '', "any version of $module is available";
 }
}
TEMPLATE
);

$templates{$task_file} =~ s/^\\=/=/mg;

my $valid_keys = join '|', keys %vars;
$valid_keys    = qr/$valid_keys/;

for my $file (sort keys %templates) {
 my $template = $templates{$file};
 $template =~ s/\b__($valid_keys)__\b/$vars{$1}/go;

 open my $fh, '>', $file;
 print $fh $template;
 close $fh;
}
