use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/MouseX/YAML.pm';

requires 'Mouse' => 0.40;

if(!load_first_existing_class(qw(YAML::XS YAML::Syck YAML))){
    # This module requires YAML by default, because YAML is in pure Perl
    requires 'YAML' => 0.70;
}

recommends 'YAML::XS' => 0.32;

sub load_first_existing_class {
    foreach my $module(@_){
        eval q{require $module} && return $module;
    }
    return undef;
}

test_requires 'Test::More' => 0.88; # done_testing()


tests 't/*.t', 't/*/*.t';
author_tests 'xt';

auto_set_repository() if -d '.git';

clean_files qw(
    MouseX-YAML-* *.stackdump
    cover_db
    nytprof
    *.out
);

WriteAll check_nmake => 0;
