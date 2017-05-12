# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl OMA-DRM.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use lib 'lib/';
use Test::More tests => 4;
BEGIN { use_ok('OMA::Download::DRM') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

    my $data=_readfile('image.jpg');

    my $drm = OMA::Download::DRM->new(
        'key'                 => 'im9aazbjfgsorehf',
        'data'                => \$data,
        'content-type'        => 'image/jpeg',
        'domain'              => 'example.com'
    );
    
    my $res = $drm->combined('display');
	ok(1);
	$res = $drm->separate_content('http://example.com/pics/image239872', 'Chinese Sign');
	ok(2);
    
	$res = $drm->separate_rights('display', count => 3);
	ok(3);
	
sub _readfile {
    my $file = shift;
    my $buffer='';
    my $o='';
    open T, $file or die $!;
        binmode T;
        while(read(T, $buffer, 65536)) {
            $o.= $buffer;
        }
    close T;
    $o;
}
1;