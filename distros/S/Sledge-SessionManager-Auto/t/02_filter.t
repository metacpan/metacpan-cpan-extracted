use strict;
use warnings;
use Test::Base;
BEGIN {
    eval q[use Sledge::TestPages;];
    plan skip_all => "Sledge::TestPages required for testing base" if $@;
};
use t::TestPages;

plan tests => 1*blocks;

filters {
    input => [qw/yaml/],
};

run {
    my $block = shift;

    local %ENV = (
        %{$block->input},
        %ENV,
    );

    no strict 'refs';
    local *{"t::TestPages::dispatch_test"} = sub {}; ## no critic

    my $pages = t::TestPages->new;
    $pages->dispatch('test');

    ok($pages->output =~ /@{[ $block->expected]}/, $pages->output);
};

__END__
=== agent is pc (use cookie)
--- input
HTTP_USER_AGENT: Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)
--- expected chomp
<a href="/foo">bar</a>
=== agent is mobile (use query)
--- input
HTTP_USER_AGENT: KDDI-HI31 UP.Browser/6.2.0.5 (GUI) MMP/2.0
--- expected chomp
<a href="/foo\?sid=(.+)">bar</a>
=== agent is mobile ez (use mobile_id)
--- input
HTTP_USER_AGENT: KDDI-HI31 UP.Browser/6.2.0.5 (GUI) MMP/2.0
HTTP_X_UP_SUBNO: SID_EZ_MOBILE_ID
--- expected chomp
<a href="/foo">bar</a>
=== agent is mobile softbank (use mobile_id)
--- input
HTTP_USER_AGENT: J-PHONE/3.0/J-SH07
HTTP_X_JPHONE_UID: SID_SB_MOBILE_ID
--- expected chomp
<a href="/foo">bar</a>
