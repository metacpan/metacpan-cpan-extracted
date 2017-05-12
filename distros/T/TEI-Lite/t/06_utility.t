# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl inheritance.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok( 'TEI::Lite' ) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @html_fragment = ( qq|<p>Is this a <strong>well-balanced</strong> chunk |,
					  qq|of HTML?</p>|,
					  qq|<p>Test the linking capabilities of HTML - |,
					  qq|<a href="http://www.test.com">|,
					  qq|http://www.test.com</a>.</p>|,
					  qq|<p>We will now test an image tag.|,
					  qq|<img src="test" alt="alternate text"></p>| );


my $converstion = tei_convert_html_fragment( {}, 1, @html_fragment );

my $result = qq|<p>Is this a <hi rend="bold">well-balanced</hi> chunk of HTML?</p><p>Test the linking capabilities of HTML - <xref url="http://www.test.com">http://www.test.com</xref>.</p><p>We will now test an image tag.<figure url="test"><figDesc>alternate text</figDesc></figure></p>|;

ok( $converstion eq $result );
