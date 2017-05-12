use strict;
use warnings;
use Test::Base;
use Template;

plan tests => 1*blocks;

filters +{
    input => [qw/tt/],
};

run_is input => 'expected';

sub tt {
    my $src = shift;
    my $tt = Template->new;
    $tt->process( \$src, {}, \my $out) or die $tt->error;
    $out;
}

__END__

===
--- input
[% USE HTMLMobileJp -%]
[% HTMLMobileJp.gps_a({carrier => 'I', is_gps => 1, callback_url => 'http://example.com/'}) %]Send Location Info</a>
--- expected
<a href="http://example.com/" lcs="lcs">Send Location Info</a>

===
--- input
[% USE HTMLMobileJp -%]
[% HTMLMobileJp.ezweb_object({
    url         => 'http://aa.com/movie.amc',
    mime_type   => 'application/x-mpeg',
    copyright   => 'no',
    standby     => 'ダウンロード',
    disposition => 'devdl1q',
    size        => '119065',
    title       => 'サンプル動画'
}) -%]
--- expected
<object data="http://aa.com/movie.amc" type="application/x-mpeg" copyright="no" standby="ダウンロード">
<param name="disposition" value="devdl1q" valuetype="data" />
<param name="size" value="119065" valuetype="data" />
<param name="title" value="サンプル動画" valuetype="data" />
</object>

