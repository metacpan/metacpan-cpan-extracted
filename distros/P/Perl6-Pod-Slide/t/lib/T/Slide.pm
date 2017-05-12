#===============================================================================
#
#  DESCRIPTION:  Test Slide formatter
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id$

package T::Slide;
use TBase;
use base 'TBase';
use strict;
use warnings;
use Test::More;

sub t_DESCRIPTION : Test {
    my $t = shift;
    my $y = <<TXT;
=for DESCRIPTION
= :title<Title> :pubdate('15.04.2010')
= :author('Aliaksandr')
TXT
    my $r = TBase::parse_to_latex($y, headers=>0);
is $r,
'\title{Title}
\author{Aliaksandr}
\date{15.04.2010}
';
}

sub t_SLIDE : Test {
    my $t = shift;
    my $x = TBase::parse_to_latex ( <<TXT, headers=>0);
=begin Slide :title("Test title")
Test text B<wetwetwe>
=end Slide
TXT
is $x, '\begin{frame}[fragile]
\frametitle{Test title}
Test text \textbf{wetwetwe}

\end{frame}
'
}

sub t_03_code_lang : Test {
    my $t = shift;
    my $x = TBase::parse_to_latex ( <<'TXT', headers=>0);
=for code :lang('Perl')
  my $a;
TXT
    ok $x =~ /\\addCode{.*}{Perl}/g;
}

sub t_04_code_I : Test {
    my $t = shift;
    my $x = TBase::parse_to_latex ( <<'TXT', headers=>0);
Test I<sd> B<dsf I<s> d>
TXT
    is $x,'Test \emph{sd} \textbf{dsf \emph{s} d}

';
}

sub t_04_pause : Test {
    my $t = shift;
    my $x = TBase::parse_to_latex ( <<'TXT', headers=>0);
=Pause
TXT
    #diag $x; exit;
    is $x,'\pause
';
}
sub t_04_image: Test {
    my $t = shift;
    my $x = TBase::parse_to_latex ( <<'TXT', headers=>0);
=for Image :width('2.5in')
img/pdp1_a.jpg
TXT
    #diag $x; exit;
ok $x =~ m%width=2.5in .* img/pdp1_a.jpg%x ;
}

sub t_04_Latex : Test {
    my $t = shift;
    my $x = TBase::parse_to_latex ( <<'TXT', headers=>0);
=Latex
\medskip

TXT
    ok $x =~ m%\\medskip%
}


sub t_05_items : Test(5) {
    my $t = shift;
    my $x = TBase::parse_to_latex ( <<'TXT', headers=>0);
=item test1
=item test2
TXT
    ok $x =~ m%itemize%, '=item';
    $x = TBase::parse_to_latex ( <<'TXT', headers=>0);
=item # test1
=item # test2
TXT
    ok $x =~ m%enumerate%,'=item #';
    $x = TBase::parse_to_latex ( <<'TXT', headers=>0);
=defn test1
Ok1
=defn test2
ok2
TXT
    ok $x =~ m%description%, '=defn';
    ok $x =~ m%\[test1\]%, '=defn Term';
    $x = TBase::parse_to_latex ( <<'TXT', headers=>0);
=for item :pause
test1
=item test2
TXT
    ok $x =~ m%\\pause%, '=for item :pause';
}

sub t_0464_Latex  {
    my $t = shift;
    my $x = TBase::parse_to_latex ( <<'TXT', headers=>1);
=begin Slide :title<asdasd>
=Latex
\medskip
=end Slide
TXT
    diag $x; exit;
    ok $x =~ m%\\medskip%
}

1;


