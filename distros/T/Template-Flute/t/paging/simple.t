use strict;
use warnings;
use utf8;
use Test::More tests => 20;
use XML::Twig;
use Template::Flute;
use Data::Dumper;

$Data::Dumper::Maxdepth = 4;

my $spec =<<'SPEC';
<specification>
<list name="accounts" iterator="accounts">
<param name="username" class="link"/>
</list>
<paging name="paging" list="accounts" page_value="page" link_value="uri"
        slide_length="10" page_size="5">
<element type="first" name="first"/>
<element type="last" name="last"/>
<element type="previous" name="previous"/>
<element type="standard" name="standard"/>
<element type="active" name="active"/>
<element type="next" name="next"/>
</paging>
</specification>
SPEC

my $html = <<'HTML';
<div class="paging">
<ul>
<li class="first"><a href="">&lt;&lt; First</a>
<li class="previous"><a href="">Previous</a></li>
<li class="active"><a href="" class="selected">1</a></li>
<li class="standard"><a href="">2</a></li>
<li class="standard"><a href="">3</a></li>
<li class="standard">..........</li>
<li class="standard"><a href="">23</a></li>
<li class="standard"><a href="">24</a></li>
<li class="standard"><a href="">25</a></li>
<li class="next"><a href="">Next</a></li>
<li class="last"><a href="">Last &gt;&gt;</a></li>
</ul>
</div>
<ul>
<li class="accounts">
<span class="username">
<a class="link">jdoe</a>
</span>
</li>
</ul>
HTML

test_paging($html, $spec);



$html = <<'HTML';
<ul>
<li class="accounts">
<span class="username">
<a class="link">jdoe</a>
</span>
</li>
</ul>
<div class="paging">
<ul>
<li class="first"><a href="">&lt;&lt; First</a>
<li class="previous"><a href="">Previous</a></li>
<li class="active"><a href="" class="selected">1</a></li>
<li class="standard"><a href="">2</a></li>
<li class="standard"><a href="">3</a></li>
<li class="standard">..........</li>
<li class="standard"><a href="">23</a></li>
<li class="standard"><a href="">24</a></li>
<li class="standard"><a href="">25</a></li>
<li class="next"><a href="">Next</a></li>
<li class="last"><a href="">Last &gt;&gt;</a></li>
</ul>
</div>
HTML

test_paging($html, $spec);


sub test_paging {
    my ($html, $spec) = @_;
    my @accounts;
    for my $i (1..20) {
        push @accounts, { username => 'user-' . $i };
    }
    my $flute = Template::Flute->new(template => $html,
                                     specification => $spec,
                                     iterators => {
                                                   accounts => \@accounts,
                                                  },
                                     values => {
                                                accounts => \@accounts,
                                                page => 1,
                                                uri => 'page',
                                               });
    my $output = $flute->process;
    like $output, qr{<li class="standard"><a href="/page/2">2</a>}, "Found page 2";
    like $output, qr{<li class="active"><a class="selected" href="">1</a></li>}, "Found page 1 active";
    like $output, qr{user-5}, "User 5 found";
    unlike $output, qr{user-6}, "User 6 not found";
    unlike $output, qr{user-11}, "User 11 not found";

    $flute = Template::Flute->new(template => $html,
                                  specification => $spec,
                                  iterators => {
                                                accounts => \@accounts,
                                               },
                                  values => {
                                             accounts => \@accounts,
                                             page => 2,
                                             uri => 'page',
                                            });
    $output = $flute->process;
    like $output, qr{<li class="standard"><a href="/page">1</a>}, "Found inactive page 1";
    like $output, qr{<li class="active"><a class="selected" href="">2</a></li>}, "Found page 2 active";
    like $output, qr{user-6}, "User 6 found";
    unlike $output, qr{user-5}, "User 5 not found";
    unlike $output, qr{user-11}, "User 11 not found";
}
