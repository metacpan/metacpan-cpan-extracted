#!perl
package Shell::Tools;
use warnings;
use strict;

our $VERSION = '0.04';

=head1 Name

Shell::Tools - Perl extension to reduce boilerplate in Perl shell scripts

=head1 Synopsis

 use Shell::Tools;    # is the same as the following:
 
 use warnings;
 use strict;
 use IO::File ();
 use IO::Handle ();
 use Carp qw/carp croak confess/;
 use Pod::Usage 'pod2usage';
 use Getopt::Std 1.04 'getopts';
 sub main::HELP_MESSAGE { ... }            # calls pod2usage()
 sub main::VERSION_MESSAGE { ... }         # see documentation below
 $Getopt::Std::STANDARD_HELP_VERSION = 1;  # exit after --help or --version
 use Cwd qw/getcwd cwd abs_path/;
 use File::Spec::Functions qw/canonpath catdir catfile curdir rootdir updir
     no_upwards file_name_is_absolute splitdir abs2rel rel2abs/;
 use File::Basename qw/fileparse basename dirname/;
 use File::Temp qw/tempfile tempdir/;
 use File::Copy qw/move copy/;
 use File::Path 2.08 qw/make_path remove_tree/;
 use File::Find 'find';
 use Fcntl qw/LOCK_SH LOCK_EX LOCK_UN LOCK_NB SEEK_SET SEEK_CUR SEEK_END/;
 use FindBin ();
 use Data::Dumper 'Dumper';
 use Scalar::Util 'looks_like_number';
 use List::Util qw/first reduce/;

=head1 Description

This module exports a collection of functions from several core Perl modules
which can often be very useful when writing Perl shell scripts.

B<See also> L<Shell::Tools::Extra|Shell::Tools::Extra>, which exports
additional CPAN modules' functions and classes.

=head2 Warning

This module is intended to help write short, simple shell scripts.
Because of its many exports it is not recommended for large applications,
CGI scripts, object-oriented applications and the like.

=head1 Version

This document describes version 0.04 of Shell::Tools.

=head1 Exports

This module exports the following modules and functions.

Each module has an L<Exporter|Exporter> tag that is the same name as the module.
This is useful if you want to exclude some modules' functions from being exported,
for example C<< use Shell::Tools qw/ !:File::Copy /; >>.

=head2 L<warnings|warnings> and L<strict|strict>

These are enabled in the calling script.
(No Exporter tag.)

=cut

## no critic (ProhibitConstantPragma)

use base 'Exporter';
our @EXPORT = ();  ## no critic (ProhibitAutomaticExportation)
our %EXPORT_TAGS = ();

sub import {  ## no critic (RequireArgUnpacking)
	warnings->import;
	strict->import;
	__PACKAGE__->export_to_level(1, @_);
	return;
}


=head2 L<IO::File|IO::File> and L<IO::Handle|IO::Handle>

These modules are loaded, nothing is exported.
(No Exporter tag.)

Perl before v5.14 did not load these automatically.
Loading these modules allows you to do things like:

 open my $fh, ">", $file or die $!;
 $fh->autoflush(1);
 $fh->print("Hello");
 # Note: calling binmode this way may not work on older Perls
 $fh->binmode(":raw");

=cut

use IO::File ();    # core since Perl 5.00307
use IO::Handle ();  # core since Perl 5.00307


=head2 L<Carp|Carp>

L<Carp|Carp>'s C<carp>, C<croak> and C<confess>.

=cut

use constant _EXP_CARP => qw/carp croak confess/;
use Carp _EXP_CARP;  # core since Perl 5
push @EXPORT, _EXP_CARP;
$EXPORT_TAGS{"Carp"} = [_EXP_CARP];


=head2 L<Getopt::Std|Getopt::Std> and L<Pod::Usage|Pod::Usage>

 =head1 SYNOPSIS
 
  foo.pl [OPTIONS] FILENAME
  OPTIONS:
  -f       - foo
  -b BAR   - bar
 
 =cut
 
 getopts('fb:', \my %opts) or pod2usage;
 pod2usage("must specify a filename") unless @ARGV==1;

This module provides the functions C<main::HELP_MESSAGE> and C<main::VERSION_MESSAGE>.
C<HELP_MESSAGE> simply calls L<pod2usage|Pod::Usage>.
C<VERSION_MESSAGE> first checks for C<$main::VERSION_STRING> and prints that if available,
otherwise it will use C<$main::VERSION> to construct a message,
and if neither is available, it will use the "last modified" time of the script.
Also, C<$Getopt::Std::STANDARD_HELP_VERSION> is set, so the C<getopts> call
will exit the script if it sees C<--help> or C<--version>.

We require L<Getopt::Std|Getopt::Std> 1.04 or greater for the
support of the C<--help> and C<--version> switches.

Note that L<Pod::Usage|Pod::Usage> before Version 1.36 only looked for
a POD section titled C<SYNOPSIS>; from 1.36 upwards it also looks for a
section titled C<USAGE> (note uppercase is always important).

=cut

use constant _EXP_GETOPT_STD => qw/getopts/;
use Getopt::Std 1.04 _EXP_GETOPT_STD;
# Getopt::Std is core since Perl 5
# Getopt::Std 1.04 is core since Perl v5.8.1
push @EXPORT, _EXP_GETOPT_STD;
$EXPORT_TAGS{"Getopt::Std"} = [_EXP_GETOPT_STD];

use constant _EXP_POD_USAGE => qw/pod2usage/;
use Pod::Usage _EXP_POD_USAGE;  # core since Perl v5.6.0
push @EXPORT, _EXP_POD_USAGE;
$EXPORT_TAGS{"Pod::Usage"} = [_EXP_POD_USAGE];

sub main::HELP_MESSAGE {
	pod2usage(-output=>shift);
	return;
}
sub main::VERSION_MESSAGE {
	my $fh = shift;
	if ($main::VERSION_STRING) { print {$fh} $main::VERSION_STRING, "\n" }
	elsif ($main::VERSION) { print {$fh} $FindBin::Script, ' Version ', $main::VERSION, "\n" }
	else { print {$fh} $FindBin::Script, ' (last modified ',
		scalar localtime((stat(catfile($FindBin::RealBin,$FindBin::RealScript)))[9]), ")\n" }
	return;
}
$Getopt::Std::STANDARD_HELP_VERSION = 1;


=head2 L<Cwd|Cwd>

 my $cwd = getcwd();  # POSIX getcwd(3)
 my $cwd = cwd();
 my $abs_path = abs_path($file);  # realpath(3)

=cut

use constant _EXP_CWD => qw/getcwd cwd abs_path/;
use Cwd _EXP_CWD;  # core since Perl 5
push @EXPORT, _EXP_CWD;
$EXPORT_TAGS{"Cwd"} = [_EXP_CWD];


=head2 L<File::Spec::Functions|File::Spec::Functions>

 my $path     = canonpath($path);
 my $path     = catdir(@dirs);
 my $path     = catfile(@dirs, $filename);
 my @paths    = no_upwards(@paths);
 my $is_abs   = file_name_is_absolute($path);
 my @dirs     = splitdir($directories);
 # note abs2rel() and rel2abs() use Cwd::cwd() if $base is omitted
 my $rel_path = abs2rel($path, $base);
 my $abs_path = rel2abs($path, $base);
 my $curdir   = curdir();   # e.g. "."
 my $rootdir  = rootdir();  # e.g. "/"
 my $updir    = updir();    # e.g. ".."

 # Hint - one way to list all entries in a directory:
 my @files = do { opendir my $dh, "." or die $!; no_upwards readdir $dh };

See L<File::Spec> for docs.

Note the additional L<Exporter|Exporter> tag C<File::Spec> is provided
as an alias for C<File::Spec::Functions>.

=cut

use constant _EXP_FILE_SPEC => qw/canonpath catdir catfile curdir rootdir
	updir no_upwards file_name_is_absolute splitdir abs2rel rel2abs/;
use File::Spec::Functions _EXP_FILE_SPEC;  # core since Perl 5.00504
push @EXPORT, _EXP_FILE_SPEC;
$EXPORT_TAGS{"File::Spec::Functions"} = [_EXP_FILE_SPEC];
$EXPORT_TAGS{"File::Spec"} = [_EXP_FILE_SPEC];


=head2 L<File::Basename|File::Basename>

 my $filename = fileparse($path, @suffixes);  # suffixes optional
 my ($filename, $dirs, $suffix) = fileparse($path, @suffixes);
 $path = $dirs . $filename . $suffix;

The functions C<basename> and C<dirname> are also provided for compatibility,
but L<File::Basename> says that C<fileparse> is preferred.

=cut

use constant _EXP_FILE_BASENAME => qw/fileparse basename dirname/;
use File::Basename _EXP_FILE_BASENAME;  # core since Perl 5
push @EXPORT, _EXP_FILE_BASENAME;
$EXPORT_TAGS{"File::Basename"} = [_EXP_FILE_BASENAME];


=head2 L<File::Temp|File::Temp>

 my $fh = tempfile();
 my ($fh,$fn) = tempfile(UNLINK=>1);
 my (undef,$fn) = tempfile(OPEN=>0);
 my $tmpdir = tempdir(CLEANUP=>1);

=cut

use constant _EXP_FILE_TEMP => qw/tempfile tempdir/;
use File::Temp _EXP_FILE_TEMP;  # core since Perl v5.6.1
push @EXPORT, _EXP_FILE_TEMP;
$EXPORT_TAGS{"File::Temp"} = [_EXP_FILE_TEMP];


=head2 L<File::Copy|File::Copy>

 copy("src","dst") or die "Copy failed: $!";
 move("src","dst") or die "Move failed: $!";

=cut

use constant _EXP_FILE_COPY => qw/move copy/;
use File::Copy _EXP_FILE_COPY;  # core since Perl 5.002
push @EXPORT, _EXP_FILE_COPY;
$EXPORT_TAGS{"File::Copy"} = [_EXP_FILE_COPY];


=head2 L<File::Path|File::Path>

 # will carp and croak
 make_path('foo/bar/baz', '/quz/blah');
 remove_tree('foo/bar/baz', '/quz/blah');

Note that we require L<File::Path|File::Path> 2.08 or greater
because its interface has undergone several changes and its documentation
strongly recommends using this version or newer.

=cut

use constant _EXP_FILE_PATH => qw/make_path remove_tree/;
use File::Path 2.08 _EXP_FILE_PATH;
# File::Path is core since Perl 5.001
# File::Path 2.08 is core since Perl v5.11.1
push @EXPORT, _EXP_FILE_PATH;
$EXPORT_TAGS{"File::Path"} = [_EXP_FILE_PATH];


=head2 L<File::Find|File::Find>

 find({ no_chdir=>1, wanted=>sub {
     return if -d;
     ...;
 } }, @DIRS);

=cut

use constant _EXP_FILE_FIND => qw/find/;
use File::Find _EXP_FILE_FIND;  # core since Perl 5
push @EXPORT, _EXP_FILE_FIND;
$EXPORT_TAGS{"File::Find"} = [_EXP_FILE_FIND];


=head2 L<Fcntl|Fcntl> (selected)

C<SEEK_*> (L<seek|perlfunc/seek>) and C<LOCK_*> (L<flock|perlfunc/flock>)

=cut

use constant _EXP_FCNTL => qw/LOCK_SH LOCK_EX LOCK_UN LOCK_NB SEEK_SET SEEK_CUR SEEK_END/;
use Fcntl _EXP_FCNTL;  # core since Perl 5
push @EXPORT, _EXP_FCNTL;
$EXPORT_TAGS{"Fcntl"} = [_EXP_FCNTL];


=head2 L<FindBin|FindBin>

Nothing is exported; use these variables:
C<$FindBin::Bin>, C<$FindBin::Script>, C<$FindBin::RealBin>, and C<$FindBin::RealScript>

=cut

use FindBin ();  # core since Perl 5.00307


=head2 L<Data::Dumper|Data::Dumper>

 print Dumper(\%ENV);

=cut

use constant _EXP_DATA_DUMPER => qw/Dumper/;
use Data::Dumper _EXP_DATA_DUMPER;  # core since Perl 5.005
push @EXPORT, _EXP_DATA_DUMPER;
$EXPORT_TAGS{"Data::Dumper"} = [_EXP_DATA_DUMPER];


=head2 L<Scalar::Util|Scalar::Util> (selected)

 my $nr = "123.45";
 print "$nr looks like a number" if looks_like_numer($nr);

=cut

use constant _EXP_SCALAR_UTIL => qw/looks_like_number/;
use Scalar::Util _EXP_SCALAR_UTIL;  # core since Perl v5.7.3
push @EXPORT, _EXP_SCALAR_UTIL;
$EXPORT_TAGS{"Scalar::Util"} = [_EXP_SCALAR_UTIL];


=head2 L<List::Util|List::Util> (selected)

 # first is more efficient than grep for boolean tests
 my $found = first { /3/ } 10..20;
 my $maxval = reduce { $a > $b ? $a : $b } 1..10;

=cut

use constant _EXP_LIST_UTIL => qw/first reduce/;
use List::Util _EXP_LIST_UTIL;  # core since Perl v5.7.3
push @EXPORT, _EXP_LIST_UTIL;
$EXPORT_TAGS{"List::Util"} = [_EXP_LIST_UTIL];


1;
__END__

=head1 See Also

=over

=item *

L<Shell::Tools::Extra|Shell::Tools::Extra> - extension of this module that
also exports several functions from several CPAN modules

=item *

L<Env|Env> - imports environment variables as scalars or arrays

 use Env qw(HOME USER @PATH);

=item *

L<File::stat|File::stat> - by-name interface to Perl's built-in stat() functions

 my $st = stat($filename) or die $!;
 print "$filename is executable\n" if $st->mode & 0111;
 print "$filename has links\n" if $st->nlink > 1;

Please see the "Bugs" section of L<File::stat> -
C<$_> and C<_> (currently) do not work with C<stat> and C<lstat>!

=item *

L<File::Slurp|File::Slurp>

Since slurping a file can be as simple as the following,
it's left up to the user to import this module if desired.

 my $slurp = do { open my $fh, '<', $filename or die $!; local $/; <$fh> };

=item *

Configuration file parsers:
L<Config::General|Config::General>,
L<Config::Perl|Config::Perl> (one of my modules),
L<Config::IniFiles|Config::IniFiles>,
L<Config::INI|Config::INI> (simpler INI files), and
L<Config::Tiny|Config::Tiny> (I<even> simpler INI files).
For XML, JSON, and YAML, there are many modules available,
some examples are:
L<YAML::XS|YAML::XS>,
L<XML::Simple|XML::Simple>,
and L<JSON|JSON>.

=back

=head1 Author, Copyright, and License

Copyright (c) 2014 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command "C<perldoc perlartistic>" or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

