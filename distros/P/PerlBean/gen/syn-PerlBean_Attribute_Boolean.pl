use strict;
use PerlBean::Attribute::Boolean;
my $attr = PerlBean::Attribute::Boolean->new( {
    method_factory_name => 'true',
    short_description => 'something is true',
} );
1;
