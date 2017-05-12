#! perl
use strict;
use warnings FATAL => 'all';
 
use Test::More tests => 2;
use Template::Flute;
 
my ($flute, $out);
 
my $spec = q{<specification>
        <list name="countries" iterator="countries">
                <param name="country_name" />
                <param name="country_code" class="country_name" target="id" />
                <param name="num_spaces" />
                <param name="image" target="src" />
        </list>
</specification>};
 
my $html = q{<ul>
    <li class="countries"><img class="image" src=""><a href="javascript:void(0);"><span class="country_name"></span> (<span class="num_spaces"></span>)</a></li>
</ul>};
 
$flute = Template::Flute->new(specification => $spec,
                                 template => $html,
                                 auto_iterators => 1,
                                 values => {countries => [{country_name => 'Germany',
                                                           num_spaces => 10,
                                                          }]});
 
$out = $flute->process;
 
ok ($out =~ /Germany/, "Test for country name.")
    || diag $out;
 
$flute = Template::Flute->new(specification => $spec,
                                 template => $html,
                                 auto_iterators => 1,
                                 values => {countries => [{country_name => 'Germany',
                                                           country_code => 'DE',
                                                           num_spaces => 10,
                                                          }]});
 
$out = $flute->process;
 
ok ($out =~ /id="DE"/, "Test for country code in element ID.")
    || diag $out;
