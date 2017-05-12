#!/home/ivan/bin/perl

use strict;
use warnings;
no warnings qw(uninitialized);
use CGI ();
use Template;
use lib qw(pod-indexing-snapshot/lib pod-indexing-snapshot/);
use Pod::Perldoc;

my $cgi = CGI->new;
print $cgi->header;

my $keyword = $cgi->param('keyword');
my $nocase  = $cgi->param('nocase');

my $pod;
my $err;
my $out;

if (defined $keyword) {
    open my $fh_out, ">", \$out or die;
    open my $fh_err, ">", \$err or die;
    my $old_stdout = *STDOUT;
    *STDOUT = $fh_out;
    *STDERR = $fh_err;
    push @ARGV, qw(-MPod::Perldoc::ToHTML -T -k), $keyword;
    push @ARGV, '-i' if $nocase;
    eval { Pod::Perldoc->run() };
    $err .= $@;
    ($pod) = $out =~ /<body.*?>(.*)<\/body>/s;
    *STDOUT = $old_stdout;
}

my $tt = Template->new;
$tt->process(\*DATA, { 
    pod         => $pod, 
    err         => $err, 
    keyword     => $keyword,
    nocase      => $nocase,
    script_name => $0,
}) or die;

__DATA__
<html>
<head>
<title>perldoc -k demo</title>
<link rel="stylesheet" type="text/css" href="http://search.cpan.org/s/style.css">
<style type="text/css">
    .err { color: red }
    .pod { width: 640px; margin-left: 30px }
    .pod h1 { font-size: 130% }
    .pod h2 { font-size: 120% }
    .pod h3 { font-size: 110% }
    .pod h4 { font-size: 100% }
    .k { color: green; font-family: monospace }
    a.u { color:black; text-decoration: none; }
</style>
</head>
<body>
<div id="header"><a href="/">POD Indexing Project</a></div>
<h1><i>perldoc -k</i> demo</h1>
<form action="/[% script_name %]">
Keyword to search: <input name="keyword" value="[% keyword | html %]">
<input type="submit">
<br><input type="checkbox" id="nocase" name="nocase" value="1" [% 'checked="checked"' IF nocase %]> <label for="nocase">Case-insensitive</label>
</form>
<hr>

[% IF keyword %]
<p>Searched for `<span class="k">[% keyword | html %]</span>'</p>
[% END %]

[% IF err %]
    <div class="err">
    [% err %]
    </div>
[% END %]

[% IF pod %]
<div class="pod">[% pod %]</div>
[% END %]

</body>
</html>
