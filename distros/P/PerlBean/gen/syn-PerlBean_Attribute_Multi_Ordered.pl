use strict;
use PerlBean::Attribute::Multi::Ordered;
my $attr = PerlBean::Attribute::Multi::Ordered->new( {
    method_factory_name => 'note_to_self',
    short_description => 'my notes to self',
} );
1;
