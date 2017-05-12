use Test::More tests => 12;

{
    package Room;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'is_lit' => (
        metaclass => 'Bool',
        is        => 'rw',
        isa       => 'Bool',
        default   => 0,
        provides  => {
            set     => 'illuminate',
            unset   => 'darken',
            toggle  => 'flip_switch',
            not     => 'is_dark'
        }
    )
}

my $room = Room->new;

my @providers = qw(illuminate darken flip_switch is_dark);
for my $provider (@providers) {
    can_ok $room => $provider;
}

$room->illuminate;
ok $room->is_lit, 'set and check ok';
ok !$room->is_dark, 'set and not op ok';

$room->darken;
ok !$room->is_lit, 'unset and check ok';
ok $room->is_dark, 'unset and not op ok';

$room->flip_switch;
ok $room->is_lit, 'toggle and check ok';
ok !$room->is_dark, 'toggle and not op ok';

$room->flip_switch;
ok !$room->is_lit, 'toggle and check agein ok';
ok $room->is_dark, 'toggle and not op again ok';
