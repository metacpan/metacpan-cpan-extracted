# $Id: param-checking.t,v 1.4 2007/04/12 14:53:28 drhyde Exp $
use strict;

my $warning;
BEGIN {
    $^W=1;
    $SIG{__WARN__} = sub {
        $warning = join('', @_);
        die("Caught a warning, making it fatal:\n$warning\n")
            if($warning !~ /^Net::Random: /);
    };
}

use Test::More tests => 8;
use Net::Random;

my $r;

eval { $r = Net::Random->new(ssl => 0, src => 'fourmilab.ch', max => 12, min => -1); };
ok(!$@, "no longer dies with min < 0");

eval { $r = Net::Random->new(); };
ok($@ =~ /Bad parameters to Net::Random->new/, "dies with no params");

eval { $r = Net::Random->new(ssl => 0, src => 'rubbish'); };
ok($@ =~ /Bad parameters to Net::Random->new/, "dies with bad source");

eval { $r = Net::Random->new(ssl => 0, src => 'fourmilab.ch', max => 1.2); };
ok($@ =~ /Bad parameters to Net::Random->new/, "dies with non-integer max");

eval { $r = Net::Random->new(ssl => 0, src => 'fourmilab.ch', max => 12, min => 1.2); };
ok($@ =~ /Bad parameters to Net::Random->new/, "dies with non-integer min");

eval { $r = Net::Random->new(ssl => 0, src => 'fourmilab.ch', max => 12, min => 13); };
ok($@ =~ /Bad parameters to Net::Random->new/, "dies with min > max");

eval { $r = Net::Random->new(ssl => 0, src => 'fourmilab.ch', max => 2 ** 32); };
ok($@ =~ /Bad parameters to Net::Random->new/, "dies with max > 2^32-1");

eval { $r = Net::Random->new(ssl => 0, src => 'fourmilab.ch', min => -2, max => 2 ** 32); };
ok($@ =~ /Bad parameters to Net::Random->new/, "dies with min-to-max range > 2^32-1");
