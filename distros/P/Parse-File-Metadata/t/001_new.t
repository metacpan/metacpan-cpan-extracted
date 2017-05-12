#perl
use strict;
use warnings;
use Parse::File::Metadata;
use Test::More tests =>  5;

my ($file, $header_split, $metaref, @rules);
my $self;

$file = 't/amyfile.txt';
$header_split = '=';
$metaref = {};
@rules = (
    { label => q{'d' key must exist},
        rule => sub { exists $metaref->{d}; } },
    { label => q{'d' key must be non-negative integer},
        rule => sub { $metaref->{d} =~ /^\d+$/; } },
    { label => q{'f' key must exist},
        rule => sub { exists $metaref->{f}; } },
);

$self = Parse::File::Metadata->new( {
    file            => $file,
    header_split    => $header_split,
    metaref         => $metaref,
    rules           => \@rules,
} );
isa_ok( $self, 'Parse::File::Metadata' );

$metaref = { key => 'value' };
eval {
    $self = Parse::File::Metadata->new( {
        file            => $file,
        header_split    => $header_split,
        metaref         => $metaref,
        rules           => \@rules,
    } );
};
like( $@, qr/^Metadata hash must start out empty/,
    "Got expected error message:  'metaref' hash not empty" );

$metaref = [];
eval {
    $self = Parse::File::Metadata->new( {
        file            => $file,
        header_split    => $header_split,
        metaref         => $metaref,
        rules           => \@rules,
    } );
};
like( $@, qr/^Metadata hash must start out empty/,
    "Got expected error message:  'metaref' element must be hashref" );

$metaref = {};
my %rules = (
    alpha => { label => q{'d' key must exist},
        rule => sub { exists $metaref->{d}; } },
    beta => { label => q{'d' key must be non-negative integer},
        rule => sub { $metaref->{d} =~ /^\d+$/; } },
    gamma => { label => q{'f' key must exist},
        rule => sub { exists $metaref->{f}; } },
);
eval {
    $self = Parse::File::Metadata->new( {
        file            => $file,
        header_split    => $header_split,
        metaref         => $metaref,
        rules           => \%rules,
    } );
};
like( $@, qr/^Rules must be in array ref/,
    "Got expected error message:  'rules' element must be arrayref" );

pass("Completed all tests in $0");
