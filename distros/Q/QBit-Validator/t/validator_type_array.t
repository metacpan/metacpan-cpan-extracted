use Test::More tests => 23;

use qbit;
use QBit::Validator;
use Exception::Validator::FailedField;

#########
# type => 'array' #
#########

ok(QBit::Validator->new(data => undef, template => {type => 'array'},)->has_errors,
    'Use type type => \'array\' and data = undef');

ok(!QBit::Validator->new(data => undef, template => {type => 'array', optional => TRUE},)->has_errors,
    'Use optional => TRUE and data = undef');

ok(QBit::Validator->new(data => 'scalar', template => {type => 'array'},)->has_errors,
    'Use type type => \'array\' and data = scalar');

ok(QBit::Validator->new(data => {}, template => {type => 'array'},)->has_errors,
    'Use type type => \'array\' and data = hash');

ok(!QBit::Validator->new(data => [], template => {type => 'array'},)->has_errors,
    'Use type type => \'array\' and data = array');

#
# size_min
#

my $error;
try {
    QBit::Validator->new(data => [], template => {type => 'array', size_min => -3},);
}
catch {
    $error = TRUE;
};
ok($error, 'Option "size_min" must be positive number');

ok(
    !QBit::Validator->new(
        data     => [1, 2],
        template => {
            type     => 'array',
            size_min => 1,
        },
      )->has_errors,
    'Option "size_min" (no error)'
  );

ok(
    QBit::Validator->new(
        data     => [1, 2],
        template => {
            type     => 'array',
            size_min => 3,
        },
      )->has_errors,
    'Option "size_min" (error)'
  );

#
# size
#

$error = FALSE;
try {
    QBit::Validator->new(data => [], template => {type => 'array', size => undef},);
}
catch {
    $error = TRUE;
};
ok($error, 'Option "size" must be positive number');

ok(
    !QBit::Validator->new(
        data     => [],
        template => {
            type => 'array',
            size => 0,
        },
      )->has_errors,
    'Option "size" (no error)'
  );

ok(
    QBit::Validator->new(
        data     => [1, 2],
        template => {
            type => 'array',
            size => 1,
        },
      )->has_errors,
    'Option "size" (error)'
  );

#
# size_max
#

$error = FALSE;
try {
    QBit::Validator->new(data => [], template => {type => 'array', size_max => 3.4},);
}
catch {
    $error = TRUE;
};
ok($error, 'Option "size_max" must be positive number');

ok(
    !QBit::Validator->new(
        data     => [1, 2],
        template => {
            type     => 'array',
            size_max => 3,
        },
      )->has_errors,
    'Option "size_max" (no error)'
  );

ok(
    QBit::Validator->new(
        data     => [1, 2],
        template => {
            type     => 'array',
            size_max => 1,
        },
      )->has_errors,
    'Option "size_max" (error)'
  );

#
# all
#

$error = FALSE;
try {
    QBit::Validator->new(data => [], template => {type => 'array', all => undef},);
}
catch {
    $error = TRUE;
};
ok($error, 'Option "all" must be type => \'hash\'');

ok(
    !QBit::Validator->new(
        data     => [1, 20, 300],
        template => {
            type => 'array',
            all  => {},
        },
      )->has_errors,
    'Option "all" (no error)'
  );

ok(
    QBit::Validator->new(
        data     => [1, 20, 300],
        template => {
            type => 'array',
            all  => {max => 30},
        },
      )->has_errors,
    'Option "all" (error)'
  );

#
# contents
#

$error = FALSE;
try {
    QBit::Validator->new(data => [], template => {type => 'array', contents => undef},);
}
catch {
    $error = TRUE;
};
ok($error, 'Option "contents" must be type => \'array\'');

ok(
    !QBit::Validator->new(
        data     => [1, {key => 2}, 'qbit'],
        template => {
            type     => 'array',
            contents => [{}, {type => 'hash', fields => {key => {}}}, {in => 'qbit'}],
        },
      )->has_errors,
    'Option "contents" (no error)'
  );

ok(
    QBit::Validator->new(
        data     => [1, {key => 2}, 'qbit'],
        template => {
            type     => 'array',
            contents => [{}, {type => 'hash', fields => {key => {}}},],
        },
      )->has_errors,
    'Option "contents" (error)'
  );

#
# check
#

$error = FALSE;
try {
    QBit::Validator->new(data => [], template => {type => 'array', check => undef,},);
}
catch {
    $error = TRUE;
};
ok($error, 'Option "check" must be code');

ok(
    !QBit::Validator->new(
        data     => [1, 2, 3],
        template => {
            type  => 'array',
            check => sub {
                throw FF gettext('[2] must be equal [0] + [1]') if $_[1]->[2] != $_[1]->[0] + $_[1]->[1];
            },
        },
      )->has_errors,
    'Option "check" (no error)'
  );

ok(
    QBit::Validator->new(
        data     => [1, 2, 4],
        template => {
            type  => 'array',
            check => sub {
                throw FF gettext('[2] must be equal [0] + [1]') if $_[1]->[2] != $_[1]->[0] + $_[1]->[1];
            },
        },
      )->has_errors,
    'Option "check" (error)'
  );

