package Regex::Object::Match;

use 5.20.0;

use utf8;
use English;
use feature qw(signatures);

use Moo;

no warnings qw(experimental::signatures);
use namespace::clean;

has [qw(prematch match postmatch last_paren_match
        captures named_captures named_captures_all)
] => (
    is       => 'ro',
    required => 1,
);

has success => (
    is => 'rwp',
);

1;

__END__
