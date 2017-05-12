use strict;
use PerlBean::Attribute::Single;
my $attr = PerlBean::Attribute::Single->new( {
    method_factory_name => 'name',
    short_description => 'my name',
} );
1;
