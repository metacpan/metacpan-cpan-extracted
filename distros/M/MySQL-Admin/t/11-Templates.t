use strict;
use warnings;
my $template = qq(
[menuHeader]
<table align="center" border="0" cellpadding="0" cellspacing="0" summary="layoutMenu" width="100%" >
<tr>
<td class="underline">
<table align="center" border="0" cellpadding="0" cellspacing="0" summary="layoutMenu" >
<tr>
[/menuHeader]
[links]
<td width="10"><img src="/style/[style/]/tabwidget/mlU.png" alt="" title="[title/]" border="0" align="middle"/></td>
<tdclass="under" align="left">[text/]</td>
<td width="10" class="underR"></td>
[/links]
[currentLink]
<td width="10"><img src="/style/[style/]/tabwidget/mlO.png" alt="" title="[title/]" border="0" align="middle" /></td>
<td class="over" align="left" align="middle">[text/]</td>
<td width="10" class="overR"></td>
[/currentLink]
[menuFooter]
</tr>
</table>
</td>
</tr>
</table>
[/menuFooter]
[bheader]
<table align="center" border="0" cellpadding="0" cellspacing="0" summary="layoutMenu" width="100%" >
<tr align="left" >
<td  style=" background-position:left;background-image:url('/style/[style/]/window/wlbg.png'); background-repeat:repeat-y;"></td>
<td  align="left"  style="background-image:url('/style/[style/]/window/background.png');">
[/bheader]
[bfooter]
</td>
<td width="5" align="left" style=" background-position:left;background-image:url('/style/[style/]/window/wrbg.png');background-repeat:repeat-y;"></td>
</tr>
<tr align="left">
<td  width="5"><img src="/style/[style/]/window/wlubg.png" alt="" width="5" height="2" border="0"></td>
<td style=" background-image:url('/style/[style/]/window/wdcubg.png'); background-repeat:repeat-x;"></td>
<td><img src="/style/[style/]/window/wrubg.png" alt="" width="5" height="2" border="0"></td>
</tr>
</table>
[bfooter/]
);
open OUT, ">./test.html" or die " $!\n";
print OUT$template;
close OUT;
my %template = (
                path     => "./",
                style    => "",
                template => "test.html",
               );
my @data = (
            {
             name => 'menuHeader',
            },
            {
             name  => 'links',
             style => "mysql",
             text  => "Link",
             title => "Link"
            },
            {name => 'menuFooter'},
           );
use Template::Quick;
my $temp = new Template::Quick();
$temp->initTemplate(\%template);
my $t1 = $temp->initArray(\@data);
use Test::More tests => 3;
ok(length($t1) > 0);
ok(length($t1) < length($template));
my $t2 = initTemplate(\%template, \@data);
ok(length($t1) == length($t2));
unlink 'test.html' or warn "Could not unlink test.html: $!";

1;
