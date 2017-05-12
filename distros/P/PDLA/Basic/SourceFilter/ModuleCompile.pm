## package Foo;
use Module::Compile -base;

sub pmc_compile {
    my ($class, $source) = @_;
    # Convert $source into (most likely Perl 5) $compiled_output
    my $filtered = perldlpp('PDLA::NiceSlice', $source);
    return $filtered;
}

1;
