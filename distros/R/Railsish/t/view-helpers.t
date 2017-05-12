#!/usr/bin/env perl -w
use strict;
use Test::More tests => 6;

use Railsish::ViewHelpers;

like javascript_include_tag("foo"),
    qr{<script .*src="/javascripts/foo.js"></script>};
    
like javascript_include_tag("foo.js"),
    qr{<script .*src="/javascripts/foo.js"></script>};

like javascript_include_tag("/there/foo"),
    qr{<script .*src="/there/foo.js"></script>};    

like javascript_include_tag("/there/foo.js"),
    qr{<script .*src="/there/foo.js"></script>};

like javascript_include_tag("http://there.com/foo.js"),
    qr{<script .*src="http://there.com/foo.js"></script>};

like javascript_include_tag("http://there.com/foo"),
    qr{<script .*src="http://there.com/foo"></script>};
    
