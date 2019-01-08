package NpsSDK::Utils;

use warnings; 
use strict;

use NpsSDK::Services; 
use NpsSDK::Configuration; 
use NpsSDK::Constants; 
use NpsSDK::Version;

use Encode qw(encode);

use Digest::MD5 qw(md5_hex);

use XML::Twig; 
use XML::Parser; 

use Data::Dumper; use Data::UUID; $Data::Dumper::Terse = 1; 

our $VERSION = '1.91'; # VERSION

sub add_extra_info {
    my ($service, $ref_params) = @_;
    my %params = %{$ref_params};
    
    my %hash_merch_services = map {$_ => 1} @NpsSDK::Services::get_merch_det_not_add_services;

    return \%params if(exists($hash_merch_services{$service}));

    my %info = (
        SdkInfo => join " ", $NpsSDK::Constants::LANGUAGE, "SDK", "Version:", $NpsSDK::Version::VERSION,
    );

    my $merch_details_key = "psp_MerchantAdditionalDetails";

    if(exists($params{$merch_details_key})) {
        $params{$merch_details_key}{SdkInfo} = $info{SdkInfo};
    } else {
        $params{$merch_details_key} = \%info;
    }
    return \%params;
}

sub add_secure_hash {
    my ($secret_key, $ref_params) = @_;
    delete $ref_params->{"psp_SecureHash"} if (exists $ref_params->{"psp_SecureHash"});
    my $secure_hash= create_hmac_sha256_hash($secret_key, order_collection(%{$ref_params}));
    $ref_params->{"psp_SecureHash"} = $secure_hash;
    return $ref_params;
}

sub create_md5_hash {
    my ($secret_key, $ref_params) = @_;
    my %params = %{$ref_params};
    return md5_hex(order_collection(%params).$secret_key);
}

sub create_hmac_sha256_hash {
    use Digest::SHA qw(hmac_sha256_hex);
    my ($secret_key, $ref_params) = @_;
    return hmac_sha256_hex($ref_params, $secret_key);
}

sub create_hmac_sha512_hash {
    use Digest::SHA qw(hmac_sha512_hex);
    my ($secret_key, $ref_params) = @_;
    return hmac_sha512_hex($ref_params, $secret_key);
}

sub order_collection {
    my %collection = @_;
    my @ord_keys;
    my @values;
    foreach my $name (sort keys %collection) {
        push @ord_keys, $name;
    }
    foreach (@ord_keys) {
        push @values, ($collection{$_}) if(ref($collection{$_}) ne "HASH" and ref($collection{$_}) ne "ARRAY");
    }
    my $concatenated_data = join("", @values);
    return $concatenated_data;
}

sub check_sanitize {
    my $ref_args = (ref $_[0] eq 'HASH') ? shift : { @_ };
    my %params = %{$ref_args->{params}};
    my $is_root = $ref_args->{is_root} || 0;
    my $nodo = $ref_args->{nodo} || 0;

    my %result_params = ($is_root == 1) ? () : %params;	

    while ((my $key, my $value) = each (%params)) {
        if (ref($value) eq "HASH") {
            $result_params{$key} = NpsSDK::Utils::check_sanitize(params=>$value, nodo=>$key);
        } elsif (ref($value) eq "ARRAY") {
            $result_params{$key} = _check_sanitize_array(params=>$value, nodo=>$key);
        } else {
            $result_params{$key} = _validate_size(value=>$value, key=>$key, nodo=>$nodo);
        }
    }

    return \%result_params;
}

sub _check_sanitize_array {
    my $ref_args = (ref $_[0] eq 'HASH') ? shift : { @_ };
    my @params = @{$ref_args->{params}};
    my $nodo = $ref_args->{nodo};
    my @result_params;
    
    foreach my $param (@params) {
        push @result_params, NpsSDK::Utils::check_sanitize(params=>$param, nodo=>$nodo);
    }
    return \@result_params;
}

sub _validate_size {
    my $ref_args = (ref $_[0] eq 'HASH') ? shift : { @_ };

    my $key_name = ($ref_args->{nodo} ne 0) ? 
                    $ref_args->{nodo} . "." . $ref_args->{key} . ".max_length" : join(".", $ref_args->{key},"max_length");
 
    return "" . substr($ref_args->{value}, 0, $NpsSDK::Constants::SANITIZE{$key_name}) if (exists $NpsSDK::Constants::SANITIZE{$key_name});

    return $ref_args->{value};
}

sub mask_data {
    my ($data) = @_;
    $data = _mask_card_number($data);
    $data = _mask_exp_date($data);
    $data = _mask_cvc($data);
    $data = _mask_tokenization_card_number($data);
    $data = _mask_tokenization_exp_date($data);
    $data = _mask_tokenization_cvc($data);
    return $data;
}

sub _mask_card_number {
    my $data = shift;
    my $card_number_key = "</psp_CardNumber>";
    my @card_numbers = _find_card_numbers($data, $card_number_key);
    return replace_card_numbers($data, \@card_numbers, $card_number_key);
}

sub _mask_tokenization_card_number {
    my $data = shift;
    my $card_number_key = "</Number>";
    my @card_numbers = _find_card_numbers($data, $card_number_key);
    return replace_card_numbers($data, \@card_numbers, $card_number_key);
}

sub _find_card_numbers {
    my ($data, $key) = @_;
    my @card_numbers = ($data =~ /(\d{13,19}$key)/g);
    return @card_numbers;
}

sub replace_card_numbers {
    my ($data, $ref_array, $card_number_key) = @_;
    my @card_numbers = @{$ref_array};
    foreach my $card_number (@card_numbers) {
        my $final_len = length($card_number) - length($card_number_key);
        my $card_number_len = length(substr($card_number, 0, $final_len));
        my $masked_chars = "*"x($card_number_len - 10);
        my $head_card = substr($card_number, 0, 6);
        my $tail_card = substr($card_number, length($card_number) - 4 - length($card_number_key), length($card_number));
        my $new_card_number = join("", $head_card, $masked_chars, $tail_card);
        $data =~ s/\Q$card_number\E/$new_card_number/g;
    }
    return $data;
}

sub _mask_exp_date {
    my $data = shift;
    my $exp_date_key = "</psp_CardExpDate>";
    my @exp_dates = _find_exp_date($data, $exp_date_key);
    return replace_exp_dates($data, \@exp_dates, $exp_date_key);
}

sub _mask_tokenization_exp_date {
    my $data = shift;
    my $exp_date_key = "</ExpirationDate>";
    my @exp_dates = _find_exp_date($data, $exp_date_key);
    return replace_exp_dates($data, \@exp_dates, $exp_date_key);
}

sub _find_exp_date {
    my ($data, $key) = @_;
    my @exp_dates = ($data =~ /(\d{4}$key)/g);
    return @exp_dates;
}

sub replace_exp_dates {
    my ($data, $ref_array, $exp_date_key) = @_;
    my @exp_dates = @{$ref_array};
    foreach my $exp_date (@exp_dates) {
        my $new_exp_date = join("", "****", $exp_date_key);
        $data =~ s/\Q$exp_date\E/$new_exp_date/g;
    }
    return $data;
}

sub _mask_cvc {
    my $data = shift;
    my $cvcertificate_key = "</psp_CardSecurityCode>";
    my @cvcs = _find_cvc($data, $cvcertificate_key);
    return replace_cvcs($data, \@cvcs, $cvcertificate_key);
}

sub _mask_tokenization_cvc {
    my $data = shift;
    my $cvcertificate_key = "</SecurityCode>";
    my @cvcs = _find_cvc($data, $cvcertificate_key);
    return replace_cvcs($data, \@cvcs, $cvcertificate_key);
}

sub _find_cvc {
    my ($data, $key) = @_;
    my @cvcs = ($data =~ /(\d{3,4}$key)/g);
    return @cvcs;
}

sub replace_cvcs {
    my ($data, $ref_array, $cvcertificate_key) = @_;
    my @cvsc = @{$ref_array};
    foreach my $cvc (@cvsc) {
        my $final_len = length($cvc) - length($cvcertificate_key);
        my $masked_chars = "*"x(length(substr($cvc, 0, $final_len)));
        my $new_cvc = join("", $masked_chars, $cvcertificate_key);
        $data =~ s/\Q$cvc\E/$new_cvc/g;
    }
    return $data;
}

sub log_data {
    my ($http_object) = @_;
    my $xml_debug = XML::Twig->new(pretty_print => 'indented');
    my $xml_info = XML::Twig->new(pretty_print => 'indented');

    if (ref($http_object) eq "HTTP::Request") {
        show_logs($http_object, $xml_debug, $xml_info);
    }

    if (ref($http_object) eq "HTTP::Response" and $http_object->code ne 500) {
        show_logs($http_object, $xml_debug, $xml_info);
    }
}

sub show_logs {
    my ($object, $debug, $info) = @_;
    $debug->safe_parse($object->content);
    $info->safe_parse(mask_data($object->content));
    $NpsSDK::Configuration::logger->debug(encode("UTF-8", ref($object) . " " . $debug->sprint()));
    $NpsSDK::Configuration::logger->info(encode("UTF-8", ref($object) . " " . $info->sprint()));
}

sub encode_params {
    my ($params) = @_;
    my %result = %{$params};
    while ((my $key, my $value) = each (%result)) {
        if (ref($value) eq "HASH") {
            $result{$key} = NpsSDK::Utils::encode_params($value);
        } elsif (ref($value) eq "ARRAY") {
            $result{$key} = NpsSDK::Utils::encode_array($value);
        } else {
            $result{$key} = encode("UTF-8", $params->{$key});
        }
    }
    return \%result;
}

sub encode_array {
    my ($array) = @_;
    my @result_params;
    foreach my $item (@{$array}) {
        push @result_params, NpsSDK::Utils::encode_params($item);
    }
    return \@result_params;
}

1;
