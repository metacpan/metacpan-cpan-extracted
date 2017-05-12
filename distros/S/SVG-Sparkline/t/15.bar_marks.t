#!/usr/bin/env perl

use Test::More tests => 19;
use Test::Exception;
use Carp;
use SVG::Sparkline;

use strict;
use warnings;

# positive only
{
    my $b1 = SVG::Sparkline->new( Bar => { values=>[4,2,8,10,5], mark=>[1=>'blue'] } );
    is( "$b1",
        '<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v-4h3v2h3v-6h3v-2h3v5h3v5z" fill="#000" stroke="none" /><rect fill="blue" height="2" stroke="none" width="3" x="3" y="-2" /></svg>',
        'pos only: mark index'
    );
}

{
    my $b2 = SVG::Sparkline->new( Bar => { values=>[4,2,8,10,5], mark=>[first=>'blue'] } );
    is( "$b2",
        '<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v-4h3v2h3v-6h3v-2h3v5h3v5z" fill="#000" stroke="none" /><rect fill="blue" height="4" stroke="none" width="3" x="0" y="-4" /></svg>',
        'pos only: mark first'
    );
}

{
    my $b3 = SVG::Sparkline->new( Bar => { values=>[4,2,8,10,5], mark=>[last=>'red'] } );
    is( "$b3",
        '<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v-4h3v2h3v-6h3v-2h3v5h3v5z" fill="#000" stroke="none" /><rect fill="red" height="5" stroke="none" width="3" x="12" y="-5" /></svg>',
        'pos only: mark last'
    );
}

{
    my $b4 = SVG::Sparkline->new( Bar => { values=>[4,2,8,10,5], mark=>[low=>'red'] } );
    is( "$b4",
        '<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v-4h3v2h3v-6h3v-2h3v5h3v5z" fill="#000" stroke="none" /><rect fill="red" height="2" stroke="none" width="3" x="3" y="-2" /></svg>',
        'pos only: mark low'
    );
}

{
    my $b5 = SVG::Sparkline->new( Bar => { values=>[4,2,8,10,5], mark=>[high=>'green'] } );
    is( "$b5",
        '<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v-4h3v2h3v-6h3v-2h3v5h3v5z" fill="#000" stroke="none" /><rect fill="green" height="10" stroke="none" width="3" x="9" y="-10" /></svg>',
        'pos only: mark high'
    );
}

{
    my $bz = SVG::Sparkline->new( Bar => { values=>[4,0,8,10,5], mark=>[1=>'green'] } );
    is( "$bz",
        '<svg height="12" viewBox="0 -11 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v-4h3v4h3v-8h3v-2h3v5h3v5z" fill="#000" stroke="none" /><ellipse cx="4.5" cy="0" fill="green" rx="1.5" ry="0.5" stroke="none" /></svg>',
        'pos only: zero height mark'
    );
}
# negative only
{
    my $b1 = SVG::Sparkline->new( Bar => { values=>[-4,-2,-8,-10,-5], mark=>[1=>'blue'] } );
    is( "$b1",
        '<svg height="12" viewBox="0 -1 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v4h3v-2h3v6h3v2h3v-5h3v-5z" fill="#000" stroke="none" /><rect fill="blue" height="2" stroke="none" width="3" x="3" y="0" /></svg>',
        'neg only: mark index'
    );
}

{
    my $b2 = SVG::Sparkline->new( Bar => { values=>[-4,-2,-8,-10,-5], mark=>[first=>'blue'] } );
    is( "$b2",
        '<svg height="12" viewBox="0 -1 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v4h3v-2h3v6h3v2h3v-5h3v-5z" fill="#000" stroke="none" /><rect fill="blue" height="4" stroke="none" width="3" x="0" y="0" /></svg>',
        'neg only: mark first'
    );
}

{
    my $b3 = SVG::Sparkline->new( Bar => { values=>[-4,-2,-8,-10,-5], mark=>[last=>'red'] } );
    is( "$b3",
        '<svg height="12" viewBox="0 -1 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v4h3v-2h3v6h3v2h3v-5h3v-5z" fill="#000" stroke="none" /><rect fill="red" height="5" stroke="none" width="3" x="12" y="0" /></svg>',
        'neg only: mark last'
    );
}

{
    my $b4 = SVG::Sparkline->new( Bar => { values=>[-4,-2,-8,-10,-5], mark=>[low=>'red'] } );
    is( "$b4",
        '<svg height="12" viewBox="0 -1 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v4h3v-2h3v6h3v2h3v-5h3v-5z" fill="#000" stroke="none" /><rect fill="red" height="10" stroke="none" width="3" x="9" y="0" /></svg>',
        'neg only: mark low'
    );
}

{
    my $b5 = SVG::Sparkline->new( Bar => { values=>[-4,-2,-8,-10,-5], mark=>[high=>'green'] } );
    is( "$b5",
        '<svg height="12" viewBox="0 -1 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v4h3v-2h3v6h3v2h3v-5h3v-5z" fill="#000" stroke="none" /><rect fill="green" height="2" stroke="none" width="3" x="3" y="0" /></svg>',
        'neg only: mark high'
    );
}

{
    my $bz = SVG::Sparkline->new( Bar => { values=>[-4,0,-8,-10,-5], mark=>[1=>'green'] } );
    is( "$bz",
        '<svg height="12" viewBox="0 -1 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v4h3v-4h3v8h3v2h3v-5h3v-5z" fill="#000" stroke="none" /><ellipse cx="4.5" cy="0" fill="green" rx="1.5" ry="0.5" stroke="none" /></svg>',
        'neg only: zero height mark'
    );
}

# pos and neg
{
    my $b1 = SVG::Sparkline->new( Bar => { values=>[-2,-5,1,5,3], mark=>[1=>'blue'] } );
    is( "$b1",
        '<svg height="12" viewBox="0 -6 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v2h3v3h3v-6h3v-4h3v2h3v3z" fill="#000" stroke="none" /><rect fill="blue" height="5" stroke="none" width="3" x="3" y="0" /></svg>',
        'pos and neg: mark index'
    );
}

{
    my $b2 = SVG::Sparkline->new( Bar => { values=>[-2,-5,1,5,3], mark=>[first=>'blue'] } );
    is( "$b2",
        '<svg height="12" viewBox="0 -6 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v2h3v3h3v-6h3v-4h3v2h3v3z" fill="#000" stroke="none" /><rect fill="blue" height="2" stroke="none" width="3" x="0" y="0" /></svg>',
        'pos and neg: mark first'
    );
}

{
    my $b3 = SVG::Sparkline->new( Bar => { values=>[-2,-5,1,5,3], mark=>[last=>'red'] } );
    is( "$b3",
        '<svg height="12" viewBox="0 -6 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v2h3v3h3v-6h3v-4h3v2h3v3z" fill="#000" stroke="none" /><rect fill="red" height="3" stroke="none" width="3" x="12" y="-3" /></svg>',
        'pos and neg: mark last'
    );
}

{
    my $b4 = SVG::Sparkline->new( Bar => { values=>[-2,-5,1,5,3], mark=>[low=>'red'] } );
    is( "$b4",
        '<svg height="12" viewBox="0 -6 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v2h3v3h3v-6h3v-4h3v2h3v3z" fill="#000" stroke="none" /><rect fill="red" height="5" stroke="none" width="3" x="3" y="0" /></svg>',
        'pos and neg: mark low'
    );
}

{
    my $b5 = SVG::Sparkline->new( Bar => { values=>[-2,-5,1,5,3], mark=>[high=>'green'] } );
    is( "$b5",
        '<svg height="12" viewBox="0 -6 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v2h3v3h3v-6h3v-4h3v2h3v3z" fill="#000" stroke="none" /><rect fill="green" height="5" stroke="none" width="3" x="9" y="-5" /></svg>',
        'pos and neg: mark high'
    );
}

{
    my $bz = SVG::Sparkline->new( Bar => { values=>[-2,-5,0,5,3], mark=>[2=>'green'] } );
    is( "$bz",
        '<svg height="12" viewBox="0 -6 15 12" width="15" xmlns="http://www.w3.org/2000/svg"><path d="M0,0v2h3v3h3v-5h3v-5h3v2h3v3z" fill="#000" stroke="none" /><ellipse cx="7.5" cy="0" fill="green" rx="1.5" ry="0.5" stroke="none" /></svg>',
        'pos and neg: zero height mark'
    );
}

throws_ok {
    SVG::Sparkline->new( Bar => { values=>[-2,-5,0,5,3], mark=>[xyzzy=>'green'] } );
} qr/not a valid mark/, 'bar: unrecogized mark not allowed';
