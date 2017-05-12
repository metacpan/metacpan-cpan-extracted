package SheetTest;

=head1 NAME

SheetTest - Spreadsheet::Engine test mechanism

=head1 SYNOPSIS

  use lib 't/lib';
  use SheetTest;

  run_tests( 
    commands => \@commands,
    against => 't/data/my_test_data.txt'
  );

=head1 DESCRIPTION

Run a series of test commands against a spreadsheet.

=head1 EXPORTS

=head2 run_tests

  run_tests( 
    commands => \@commands,
    against => 't/data/my_test_data.txt'
  );

Both arguments are optional. 

If a list of commands is not given, then the commands will be read from
the <DATA> section of the calling test file. 

If a source file is not given, then a blank spreadsheet will be created,
and the commands given will be responsible for also setting up all data.

The $sheet created will be returned in case you want to peform any other
tests against it.

=head1 COMMANDS

=head2 test / like

  test B1 30
  like B2 ^string

Test against the data value in the cell specified.

=head2 testtype

   testtype B3 n

Test against the valuetype in the cell specified.

=head2 isnear

  isnear B1 0.404194

Test that the numeric value given is correct to at least as many decimal
places given.

=head2 others

Any other line (ignoring blank lines and comment lines starting with #)
is executed 'as is' and followed by a recalc.

=cut

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw/run_tests/;

use Spreadsheet::Engine;
use Spreadsheet::Engine::Storage::SocialCalc;

use Scalar::Util 'looks_like_number';
use Test::Builder;

my $Test = Test::Builder->new();

sub run_tests {
  my %conf = @_;

  my $sheet =
    exists $conf{against}
    ? Spreadsheet::Engine::Storage::SocialCalc->load($conf{against})
    : Spreadsheet::Engine->new;

  my @cmds =
    exists $conf{commands}
    ? @{ $conf{commands} }
    : do { my $data = caller() . '::DATA'; <$data> };

  foreach my $cmd (@cmds) {
    chomp $cmd;
    next if $cmd =~ /^#/;
    next unless $cmd =~ /\S/;

    # There are ways of messing with Level and exported_to etc., but
    # there's a potential bug where Test::Builder::ok explicitly looks
    # in caller() rather than guessing correctly where $TODO is.
    # After discussion with Schwern, this is probably easiest:
    # (During the conversation Schwern patched that bug, but we
    # can't rely on that fix without a high dependency)
    no strict 'refs';
    local ${ caller() . '::TODO' } = 'later' if $cmd =~ s/^TODO //;

    if ($cmd =~ /^test\s(\w+)\s(.*?)$/) {
      my ($ref, $want) = ($1, $2);
      my $got = $sheet->raw->{datavalues}{$ref};

      # ignore trailing whitespace if we want (and got) a number
      (my $tmp = $want) =~ s/\s+$//;
      looks_like_number($tmp) && (($sheet->raw->{valuetypes}{$ref} || '') =~ /^n/)
        ? $Test->is_num($got, $tmp, "$ref == $tmp")
        : $Test->is_eq($got, $want, "$ref eq $want");
    } elsif ($cmd =~ /^isnear\s(\w+)\s(.*?)\s*$/) {
      my ($ref, $want) = ($1, $2);
      (my $dec_part = $want) =~ s/.*\.//;
      my $margin = 0.1**length $dec_part;
      my $got    = $sheet->raw->{datavalues}{$ref};
      my $diff   = abs($got - $want);
      $Test->ok($diff <= $margin, "$ref =~ $want")
        or $Test->diag("        got: $got\n   expected: $want +/- $margin");
    } elsif ($cmd =~ /^testtype\s(\w+)\s(.*?)$/) {
      $Test->is_eq($sheet->raw->{valuetypes}{$1}, $2, "$1 = $2");
    } elsif ($cmd =~ /^iserror\s(\w+)\s*$/) {
      $Test->is_eq(substr($sheet->raw->{valuetypes}{$1}, 0, 1),
        'e', "$1 is an error");
    } elsif ($cmd =~ /^like\s(\w+)\s(.*?)$/) {
      $Test->like($sheet->raw->{datavalues}{$1}, qr/$2/, "$1 =~ $2");
    } else {
      $sheet->execute($cmd);
      $sheet->recalc;
    }
  }
  return $sheet;
}

1;

=head1 HISTORY

This code was created for Spreadsheet::Engine.

=head1 COPYRIGHT 

Copyright (c) 2007, 2008 Tony Bowden

=head1 LICENCE

The contents of this file are subject to the Artistic License 2.0;
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
  http://www.perlfoundation.org/artistic_license_2_0

=cut

