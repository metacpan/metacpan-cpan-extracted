#! perl

use Modern::Perl '2012';
use strict;
use warnings FATAL => 'all';
use autodie;
use version; our $VERSION = qv('v0.0.5');

use Carp;
use File::Next;
use File::Spec;
use File::stat;
use FindBin::Real qw(Bin Script);
use Getopt::Euclid;
use Storable;

my $print_info = $ARGV{-v};
my $input      = $ARGV{-i};
my $cache      = File::Spec->catfile( Bin(), '_mtimes' );

if ($print_info) {
    say "Looking for Perl sources in $input"
      or croak 'Failed to write to standard output';
    say "perltidy options: $ARGV{-P}"
      or croak 'Failed to write to standard output';
}

my $next_file = File::Next::files(
    {
        descend_filter => sub { $_ ne '.git' && $_ ne 'blib' },
        file_filter =>
          sub { $_ !~ /tidyall.pl/sxm && $_ =~ /[.](?:pl|pm|t)$/mixs }
    },
    $input
);

my %mtimes = -e $cache ? %{ retrieve($cache) } : ();

while ( defined( my $file = $next_file->() ) ) {
    my $mtime = stat($file)->mtime;
    if ( $mtime ~~ $mtimes{$file} ) {
        next;
    }

    my $perltidy = "perltidy $ARGV{-P} $file";
    if ($print_info) {
        say $perltidy or croak 'Failed to write to standard output';
    }

    system $perltidy;
    $mtimes{$file} = stat($file)->mtime;
    store \%mtimes, $cache;
}

exit 0;

__END__

=head1 NAME

tidyall - Recursively find all Perl sources and run perltidy on them all

=head1 VERSION

This documentation refers to tidyall version v0.0.5

=head1 USAGE

   tidyall -in .\directory [options]

=head1 DESCRIPTION

'tidyall' looks for perl sources in the input directory and its children and 
runs the perltidy pretty printer on each source file it finds.  The first time
tidyall executes, it will store the modification times of the source files and
on the next run, only modified files will be tidied.  By default tidyall 
searches the current directory if no directory is speicfied, and uses perltidy's
'-b' option to modify the source files in place (and create a backup).

=head1 REQUIRED ARGUMENTS

None.

=head1 OPTIONS

=over

=item -i[n] [=] <directory>

Specify input directory

=for Euclid
		directory.type: readable
		directory.default: '.'

=item -P [=] <opts>

=for Euclid
		opts.default: '-b'

perltidy options

=item -v

=item --verbose

Print all warnings

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 DIAGNOSTICS

None at this time.

=head1 EXIT STATUS

Zero on success.  No others defined at this time.

=head1 CONFIGURATION

None.

=head1 DEPENDENCIES

=over

    autodie
    Carp
    File::Next
    File::Spec
    File::stat
    FindBin::Real
    Getopt::Euclid
    Modern::Perl 2012
    Storable

=back

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Jim Counts - @jamesrcounts

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 Jim Counts

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

