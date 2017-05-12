
package RayApp::String;

use strict;
use warnings;

$RayApp::String::VERSION = '1.160';
		
use Digest::MD5 ();
use base 'RayApp::Source';

sub new {
	my $class = shift;
	my %opts = @_;

	my $md5_hex;
	if (defined $opts{content}) {
		$md5_hex = Digest::MD5::md5_hex($opts{content});
	} else {
		$md5_hex = Digest::MD5::md5_hex('');
	}

	return bless {
		uri => "md5:$md5_hex",
		content => $opts{content},
		md5_hex => $md5_hex,
		rayapp => $opts{rayapp},
	}, $class;
}

1;

