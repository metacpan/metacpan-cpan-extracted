#!/usr/bin/perl
use strict;
use warnings;
use SVN::Dump;

my $dump = SVN::Dump->new( { file => @ARGV ? $ARGV[0] : '-' } );
my $file = @ARGV ? $ARGV[0] : "on STDIN";

# compute some stats
my %type;
my %kind;
while ( my $record = $dump->next_record() ) {
    $type{ $record->type() }++;
    $kind{ $record->get_header('Node-action') }++
        if $record->type() eq 'node';
}

# print the results
print "Statistics for dump $file:\n",
      "  version:   ", $dump->version(), "\n",
      "  uuid:      ", $dump->uuid(), "\n",
      "  revisions: ", $type{revision}, "\n",
      "  nodes:     ", $type{node}, "\n";
print map { sprintf "  - %-7s: %d\n", $_, $kind{$_} } sort keys %kind;

