use strict;
use warnings;
use Test::More 'no_plan';
use Data::Dumper;

BEGIN { chdir 't' if -d 't' }
BEGIN { use lib '../lib'    }

### DECLARE
my $Class   = 'Params::Profile';
my $DV_result_class = 'Data::FormValidator::Results';
my $DV_profile = {
                'required'              => [ qw/paramone
                                                paramtwo
                                            /
                                            ],
                'optional'              => [ qw/paramopt/ ],
                'constraint_methods'    => {
                        'paramone'  => qr/^[a-z]+$/,
                        'paramopt'  => qr/^[0-9]+$/,
                    },
            };
my $DV_profile2 = {
                'required'              => [ qw/paramthree
                                                paramfour
                                            /
                                            ],
                'optional'              => [ qw/paramoption/ ],
                'constraint_methods'    => {
                        'paramthree'  => qr/^[a-z]+$/,
                        'paramfour'  => qr/^[0-9]+$/,
                    },
            };
my $PC_profile = {
                paramone    => {
                                required    => 1,
                                allow       => qr/^[a-z]+$/,
                            },
                paramtwo    => {
                                required    => 1,
                            },
                paramopt    => {
                                required    => 0,
                                allow       => qr/^[0-9]+$/,
                            },
            };

my $PC_profile2 = {
                paramthree  => {
                                required    => 1,
                                allow       => qr/^[a-z]+$/,
                            },
                paramfour   => {
                                required    => 1,
                            },
                paramfive   => {
                                required    => 0,
                                allow       => qr/^[0-9]+$/,
                            },
            };

my $PC_profile_merged = {
          'paramopt' => { 
                          'required' => 0,
                          'allow' => qr/(?-xism:^[0-9]+$)/
                        },
          'paramtwo' => { 
                          'required' => 1
                        },
          'paramfour' => { 
                           'required' => 1
                         },
          'paramthree' => { 
                            'required' => 1,
                            'allow' => qr/(?-xism:^[a-z]+$)/
                          },
          'paramfive' => { 
                           'required' => 0,
                           'allow' => qr/(?-xism:^[0-9]+$)/
                         },
          'paramone' => { 
                          'required' => 1,
                          'allow' => qr/(?-xism:^[a-z]+$)/
                        }
    };


my @ok_warnings = (
        qr/Cannot alias .*? to missing profile: main::fake_other_profile/,
        qr/Profile type clash for: test_profile_clash/,
    );

### USE CLASS
use_ok( $Class );

### TEST WORKAROUNDS
{
    no warnings 'redefine';
    *Params::Profile::_raise_warning = sub {
        my ($self, $warning) = @_;
        return if grep({ $warning =~ $_ } @ok_warnings);
        diag('A warning was raised: ' . $warning);
    };
}

### CHECKS

### Register a fake alias
ok(!$Class->register_profile(
                        'method'    => 'fake_alias',
                        'profile'   => 'fake_other_profile',
                    ), 'Fake alias check');

### Register a DV profile
ok($Class->register_profile(
                        'method'  => 'test_profile_dv',
                        'profile' => $DV_profile,
                    ), 'Register profile for "test_profile_dv"');

### Register an alias for the profile
ok($Class->register_profile(
                    'method'    => 'alias_method',
                    'profile'   => 'test_profile_dv',
                ), 'Register alias_method as alias for test_profile_dv');

### Verify profiles.
ok($Class->verify_profiles, 'Verify Profiles');

### Type collision
ok(!$Class->register_profile(
                        'method'  => 'test_profile_clash',
                        'profile' => [ $PC_profile, $DV_profile2 ],
                    ), 'Profile type clash');


### Subroutine tests DV
sub test_profile_dv {
    my (%opt) = @_;
    my ($result);
    ok($Class->validate('params' => \%opt), 'DV: Validate parameters');
    ok($result = $Class->check('params' => \%opt), 'DV: Check parameters');
    ok(UNIVERSAL::isa($result, $DV_result_class), 'DV: Got Data::FormValidator result class');
    ok($result->success, 'DV: Succesfully validated parameters');
}
test_profile_dv('paramone' => 'a', 'paramtwo' => 5);

### Get profile
is_deeply($Class->get_profile('method' => 'test_profile_dv'), $DV_profile, 'DV: Got profile');

### Merged test
ok($Class->register_profile(
                        'method'  => 'test_profile_dv',
                        'profile' => [ $DV_profile, $DV_profile2 ],
                    ), 'DV: Register merged profile for "test_profile_dv"');

### Subroutine tests PC
ok($Class->register_profile(
                        'method'  => 'test_profile_pc',
                        'profile' => $PC_profile,
                    ), 'PC: Register profile for "test_profile_pc"');

sub test_profile_pc {
    my (%opt) = @_;
    my ($result);
    ok($Class->validate('params' => \%opt), 'PC: Validate parameters');
    ok($result = $Class->check('params' => \%opt), 'PC: Check parameters');
}
test_profile_pc('paramone' => 'a', 'paramtwo' => 5);

### Check for forrect profile
is_deeply($Class->get_profile('method' => 'test_profile_pc'), $PC_profile, 'PC: Got profile');

### Test merge
ok($Class->register_profile(
                        'method'  => 'test_profile_pc',
                        'profile' => [ $PC_profile, $PC_profile2 ],
                    ), 'PC: Register merged profile for "test_profile_pc"');

# rt.cpan.org #43284 Regexp handling not working correctly with is_deeply
#is_deeply($Class->get_profile('method' => 'main::test_profile_pc'), $PC_profile_merged, 'PC: Correctly merged profile');

