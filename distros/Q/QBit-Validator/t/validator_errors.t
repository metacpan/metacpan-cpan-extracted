use Test::More tests => 11;
use Test::Deep;

use qbit;
use QBit::Validator;
use Exception::Validator::FailedField;

my $validator = QBit::Validator->new(
    template => {
        type   => 'hash',
        fields => {
            login => {
                len_min => 1,
                len_max => 12,
                regexp  => qr/^[a-z0-9]+/,
                msg     => 'Login can contain any letters a to z and any numbers from 0 through 9'
            },
            password  => {len_min => 1, len_max => 16, regexp => qr/^[a-z0-9_]+/i},
            password2 => {
                len_min => 1,
                len_max => 16,
                regexp  => qr/^[a-z0-9_]+/i,
                check   => sub {
                    my ($qv, $password2) = @_;

                    if ($qv->data->{'password'} ne $password2) {
                        throw FF 'password and password2 must be equals';
                    }
                }
            },
            person => {
                type   => 'hash',
                fields => {
                    first_name => {len_min => 1, len_max => 215},
                    middle_name => {optional => TRUE, len_min => 1, len_max => 215},
                    surname     => {len_min  => 1,    len_max => 215},
                    age         => {
                        min => 18,
                        max => 50,
                    },
                    gender => {in => [qw(m w)]},
                    height => {
                        min   => 1,
                        check => sub {
                            my ($qv, $height) = @_;

                            my $error = FALSE;
                            if ($qv->data->{'person'}{'gender'} eq 'm') {
                                $error = TRUE unless $height > 48 && $height < 272;
                            } elsif ($qv->data->{'person'}{'gender'} eq 'w') {
                                $error = TRUE unless $height > 55 && $height < 232;
                            }

                            throw FF 'Enter your height' if $error;
                        }
                    },
                    weight => {
                        min => 2,
                        max => 570,
                    },
                },
                deps => {height => 'gender',},
            },
            contacts => {
                type   => 'hash',
                fields => {
                    phone => {optional => TRUE, len_min => 1,},
                    email => {optional => TRUE, len_min => 1,},
                }
            },
            pets => {
                type     => 'array',
                contents => [
                    {in => [qw(cat dog)]},
                    {
                        type   => 'hash',
                        fields => {
                            name  => {len_min => 1, len_max => 16},
                            breed => {
                                optional => TRUE,
                                len_min  => 3,
                                len_max  => 120
                            }
                        },
                    }
                ]
            }
        },
        deps => {password2 => 'password',},
    }
);

$validator->validate(
    {
        login     => '_l0gin',
        password  => 's3cret',
        password2 => 's3creR',
        person    => {
            first_name => 'Anna',
            surname    => 'White',
            age        => 14,
            gender     => 'w',
            height     => 54,
        },
        contacts => {facebook => 'anna-white',},
        pets     => [
            'cat',
            {
                name  => 'babu',
                breed => 'no'
            }
        ],
        extra_key => "Don't check"
    }
);

#
# has_errors
#

ok($validator->has_errors, 'has errors');

#
# get_errors
#

cmp_deeply(
    $validator->get_errors,
    {
        'password2' => 'password and password2 must be equals',
        'contacts'  => 'Extra fields: facebook',
        'person'    => {
            'weight' => 'Data must be defined',
            'height' => 'Enter your height',
            'age'    => 'Got value "14" less then "18"'
        },
        'pets'  => [undef, {'breed' => 'Length "no" less then "3"'}],
        'login' => 'Login can contain any letters a to z and any numbers from 0 through 9'
    },
    'get_errors'
);

#
# get_fields_with_error
#

cmp_deeply(
    [$validator->get_fields_with_error],
    [
        {
            'path'    => '/contacts/',
            'message' => 'Extra fields: facebook'
        },
        {
            'message' => 'Login can contain any letters a to z and any numbers from 0 through 9',
            'path'    => '/login/'
        },
        {
            'message' => 'password and password2 must be equals',
            'path'    => '/password2/'
        },
        {
            'message' => 'Got value "14" less then "18"',
            'path'    => '/person/age/'
        },
        {
            'path'    => '/person/height/',
            'message' => 'Enter your height'
        },
        {
            'path'    => '/person/weight/',
            'message' => 'Data must be defined'
        },
        {
            'path'    => '/pets/1/breed/',
            'message' => 'Length "no" less then "3"'
        }
    ],
    'get_fields_with_error'
);

#
# has_error
#

ok($validator->has_error('contacts'),      'contracts has error');
ok($validator->has_error('/person/age'),   'person.age has error');
ok($validator->has_error('/pets/1/breed'), 'pets[1].breed has error');

ok(!$validator->has_error('password'),           'password has not error');
ok(!$validator->has_error('/person/first_name'), 'person.first_name has not error');

#
# get_error
#

is($validator->get_error('contacts'), gettext('Extra fields: %s', 'facebook'), 'Message for contacts');
is($validator->get_error('/person/age'), gettext('Got value "%s" less then "%s"', 14, 18), 'Message for person.age');
is($validator->get_error('/pets/1/breed'), gettext('Length "%s" less then "%s"', 'no', 3), 'Message for pets[1].breed');
