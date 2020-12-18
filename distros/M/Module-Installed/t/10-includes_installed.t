#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Module::Installed qw(module_installed includes_installed);
use Test::More;

my $file = 't/data/test.pl';

# bad file
{
    is eval { includes_installed('no.file'); 1}, undef, "croak() if bad file ok";
    like $@, qr/requires a valid Perl/, "...and error message is sane";
}

# no PPI
{
    $ENV{MI_TEST_PPI} = 'XXX';

    is eval { includes_installed($file); 1}, undef, "croak() if PPI not found ok";
    like $@, qr/requires PPI/, "...and error states why correctly";

    delete $ENV{MI_TEST_PPI};
}

# validate hash
{

    if (module_installed('PPI')) {
        my $includes = includes_installed($file);

        is $includes->{'Load::Fail'}, 0, "Load::Fail nok";
        is $includes->{'Not::Installed'}, 0, "Not::Installed nok";
        is $includes->{'Exporter'}, 1, "Exporter ok";
        is $includes->{'warnings'}, 1, "warnings ok";
        is $includes->{'strict'}, 1, "strict ok";
        is $includes->{'Data::Dumper'}, 1, "Data::Dumper ok";
        is $includes->{'Carp'}, 1, "Carp ok";
    }
}

# validate cb
{

    if (module_installed('PPI')) {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, shift; };

        my $includes = includes_installed($file, sub { warn "$_[0]\n"; });

        for my $w (@warnings) {
            chomp $w;
            is((grep {$w eq $_} keys %$includes), 1, "$w included in return ok");

        }
    }
}

done_testing();

