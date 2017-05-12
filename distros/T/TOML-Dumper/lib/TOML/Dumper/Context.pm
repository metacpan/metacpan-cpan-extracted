package TOML::Dumper::Context;
use strict;
use warnings;

use TOML::Dumper::Context::Root;

sub new {
    my $class = shift;
    return TOML::Dumper::Context::Root->new(@_);
}

1;
__END__
