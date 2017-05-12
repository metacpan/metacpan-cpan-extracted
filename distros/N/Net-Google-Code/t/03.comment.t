use strict;
use warnings;

use Test::More tests => 9;

use Net::Google::Code::Issue::Comment;
use Test::MockModule;
my $comment =
  Net::Google::Code::Issue::Comment->new( project => 'net-google-code' );
isa_ok( $comment, 'Net::Google::Code::Issue::Comment', '$comment' );

my $mock = Test::MockModule->new('Net::Google::Code::Issue::Attachment');
$mock->mock(
    'fetch',
    sub { '' }
);

my $content;
{
        local $/;
        $content = <DATA>;
}

use HTML::TreeBuilder;
my $tree = HTML::TreeBuilder->new;
$tree->parse_content($content);
$tree->elementify;

$comment->parse( $tree );

my %info = (
    sequence => 1,
    author   => 'sunnavy',
    date     => '2009-05-12T09:29:18',
    content  => undef,
);

for my $item ( keys %info ) {
    if ( defined $info{$item} ) {
        is( $comment->$item, $info{$item}, "$item is extracted" );
    }
    else {
        ok( !defined $comment->$item, "$item is not defined" );
    }
}

my $updates = { labels => ['-Priority-Medium'], };

is_deeply( $updates, $comment->updates, 'updates are extracted' );

is( scalar @{$comment->attachments}, 2, 'attachments are extracted' );
is( $comment->attachments->[0]->name, '/tmp/a', '1st attachment' );
is( $comment->attachments->[1]->name, '/tmp/b', '2nd attachment' );

__DATA__
<td class="vt issuecomment">
 
 
 
 <span class="author">Comment <a name="c1"
 href="#c1">1</a>
 by
 <a style="white-space: nowrap" href="/u/sunnavy/">sunnavy</a></span>,
 <span class="date" title="Tue May 12 02:29:18 2009">May 12, 2009</span>
<pre>

<i>(No comment was entered for this change.)</i>
</pre>
 
 <div class="attachments">
 
 
 




 <table cellspacing="3" cellpadding="2" border="0">
 <tr><td width="20">
 <a href="http://net-google-code.googlecode.com/issues/attachment?aid=108689494720583752&amp;name=%2Ftmp%2Fa" target="new">
 <img width="15" height="15" src="/hosting/images/paperclip.gif" border="0" >
 </a>
 </td>

 <td style="min-width:16em" valign="top">
 
 <b >/tmp/a</b>
 <br>
 3 bytes
 
 
 &nbsp; <a href="http://net-google-code.googlecode.com/issues/attachment?aid=108689494720583752&amp;name=%2Ftmp%2Fa">Download</a>
 
 </td>
 
 </tr>
 
 </table>


 
 
 




 <table cellspacing="3" cellpadding="2" border="0">
 <tr><td width="20">
 <a href="http://net-google-code.googlecode.com/issues/attachment?aid=7462239237569252501&amp;name=%2Ftmp%2Fb" target="new">
 <img width="15" height="15" src="/hosting/images/paperclip.gif" border="0" >
 </a>
 </td>
 <td style="min-width:16em" valign="top">
 
 <b >/tmp/b</b>

 <br>
 5 bytes
 
 
 &nbsp; <a href="http://net-google-code.googlecode.com/issues/attachment?aid=7462239237569252501&amp;name=%2Ftmp%2Fb">Download</a>
 
 </td>
 
 </tr>
 
 </table>


 
 </div>

 
 
 <div class="updates">
 <div class="round4"></div>
 <div class="round2"></div>
 <div class="round1"></div>
 <div class="box-inner">
 <b>Labels:</b> -Priority-Medium<br>
 </div>

 <div class="round1"></div>
 <div class="round2"></div>
 <div class="round4"></div>
 </div>
 
 </td>

