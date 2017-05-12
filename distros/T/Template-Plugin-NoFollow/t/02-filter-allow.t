use strict;
use warnings;
use Template;
use Test::More tests => 3;

###############################################################################
# Check that specifying "allow" lets certain things through without being
# marked as "nofollow".
check_allow: {
    my $template = qq{
[%- USE NoFollow(allow=>'www.example.com') -%]
[% FILTER nofollow %]
<a href="http://www.example.com/">example</a>
<a href="http://www.google.com/">google</a>
[%- END %]
};
    my $expected = qq{
<a href="http://www.example.com/">example</a>
<a rel="nofollow" href="http://www.google.com/">google</a>
};
    my $output;
    my $tt = Template->new();
    $tt->process( \$template, undef, \$output );
    is( $output, $expected, "'allow' works" );
}

###############################################################################
# Check that an "allow" list works fine too.
check_allow_list: {
    my $template = qq{
[%- USE NoFollow(allow=>['www.example.com','www.foobar.com']) -%]
[% FILTER nofollow %]
<a href="http://www.example.com/">example</a>
<a href="http://www.foobar.com/index.html">foobar</a>
<a href="http://www.google.com/">google</a>
[%- END %]
};
    my $expected = qq{
<a href="http://www.example.com/">example</a>
<a href="http://www.foobar.com/index.html">foobar</a>
<a rel="nofollow" href="http://www.google.com/">google</a>
};
    my $output;
    my $tt = Template->new();
    $tt->process( \$template, undef, \$output );
    is( $output, $expected, "'allow' list works" );
}

###############################################################################
# Check regex support.
check_allow_regex: {
    my $template = qq{
[%- USE NoFollow(allow=>['^http://www.example.com']) -%]
[% FILTER nofollow %]
<a href="http://www.example.com/">HTTP</a>
<a href="ftp://www.example.com/">FTP</a>
<a href="http://spoof.example.com/http://www.example.com">spoof</a>
[%- END %]
};
    my $expected = qq{
<a href="http://www.example.com/">HTTP</a>
<a rel="nofollow" href="ftp://www.example.com/">FTP</a>
<a rel="nofollow" href="http://spoof.example.com/http://www.example.com">spoof</a>
};
    my $output;
    my $tt = Template->new();
    $tt->process( \$template, undef, \$output );
    is( $output, $expected, "regex support" );
}
