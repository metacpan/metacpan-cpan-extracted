#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use Test::More;
use Monitoring::Sneck::Checks;

my $data = $FindBin::Bin . '/data';
my $run  = sub {
	my ( $check, @args ) = @_;
	return Monitoring::Sneck::Checks->run( check => $check, args => \@args );
};

# file_mode, owned by whoever checked this out, its mode set as each case needs
my $file = $data . '/file_mode/secret';
my ( $uid, $gid ) = ( stat($file) )[ 4, 5 ];
my $user  = getpwuid($uid) // $uid;
my $group = getgrgid($gid) // $gid;
chmod( 0600, $file ) or die($!);
my $return = $run->( 'file_mode', '-f', $file, '-m', '0600', '-o', $user );
is( $return->{code},   0,                                                                  'mode and owner' );
is( $return->{stdout}, 'FILE_MODE OK - ' . $file . ' 0600 ' . $user . ':' . $group . "\n", 'output' );
is( $run->( 'file_mode', '-f', $file, '-M', '0640', '-o', $uid, '-g', $gid )->{code}, 0,
	'--max-mode allows less, IDs' );
chmod( 0644, $file );
$return = $run->( 'file_mode', '-f', $file, '-M', '0640', '-m', '0600' );
is( $return->{code}, 2, 'too open is CRITICAL' );
is(
	$return->{stdout},
	'FILE_MODE CRITICAL - '
		. $file
		. ' 0644 '
		. $user . ':'
		. $group
		. ", mode is not 0600, mode is more than 0640\n",
	'and says how'
);
like( $run->( 'file_mode', '-f', $file, '-o', 0 )->{stdout}, qr/, owner is not 0\n\z/, 'wrong owner' ) if $uid != 0;
# the sticky bit, on the directory holding it, put back after
my $sticky = $data . '/file_mode';
my $mode   = ( stat($sticky) )[2] & 07777;
chmod( 01777, $sticky );
is( $run->( 'file_mode', '-f', $sticky, '-m', '1777' )->{code}, 0, 'sticky directory' );
chmod( $mode, $sticky );
like( $run->( 'file_mode', '-f', $sticky . '/nope', '-m', '0600' )->{stdout},
	qr/\AFILE_MODE CRITICAL - \S+nope, No such file/, 'missing' );
is( $run->( 'file_mode', '-f', $sticky . '/nope', '-m', '0600', '-i' )->{code}, 0, 'missing with -i' );

foreach my $bad ( [ '-f', $file ], [ '-f', $file, '-m', '644x' ], [ '-f', $file, '-o', 'no-such-user-here' ] ) {
	is( $run->( 'file_mode', @{$bad} )->{code}, 3, 'bad args, ' . join( ' ', @{$bad} ) );
}

# sshd_config, the Include in it found under the directory it is in
my $sshd = $data . '/sshd_config/sshd_config';
$return = $run->(
	'sshd_config',      '-f', $sshd, '-e', 'PermitRootLogin=no', '-e', 'passwordauthentication=no', '-e',
	'MaxAuthTries=3|4', '-e', 'Ciphers=chacha20-poly1305@openssh.com,aes256-gcm@openssh.com'
);
is( $return->{code}, 0, 'settings, an include winning, case, =, and quotes' );
is(
	$return->{stdout},
	"SSHD_CONFIG OK - PermitRootLogin no, passwordauthentication no, MaxAuthTries 4, Ciphers chacha20-poly1305\@openssh.com,aes256-gcm\@openssh.com\n",
	'output'
);
$return = $run->( 'sshd_config', '-f', $sshd, '-e', 'MaxAuthTries=3', '-e', 'X11Forwarding=no' );
is( $return->{code}, 2, 'wrong and not set are CRITICAL' );
is( $return->{stdout}, "SSHD_CONFIG CRITICAL - MaxAuthTries is 4, not 3, X11Forwarding is not set\n",
	'Match left out' );
is( $run->( 'sshd_config', '-f', $sshd, '-e', 'X11Forwarding=no', '-d', 'X11Forwarding=no' )->{stdout},
	"SSHD_CONFIG OK - X11Forwarding no by default\n", '--default' );
like(
	$run->( 'sshd_config', '-f', $sshd, '-e', 'X11Forwarding=no', '-d', 'X11Forwarding=yes' )->{stdout},
	qr/X11Forwarding is yes by default, not no/,
	'--default not allowed'
);
like(
	$run->( 'sshd_config', '-f', $sshd, '-I', $data . '/nowhere', '-e', 'PermitRootLogin=no' )->{stdout},
	qr/\ASSHD_CONFIG CRITICAL - PermitRootLogin is yes, not no\n\z/,
	'--include-dir, under which the include is not found'
);
like( $run->( 'sshd_config', '-f', $data . '/nope', '-e', 'A=b' )->{stdout},
	qr/\ASSHD_CONFIG CRITICAL - can not read/, 'missing' );
like(
	$run->( 'sshd_config', '-f', $data . '/sshd_config/loop', '-e', 'A=b' )->{stdout},
	qr/Include goes over 16 deep/,
	'Include loop'
);
is( $run->( 'sshd_config', '-f', $sshd )->{code}, 3, 'no --expect' );
is( $run->( 'sshd_config', '-f', $sshd, '-e', 'PermitRootLogin' )->{code}, 3, 'bad --expect' );

done_testing();
