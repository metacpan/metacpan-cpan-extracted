package Regex::Object::Match;

use 5.20.0;
use strict;
use warnings qw(FATAL);
use utf8;

use Moo;
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

sub BUILD {
    my $self = shift;
    $self->_set_success(defined $self->match);
}

1;

__END__
