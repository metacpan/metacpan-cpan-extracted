package Test::BDD::Infrastructure::Logfile;

use strict;
use warnings;

our $VERSION = '1.005'; # VERSION
# ABSTRACT: cucumber step definitions for watching log files
 
use Test::More;
use Test::BDD::Cucumber::StepFile qw( Given When Then );

sub S { Test::BDD::Cucumber::StepFile::S }

use File::Slurp;
use File::stat qw(stat);


Given qr/^the log file (.*) is (searched|watched)$/, sub {
  my $file = $1;
  my $mode = $2;
  if( ! -e $file ) {
    fail("the log file $file does not exist!");
  }
  S->{'search_file'} = $file;
  S->{'search_offset'} =
    $mode =~ /^watched/ ? stat($file)->size : 0;
};

sub read_file_offset {
  my ( $path, $offset ) = @_;
  if( ! defined $offset ) {
    die('no offset given for logfile!');
  }
  my $fh = IO::File->new($path, 'r');
  diag("reading logfile with offset $offset");
  $fh->seek($offset, 0);
  my ( @lines, $lines );
  if( wantarray ) {
    @lines = read_file( $fh );
    $lines = join('',@lines);
  } else {
    $lines = read_file( $fh );
  }
  $fh->close;
  diag("lines written to log file during test:\n$lines-----END OF LOG-----");
  if( wantarray ) {
    return @lines;
  }
  return $lines;
}

Then qr/^the log file must ((?:not )?contain) the message (.*)$/, sub {
  my $match = $1;
  my $pattern = $2;
  my @lines = read_file_offset( S->{'search_file'}, S->{'search_offset'} );
  my @found = grep {
    $lines[$_] =~ /\Q$pattern\E/
  } 0..$#lines;
  if( @found ) {
    diag("found pattern $pattern on lines ".join(', ', @found));
  }
  if( $match eq 'not contain' ) {
    cmp_ok( scalar(@found), '==', 0, 'random string should not be found');
  } else {
    cmp_ok( scalar(@found), '==', 1, 'random string must be found 1 time');
  }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Infrastructure::Logfile - cucumber step definitions for watching log files

=head1 VERSION

version 1.005

=head1 Synopsis

  Scenario: The client ip must be logged in access log
    Given the log file /var/log/apache2/access.log is watched
    ...
    Then the log file must contain the message ^123.123.123.123 - -

=head1 Step definitions

  Given the log file <file> is (searched|watched)

If the Given statment is used with 'searched' then the whole
file will be searched for the pattern. If used with 'watched'
then it will only search lines after the current EOF position.

  Then the log file must (not contain|contain) the message <regex>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
