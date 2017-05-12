#!/usr/bin/perl

use strict;
use warnings;

$|=0;

print <<"EOF";
Status: 200
Content-Type: text/html

<html>
<head>
<style>body {background-color: red; color: yellow; font-weight: 800;}</style>
</head>
<body>
<p>Load Status: <span id="xx">loading -- please wait</span><!-- FlushHead -->
</p>
<p>content</p>
EOF

sleep 2;

if ($main::app) {
    local $"=", ";
    print "<p>Apps:</p>\n<ul>";
    for (sort keys %{$main::app->{_compiled}}) {
        print "    <li>$_</li>\n";
    }
    print "</ul>\n";
}

print <<"EOF";
<p>more content</p>
<script>
  document.getElementById('xx').innerHTML='loaded';
  document.body.style.backgroundColor='green';
</script>
</body>
</html>
EOF
