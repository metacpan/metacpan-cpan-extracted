#$Id: test.pl,v 1.6 2001/09/16 04:39:56 joe Exp $
use 5.006;
use Test;
use strict;
BEGIN { plan tests => 4 };

my $pid = open FILTER, "-|";
die "fork failed: $!" unless defined $pid;
$| = 1;

if ($pid) {  # parent
    my @score = (136, 130); # message scores
    my $warnings = 12;      # total warning headers

    my ($n, $lines, $disabled);

    for (grep /^Gnus-Warning:/ => <FILTER>) {
        ++$lines;
        /filter disabled/ and ++$disabled;

        next unless /Flavell Bogosity Index (\d+)/;
        ok( $1 == $score[$n++] ); # test 1,2
    }
    ok ($disabled == 1);          # test 3
    ok ( $lines == $warnings );   # test 4
    close FILTER or die $?;
}

else {      # child
    my $cursor = tell DATA;

    TEST_123: {

        local $/;

        foreach my $msg (split '\nEOM\n\n', <DATA>) {
            open MESSAGE, "| perl -Mlib=blib/lib -wT gnusfilter" or die "fork failed: $!";
            print MESSAGE $msg;
            close MESSAGE or die $?;
        }
    }

    seek DATA, $cursor, 0;

    TEST_4: {
        open MESSAGE, "| perl -Mlib=blib/lib -wT gnusfilter" or die "fork failed: $!";
        print MESSAGE <DATA>;
        seek DATA, 0, 0;
        print MESSAGE <DATA>; # ensures 8K worth of data
    }

    close MESSAGE or die $?;

}

__DATA__
Path: e3500-atl1.usenetserver.com!cyclone-atl1!e420r-sjo4.usenetserver.com!usenetserver.com!newshub2.rdc1.sfba.home.com!news.home.com!news1.rdc1.az.home.com.POSTED!not-for-mail
From: "Rufio" <davecawdell@home.com>
Newsgroups: comp.lang.c++,comp.lang.java,comp.lang.c
References: <3b7daa5b.11370082@news.atl.bellsouth.net> <3B7DDC66.1060208@home.com> <7084276d.0108181206.130bae5d@posting.google.com> <3B7EEA6E.3030107@home.com> <9lo2h9$afg$01$1@news.t-online.com> <3B7FADEB.8030207@netscape.net>
Subject: Re: Will C/C++ or Java be dominant in the future?
Lines: 36
X-Priority: 3
X-MSMail-Priority: Normal
X-Newsreader: Microsoft Outlook Express 5.50.4807.1700
X-MimeOLE: Produced By Microsoft MimeOLE V5.50.4807.1700
Message-ID: <dqQf7.161485$Cy.21892858@news1.rdc1.az.home.com>
Date: Sun, 19 Aug 2001 14:54:01 GMT
NNTP-Posting-Host: 24.1.249.93
X-Complaints-To: abuse@home.net
X-Trace: news1.rdc1.az.home.com 998232841 24.1.249.93 (Sun, 19 Aug 2001 07:54:01 PDT)
NNTP-Posting-Date: Sun, 19 Aug 2001 07:54:01 PDT
Organization: Excite@Home - The Leader in Broadband http://home.com/faster
Xref: e420r-sjo4.usenetserver.com comp.lang.c++:245890 comp.lang.java:29101 comp.lang.c:206408

"MGM" <nospam@netscape.net> wrote in message
news:3B7FADEB.8030207@netscape.net...
> A sole invention? It looks to me like a sole plagiarism of C, C++, and
> Java. That's funny to see the words "invention" and M$ in the same
sentence!
>
> mgm

Oh - if M$ did it, it can't be plagiarism. They wouldn't do something like
that;
they're "good guts".

>
> Jakob Bieling wrote:
>
> >>Java has seen success because it offers improvements.
> >>Given more time, it can see even MORE improvements.
> >>
> >
> > Not only Java will improve!
> >
> >
> >>C has gone from C.....to C++.....now heading into C#.
> >>
> >
> > C# does not originate from C++. C# is a sole invention of Microsoft.
> >
> > jb
> >
> >
> >
>
>
EOM

Path: e3500-atl1.usenetserver.com!cyclone-atl1!e420r-sjo4.usenetserver.com!cyclone2.usenetserver.com!usenetserver.com!newsfeed1.cidera.com!Cidera!cyclone.tampabay.rr.com!news-post.tampabay.rr.com!typhoon.tampabay.rr.com.POSTED!not-for-mail
From: cuplan@tampabay.rr.com (Cuplan)
Newsgroups: comp.lang.c++,comp.lang.java,comp.lang.c
Subject: Re: Will C/C++ or Java be dominant in the future?
Reply-To: cuplan@tampabay.rr.com
Message-ID: <3b7e1c40.407394295@news-server>
References: <3b7daa5b.11370082@news.atl.bellsouth.net> <azif7.38436$hO5.8178885@news3.rdc1.on.home.com> <3b7e0ef9.1523312@news.atl.bellsouth.net>
X-Newsreader: Forte Free Agent 1.21/32.243
Lines: 63
Date: Sat, 18 Aug 2001 08:03:51 GMT
NNTP-Posting-Host: 65.32.42.189
X-Complaints-To: abuse@rr.com
X-Trace: typhoon.tampabay.rr.com 998121831 65.32.42.189 (Sat, 18 Aug 2001 04:03:51 EDT)
NNTP-Posting-Date: Sat, 18 Aug 2001 04:03:51 EDT
Organization: RoadRunner - TampaBay
Xref: e420r-sjo4.usenetserver.com comp.lang.c++:245554 comp.lang.java:29045 comp.lang.c:206137

On Sat, 18 Aug 2001 06:45:14 GMT, herman404@yahoo.com (Herman) wrote:

>Thanks for the info.  It seems that everyone here advises me to learn
>Java, and it certainly can't hurt so I might as well go ahead.  They
>started teaching us C in university, then moved us on to C++ and OOP
>concepts.  [Since then the cirriculum has been restructured to make
>Java the first language]  Afterwards we studied comparative
>programming languages [Ada, Scheme], and data structures [entirely in
>C++] and operating systems programming [entirely in C].  

Well, IMHO, data structures is more easily taught in C.  Feel lucky
that you got a comparative languages course.  I didn't, and know
comparatively little about languages other than C, C++, Perl, and
Java.  I feel very shortchanged.  It was a stroke of luck that I even
got a chance to learn C++.

>In the
>Anchordesk talkback, the C people maintained demand for C knowledge
>will always be high, just that there will be more Java programmers
>because it is easier to pick up.  They maintained that there will
>always be stuff you can do in C that you can't do in Java.  The Java
>people retorted with "Once upon a time, there were things that you can
>do in assembly that you can't do in C", obviously meaning that C's
>days are numbered.  There was talk about newbies and Java, but I think
>[this is my own personal view] that beginners should be taught the
>basics of programming languages using C, then move them on to C++
>where you introduce OOP.  Since Java is completely object oriented,
>they will have an easier time learning Java that way than if they
>picked up Java first thing off, IMHO.

I disagree.  Pointers and pointer math are a pain in the ass for a
beginer to learn, and many will be struggling with procedural
programming as it is.  C is also got that damned preprocessor that
makes everything hard to read.  I don't think C++ should be the next
step up, either.  Why?  Because manual memory management is another
highly difficult thing for a beginner to learn, and it's woefully
complex (regardless of what proponents will say).  Not only that, but
C++ has all sorts of very NON OO constructs in it that just make it a
mess.  "Friend functions" are one good case.

Moreover, I see no reason to hide OO, the dominant development
paradigm, from the beginner.  Forcing them to move from a purely
procedural programming environment to an OO one would prolly just
serve to confuse them.  I know I'm not what you'd call "senior," but
it seems to me that the overwhelming majority of bad design calls and
bad programming in Java is the result of people failing to totally
apprehend the object paradigm and hold on to old C programming tricks.

No...I think moving from Java to C++ to C to MIPS Assembly would be
much wiser.  This gives student time to learn the object pardigm and
learn how programming goes, then slowly infuse things like pointers
and whatnot, and culminate with teaching them the ultimate lesson
about programming- that it's all just a bunch of binary numbers with
no real meaning without being placed into context.


--
Cuplan (the great AMMM Acting Froup Lord).

"I was younger once, and I created a lie
 And though my body was strong,
 I was self-deluded, confident, and blind"
      -Swans, "Blind"
EOM

Path: e3500-atl1.usenetserver.com!cyclone-atl1!e420r-sjo4.usenetserver.com!usenetserver.com!newsfeed1.cidera.com!Cidera!news.maxwell.syr.edu!news.mel.connect.com.au!newshub1.rdc1.nsw.optushome.com.au!news1.rdc1.nsw.optushome.com.au.POSTED!not-for-mail
From: "ralmin" <sbiber@optushome.com.au>
Newsgroups: comp.lang.c++,comp.lang.c
References: <3b7daa5b.11370082@news.atl.bellsouth.net> <azif7.38436$hO5.8178885@news3.rdc1.on.home.com> <9llup3$fn9$07$1@news.t-online.com>
Subject: Re: Will C/C++ or Java be dominant in the future?
Lines: 12
X-Priority: 3
X-MSMail-Priority: Normal
X-Newsreader: Microsoft Outlook Express 5.50.4522.1200
X-MimeOLE: Produced By Microsoft MimeOLE V5.50.4522.1200
Message-ID: <z0Kf7.2288$Ee.17130@news1.rdc1.nsw.optushome.com.au>
Date: Sun, 19 Aug 2001 07:37:03 GMT
NNTP-Posting-Host: 203.164.166.141
X-Complaints-To: abuse@optushome.com.au
X-Trace: news1.rdc1.nsw.optushome.com.au 998206623 203.164.166.141 (Sun, 19 Aug 2001 17:37:03 EST)
NNTP-Posting-Date: Sun, 19 Aug 2001 17:37:03 EST
Organization: @Home Network
Xref: e420r-sjo4.usenetserver.com comp.lang.c++:245816 comp.lang.c:206355

> Also, see above. Imo, pointers are not a concept that is hard to
understand.
> When I do a project in VB now, I am missing pointers. The things you can
do
> with them are just great (Linked Lists are just one example...)

VB does have pointers. Just a stupid implementation of them. Check out the
varptr() function.

Ralmin.

