#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';
use MyTest::PPG ':all';
use Test::Most tests => 2;
use Pod::Parser::Groffmom;

my $file = 't/tofile.tmp';
my $pod = <<"END";
=head1 Some text

This is some text

=for mom tofile $file

=begin mom tofile

This is some file

  with more text

=end mom tofile

This is more text
END

my $body = <<'END';

.HEAD "Some text"

This is some text

This is more text

END

eq_or_diff body(get_mom($pod)), $body,
    '"tofile" text should not be in the body of the mom';
open my $fh, '<', $file or die "Could not open ($file) for reading: $!";
my $contents = do { local $/, <$fh> };

my $expected = <<'END';
This is some file

  with more text

END

eq_or_diff $contents, $expected,
    '... and the "tofile" file contents should be correct';

if ( -f $file ) {
    unlink $file or die "Could not unlink($file): $!";
}
