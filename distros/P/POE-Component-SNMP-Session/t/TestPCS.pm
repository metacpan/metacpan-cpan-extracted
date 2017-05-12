package TestPCS;

use base qw/Exporter/;

our @EXPORT = qw/check_done get_sent get_seen set_sent set_seen/;

# $POE::Component::SNMP::Session::Dispatcher::DEBUG = 1;

sub get_sent { ++$_[0]->{get_sent} }

sub get_seen { ++$_[0]->{get_seen} }

sub set_sent { ++$_[0]->{set_sent} }

sub set_seen { ++$_[0]->{set_seen} }

sub check_done {
    no warnings "uninitialized";
    $_[0]->{set_sent} == $_[0]->{set_seen}
	and
	$_[0]->{get_sent} == $_[0]->{get_seen}
}

1;
