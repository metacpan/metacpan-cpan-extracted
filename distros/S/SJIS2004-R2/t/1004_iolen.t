######################################################################
#
# 1004_iolen.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use SJIS2004::R2;
use vars qw(@test);

@test = (
# 1
    sub { $_='';           iolen($_) == 0  },
    sub { $_='1';          iolen($_) == 1  },
    sub { $_='12';         iolen($_) == 2  },
    sub { $_='123';        iolen($_) == 3  },
    sub { $_='ABCD';       iolen($_) == 4  },
    sub { $_='ｱｲｳｴｵ';      iolen($_) == 5  },
    sub { $_='あいうえお'; iolen($_) == 10 },
    sub { ('SJIS2004' eq ('CP'.'932'.'X')) == do { $_='彁';   iolen($_) == 4 } },
    sub { ('SJIS2004' eq ('CP'.'932'.'X')) == do { $_='彁彁'; iolen($_) == 8 } },
    sub {1},
# 11
    sub { $_='';           iolen() == 0    },
    sub { $_='1';          iolen() == 1    },
    sub { $_='12';         iolen() == 2    },
    sub { $_='123';        iolen() == 3    },
    sub { $_='ABCD';       iolen() == 4    },
    sub { $_='ｱｲｳｴｵ';      iolen() == 5    },
    sub { $_='あいうえお'; iolen() == 10   },
    sub { ('SJIS2004' eq ('CP'.'932'.'X')) == do { $_='彁';   iolen() == 4 } },
    sub { ('SJIS2004' eq ('CP'.'932'.'X')) == do { $_='彁彁'; iolen() == 8 } },
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
