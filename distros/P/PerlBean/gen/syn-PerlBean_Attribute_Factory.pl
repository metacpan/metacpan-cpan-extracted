use strict;
use PerlBean::Attribute::Factory;
my $factory = PerlBean::Attribute::Factory->new();
my $attr = $factory->create_attribute( {
    type => 'BOOLEAN',
    method_factory_name => 'true',
    short_description => 'something is true',
} );
1;
