#!/usr/bin/perl

use lib 'lib', '../lib';

package My::IO::File;

use Moose;
use MooseX::GlobRef;

require IO::File;   # IO:: modules are not loaded automatically by "extends"

extends 'Moose::Object', 'IO::File';
with 'MooseX::GlobRef::Role::Object';

has 'file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'mode' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'r',
);

sub BUILD {
    my ($fh) = @_;
    $fh->open( $fh->file, $fh->mode );
};

sub slurp {
    my ($fh) = @_;
    local $/ = undef;
    return $fh->getline;
};

my $io = My::IO::File->new( file => $ARGV[0] || die "Usage: $0 *file*\n" );

print "::::::::::::::\n";
print $io->file, "\n";
print "::::::::::::::\n";
print $io->getlines;
print "::::::::::::::\n";
print $io->dump;
