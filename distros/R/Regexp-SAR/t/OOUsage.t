use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Regexp::SAR') }

{
    my $sar = new Regexp::SAR;

    my $pathRes = 0;
    $sar->addRegexp( "abcd", sub { $pathRes += 1; } );
    $sar->match("qabcdef");
    is( $pathRes, 1, "match once" );
}

{
    my $sar = new Regexp::SAR;
    my $pathRes = 0;
    $sar->addRegexp( "abcd", sub { $pathRes += 1; } );
    my $str = "qabcdef";
    $sar->matchRef(\$str);
    is( $pathRes, 1, "match once" );
}

{
    my $sar = new Regexp::SAR;
    my $pathRes = 0;
    $sar->addRegexp( "abcd", sub { $pathRes += 1; } );
    my $str = "qqqqqqqqqqqq";
    $sar->matchRef(\$str);
    is( $pathRes, 0, "" );
}

{
    my $sar = new Regexp::SAR;
    my $pathRes = 0;
    $sar->addRegexp( "abcd", sub { $pathRes += 1; } );
    my $str = "qabcde abcd f";
    $sar->match(\$str);
    is( $pathRes, 2, "" );
}

{
    my $sar = new Regexp::SAR;
    my $pathRes = 0;
    $sar->addRegexp( "abcd", sub { $pathRes += 1; } );
    my $mStr = "qabcdef";
    $sar->match(\$mStr);
    is( $pathRes, 1, "" );
}

{
    my $sar = new Regexp::SAR;
    my $pathRes = 0;
    $sar->addRegexp( "abcd", sub { $pathRes += 1; } );
    $sar->addRegexp( "nm", sub { $pathRes += 2; } );
    my $mStr = "qabcdefnmq";
    $sar->matchFrom(\$mStr, 1);
    is( $pathRes, 3, "" );

    $pathRes = 0;
    $sar->matchFrom(\$mStr, 2);
    is( $pathRes, 2, "" );
}


{
    my $sar = new Regexp::SAR;
    my $mStr = "0123456 789";
    my $matchStr;
    $sar->addRegexp( '\d+', sub {
                                my ($from, $to) = @_;
                                $matchStr = substr($mStr, $from, $to - $from);
                            });
    $sar->matchAt(\$mStr, 3);
    is( $matchStr, '3456', "" );
}


{
    my $sar = new Regexp::SAR;
    my $pathRes = 0;
    $sar->addRegexp( "abcd", sub { $pathRes += 1; } );
    $sar->addRegexp( "nm", sub { $pathRes += 2; } );
    my $mStr = "qabcdefnmq";
    $sar->matchFrom(\$mStr, 1);
    is( $pathRes, 3, "" );

}


{
    my $sar     = new Regexp::SAR;
    my $pathRes = 0;
    $sar->addRegexp( "abcd", sub { $pathRes += 1; } );
    $sar->match("qabcdeabcdkabcdf");
    is( $pathRes, 3, "" );

    my $sar2     = new Regexp::SAR;
    my $pathRes2 = 0;
    $sar2->addRegexp(
        "abcd",
        sub {
            $pathRes2 += 1;
            if ( $pathRes2 == 2 ) { $sar2->stopMatch(); }
        }
    );
    $sar2->match("qabcdeabcdkabcdf");
    is( $pathRes2, 2, "" );

}


{
    my $sar = new Regexp::SAR;
    my ($from, $to);
    my $reStr = "abcd";
    $sar->addRegexp( $reStr, sub { ($from, $to) = @_; } );
    my $mStr = "qabcdef";
    $sar->match(\$mStr);
    is( $from, 1);
    is( $to, 5);
    my $matchStr = substr($mStr, $from, $to - $from);
    is($matchStr, $reStr);
    ($from, $to) = (0, 0);
    $sar->match("qqqqabcdttt");
    is( $from, 4);
    is( $to, 8);
}


{
    my $sar = new Regexp::SAR;
    my ($from, $to);
    my $reStr = '\d+';
    $sar->addRegexp( $reStr, sub { ($from, $to) = @_; $sar->stopMatch();} );
    my $mStr = "1234";
    $sar->match(\$mStr);
    my $matchStr = substr($mStr, $from, $to - $from);
    is($matchStr, $mStr);
}


{
    my $sar = new Regexp::SAR;
    my $pathRes = 0;
    $sar->addRegexp( "ab", sub { $pathRes += 1; $sar->continueFrom(8)} );
    $sar->addRegexp( "nm", sub { $pathRes += 2; } );
    my $mStr = "qabe ab fnmq";
    $sar->match($mStr);
    is( $pathRes, 3, "" );
}

{
    my $sar = new Regexp::SAR;
    my $mStr = "abc";
    my @res = ();
    my $hdl = sub {
        my ($from, $to) = @_;
        my $matchStr = substr($mStr, $from, $to - $from);
        push @res, $matchStr;
    };
    $sar->addRegexp( '\w+', $hdl );

    $sar->match($mStr);
    is( $res[0], "abc" );
    is( $res[1], "bc" );
    is( $res[2], "c" );
    is(scalar @res, 3);
}


{
    my $sar = new Regexp::SAR;
    my $mStr = "123abc456";
    my @res = ();
    my $hdl = sub {
        my ($from, $to) = @_;
        my $matchStr = substr($mStr, $from, $to - $from);
        push @res, $matchStr;
        $sar->continueFrom($to);
    };
    $sar->addRegexp( '\a+', $hdl );
    $sar->match($mStr);
    is($res[0], "abc");
}


{
    my $sar = new Regexp::SAR;
    my $mStr = "123abc456";
    my @res = ();
    my $hdl = sub {
        my ($from, $to) = @_;
        my $matchStr = substr($mStr, $from, $to - $from);
        push @res, $matchStr;
        $sar->continueFrom($to);
    };
    $sar->addRegexp( '\d+', $hdl );
    $sar->addRegexp( '\a+', $hdl );

    $sar->match($mStr);
    is($res[0], "123");
    is($res[1], "abc");
    is($res[2], "456");
}


{
    my $sar = new Regexp::SAR;
    my $mStr = "123abc";
    my @res = ();
    my $hdl = sub {
        my ($from, $to) = @_;
        my $matchStr = substr($mStr, $from, $to - $from);
        push @res, $matchStr;
        $sar->continueFrom($to);
    };
    $sar->addRegexp( '\d+', $hdl );
    $sar->addRegexp( '\w+', $hdl );

    $sar->match($mStr);
    is($res[0], "123");
    is($res[1], "123abc");
}


{
    my $sar = new Regexp::SAR;
    my $mStr = "123abc";
    my @res = ();
    my $hdl = sub {
        my ($from, $to) = @_;
        my $matchStr = substr($mStr, $from, $to - $from);
        push @res, $matchStr;
        $sar->continueFrom($to+1);
    };
    $sar->addRegexp( '\d+', $hdl );
    $sar->addRegexp( '\a+', $hdl );

    $sar->match($mStr);
    is($res[0], "123");
    is($res[1], "bc");
}


{
    my $sar = new Regexp::SAR;
    my $mStr = "backup:x:34:34:backup:/var/backups:/usr/sbin/nologin";
    my $matchCount = 0;
    my $elemNum = 6;
    my ($matchStart, $matchEnd) = (0, 0);
    $sar->addRegexp( ':', sub {
        my ($from, $to) = @_;
        ++$matchCount;
        $sar->continueFrom($to);
        if ($matchCount == $elemNum - 1) {
            $matchStart = $to;
        }
        elsif ($matchCount == $elemNum) {
            $matchEnd = $from;
            $sar->stopMatch();
        }
    } );
    $sar->match($mStr);
    if ($matchEnd > 0) {
        my $matchStr = substr($mStr, $matchStart, $matchEnd - $matchStart);
        is('/var/backups', $matchStr);
    }
    else {
        fail("no match found");
    }
    is($matchCount, $elemNum);
}


{
    my $sar1 = new Regexp::SAR;
    my $matched = 0;
    $sar1->addRegexp('abc', sub {$matched = 1;});
    $sar1->match('mm abc nn');
    if (!$matched) {
        ok(undef, "regexp should match");
    }
}

{
    #index many regexp for single match run
    my @matched;
    my $sar2 = new Regexp::SAR;
    my $regexps = [
                    ['ab+c', 'First Match'],
                    ['\d+', 'Second Match'],
                  ];
    my $string;
    foreach my $re (@$regexps) {
        my ($reStr, $reTitle) = @$re;
        $sar2->addRegexp( $reStr,
                        sub {
                            my ($from, $to) = @_;
                            my $matchStr = substr($string, $from, $to - $from);
                            push @matched, "$reTitle: $matchStr";
                            $sar2->continueFrom($to);
                        } );
    }
    $string = 'first abbbbc second 123 end';
    $sar2->match(\$string);
    is(scalar @matched, 2);
    is($matched[0], 'First Match: abbbbc');
    is($matched[1], 'Second Match: 123');
}


{
    #get third match and stop
    my $sar3 = new Regexp::SAR;
    my $matchedStr3;
    my $matchCount = 0;
    my $string3 = 'aa11 bb22 cc33 dd44';
    $sar3->addRegexp('\w+', sub {
                                my ($from, $to) = @_;
                                ++$matchCount;
                                if ($matchCount == 3) {
                                    $matchedStr3 = substr($string3, $from, $to - $from);
                                    $sar3->stopMatch(); 
                                }
                                else {
                                    $sar3->continueFrom($to);
                                }
                            });
    $sar3->match($string3);
    is($matchCount, 3);
    is($matchedStr3, 'cc33');

}

{
    #get match only at certain position
    my $sar4 = new Regexp::SAR;
    my $matchedStr4;
    my $string4 = 'aa11 bb22 cc33 dd44';
    $sar4->addRegexp('\w+', sub {
                                my ($from, $to) = @_;
                                $matchedStr4 = substr($string4, $from, $to - $from);
                            });
    $sar4->matchAt($string4, 5);
    is($matchedStr4, 'bb22');
}


{
    my $sar1 = new Regexp::SAR;
    my $sar2 = new Regexp::SAR;
    my $string = 'aaaaaaaaaaaaaaaaaaaaaaaaaabbbc';

    my $matched = 0;
    $sar2->addRegexp('b+c', sub {
                                ++$matched;
                            });
    $sar1->addRegexp('a+', sub {
                                my ($from, $to) = @_;
                                $sar2->matchAt($string, $to);
                                $sar1->stopMatch();
                           });
    $sar1->match($string);

    is($matched, 1);
}

{
    my $sar = new Regexp::SAR;
    my $alphaPos;
    my $anchorPos;
    $sar->addRegexp('\a', sub { $alphaPos = $_[0] });
    $sar->addRegexp('\d', sub {
                                my $digitPos = $_[0];
                                if (defined $alphaPos) {
                                    my $dist = $digitPos - $alphaPos;
                                    if ($dist == 1) {
                                        $anchorPos = $digitPos;
                                    }
                                }
                              });
    $sar->match('aa bb2cc dd');

    is($anchorPos, 5);
}

#
###############################################
done_testing();
