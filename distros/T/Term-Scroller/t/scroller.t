use strict;
use warnings;
use utf8;

use Test::More (tests => 3);

use File::Temp;
use Term::Scroller;

sub do_test {
    my %test = %{shift()};
    my $output = get_scroller_output($test{in}, @_);
    my $expect = $test{out} =~ s/\n$//sr; # chop off final newline
    #print $output;
    is( $output, $expect );
}

sub get_scroller_output {
    my $input  = shift;
    my %opts = @_;

    my $tmp = File::Temp->new;
    binmode($tmp, ':encoding(utf8)');

    my $scroll = Term::Scroller->new(%opts, out => $tmp);

    print $scroll $input;
    $scroll->end;

    my $output;
    open(my $tmpfh, '< :encoding(utf8)', $tmp) or die "could not read tmp file. $!";
    {
        local $/ = undef;
        $output = <$tmpfh>;
    }
    close($tmp);

    return $output;
}

my %test1 = ( in => <<"ENDIN", out => <<"ENDOUT");
Hey there!

\tHow are ya? This is a
\tvery simple test.
ENDIN
Hey there!\033[K
\033[0m\033[1;FHey there!\033[K
\033[K
\033[0m\033[2;FHey there!\033[K
\033[K
  How are ya? This is a\033[K
\033[0m\033[3;FHey there!\033[K
\033[K
  How are ya? This is a\033[K
  very simple test.\033[K
\033[0m
ENDOUT

do_test(\%test1, tabwidth => 2);

my %test2 = ( in => <<"ENDIN", out => <<"ENDOUT");
\033[1;31mWARNING:\033[0m This text runs long and also has colors in it!!

The next line is going to have some cursor control characters in it,
but the scroller should sanitize them out.
\033[2;FWow!! \033[K I really hope this doesn't break ...

There's also a window border on this one.
But I'm just gonna put a bunch of lines in so that the window will have to
scroll.
Lorem Ipsum Dolor
I don't actually remember any of Lorem Ipsum beyond the first three words
and I don't want to look it up so I'd rather just type a bunch until I feel
like we have enough text to test.
That should do it!
ENDIN
┌──────────────────────────────────────┐
└──────────────────────────────────────┘
\033[2;F┌──────────────────────────────────────┐
│\033[1;31mWARNING:\033[0m This text runs long and also │\033[K
\033[0m└──────────────────────────────────────┘
\033[3;F┌──────────────────────────────────────┐
│\033[1;31mWARNING:\033[0m This text runs long and also │\033[K
│                                      │\033[K
\033[0m└──────────────────────────────────────┘
\033[4;F┌──────────────────────────────────────┐
│\033[1;31mWARNING:\033[0m This text runs long and also │\033[K
│                                      │\033[K
│The next line is going to have some cu│\033[K
\033[0m└──────────────────────────────────────┘
\033[5;F┌──────────────────────────────────────┐
│\033[1;31mWARNING:\033[0m This text runs long and also │\033[K
│                                      │\033[K
│The next line is going to have some cu│\033[K
│but the scroller should sanitize them │\033[K
\033[0m└──────────────────────────────────────┘
\033[6;F┌──────────────────────────────────────┐
│\033[1;31mWARNING:\033[0m This text runs long and also │\033[K
│                                      │\033[K
│The next line is going to have some cu│\033[K
│but the scroller should sanitize them │\033[K
│Wow!!  I really hope this doesn't brea│\033[K
\033[0m└──────────────────────────────────────┘
\033[7;F┌──────────────────────────────────────┐
│                                      │\033[K
│The next line is going to have some cu│\033[K
│but the scroller should sanitize them │\033[K
│Wow!!  I really hope this doesn't brea│\033[K
│                                      │\033[K
\033[0m└──────────────────────────────────────┘
\033[7;F┌──────────────────────────────────────┐
│The next line is going to have some cu│\033[K
│but the scroller should sanitize them │\033[K
│Wow!!  I really hope this doesn't brea│\033[K
│                                      │\033[K
│There's also a window border on this o│\033[K
\033[0m└──────────────────────────────────────┘
\033[7;F┌──────────────────────────────────────┐
│but the scroller should sanitize them │\033[K
│Wow!!  I really hope this doesn't brea│\033[K
│                                      │\033[K
│There's also a window border on this o│\033[K
│But I'm just gonna put a bunch of line│\033[K
\033[0m└──────────────────────────────────────┘
\033[7;F┌──────────────────────────────────────┐
│Wow!!  I really hope this doesn't brea│\033[K
│                                      │\033[K
│There's also a window border on this o│\033[K
│But I'm just gonna put a bunch of line│\033[K
│scroll.                               │\033[K
\033[0m└──────────────────────────────────────┘
\033[7;F┌──────────────────────────────────────┐
│                                      │\033[K
│There's also a window border on this o│\033[K
│But I'm just gonna put a bunch of line│\033[K
│scroll.                               │\033[K
│Lorem Ipsum Dolor                     │\033[K
\033[0m└──────────────────────────────────────┘
\033[7;F┌──────────────────────────────────────┐
│There's also a window border on this o│\033[K
│But I'm just gonna put a bunch of line│\033[K
│scroll.                               │\033[K
│Lorem Ipsum Dolor                     │\033[K
│I don't actually remember any of Lorem│\033[K
\033[0m└──────────────────────────────────────┘
\033[7;F┌──────────────────────────────────────┐
│But I'm just gonna put a bunch of line│\033[K
│scroll.                               │\033[K
│Lorem Ipsum Dolor                     │\033[K
│I don't actually remember any of Lorem│\033[K
│and I don't want to look it up so I'd │\033[K
\033[0m└──────────────────────────────────────┘
\033[7;F┌──────────────────────────────────────┐
│scroll.                               │\033[K
│Lorem Ipsum Dolor                     │\033[K
│I don't actually remember any of Lorem│\033[K
│and I don't want to look it up so I'd │\033[K
│like we have enough text to test.     │\033[K
\033[0m└──────────────────────────────────────┘
\033[7;F┌──────────────────────────────────────┐
│Lorem Ipsum Dolor                     │\033[K
│I don't actually remember any of Lorem│\033[K
│and I don't want to look it up so I'd │\033[K
│like we have enough text to test.     │\033[K
│That should do it!                    │\033[K
\033[0m└──────────────────────────────────────┘

ENDOUT

do_test(\%test2, width => 40, height => 5, window => '─┐│┘─└│┌');

my %test3 = ( in => <<"ENDIN", out => <<"ENDOUT");
This test is simpler than the last.
But a style will be applied to the scroller
and also the window will be set to
hide when its done.
ENDIN
\033[2mThis test is simpler than the last.\033[0m\033[K
\033[0m\033[1;F\033[2mThis test is simpler than the last.\033[0m\033[K
\033[2mBut a style will be applied to the scroller\033[0m\033[K
\033[0m\033[2;F\033[2mThis test is simpler than the last.\033[0m\033[K
\033[2mBut a style will be applied to the scroller\033[0m\033[K
\033[2mand also the window will be set to\033[0m\033[K
\033[0m\033[3;F\033[2mThis test is simpler than the last.\033[0m\033[K
\033[2mBut a style will be applied to the scroller\033[0m\033[K
\033[2mand also the window will be set to\033[0m\033[K
\033[2mhide when its done.\033[0m\033[K
\033[0m\033[1;F\033[K\033[1;F\033[K\033[1;F\033[K\033[1;F\033[K
ENDOUT

do_test(\%test3, style => "\033[2m", hide => 1);

1;