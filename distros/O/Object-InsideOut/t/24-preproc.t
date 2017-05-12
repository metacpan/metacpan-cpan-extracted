use strict;
use warnings;

use Test::More 'tests' => 6;

package My::Class; {
    use Object::InsideOut;

    my @data :Field('Get' => 'data');
    my @info :Field('Get' => 'info');
    my @misc :Field('Get' => 'misc');

    my %init_args :InitArgs = (
        'DATA' => {
            'Preproc' => \&preproc,
            'Field'   => \@data,
        },
        'INFO' => {
            'Preproc' => \&preproc,
            'Field'   => \@info,
            'Default' => 'deleted',
        },
        'MISC' => {
            'Preproc' => \&preproc,
            'Field'   => \@misc,
        },
    );

    sub preproc
    {
        my ($class, $param, $spec, $obj, $value) = @_;

        Test::More::is($class, __PACKAGE__, 'Correct class');

        # Delete param and let specified default be set
        if (exists($$spec{'Default'})) {
            return;
        }

        # Override the specified value
        if (defined($value)) {
            return ('overridden');
        }

        # Provide a default
        return ('default');
    }
};

package main;

MAIN:
{
    my $obj = My::Class->new('INFO' => 'information',
                             'MISC' => 'miscellaneous');

    is($obj->data(), 'default'    => 'Preprocessing - default');
    is($obj->info(), 'deleted'    => 'Preprocessing - deleted');
    is($obj->misc(), 'overridden' => 'Preprocessing - overridden');
}

exit(0);

# EOF
