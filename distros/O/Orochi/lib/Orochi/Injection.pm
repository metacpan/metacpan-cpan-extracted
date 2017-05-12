package Orochi::Injection;
use Moose::Role;
use namespace::clean -except => qw(meta);

requires 'expand';

sub expand_all_injections {
    my ($self, $c, $thing) = @_;

    $c->_expander->visit( $thing );
    return $thing;
}

1;