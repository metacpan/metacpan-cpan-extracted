use Test::More tests => 39;

use qbit;
use QBit::Validator;

my $error = FALSE;
try {
    QBit::Validator->new();
}
catch {
    $error = TRUE;
};
ok($error, 'Expected "data" and "template"');

$error = FALSE;
try {
    QBit::Validator->new(data => 5, template => undef);
}
catch {
    $error = TRUE;
};
ok($error, 'Key "template" must be HASH');

##########
# SCALAR #
##########

ok(QBit::Validator->new(data => [], template => {},)->has_errors, 'Default type: SCALAR');

$error = FALSE;
try {
    QBit::Validator->new(data => 5, template => {no_exist_option => TRUE});
}
catch {
    $error = TRUE;
};
ok($error, 'Key "no_exist_option"');

#
# regexp
#
$error = FALSE;
try {
    QBit::Validator->new(data => 23, template => {regexp => 'regexp'},);
}
catch {
    $error = TRUE;
};
ok($error, 'Check "regexp" for scalar (bad regexp)');

ok(!QBit::Validator->new(data => 23, template => {regexp => qr/^\d+$/},)->has_errors,
    'Check "regexp" for scalar (no error)');

ok(QBit::Validator->new(data => '23a', template => {regexp => qr/^\d+$/},)->has_errors,
    'Check "regexp" for scalar (error)');

#
# min
#

$error = FALSE;
try {
    QBit::Validator->new(data => 7, template => {min => undef},);
}
catch {
    $error = TRUE;
};
ok($error, 'Check "min" for scalar (bad min)');

ok(!QBit::Validator->new(data => 7, template => {min => 5},)->has_errors, 'Check "min" for scalar (no error)');

ok(QBit::Validator->new(data => 5, template => {min => 7},)->has_errors, 'Check "min" for scalar (error)');

#
# eq
#

ok(!QBit::Validator->new(data => undef, template => {eq => undef},)->has_errors, 'Check "eq" for scalar (no error)');

ok(QBit::Validator->new(data => 7, template => {eq => undef},)->has_errors, 'Check "eq" for scalar (error)');

ok(!QBit::Validator->new(data => 7, template => {eq => 7},)->has_errors, 'Check "eq" for scalar (no error)');

ok(QBit::Validator->new(data => 7, template => {eq => 5},)->has_errors, 'Check "eq" for scalar (error)');

#
# max
#

$error = FALSE;
try {
    QBit::Validator->new(data => 7, template => {max => undef},);
}
catch {
    $error = TRUE;
};
ok($error, 'Check "max" for scalar (bad max)');

ok(!QBit::Validator->new(data => 5, template => {max => 7},)->has_errors, 'Check "max" for scalar (no error)');

ok(QBit::Validator->new(data => 7, template => {max => 5},)->has_errors, 'Check "max" for scalar (error)');

#
# len_min
#

$error = FALSE;
try {
    QBit::Validator->new(data => 1234567, template => {len_min => undef},);
}
catch {
    $error = TRUE;
};
ok($error, 'Check "len_min" for scalar (bad len_min)');

ok(!QBit::Validator->new(data => 1234567, template => {len_min => 5},)->has_errors,
    'Check "len_min" for scalar (no error)');

ok(QBit::Validator->new(data => 12345, template => {len_min => 7},)->has_errors, 'Check "len_min" for scalar (error)');

#
# len
#

$error = FALSE;
try {
    QBit::Validator->new(data => 1234567, template => {len => undef},);
}
catch {
    $error = TRUE;
};
ok($error, 'Check "len" for scalar (bad len)');

ok(!QBit::Validator->new(data => 1234567, template => {len => 7},)->has_errors, 'Check "len" for scalar (no error)');

ok(QBit::Validator->new(data => 1234567, template => {len => 5},)->has_errors, 'Check "len" for scalar (error)');

#
# len_max
#

$error = FALSE;
try {
    QBit::Validator->new(data => 1234567, template => {len_max => undef},);
}
catch {
    $error = TRUE;
};
ok($error, 'Check "len_max" for scalar (bad len_max)');

ok(!QBit::Validator->new(data => 12345, template => {len_max => 7},)->has_errors,
    'Check "len_max" for scalar (no error)');

ok(QBit::Validator->new(data => 1234567, template => {len_max => 5},)->has_errors,
    'Check "len_max" for scalar (error)');

#
# in
#

$error = FALSE;
try {
    QBit::Validator->new(data => 'qbit', template => {in => undef},);
}
catch {
    $error = TRUE;
};
ok($error, 'Check "in" for scalar (bad in)');

ok(!QBit::Validator->new(data => 'qbit', template => {in => 'qbit'},)->has_errors, 'Check "in" for scalar (no error)');

ok(!QBit::Validator->new(data => 'qbit', template => {in => [qw(qbit 7)]},)->has_errors,
    'Check "in" for scalar (no error)');

ok(QBit::Validator->new(data => 5, template => {in => 7},)->has_errors, 'Check "in" for scalar (error)');

#
# check
#

$error = FALSE;
try {
    QBit::Validator->new(data => 'qbit', template => {check => undef},);
}
catch {
    $error = TRUE;
};
ok($error, 'Option "check" must be code');

ok(
    !QBit::Validator->new(
        data     => 'qbit',
        template => {
            check => sub {
                throw FF gettext('Data must be equal "qbit"') if $_[1] ne 'qbit';
              }
        },
      )->has_errors,
    'Option "check" (no error)'
  );

ok(
    QBit::Validator->new(
        data     => 5,
        template => {
            check => sub {
                throw FF gettext('Data must be no equal 5') if $_[1] == 5;
              }
        },
      )->has_errors,
    'Option "check" (error)'
  );

ok(
    !QBit::Validator->new(
        data     => undef,
        template => {
            optional => TRUE,
            check    => sub {
                throw FF gettext('Must be defined')
                  unless defined($_[1]);
            },
        },
      )->has_errors,
    'Option "check" not running (no error)'
  );

#
# msg
#

is(
    QBit::Validator->new(data => 5, template => {max => 2,},)->get_all_errors,
    gettext('Got value "%s" more than "%s"', 5, 2),
    'Get all errors'
  );

is(QBit::Validator->new(data => 5, template => {in => 7, max => 2, msg => 'my error msg'},)->get_error(),
    'my error msg', 'Get my error');

#
# throw => TRUE
#

$error = FALSE;
try {
    QBit::Validator->new(data => 5, template => {in => 7, max => 2,}, throw => TRUE);
}
catch Exception::Validator with {
    $error = TRUE;
};
ok($error, 'throw Exception');

$error = FALSE;
try {
    QBit::Validator->new(data => 5, template => {in => 5}, unknown_option => TRUE);
}
catch Exception::Validator with {
    $error = TRUE;
};
ok($error, 'throw Exception (get unknown option)');

#
# correct error
#

is(
    QBit::Validator->new(
        data     => 'error',
        template => {
            check => sub {
                throw FF gettext('Data must be equal 5') if $_[1] != 5;
              }
        },
      )->get_error,
    gettext('Internal error'),
    'Check right error'
  );
