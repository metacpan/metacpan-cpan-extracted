use strict;
use warnings;

package MyApp::Templates;

use base 'Template::Declare';
use Template::Declare::Tags qw/ HTML /;
my $time;

template main => sub {
    $time = time;
    caption { attr { id => 'a' } }
    link {};
    table {
        row {
            cell { "Hello, world!" }
        };
        row {
            cell { datetime { $time } };
        };
    }
    img { attr { src => 'cat.gif' } }
    label {}
    canvas { attr { id => 'foo' } }
};

package main;
use Test::More tests => 4;
use Template::Declare::TagSet::HTML;

my $tagset = Template::Declare::TagSet::HTML->new();
ok $tagset->can_combine_empty_tags('img'), '<img />';
ok !$tagset->can_combine_empty_tags('label'), '<label></label>';
ok !$tagset->can_combine_empty_tags('caption'), '<caption></caption>';

Template::Declare->init( dispatch_to => ['MyApp::Templates']);
my $out = Template::Declare->show('main') . "\n";
is $out, <<_EOC_;

<caption id="a"></caption>
<link />
<table>
 <tr>
  <td>Hello, world!</td>
 </tr>
 <tr>
  <td>
   <time>$time</time>
  </td>
 </tr>
</table>
<img src="cat.gif" />
<label></label>
<canvas id="foo"></canvas>
_EOC_

