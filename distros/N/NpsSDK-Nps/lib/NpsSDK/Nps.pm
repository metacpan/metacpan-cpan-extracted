package NpsSDK::Nps;

use warnings; 
use strict;

use NpsSDK::SoapClient;
use NpsSDK::Services;

our $VERSION = '1.91'; # VERSION

sub pay_online_2p {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::PAY_ONLINE_2P, $params);
    return $resp;
}

sub authorize_2p {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::AUTHORIZE_2P, $params);
    return $resp;
}

sub query_txs {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::QUERY_TXS, $params);
    return $resp;
}

sub simple_query_tx {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::SIMPLE_QUERY_TX, $params);
    return $resp;
}

sub refund {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::REFUND, $params);
    return $resp;
}

sub capture {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::CAPTURE, $params);
    return $resp;
}

sub authorize_3p {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::AUTHORIZE_3P, $params);
    return $resp;
}

sub bank_payment_3p {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::BANK_PAYMENT_3P, $params);
    return $resp;
}

sub bank_payment_2p {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::BANK_PAYMENT_2P, $params);
    return $resp;
}

sub cash_payment_3p {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::CASH_PAYMENT_3P, $params);
    return $resp;
}

sub change_secret_key {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::CHANGE_SECRET_KEY, $params);
    return $resp;
}

sub fraud_screening {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::FRAUD_SCREENING, $params);
    return $resp;
}

sub notify_fraud_screening_review {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::NOTIFY_FRAUD_SCREENING_REVIEW, $params);
    return $resp;
}

sub pay_online_3p {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::PAY_ONLINE_3P, $params);
    return $resp;
}

sub split_authorize_3p {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::SPLIT_AUTHORIZE_3P, $params);
    return $resp;
}

sub split_pay_online_3p {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::SPLIT_PAY_ONLINE_3P, $params);
    return $resp;
}

sub query_card_number {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::QUERY_CARD_NUMBER, $params);
    return $resp;
}

sub get_iin_details {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::GET_IIN_DETAILS, $params);
    return $resp;
}

sub create_payment_method {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::CREATE_PAYMENT_METHOD, $params);
    return $resp;
}

sub create_payment_method_from_payment {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::CREATE_PAYMENT_METHOD_FROM_PAYMENT, $params);
    return $resp;
}

sub retrieve_payment_method {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::RETRIEVE_PAYMENT_METHOD, $params);
    return $resp;
}

sub update_payment_method {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::UPDATE_PAYMENT_METHOD, $params);
    return $resp;
}

sub delete_payment_method {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::DELETE_PAYMENT_METHOD, $params);
    return $resp;
}

sub create_customer {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::CREATE_CUSTOMER, $params);
    return $resp;
}

sub retrieve_customer {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::RETRIEVE_CUSTOMER, $params);
    return $resp;
}

sub update_customer {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::UPDATE_CUSTOMER, $params);
    return $resp;
}

sub delete_customer {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::DELETE_CUSTOMER, $params);
    return $resp;
}

sub recache_payment_method_token {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::RECACHE_PAYMENT_METHOD_TOKEN, $params);
    return $resp;
}

sub create_payment_method_token {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::CREATE_PAYMENT_METHOD_TOKEN, $params);
    return $resp;
}

sub retrieve_payment_method_token {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::RETRIEVE_PAYMENT_METHOD_TOKEN, $params);
    return $resp;
}

sub create_client_session {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::CREATE_CLIENT_SESSION, $params);
    return $resp;
}

sub get_installments_options {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::GET_INSTALLMENTS_OPTIONS, $params);
    return $resp;
}

sub split_pay_online_2p {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::SPLIT_PAY_ONLINE_2P, $params);
    return $resp;
}

sub split_authorize_2p {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::SPLIT_AUTHORIZE_2P, $params);
    return $resp;
}

sub query_card_details {
    my ($params) = @_;
    my $resp = NpsSDK::SoapClient::soap_call($NpsSDK::Services::QUERY_CARD_DETAILS, $params);
    return $resp;
}

1;