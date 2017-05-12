package SNMPMonitor::Plugin::PluginTemplate;
use common::sense;

use NetSNMP::ASN     (':all');
use parent qw(SNMPMonitor::Plugin);

sub set_plugin_oid { '0.0.0' };

sub monitor {
    my $self = shift;
    my $request = shift; 
    my $FH = shift || 'STDERR';

    print $FH "--> Request in: " . $self->name . "\n";
    print $FH "--> reporting 'Test Successful'\n";

    $request->setValue(ASN_OCTET_STR, "Test Successful");

}
    
1;
__END__
