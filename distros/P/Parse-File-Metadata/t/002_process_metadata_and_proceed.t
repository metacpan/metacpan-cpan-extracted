#perl
use strict;
use warnings;
use File::Spec;
use Parse::File::Metadata;
use Test::More tests => 25;

my ($file, $header_split, $metaref, @rules);
my $self;
my ($dataprocess, $metadata_out, $exception);
my $expected_metadata;
my %exceptions_seen;

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

$dataprocess = sub { my @fields = split /,/, $_[0], -1; };

$self->process_metadata_and_proceed( $dataprocess );
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

$dataprocess = sub { my @fields = split /,/, $_[0], -1; };

$self->process_metadata_and_proceed( $dataprocess );
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

$dataprocess = undef;
eval {
    $self->process_metadata_and_proceed( $dataprocess );
};
like( $@, qr/^Must define subroutine for processing data rows/,
    "Got expected error:  process_metadata_and_proceed() argument undefined" );

eval {
    $self->process_metadata_and_proceed( [ qw( a b c ) ] );
};
like( $@, qr/^Must define subroutine for processing data rows/,
    "Got expected error:  process_metadata_and_proceed() wrong argument type" );

# 4
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

$dataprocess = sub { my @fields = split /,/, $_[0], -1; };

$self->process_metadata_and_proceed( $dataprocess );
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

# 5
$file = File::Spec->catfile( 't', 'dmyfile.txt' );
$header_split = '\s*=\s*';
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

$dataprocess = sub { my @fields = split /,/, $_[0], -1; };

$self->process_metadata_and_proceed( $dataprocess );
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

# 6
$file = File::Spec->catfile( 't', 'emyfile.txt' );
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

$dataprocess = sub { my @fields = split /,/, $_[0], -1; };

$self->process_metadata_and_proceed( $dataprocess );
$metadata_out   = $self->get_metadata();
$exception      = $self->get_exception();
$expected_metadata = {
    a => q{alpha},
    b => q{beta,charlie,delta},
    c => q{epsilon	zeta	eta},
    d => q{This is not a non-negative integer},
    e => q{This is a string},
};
is_deeply( $metadata_out, $expected_metadata,
    "Got expected metadata" );
is(scalar @{$exception}, 2, "Got 2 metadata rule failures");
%exceptions_seen = map {$_  => 1 } @{$exception};
ok( exists $exceptions_seen{q|'d' key must be non-negative integer|},
    "Got expected failure label" );
ok( exists $exceptions_seen{q|'f' key must exist|},
    "Got expected failure label" );

# 7
# DOS line endings
$file = File::Spec->catfile( 't', 'xmyfile.txt' );
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

$dataprocess = sub { my @fields = split /,/, $_[0], -1; };

$self->process_metadata_and_proceed( $dataprocess );
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
