package I;

use Object::Realize::Later
    realize       => sub { bless {}, 'Another::Class' },
    becomes       => 'Another::Class',
    source_module => 'J';

sub new { bless {}, shift }

1;
