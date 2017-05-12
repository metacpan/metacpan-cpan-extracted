package MyTypemap;
sub get_typemap { return {} };

package HandlerClass;

sub bar {
    return "Verdammte Axt";
}
package main;
use Test::More;
eval "require IO::Scalar"
    or plan skip_all => 'IO::Scalar required for testing...';

plan tests => 12;

use_ok(SOAP::WSDL::Server);
use_ok(SOAP::WSDL::Server::CGI);

my $server = SOAP::WSDL::Server::CGI->new({
    class_resolver => 'MyTypemap',
});
$server->set_action_map_ref({
    'testaction' => 'testmethod',
});

{
    no warnings qw(once);
    *IO::Scalar::BINMODE = sub {};
}
my $output = q{};
my $fh = IO::Scalar->new(\$output);
my $stdout = *STDOUT;
my $stdin = *STDIN;

# don't try to print() anything from here on - it gehts caught in $output,
#and does not make it to STDOUT...

*STDOUT = $fh;
{
    local %ENV;
    $server->handle();

    like $output, qr{ \A Status: \s 411 \s Length \s Required}x;
    $output = q{};

    $ENV{'CONTENT_LENGTH'} = '0e0';
    $server->handle();

    like $output, qr{ Error \s deserializing }xsm;
    $output = q{};

    $server->set_action_map_ref({
        'foo' => 'bar',
    });
    $server->set_dispatch_to( 'HandlerClass' );

    $server->handle();
    like $output, qr{no \s element \s found}xms;
    $output = q{};

    $ENV{REQUEST_METHOD} = 'POST';
    $ENV{HTTP_SOAPACTION} = 'test';
    $server->handle();
    like $output, qr{no \s element \s found}xms;
    $output = q{};

    delete $ENV{HTTP_SOAPACTION};

    $ENV{EXPECT} = 'Foo';
    $ENV{HTTP_SOAPAction} = 'foo';
    $server->handle();

    like $output, qr{no \s element \s found}xms;
    $output = q{};

    $ENV{EXPECT} = '100-Continue';
    $ENV{HTTP_SOAPAction} = 'foo';
    $server->handle();
    like $output, qr{100 \s Continue}xms;
    $output = q{};

    delete $ENV{EXPECT};

    my $input = 'Foobar';
    my $ih = IO::Scalar->new(\$input);
    $ih->seek(0);
    *STDIN = $ih;

#    my $buffer;
#    read(*STDIN, $buffer, 6);
#    die $buffer;
    $ENV{HTTP_SOAPAction} = 'bar';
    $ENV{CONTENT_LENGTH} = 6;
    $server->handle();
    like $output, qr{ Error \s deserializing \s message}xms;
    $output = q{};
    $ih->seek(0);

    $input = q{<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" >
    <SOAP-ENV:Body></SOAP-ENV:Body></SOAP-ENV:Envelope>};
    $ENV{HTTP_SOAPAction} = 'bar';
    $ENV{CONTENT_LENGTH} = length $input;
    $server->handle();
#    die $output;
    like $output, qr{ Not \s found:}xms;
    $output = q{};
    $ih->seek(0);


    $server->set_dispatch_to( 'HandlerClass' );
    $server->set_action_map_ref({
        'bar' => 'bar',
    });
    $input = q{<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" >
    <SOAP-ENV:Body></SOAP-ENV:Body></SOAP-ENV:Envelope>};
    $ENV{HTTP_SOAPAction} = q{"bar"};
    $ENV{CONTENT_LENGTH} = length $input;
    $server->handle();
    use Data::Dumper;
    like $output, qr{ \A Status: \s 200 \s OK}xms;
    $output = q{};
    $ih->seek(0);


    $server->set_dispatch_to( 'HandlerClass' );
    $server->set_action_map_ref({
        'bar' => 'bar',
    });
    $input = q{<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" >
    <SOAP-ENV:Body></SOAP-ENV:Body></SOAP-ENV:Envelope>};
    $ENV{SERVER_SOFTWARE} ='IIS Foobar';
    $ENV{HTTP_SOAPAction} = q{"bar"};
    $ENV{CONTENT_LENGTH} = length $input;
    $server->handle();
    use Data::Dumper;
    like $output, qr{ \A HTTP/1.0 \s 200 \s OK}xms;
    $output = q{};
    $ih->seek(0);

}

# restore handles
*STDOUT = $stdout;
*STDIN = $stdin;
# print $output;