package NpsSDK::SoapClient;

use warnings; 
use strict;

use NpsSDK::Configuration; 
use NpsSDK::Utils; 
use NpsSDK::Constants; 
use NpsSDK::Errors;

use Data::Structure::Util qw( unbless );

use Encode qw(encode);

our $VERSION = '1.9'; # VERSION

my $connection; 
my $response; 
my $error;

sub _setup {
    my $self = shift;
    if (defined $NpsSDK::Configuration::logger) {
        NpsSDK::LogException->error if ($NpsSDK::Configuration::logger->is_debug() and 
                                $NpsSDK::Configuration::environment eq $NpsSDK::Constants::PRODUCTION_ENV); 

        eval {  require SOAP::Lite;
                SOAP::Lite->import(+trace => [ transport => sub {
                my ($http_object) = @_;
                NpsSDK::Utils::log_data($http_object);
                }]);
             }

    } else {
        use SOAP::Lite;
    }
    
    $connection = SOAP::Lite
        -> on_action(sub {sprintf '%s%s', @_})
        -> on_fault( sub {
            my ( $soap, $res ) = @_;
            if (index($res, "timeout") != -1) { $error = 1; }
            elsif (index($res, "connect") != -1) { $error = 2; }
        });

    if ($NpsSDK::Configuration::cert_verify_peer == 1) {
        use IO::Socket::SSL;
        $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;
        if (defined $NpsSDK::Configuration::proxy_url) {
            $connection -> proxy(NpsSDK::Configuration::get_url(),
                                 proxy => ['http' => $NpsSDK::Configuration::proxy_url],
                                 timeout => $NpsSDK::Configuration::timeout,
                                 ssl_opts => [ SSL_verify_mode => 0 ]);
        } else {
           $connection -> proxy(NpsSDK::Configuration::get_url(),
                          timeout => $NpsSDK::Configuration::timeout,
                          ssl_opts => [ SSL_verify_mode => 0 ]);
        }
    } else {
        if (defined $NpsSDK::Configuration::proxy_url) {
            $connection -> proxy(NpsSDK::Configuration::get_url(),
                                 proxy => ['http' => $NpsSDK::Configuration::proxy_url],
                                 timeout => $NpsSDK::Configuration::timeout);
        } else {
           $connection -> proxy(NpsSDK::Configuration::get_url(),
                          timeout => $NpsSDK::Configuration::timeout);
        }
    }
    
    if (defined $NpsSDK::Configuration::certificate and defined $NpsSDK::Configuration::certificate_key) {
        $connection->transport->ssl_opts(
            SSL_cert_file => $NpsSDK::Configuration::certificate,
            SSL_key_file  => $NpsSDK::Configuration::certificate_key
        );
    }
}

sub soap_call {
    my ($service, $ref_params) = @_;
    _setup();
    
    my $params = NpsSDK::Utils::add_extra_info($service, $ref_params);

    $params = NpsSDK::Utils::check_sanitize(params=>$params, is_root=>1)
        if (defined $NpsSDK::Configuration::sanitize);

    $params = NpsSDK::Utils::add_secure_hash($NpsSDK::Configuration::secret_key, $params)
        if (!(exists $params->{"psp_ClientSession"}));
        
    eval {$response = $connection->$service(transform_params(("Requerimiento" => $params)));};
    
    if (defined $error) {
        if ($error == 1) {
            $NpsSDK::Configuration::logger->warn(encode("UTF-8", "Timeout error"));
            return NpsSDK::TimeoutException->new();
        } elsif ($error == 2 ) {
            $NpsSDK::Configuration::logger->warn(encode("UTF-8", "Connection error"));
            return NpsSDK::ConnectionException->new();
        } else {
            $NpsSDK::Configuration::logger->error(encode("UTF-8", "Unknown error"));
            return NpsSDK::UnknownError->new();
        }
    } else {
        my $result = NpsSDK::Utils::encode_params(unbless($response->result));
        return $result;
    }
}

sub transform_params {
    my %params = @_;
    my @params;
    foreach my $key (keys %params) {
        my $item = SOAP::Data->name($key => $params{$key});
        push(@params, $item);
    }
    return @params;
}

1;

