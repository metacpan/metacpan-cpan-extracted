use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

# A consumer of State::Store's C ABI, as a third party would write one: it
# finds the header through ExtUtils::Depends and nothing else. Built and run
# by xt/abi-consumer.t; it is not installed and not shipped as a module.
my $pkg = ExtUtils::Depends->new('State::Store::ABI::Consumer', 'State::Store');

WriteMakefile(
    NAME         => 'State::Store::ABI::Consumer',
    VERSION_FROM => 'lib/State/Store/ABI/Consumer.pm',
    XS           => { 'Consumer.xs' => 'Consumer.c' },
    OBJECT       => 'Consumer$(OBJ_EXT)',
    $pkg->get_makefile_vars,
);
