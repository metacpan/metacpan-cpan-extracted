use strict;
use CGI;
use Template::Test;

my $query = { foo => 'bar'};
test_expect(\*DATA, undef, { query => $query });

__END__
--test--
[% USE StickyQuery -%]
[% FILTER stickyquery param => query -%]
<a href="go.cgi?foo=1">go!</A>
[%- END %]
--expect--
<a href="go.cgi?foo=bar">go!</A>

