#!perl

use utf8;

use 5.010;

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Exception qw/lives/;

plan 'tests' => 10;

ok( lives {
        require Perl::Critic::Mardem;
    }
);

ok( lives {
        require Perl::Critic::Mardem::Util;
    }
);

ok( lives {
        require Perl::Critic::Policy::Mardem::ProhibitBlockComplexity;
    }
);

ok( lives {
        require Perl::Critic::Policy::Mardem::ProhibitConditionComplexity;
    }
);

ok( lives {
        require Perl::Critic::Policy::Mardem::ProhibitFileSize;
    }
);

ok( lives {
        require Perl::Critic::Policy::Mardem::ProhibitLargeBlock;
    }
);

ok( lives {
        require Perl::Critic::Policy::Mardem::ProhibitLargeFile;
    }
);

ok( lives {
        require Perl::Critic::Policy::Mardem::ProhibitLargeSub;
    }
);

ok( lives {
        require Perl::Critic::Policy::Mardem::ProhibitManyConditionsInSub;
    }
);

ok( lives {
        require Perl::Critic::Policy::Mardem::ProhibitReturnBooleanAsInt;
    }
);

done_testing();

__END__

#-----------------------------------------------------------------------------
