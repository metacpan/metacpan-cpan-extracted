use strict;
use warnings;
use Test::More tests => 13;
use File::Spec;
use File::Basename qw(dirname);
use_ok qw(SOAP::WSDL);

my $path = File::Spec->rel2abs(dirname( __FILE__ ) );
$path =~s{\\}{/}xmsg;   # fix for windows
my $soap = SOAP::WSDL->new();
$soap->wsdl("file://$path/WSDL_NOT_FOUND.wsdl");

eval { $soap->wsdlinit() };
like $@, qr{ does \s not \s exist }x, 'does not exist';

eval { $soap = SOAP::WSDL->new(
    wsdl => "file://$path/WSDL_NOT_FOUND.wsdl");
};
like $@, qr{ does \s not \s exist }x, 'does not exist (constructor)';

$soap = SOAP::WSDL->new();
$soap->wsdl( "file://$path/WSDL_EMPTY_DEFINITIONS.wsdl");
eval { $soap->wsdlinit() };
like $@, qr{ unable \s to \s extract \s schema \s from \s WSDL }x, 'empty definition';

# Try out all call() variants
eval { $soap->call('NewOperation', 'value'); };
like $@, qr{ unable \s to \s extract \s schema \s from \s WSDL }x, 'empty definition';

$soap = SOAP::WSDL->new();
$soap->wsdl( "file://$path/WSDL_NO_MESSAGE.wsdl");
eval { $soap->wsdlinit() };
# eval { $soap->call('NewOperation', 'value'); };
like $@, qr{ Message \s \{http://www.example.org/WSDL_1/\}NewOperationRequest \s not \s found }x, 'empty definition';

$soap = SOAP::WSDL->new();
$soap->wsdl( "file://$path/WSDL_1.wsdl");
$soap->wsdlinit();
$soap->no_dispatch(1);

like $soap->call('NewOperation', NewOperation => { in => 'test' }), qr{ <in>test</in> }x;
like $soap->call('NewOperation', { NewOperation => { in => 'test' } }), qr{ <in>test</in> }x;

$soap->set_proxy('http://foo.de', timeout => 256);
is $soap->get_client->get_transport()->timeout(), 256, 'timeout';

$soap = SOAP::WSDL->new( wsdl => "file://$path/WSDL_1.wsdl",
    servicename => 'NewService',
    portname => 'NewPort',
    no_dispatch => 1,
    keep_alive => 1,
);
$soap->proxy('http://example.org');
like $soap->call('NewOperation', NewOperation => { in => 'test' }), qr{ <in>test</in> }x;
like $soap->call('NewOperation', { NewOperation => { in => 'test' } }), qr{ <in>test</in> }x;


eval {
    $soap = SOAP::WSDL->new( wsdl => "file://$path/WSDL_NO_BINDING.wsdl",
        servicename => 'NewService',
        portname => 'NewPort',
        no_dispatch => 1,
    );
};
like $@, qr{ no \s binding }x, 'No binding error';

eval {
    $soap = SOAP::WSDL->new( wsdl => "file://$path/WSDL_NO_PORTTYPE.wsdl",
        servicename => 'NewService',
        portname => 'NewPort',
        no_dispatch => 1,
    );
};
like $@, qr{ cannot \s find \s portType  }x, 'No porttype error';
