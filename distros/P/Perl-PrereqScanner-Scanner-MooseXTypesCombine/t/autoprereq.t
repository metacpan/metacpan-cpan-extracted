#!perl
use strict;
use warnings;

use File::Temp qw{ tempfile };
use Perl::PrereqScanner;
use PPI::Document;
use Try::Tiny;

use Test::More;

# cargo-culted from Perl::PrereqScanner
sub prereq_is {
  my ($str, $want, $comment) = @_;
  $comment ||= $str;

  my $scanner = Perl::PrereqScanner->new( extra_scanners => ['MooseXTypesCombine'] );

  # scan_ppi_document
  try {
    my $result  = $scanner->scan_ppi_document( PPI::Document->new(\$str) );
    is_deeply($result->as_string_hash, $want, $comment);
  } catch {
    fail("scanner died on: $comment");
    diag($_);
  };

  # scan_string
  try {
    my $result  = $scanner->scan_string( $str );
    is_deeply($result->as_string_hash, $want, $comment);
  } catch {
    fail("scanner died on: $comment");
    diag($_);
  };

  # scan_file
  try {
    my ($fh, $filename) = tempfile( UNLINK => 1 );
    print $fh $str;
    close $fh;
    my $result  = $scanner->scan_file( $filename );
    is_deeply($result->as_string_hash, $want, $comment);
  } catch {
    fail("scanner died on: $comment");
    diag($_);
  };
}

prereq_is(
  <<MXTC,
use parent 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(qw(
  MooseX::Types::Moose
  MooseX::Types::Path::Class
));
MXTC
  {
    'parent' => '0',
    'MooseX::Types::Combine' => 0,
    'MooseX::Types::Moose' => 0,
    'MooseX::Types::Path::Class' => 0,
  }
);

prereq_is(
  <<'MXTC',
our @ISA = qw{ MooseX::Types::Combine };
__PACKAGE__ -> provide_types_from ( "MooseX::Types::Moose",
  ('MooseX::Types::Common::String', $var_that_wont_match) );
MXTC
  {
    'MooseX::Types::Combine' => 0,
    'MooseX::Types::Moose' => 0,
    'MooseX::Types::Common::String' => 0,
  }
);

prereq_is(
  <<'MXTC',
# this package doesn't inherit from MXTC, it just has a similar method call
__PACKAGE__ -> provide_types_from ( "MooseX::Types::Moose", 'MooseX::Types::Common::String' );
MXTC
  {
  }
);

done_testing;
