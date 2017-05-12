use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
    use_ok('Module::Mask');
}

use lib qw( t/lib );

{
    my $mask = new Module::Mask::Inverted qw( Other );

    ok($mask->is_masked('Dummy'), 'Dummy is masked');

    my $file = __FILE__;
    my $line = __LINE__; eval { require Dummy };
    like(
        $@, qr(^Dummy\.pm masked by Module::Mask::Inverted\b),
        'Dummy was masked'
    );
    like($@, qr(line\s+\Q$line\E), 'line number correct');
    like($@, qr(at\s+\Q$file\E), 'file name correct');

    eval { require Dummy };
    ok($@, 'second time still dies');

    eval { require Other };
    ok(!$@, 'Other gets loaded') or diag $@;
}

__END__

vim: ft=perl
