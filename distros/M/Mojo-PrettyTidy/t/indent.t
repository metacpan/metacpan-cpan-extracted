use v5.40.0;
use common::sense;
use feature 'signatures';

use Test::More;
use lib 'lib';
use Mojo::PrettyTidy;

my $pt = Mojo::PrettyTidy->new(
                                indent_width => 2,
                                tab_width    => 2,
                                attributes   => 0,
                                columns      => 0,
                                javascript   => 0,
                                perl         => 0, );

sub tidy_is ( $name, $in, $expected ) {
  is $pt->tidy( $in ), $expected, $name;
}

tidy_is(
         'nested div text payload indents and closing tags pull back',
         "<div><div>alpha</div></div>\n",
         join "\n",
         '<div>',
         '  <div>',
         '    alpha',
         '  </div>',
         '</div>', );

tidy_is(
         'solo input tags indent without increasing nesting',
         '<div><input type="text"><input type="hidden"></div>' . "\n",
         join "\n",
         '<div>',
         '  <input type="text">',
         '  <input type="hidden">',
         '</div>', );

tidy_is(
         'picture/img inside anchor indents structurally',
         '<a href="/x"><picture><img src="/x.png"></picture></a>' . "\n",
         join "\n",
         '<a href="/x">',
         '  <picture>',
         '    <img src="/x.png">',
         '  </picture>',
         '</a>', );

tidy_is(
  'table cell pre/code payload indents and table closers pull back',
'<table><tbody><tr><td><pre><code><%= $value %></code></pre></td></tr></tbody></table>'
      . "\n",
  join "\n",
  '<table>',
  '  <tbody>',
  '    <tr>',
  '      <td>',
  '        <pre>',
  '          <code>',
  '            <%= $value %>',
  '          </code>',
  '        </pre>',
  '      </td>',
  '    </tr>',
  '  </tbody>',
  '</table>', );

tidy_is(
         'list items and nested div payload indent structurally',
         '<ul><li><div>one</div></li><li><div>two</div></li></ul>' . "\n",
         join "\n",
         '<ul>',
         '  <li>',
         '    <div>',
         '      one',
         '    </div>',
         '  </li>',
         '  <li>',
         '    <div>',
         '      two',
         '    </div>',
         '  </li>',
         '</ul>', );

done_testing;

