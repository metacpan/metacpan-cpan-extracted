package Net::SSH::Perl::Key::ECDSA256;
use strict;
use warnings;

use base qw( Net::SSH::Perl::Key::ECDSA );

sub ssh_name { 'ecdsa-sha2-nistp256' }

sub digest { 'SHA256' }

sub siglen { 32 }

sub keygen { shift->SUPER::keygen(256) }

1;
