use Test::More 0.98;

use_ok( 'Net::MAC::Vendor' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Something that works
subtest works => sub {
my $html = <<"HTML";
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<HTML><HEAD><TITLE>Search Results: IEEE Standards OUI Public Database</TITLE>
<LINK REV=MADE HREF="mailto:w.pienciak%40ieee.org">
</HEAD><BODY BGCOLOR="#fffff0"> <p>Here are the results of your search through the public section
        of the IEEE Standards OUI database report for <b>00-0D-07</b>:

<hr><p><pre><b>00-0D-07</b>   (hex)             Calrec Audio Ltd
000D07     (base 16)            Calrec Audio Ltd
                                Nutclough Mill
                                Hebden Bridge West Yorkshire HX7 8EZ
                                UNITED KINGDOM
</pre></p>
        <hr><p>Your attention is called to the fact that the firms and numbers
        listed may not always be obvious in product implementation.  Some
        manufacturers subcontract component manufacture and others include
        registered firms' OUIs in their products.</p>
        <hr>
        <h5 align=center>
        <a href="/index.html">[IEEE Standards Home Page]</a> --
        <a href="/search.html">[Search]</a> --
        <a href="/cgi-bin/staffmail">[E-mail to Staff]</a> <br>
        <a href="/c.html">Copyright &copy; 2004 IEEE</a></h5>
HTML

my $expected_oui = <<"OUI";
00-0D-07   (hex)             Calrec Audio Ltd
000D07     (base 16)            Calrec Audio Ltd
                                Nutclough Mill
                                Hebden Bridge West Yorkshire HX7 8EZ
                                UNITED KINGDOM
OUI

{
my $oui = Net::MAC::Vendor::extract_oui_from_html( $html, '00-0D-07' );
is( $oui, $expected_oui, "Extracted OUI" );
}


};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Something that works
subtest undefined => sub {
	local *STDERR;
	open STDERR, ">", \my $output;
	my $oui = Net::MAC::Vendor::extract_oui_from_html( '' );
	is( $oui, undef, "Get back undef for bad HTML" );
	};

done_testing();
