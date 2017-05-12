package t::lib::TestUtils;

use strict;
use warnings;

{
    package Person;
    use Moo;
    has name  => (is => 'ro');
    has title => (is => 'ro');
}

{
    package Pontiff;
    use Moo;
    extends qw(Person);
}

{
    package Place;
    use Moo;
    has name  => (is => 'ro');
}

{
    package Organization;
    use Moo;
    use MooX::ObjectBuilder;
    has name => (is => 'ro');
    has boss => (
        predicate => 1,
        clearer => 1,
        is => make_builder(
            'Person' => {
                boss_name   => 'name',
                boss_title  => 'title',
                boss_class  => '__CLASS__',
            },
        )
    );
    has headquarters => (
        predicate => 1,
        clearer => 1,
        is => make_builder(
            sub { 'Place'->new(@_) } => (
                hq_name => 'name',
            ),
        )
    );
}


1;
