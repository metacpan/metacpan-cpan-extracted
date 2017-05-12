BEGIN {
    $SIG{__WARN__} = sub {
        my $warning = shift;
        return if $warning =~ /String found|predeclare/;
        CORE::warn($warning);
    };
}

use lib 't/lib';
use Test::More;
use Test::Class::Load 't/lib';
diag("Testing Test::Class::Most $Test::Class::Most::VERSION, Perl $], $^X");
diag("Testing Test::Class       $Test::Class::VERSION");
