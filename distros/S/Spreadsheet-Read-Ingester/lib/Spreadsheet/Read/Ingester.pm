package Spreadsheet::Read::Ingester ;
$Spreadsheet::Read::Ingester::VERSION = '0.002';
use strict;
use warnings;

use Storable;
use File::Spec;
use File::Signature;
use File::UserConfig;
use Spreadsheet::Read;

### Public methods ###

sub new {
  my $s    = shift;
  my $file = shift;
  my @args = @_;

  my $sig = '';
  eval { $sig  = File::Signature->new($file)->{digest} };

  my $configdir = File::UserConfig->new(dist => 'Spreadsheet-Read-Ingester')->configdir;
  my $parsed_file = File::Spec->catfile($configdir, $sig);

  my $data;

  # try to retrieve parsed data
  eval { $data = retrieve $parsed_file };

  # otherwise reingest from raw file
  if (!$data) {
    my $data = Spreadsheet::Read->new($file, @_);
    my $error = $data->[0]{error};
    die "Unable to read data from file: $file. Error: $error" if $data->[0]{error};
    store $data, $parsed_file;
  }

  return $data;
}

sub cleanup {
  my $s = shift;
  my $age = shift // 30;

  my $configdir = File::UserConfig->new(dist => 'Spreadsheet-Read-Ingester')->configdir;

  opendir (DIR, $configdir) or die 'Could not open directory.';
  my @files = readdir (DIR);
  closedir (DIR);
  foreach my $file (@files) {
    $file = File::Spec->catfile($configdir, $file);
    unlink $file if -M $file >= $age;
  }
}

1; # Magic true value
# ABSTRACT: ingest spreadsheets to Perl data structure for faster, repeated processing

__END__

=pod

=head1 NAME

Spreadsheet::Read::Ingester - ingest spreadsheets to Perl data structure for faster, repeated processing

=head1 SYNOPSIS

  use Spreadsheet::Read::Ingester;

  # ingest raw file, store parsed data file, and return data object
  my $data = Spreadsheet::Read::Ingester->new('/path/to/file');

  # the returned data object has all the methods of a L<Spreadsheet::Read> object
  my $num_cols = $data->sheet(1)->maxcol;

  # delete old data files older than 30 days to save disk space
  Spreadsheet::Read::Ingester->cleanup;

=head1 DESCRIPTION

This module is a simple wrapper for L<Spreadsheet::Read> to make repeated
ingestion of raw data files faster.

Processing spreadsheet and csv from raw data files can be time consuming,
especially with large data sets. Sometimes it's necessary to ingest the raw data
file repeatedly. This module saves time be ingesting and parsing the data once
using L<Spreadsheet::Read> and then immediately saves the parsed data to
to the user's home directory with L<Storable>. Files are stored in the directory
determined by L<File::UserConfig>.

Subsequent ingestions of the original data file L<Spreadsheet::Read::Ingester>
are retrieved from the stored Perl data structure instead of the raw file.

L<Spreadsheet::Read::Ingester> generates a unique file signature for the file so
that if the original file changed, the data will be reingested from the raw file
instead and a new parsed file with a new signature will be saved.

To access the data from the stored files and newly ingested files using the
L<Spreadsheet::Read::Ingester> object, consult the L<Spreadsheet::Read>
documentation for the methods it provides.

=head1 METHODS

=head2 new( $path_to_file )

  my $data = Spreadsheet::Read::Ingester->new('/path/to/file');

Takes same arguments as the new constructor in L<Spreadsheet::Read> module.
Returns an object identical to the object returned by the L<Spreadsheet::Read>
module along with its corresponding methods.

=head2 cleanup($days)
=method cleanup()

  Spreadsheet::Read::Ingester->cleanup(0);

Deletes all stored files from the user's application data directory. Takes an
optional argument indicating the minimum number of days old the file must be
before it is deleted. Defaults to 30 days. Passing a value of 0 deletes all
files.

=head1 REQUIRES

=over 4

=item * L<File::Signature|File::Signature>

=item * L<File::Spec|File::Spec>

=item * L<File::UserConfig|File::UserConfig>

=item * L<Spreadsheet::Read|Spreadsheet::Read>

=item * L<Storable|Storable>

=item * L<strict|strict>

=item * L<warnings|warnings>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Spreadsheet::Read::Ingester

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Spreadsheet-Read-Ingester>

=back

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/sdondley/Spreadsheet-Read-Ingester>

  git clone git://github.com/sdondley/Spreadsheet-Read-Ingester.git

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/sdondley/Spreadsheet-Read-Ingester/issues>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 SEE ALSO

L<Spreadsheet::Read>

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
