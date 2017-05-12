#! /usr/bin/perl -w

use strict;
use Test::More tests => 4;

my $key = q{---- BEGIN SSH2 PUBLIC KEY ----
Subject: sshuser
Comment: "2048-bit rsa, sshuser@host001, Wed Dec 09 2009 13:26:29 -060\
0"
AAAAB3NzaC1yc2EAAAADAQABAAABAQCpk7XrNvKvrM6whhspMfFCv1LouTJHwVRNiAi2oT
BxV0kng1TFjbHRo+gVnPG0c0bh1xUJ5ZCKRnGyHKkTqRocoeynnWT/uTfOtnClfCbSSnRj
65WP9JYrYbrkGJs00aYz8zvl5pwKbAaBMlxo+0fpr8Bu06O3AcLWm1P9DqIAkkrXuk7lc8
YliW94gxnycXJCnuZhVHvT2Hrv3zUmo0jpIGemMoSM/KJKslYD+7saEhYU/zC3DWvoeMJo
G0XgtYbPhOOoMrtF3BChqj6ZJPdzkwF/gxuWFh7UKoO+7CJbmKm+HPFtw46YdFJ/bB8A+l
z5gHSoXoJArAvUinRsaw79
---- END SSH2 PUBLIC KEY ----
};

my $key_openssh = q{ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpk7XrNvKvrM6whhspMfFCv1LouTJHwVRNiAi2oTBxV0kng1TFjbHRo+gVnPG0c0bh1xUJ5ZCKRnGyHKkTqRocoeynnWT/uTfOtnClfCbSSnRj65WP9JYrYbrkGJs00aYz8zvl5pwKbAaBMlxo+0fpr8Bu06O3AcLWm1P9DqIAkkrXuk7lc8YliW94gxnycXJCnuZhVHvT2Hrv3zUmo0jpIGemMoSM/KJKslYD+7saEhYU/zC3DWvoeMJoG0XgtYbPhOOoMrtF3BChqj6ZJPdzkwF/gxuWFh7UKoO+7CJbmKm+HPFtw46YdFJ/bB8A+lz5gHSoXoJArAvUinRsaw79 "2048-bit rsa, sshuser@host001, Wed Dec 09 2009 13:26:29 -0600"
};

use_ok('Parse::SSH2::PublicKey');


my @keys = Parse::SSH2::PublicKey->parse( $key );
is( @keys, 1, "Correct number of keys parsed from input" );

my $k = $keys[0];
is( $k->secsh, $key, "SECSH output format" );
is( $k->openssh, $key_openssh, "OpenSSH output format" );


