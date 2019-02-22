package Spreadsheet::Read::Ingester ;
$Spreadsheet::Read::Ingester::VERSION = '0.010';
use strict;
use warnings;

use Storable;
use File::Spec;
use File::Signature;
use File::UserConfig;
use base qw (Spreadsheet::Read);

### Public methods ###

# Override constructor
sub new {
  my $s = shift;
  my $data = $s->_fetch_data(@_);
  return $data;
}

# wrap functions that require 'Spreadsheet::Read' objects
my @funcs = qw (parses rows row col2label cr2cell cell2cr cellrow);

foreach my $func (@funcs) {
  { no strict;
    *$func = sub {
      my $s = shift;
      bless $s, 'Spreadsheet::Read';
      my $super_func = "SUPER::$func";
      if (wantarray) {
        my @result = $s->$super_func(shift);
        bless $s, 'Spreadsheet::Read::Ingester';
        return @result;
      } else {
        my $result = $s->$super_func(shift);
        bless $s, 'Spreadsheet::Read::Ingester';
        return $result;
      }
    }
  }
}

# Override add function
sub add {
  my $book = shift;
  my $data = $book->_fetch_data(@_);
  $book && (ref $book eq "ARRAY" ||
            ref $book eq __PACKAGE__) && $book->[0]{sheets} or return $data;

  my $c1 = $book->[0];
  my $c2 = $data->[0];

  unless ($c1->{parsers}) {
      $c1->{parsers}[0]{$_} = $c1->{$_} for qw( type parser version );
      $book->[$_]{parser} = 0 for 1 .. $c1->{sheets};
      }
  my ($pidx) = (grep { my $p = $c1->{parsers}[$_];
      $p->{type}    eq $c2->{type}   &&
      $p->{parser}  eq $c2->{parser} &&
      $p->{version} eq $c2->{version} } 0 .. $#{$c1->{parsers}});
  unless (defined $pidx) {
      $pidx = scalar @{$c1->{parsers}};
      $c1->{parsers}[$pidx]{$_} = $c2->{$_} for qw( type parser version );
      }

  foreach my $sn (sort { $c2->{sheet}{$a} <=> $c2->{sheet}{$b} } keys %{$c2->{sheet}}) {
      my $s = $sn;
      my $v = 2;
      while (exists $c1->{sheet}{$s}) {
          $s = $sn."[".$v++."]";
          }
      $c1->{sheet}{$s} = $c1->{sheets} + $c2->{sheet}{$sn};
      $data->[$c2->{sheet}{$sn}]{parser} = $pidx;
      push @$book, $data->[$c2->{sheet}{$sn}];
      }
  $c1->{sheets} += $c2->{sheets};

  return $book;
}

# Fetch data from stored variable, if available
sub _fetch_data {
  my $s    = shift;
  my $file = shift;
  my @args = @_;

  my $sig = '';
  eval { $sig  = File::Signature->new($file)->{digest} };

  my %args = @args;
  my $suffix;
  foreach my $key (sort keys %args) {
    $suffix .= $key;
    $suffix .= $args{$key};
  }
  if ($suffix) {
    $sig .= "-$suffix";
  }
  my $configdir = File::UserConfig->new(dist => 'Spreadsheet-Read-Ingester')->configdir;
  my $parsed_file = File::Spec->catfile($configdir, $sig);

  my $data;

  # try to retrieve parsed data
  eval { $data = retrieve $parsed_file };

  # otherwise reingest from raw file
  if (!$data) {
    $data = $s->SUPER::new($file, @_);
    my $error = $data->[0]{error};
    die "Unable to read data from file: $file. Error: $error" if $data->[0]{error};
    store $data, $parsed_file;
  }

  return $data;
}

sub cleanup {
  my $s = shift;
  my $age = shift;

  if (!defined $age) {
    $age = 30;
  } elsif ($age eq '0') {
    $age = -1
  } elsif ($age !~ /^\d+$/) {
    warn 'cleanup method accepts only positive integer values or 0';
    return;
  }

  my $configdir = File::UserConfig->new(dist => 'Spreadsheet-Read-Ingester')->configdir;

  opendir (DIR, $configdir) or die 'Could not open directory.';
  my @files = readdir (DIR);
  closedir (DIR);
  foreach my $file (@files) {
    $file = File::Spec->catfile($configdir, $file);
    next if (-d $file);
    if (-M $file >= $age) {
      unlink $file or die 'Cannot remove file: $file';
    }
  }
}

1; # Magic true value
# ABSTRACT: ingest and save csv and spreadsheet data to a perl data structure to avoid reparsing

__END__

=pod

=head1 NAME

Spreadsheet::Read::Ingester - ingest and save csv and spreadsheet data to a perl data structure to avoid reparsing

=head1 SYNOPSIS

  use Spreadsheet::Read::Ingester;

  # ingest raw file, store parsed data file, and return data object
  my $data = Spreadsheet::Read::Ingester->new('/path/to/file');

  # the returned data object has all the methods of a L<Spreadsheet::Read> object
  my $num_cols = $data->sheet(1)->maxcol;

  # delete old data files older than 30 days to save disk space
  Spreadsheet::Read::Ingester->cleanup;

=head1 DESCRIPTION

This module is intended to be a drop-in replacement for L<Spreadsheet::Read> and
is a simple, unobtrusive wrapper for it.

Parsing spreadsheet and csv data files is time consuming, especially with large
data sets. If a data file is ingested more than once, much time and processing
power is wasted reparsing the same data. To avoid reparsing, this module uses
L<Storable> to save a parsed version of the data to disk when a new file is
ingested. All subsequent ingestions are retrieved from the stored Perl data
structure. Files are saved in the directory determined by L<File::UserConfig>
and is a function of the user's OS.

The stored data file names are the unique file signatures for the raw data file.
The signature is used to detect if the original file changed, in which case the
data is reingested from the raw file and a new parsed file is saved using an
updated file signature. Arguments passed to the constructor are appended to the
name of the file to ensure different parse options are accounted for. Parsed
data files are kept indefinitely but can be deleted with the C<cleanup()>
method.

Consult the L<Spreadsheet::Read> documentation for accessing the data object
returned by this module.

=head1 METHODS

=head2 new( $path_to_file )

  my $data = Spreadsheet::Read::Ingester->new('/path/to/file');

Takes same arguments as the new constructor in L<Spreadsheet::Read> module.
Returns an object identical to the object returned by the L<Spreadsheet::Read>
module along with its corresponding methods.

=head2 cleanup( $file_age_in_days )

=head2 cleanup()

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/sdondley/Spreadsheet-Read-Ingester/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 LIMITATIONS

If a new parser is installed (e.g. L<Text::CSV_XS>) and a previous ingestion
used a different parser (e.g. L<Text::CSV_PP>), results from the previous parser
will be returned. Most likely, this will have no practical consequence. But if
you are concerned, you can avoid the problem by specifying the same parser using
an environment variable per the L<Spreadsheet::Read> documentation:

  env SPREADSHEET_READ_CSV=Text::CSV_PP ...

Similarly, upgrading to a newer version of a parser can cause the same problem.
Currently, the only workaround is to delete the stored data files parsed with
the old older parser version.

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
