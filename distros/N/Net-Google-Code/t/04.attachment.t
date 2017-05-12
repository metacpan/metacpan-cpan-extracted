use strict;
use warnings;

use Test::More tests => 7;

use Test::MockModule;
use Net::Google::Code::Issue::Attachment;
my $attachment = Net::Google::Code::Issue::Attachment->new( project => 'test' );
isa_ok( $attachment, 'Net::Google::Code::Issue::Attachment', '$attachment' );


my $content;
{
        local $/;
        $content = <DATA>;
}

my $mock = Test::MockModule->new('Net::Google::Code::Issue::Attachment');
$mock->mock(
    'fetch',
    sub { 'ok' }
);

$attachment->parse( $content );

my %info = (
    url =>'http://net-google-code.googlecode.com/issues/attachment?aid=108689494720583752&name=%2Ftmp%2Fa',
    name => '/tmp/a',
    size => '3 bytes',
    id   => '108689494720583752',
    content_type => 'text/plain',
    content => 'ok',
);

for my $item ( keys %info ) {
    if ( defined $info{$item} ) {
        is ( $attachment->$item, $info{$item}, "$item is extracted" );
    }
    else {
        ok( !defined $attachment->$item, "$item is not defined" );
    }
}


__DATA__
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
