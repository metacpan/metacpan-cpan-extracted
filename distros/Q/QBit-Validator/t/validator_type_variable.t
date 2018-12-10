use Test::More tests => 19;
use Test::Deep;

use qbit;
use QBit::Validator;
use Exception::Validator::FailedField;

############
# VARIABLE #
############

#
# OR
#

ok(
    !QBit::Validator->new(
        data     => 3,
        template => {
            type       => 'variable',
            conditions => [{max => 5}, {len_max => 1},]
        },
      )->has_errors,
    '3 - max = 5 or len_max = 1 (first condition)'
  );

ok(
    !QBit::Validator->new(
        data     => 7,
        template => {
            type       => 'variable',
            conditions => [{max => 5}, {len_max => 1},]
        },
      )->has_errors,
    '7 - max = 5 or len_max = 1 (second condition)'
  );

ok(
    QBit::Validator->new(
        data     => 10,
        template => {
            type       => 'variable',
            conditions => [{max => 5}, {len_max => 1},]
        },
      )->has_errors,
    '10 - max = 5 or len_max = 1 (error)'
  );

#
# SWITCH current element
#

ok(
    !QBit::Validator->new(
        data     => 3,
        template => {
            type       => 'variable',
            conditions => [{if => {max => 5}, then => {in => [1, 3, 5]}}, {if => {len_max => 1}},]
        },
      )->has_errors,
    '3 - if (max = 5) then (in [1, 3, 5]) or len_max = 1 (working "then"'
  );

ok(
    QBit::Validator->new(
        data     => 2,
        template => {
            type       => 'variable',
            conditions => [{if => {max => 5}, then => {in => [1, 3, 5]}}, {if => {len_max => 1}},]
        },
      )->has_errors,
    '3 - if (max = 5) then (in [1, 3, 5]) or len_max = 1 (working "then", error: 2 not in [1, 3, 5]'
  );

# else in last condition only
try {
    QBit::Validator->new(
        data     => 10,
        template => {
            type       => 'variable',
            conditions => [{if => {max => 5}, else => {max => 15}}, {if => {len_max => 1}},]
        },
      )
}
catch {
    is(shift->message, gettext('Option "else" must only be in the last condition'), 'Correct message');
}
finally {
    ok(shift, 'throw error')
};

ok(
    !QBit::Validator->new(
        data     => 10,
        template => {
            type       => 'variable',
            conditions => [{if => {max => 5}}, {if => {len_max => 1}, else => {max => 15}},]
        },
      )->has_errors,
    '10 - max = 5 or len_max = 1 or max = 15 (working "else")'
  );

ok(
    QBit::Validator->new(
        data     => 20,
        template => {
            type       => 'variable',
            conditions => [{if => {max => 5}}, {if => {len_max => 1}, else => {max => 15}},]
        },
      )->has_errors,
    '20 - max = 5 or len_max = 1 or max = 15 (working "else", error: 20 > 15)'
  );

ok(
    !QBit::Validator->new(
        data     => 7,
        template => {
            type       => 'variable',
            conditions => [{if => {max => 5}}, {if => {len_max => 1}, then => {eq => 7}, else => {max => 15}},]
        },
      )->has_errors,
    '7 - max = 5 or if (len_max = 1) then {eq 7} else {max = 15} (working "then")'
  );

ok(
    QBit::Validator->new(
        data     => 9,
        template => {
            type       => 'variable',
            conditions => [{if => {max => 5}}, {if => {len_max => 1}, then => {eq => 7}, else => {max => 15}},]
        },
      )->has_errors,
    '9 - max = 5 or if (len_max = 1) then {eq 7} else {max = 15} (working "then", error: 9 <> 7)'
  );

# use path

ok(
    !QBit::Validator->new(
        data => {
            key  => 1,
            key2 => 2,
        },
        template => {
            type   => 'hash',
            fields => {
                key  => {},
                key2 => {
                    type       => 'variable',
                    conditions => [
                        {
                            if   => ['/key', {eq => 1}],
                            then => {eq => 2},
                            else => {eq => 7},
                        },
                    ]
                }
            },
        },
      )->has_errors,
    'key = 1, key2 = 2'
  );

ok(
    !QBit::Validator->new(
        data => {
            key  => 2,
            key2 => 7,
        },
        template => {
            type   => 'hash',
            fields => {
                key  => {},
                key2 => {
                    type       => 'variable',
                    conditions => [
                        {
                            if   => ['/key', {eq => 1}],
                            then => {eq => 2},
                            else => {eq => 7},
                        },
                    ]
                }
            },
        },
      )->has_errors,
    'key = 2, key2 = 7'
  );

ok(
    QBit::Validator->new(
        data => {
            key  => 1,
            key2 => 5,
        },
        template => {
            type   => 'hash',
            fields => {
                key  => {},
                key2 => {
                    type       => 'variable',
                    conditions => [
                        {
                            if   => ['/key', {eq => 1}],
                            then => {eq => 2},
                            else => {eq => 7},
                        },
                    ]
                }
            },
        },
      )->has_errors,
    'key = 1, key2 = 5'
  );

ok(
    QBit::Validator->new(
        data => {
            key  => 2,
            key2 => 3,
        },
        template => {
            type   => 'hash',
            fields => {
                key  => {},
                key2 => {
                    type       => 'variable',
                    conditions => [
                        {
                            if   => ['/key', {eq => 1}],
                            then => {eq => 2},
                            else => {eq => 7},
                        },
                    ]
                }
            },
        },
      )->has_errors,
    'key = 2, key2 = 3'
  );

# path for array

ok(
    !QBit::Validator->new(
        data => {
            key  => 1,
            key2 => [{key3 => 2}, {key3 => 2}, {key3 => 2},],
        },
        template => {
            type   => 'hash',
            fields => {
                key  => {},
                key2 => {
                    type => 'array',
                    all  => {
                        type   => 'hash',
                        fields => {
                            key3 => {
                                type       => 'variable',
                                conditions => [
                                    {
                                        if   => ['../../../key', {eq => 1}],
                                        then => {eq => 2},
                                        else => {eq => 7},
                                    },
                                ],
                            },
                        },
                    },
                },
            },
        },
      )->has_errors,
    'key = 1, key3 = 2'
  );

ok(
    !QBit::Validator->new(
        data => {
            key  => 3,
            key2 => [{key3 => 7}, {key3 => 7}, {key3 => 7},],
        },
        template => {
            type   => 'hash',
            fields => {
                key  => {},
                key2 => {
                    type => 'array',
                    all  => {
                        type   => 'hash',
                        fields => {
                            key3 => {
                                type       => 'variable',
                                conditions => [
                                    {
                                        if   => ['../../../key', {eq => 1}],
                                        then => {eq => 2},
                                        else => {eq => 7},
                                    },
                                ],
                            },
                        },
                    },
                },
            },
        },
      )->has_errors,
    'key = 3, key3 = 7'
  );

ok(
    QBit::Validator->new(
        data => {
            key  => 1,
            key2 => [{key3 => 4}, {key3 => 4}, {key3 => 4},],
        },
        template => {
            type   => 'hash',
            fields => {
                key  => {},
                key2 => {
                    type => 'array',
                    all  => {
                        type   => 'hash',
                        fields => {
                            key3 => {
                                type       => 'variable',
                                conditions => [
                                    {
                                        if   => ['../../../key', {eq => 1}],
                                        then => {eq => 2},
                                        else => {eq => 7},
                                    },
                                ],
                            },
                        },
                    },
                },
            },
        },
      )->has_errors,
    'key = 1, key3 = 4'
  );

ok(
    QBit::Validator->new(
        data => {
            key  => 3,
            key2 => [{key3 => 5}, {key3 => 5}, {key3 => 5},],
        },
        template => {
            type   => 'hash',
            fields => {
                key  => {},
                key2 => {
                    type => 'array',
                    all  => {
                        type   => 'hash',
                        fields => {
                            key3 => {
                                type       => 'variable',
                                conditions => [
                                    {
                                        if   => ['../../../key', {eq => 1}],
                                        then => {eq => 2},
                                        else => {eq => 7},
                                    },
                                ],
                            },
                        },
                    },
                },
            },
        },
      )->has_errors,
    'key = 3, key3 = 5'
  );
