
package Net::DHCP::Control::ServerHandle;
use Net::DHCP::Control::Generic;
use Data::Dumper;
use Net::DHCP::Control;
@ISA = 'Net::DHCP::Control::Generic';

%OPTS = (new => { host => '127.0.0.1',
		  port => scalar(Net::DHCP::Control::DHCP_PORT()),
		  key_name => undef,
		  key_type => undef,
		  key => undef,
		},
	);
	 

sub new {
    my ($base, %opts) = @_;
    my $class = ref $base || $base;
    $base->validate_options(\%opts);

    my $authenticator;

    if (exists $opts{key}) {
	$authenticator =
	    Net::DHCP::Control::new_authenticator(@opts{qw(key_name key_type key)})
	    or return;
    }
    $handle = Net::DHCP::Control::connect($opts{host}, $opts{port}, $authenticator)
	or return;
    return $handle;
}


1;
