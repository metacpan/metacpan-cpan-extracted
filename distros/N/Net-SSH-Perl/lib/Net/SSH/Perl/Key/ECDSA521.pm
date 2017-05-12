package Net::SSH::Perl::Key::ECDSA521;
use strict;
use warnings;

use base qw( Net::SSH::Perl::Key::ECDSA );

sub ssh_name { 'ecdsa-sha2-nistp521' }

sub digest { 'SHA512' }

sub siglen { 66 }

sub keygen { shift->SUPER::keygen(521) }

1;
