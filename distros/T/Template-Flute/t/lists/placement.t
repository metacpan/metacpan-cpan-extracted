# Test for list placement
use strict;
use warnings;

use Test::More tests => 1;
use Template::Flute;

my $spec = q{<specification>
<list name="list" iterator="tokens">
<param name="key"/>
</list>
<container name="pagging" value="pagination">
	<value name="pagination" op="hook"/>
</container>
</specification>
};

my $iter = [{key => 'FOO'}, {key => 'BAR'}];

# first test: separator outside the list
my $html = q{
<div class="pagging"><ul class="pagination"></ul></div>
<div class="list"><span class="key">KEY</span></div>
<div class="pagging">XXX<ul class="pagination"></ul></div>
};

my $tf = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {
                                         tokens => $iter,
                                         pagination => '<ul class="hooked"><li>1</li></ul>',
                                        },
                             );

my $out = $tf->process;

like $out, qr/hooked.*FOO.*BAR.*hooked/, "found list and other things";
