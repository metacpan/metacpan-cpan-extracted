use 5.006;
use strict;
use warnings;

use Module::CheckDep::Version qw(check_deps);
use Test::More;

use constant AUTH => 'STEVEB';

{ # author

    my $ok = eval {
        check_deps();
        1;
    };

    is $ok, undef, "die() without author param sent in ok";
    like $@, qr//, "...and the error is sane";
}

{ # return

    my $ret = check_deps(AUTH, return => 1);
    is ref $ret, 'HASH', "returns ok";
}

{ # all

    my $self_deps = check_deps(AUTH, return => 1);
    my $all_deps  = check_deps(AUTH, all => 1, return => 1);

    is ref $self_deps, 'HASH', "non-all return is an href ok";
    is ref $self_deps, 'HASH', "all return is an href ok";

    is 
        keys %$self_deps < keys %$all_deps, 
        1, 
        "all deps has more entries than non-all ok";
}

{ # module

    my $ret = check_deps(AUTH, module => 'RPi::WiringPi', return => 1);
    is ref $ret, 'HASH', "returns ok";
    is keys %$ret, 1, "with module param, only one result returned ok";
}

{ # handler

    check_deps(AUTH, handler => \&handler);
}

{ # ignore_any

        my $ignored = check_deps(
                        AUTH, module => 'Test::BrewBuild', 
                        all => 1,
                        return => 1
                      );

        my $include = check_deps(
                        AUTH, module => 'Test::BrewBuild', 
                        all => 1,
                        return => 1,
                        ignore_any => 0
                      );
        use Data::Dumper;

        my $exc = keys %{ $ignored->{'Test-BrewBuild'} }; 
        my $inc = keys %{ $include->{'Test-BrewBuild'} };

        is $exc < $inc, 1, "ignore_any => 0 ok";
}    

sub handler {
    my $data = shift;
    
    is ref $data, 'HASH', "handler param is an href ok";

    for my $dist (%$data){
        for my $dep (keys %{ $data->{$dist} }){
            
            is 
                ref $data->{$dist}{$dep}, 
                'HASH', 
                "dep $dep for $dist is an href ok";

            is 
                exists $data->{$dist}{$dep}{dep_ver}, 
                1, 
                "dep $dep for $dist has a 'dep_ver' key";

            is 
                exists $data->{$dist}{$dep}{cur_ver}, 
                1, 
                "dep $dep for $dist has a 'cur_ver' key";

        }
    }
}

done_testing();
