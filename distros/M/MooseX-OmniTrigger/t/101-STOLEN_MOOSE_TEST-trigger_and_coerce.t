use strict; use warnings;

use Test::More;

{ package Fake::DateTime;

    use Moose;

    has string_repr => (is => 'ro');
}

{ package Mortgage;

    use Moose;
    use Moose::Util::TypeConstraints;
    use MooseX::OmniTrigger;

    coerce 'Fake::DateTime',
        from 'Str',
            via { Fake::DateTime->new(string_repr => $_) };

    has closing_date => (is => 'rw', isa => 'Fake::DateTime', coerce  => 1, omnitrigger => sub {

        my ($self, $attr_name, $new, $old) = @_;

        ::pass('...omnitrigger is being called');

        ::isa_ok($self->closing_date          , 'Fake::DateTime');
        ::isa_ok(                    $new->[0], 'Fake::DateTime');
    });
}

{
    my $mtg = Mortgage->new(closing_date => 'yesterday');

    isa_ok($mtg, 'Mortgage');

    # check that coercion worked

    isa_ok($mtg->closing_date, 'Fake::DateTime');
}

Mortgage->meta->make_immutable;

ok(Mortgage->meta->is_immutable, '...Mortgage is now immutable');

{
    my $mtg = Mortgage->new(closing_date => 'yesterday');

    isa_ok($mtg, 'Mortgage');

    # check that coercion worked

    isa_ok($mtg->closing_date, 'Fake::DateTime');
}

done_testing;
