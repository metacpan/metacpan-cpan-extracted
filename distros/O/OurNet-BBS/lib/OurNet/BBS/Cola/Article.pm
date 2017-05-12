# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/Cola/Article.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 3815 $ $DateTime: 2003/01/25 00:54:33 $

package OurNet::BBS::Cola::Article;

use if $OurNet::BBS::Encoding, 'encoding' => 'big5', STDIN => undef, STDOUT => undef;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::Article/;
use fields qw/_ego _hash/;
use OurNet::BBS::Base (
    '$HEAD_REGEX' => qr/[^\s]+ 作者 [^\s]+ ([^ \(]+)\s?(?:\((.+?)\) )?[^\015\012]*\015\012[^\s]+ 標題 [^\s]+ (.*?)\s*\x1b\[m\015\012[^\s]+ 時間 [^\s]+ (.+?)\s+\x1b\[m\015\012.+\015\012/,
);

sub writeok { 0 };
sub readok { 1 };

1;
