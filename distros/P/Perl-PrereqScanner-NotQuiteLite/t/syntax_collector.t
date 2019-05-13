use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

test('spec follows', <<'END', {'Syntax::Collector' => 0, strict => 0, warnings => 0, 'Scalar::Util' => 0});
use Syntax::Collector q/
    use strict 0;
    use warnings 0 FATAL => 'all';
    use Scalar::Util 0 qw(blessed);
/;
END

test('-collect', <<'END', {'Syntax::Collector' => 0, strict => 0, warnings => 0, 'Scalar::Util' => 0});
use Syntax::Collector -collect => q/
    use strict 0;
    use warnings 0 FATAL => 'all';
    use Scalar::Util 0 qw(blessed);
/;
END

test('no spec', <<'END', {'Syntax::Collector' => 0});
use Syntax::Collector;
END

done_testing;
