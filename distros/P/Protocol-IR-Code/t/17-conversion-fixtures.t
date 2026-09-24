#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname basename);
use File::Spec;
use Protocol::IR::Converter;

# Data-driven conversion tests backed by the per-protocol fixture files in
# t/data/conv-*.tsv. Each file is hand-editable reference data -- add a row
# or correct a value there, not in this program. See the header comment of
# any conv-*.tsv file for the column layout:
#
#   name, protocol, address, subaddress, command, expected Pronto hex,
#   decoded protocol, decoded address, decoded subaddress, decoded command
#
# For every row both conversion directions are checked against the file:
#   structured (protocol/address/subaddress/command) -> Pronto hex must equal
#   the file, and Pronto hex -> structured must equal the decoded columns.
# The decoded columns differ from the source columns for frame variants
# that share a timing signature: NEC2 decodes as NEC, the half-header
# NECX1/NECX2 decode as SAMSUNG with bit-reversed address/command bytes, and
# 48-NEC2 decodes as 48-NEC1. Protocols without a subaddress field record -1.

my $converter = Protocol::IR::Converter->new();
my $data_dir  = File::Spec->catdir(dirname(__FILE__), 'data');
my @files     = sort glob(File::Spec->catfile($data_dir, 'conv-*.tsv'));

cmp_ok(scalar(@files), '>=', 11, 'per-protocol conversion fixtures present');

for my $file (@files) {
    (my $proto = basename($file)) =~ s/^conv-//;
    $proto =~ s/\.tsv$//;

    subtest "conversion fixture: $proto" => sub {
        open my $fh, '<', $file or die "Cannot open $file: $!\n";
        my $rows = 0;
        while (my $line = <$fh>) {
            chomp $line;
            $line =~ s/\r$//;
            next if $line =~ /^\s*#/ || $line !~ /\S/;

            my @col = split /\t/, $line;
            is(scalar(@col), 10, "row " . ($rows + 1) . " has 10 columns")
                or next;
            my ($name, $proto2, $addr, $subaddr, $cmd, $pronto,
                $dproto, $daddr, $dsub, $dcmd) = @col;

            my $code = eval {
                $converter->import_code($proto2, {
                    address    => _int($addr),
                    subaddress => _int($subaddr),
                    command    => _int($cmd),
                });
            };
            ok($code, "$name: structured code imports") or next;

            is($converter->export_code($code, 'Pronto'), $pronto,
                "$name: structured -> Pronto matches fixture");

            my $decoded = eval { $converter->import_format('Pronto', $pronto) };
            ok($decoded, "$name: Pronto decodes") or next;
            is($decoded->protocol,    $dproto,   "$name: Pronto -> protocol");
            is($decoded->address,     _int($daddr), "$name: Pronto -> address");
            is($decoded->subaddress,  _int($dsub),  "$name: Pronto -> subaddress");
            is($decoded->command,     _int($dcmd),  "$name: Pronto -> command");
            $rows++;
        }
        close $fh;
        cmp_ok($rows, '>', 0, "fixture for $proto has data rows");
    };
}

done_testing;

# Accept decimal or 0x-prefixed hex in the fixture columns.
sub _int {
    my ($v) = @_;
    return $v =~ /^0x/i ? hex($v) : $v + 0;
}
