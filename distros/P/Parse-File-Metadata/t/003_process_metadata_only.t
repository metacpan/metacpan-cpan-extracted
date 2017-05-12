#perl
use strict;
use warnings;
use File::Spec;
use Parse::File::Metadata;
use Test::More tests => 11;

my ($file, $header_split, $metaref, @rules);
my $self;
my ($dataprocess, $metadata_out, $exception);
my $expected_metadata;

# 1
$file = File::Spec->catfile( 't', 'amyfile.txt' );
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

$self->process_metadata_only();
$metadata_out   = $self->get_metadata();
$exception      = $self->get_exception();
$expected_metadata = {
    a => q{alpha},
    b => q{beta,charlie,delta},
    c => q{epsilon	zeta	eta},
    d => q{1234567890},
    e => q{This is a string},
    f => q{,},
};
is_deeply( $metadata_out, $expected_metadata,
    "Got expected metadata" );
ok( ! scalar @{$exception}, "No exception:  all metadata criteria met" );

# 2
$file = File::Spec->catfile( 't', 'bmyfile.txt' );
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

$self->process_metadata_only();
$metadata_out   = $self->get_metadata();
$exception      = $self->get_exception();
$expected_metadata = {
    a => q{alpha},
    b => q{beta,charlie,delta},
    c => q{epsilon	zeta	eta},
    d => q{1234567890},
    e => q{This is a string},
};
is_deeply( $metadata_out, $expected_metadata,
    "Got expected metadata" );
ok( $exception->[0], "Metadata criteria not met" );
is( $exception->[0], q{'f' key must exist},
    "Got expected metadata criterion label" );

# 3
$file = File::Spec->catfile( 't', 'cmyfile.txt' );
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

$self->process_metadata_only();
$metadata_out   = $self->get_metadata();
$exception      = $self->get_exception();
$expected_metadata = {
    a => q{alpha},
    b => q{beta,charlie,delta},
    c => q{epsilon	zeta	eta},
    d => q{1234567890},
    e => q{This is a string},
    f => q{,},
};
is_deeply( $metadata_out, $expected_metadata,
    "Got expected metadata" );
ok( ! scalar @{$exception}, "No exception:  all metadata criteria met" );

pass("Completed all tests in $0");
