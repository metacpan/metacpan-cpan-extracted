package Test::Monitis;

use strict;
use warnings;

require Test::More;
require Monitis;

my $api;
my $agent;

sub api {
    $api ||= Monitis->new(
        api_key    => $ENV{MONITIS_API_KEY},
        secret_key => $ENV{MONITIS_SECRET_KEY}
    );
}

sub agent {$agent}

sub import {
    my $class  = shift;
    my $caller = caller;

    my %params = @_;

    $params{live}++ if $params{agent};

    if (delete $params{live}) {
        unless ($ENV{MONITIS_API_KEY} && $ENV{MONITIS_SECRET_KEY}) {
            Test::More::plan(skip_all =>
                  "Provide MONITIS_API_KEY and MONITIS_SECRET_KEY to run live tests"
            );
        }
        no strict 'refs';
        *{"${caller}::api"} = \&api;
        use strict;
    }


    if (delete $params{agent}) {
        my $agents = api->agents->get;

        unless (@$agents) {
            Test::More::plan(
                skip_all => "At least one agent required for this test");
        }

        $agent = shift @$agents;

        no strict 'refs';
        *{"${caller}::agent"} = \&agent;
        use strict;
    }

    warnings->import;
    strict->import;

    eval <<END;
        package $caller;
        Test::More->import(\%params);
END

    die $@ if $@;
}

1;
