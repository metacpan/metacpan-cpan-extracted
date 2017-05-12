#!/usr/bin/env perl

use strict;
use Template::Test;

test_expect(\*DATA);

__END__
--test--
[% USE Filter.Minify.JavaScript -%]
[% FILTER minify_js %]
   $(document).ready(
       function() {
           alert('hello world!');
       }
   );
[% END %]
--expect--
$(document).ready(function(){alert('hello world!');});

