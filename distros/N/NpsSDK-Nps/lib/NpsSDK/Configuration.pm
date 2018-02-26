package NpsSDK::Configuration;

use warnings; 
use strict;
 
use NpsSDK::Constants;
use NpsSDK::Errors;

our $VERSION = '1.4'; # VERSION

our ($logger, $environment, $secret_key, $timeout, $sanitize, $proxy_url, $proxy_port,
     $proxy_user, $proxy_pass, $certificate, $certificate_key, $cert_verify_peer);

sub configure {
    my %params = (@_);
    $environment = $params{environment};
    $secret_key = $params{secret_key};
    $sanitize = $params{sanitize} if defined $params{sanitize};
    $timeout = $params{timeout} ? $params{timeout} : 60;
    $logger = $params{logger};
    $proxy_url = $params{proxy_url} if defined $params{proxy_url};
    $proxy_port = $params{proxy_port} if defined $params{proxy_port};
    $proxy_user = $params{proxy_user} if defined $params{proxy_user};
    $proxy_pass = $params{proxy_pass} if defined $params{proxy_pass};
    $cert_verify_peer = $params{cert_verify_peer} ? $params{cert_verify_peer} : 0;
    $certificate = $params{certificate} if defined $params{certificate};
    $certificate_key = $params{cert_key} if defined $params{cert_key};
}

sub get_url {
    NpsSDK::IndexError->error() if($environment < 0);
    my @envs = ($NpsSDK::Constants::PRODUCTION_URL,
                $NpsSDK::Constants::STAGING_URL,
                $NpsSDK::Constants::SANDBOX_URL,);
    return $envs[$environment] if $envs[$environment]; 
    NpsSDK::EnvironmentNotFound->error();
}

1;