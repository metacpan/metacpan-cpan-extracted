# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4
# Net::BaruwaAPI Perl bindings for the Baruwa REST API
# Copyright (C) 2015-2019 Andrew Colin Kissa <andrew@topdog.za.net>
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
package Net::BaruwaAPI;

# use utf8;
use feature 'state';
use JSON::MaybeXS;
use HTTP::Request;
use Carp qw/croak/;
use LWP::UserAgent;
use Type::Params qw/compile/;
use Types::Standard qw(Str InstanceOf Object Int Bool Dict Num ArrayRef Optional);
use Moo;

our $VERSION = '0.06';
our $AUTHORITY = 'cpan:DATOPDOG';

my $api_path = '/api/v1';

has 'api_url' => (is => 'ro', isa => Str, predicate => 'has_api_url', required => 1);

has 'api_token' => (is => 'ro', isa => Str, predicate => 'has_api_token', required => 1);

has 'ua' => (
    isa     => InstanceOf['LWP::UserAgent'],
    is      => 'ro',
    lazy    => 1,
    default => sub {
        LWP::UserAgent->new(
            agent       => "BaruwaAPI-Perl",
            cookie_jar  => {},
            keep_alive  => 4,
            timeout     => 60,
        );
    },
);

has 'json' => (
    is => 'ro',
    isa => Object,
    lazy => 1,
    default => sub {
        return JSON::MaybeXS->new( utf8 => 1 );
    }
);

sub _call {
    my ($self) = @_;
    my $request_method = shift @_;
    my $url = shift @_;
    my $data = shift @_;

    my $ua = $self->ua;
    $ua->default_header('Authorization', "Bearer " . $self->api_token);
    $url = $self->api_url . $url;

    my $req = HTTP::Request->new( $request_method, $url );
    $req->accept_decodable;

    if ($data) {
        $req->content($data);
    }
    $req->header( 'Content-Length' => length $req->content );

    my $res = $ua->request($req);

    if ($res->header('Content-Type') and $res->header('Content-Type') =~ 'application/json') {
        my $json = $res->decoded_content;
        $data = eval { $self->json->decode($json) };
        unless ($data) {
            die unless $res->is_error;
            $data = { code => $res->code, message => $res->message };
        }
    } else {
        $data = { code => $res->code, message => $res->message };
    }

    if (not $res->is_success and ref $data eq 'HASH' and exists $data->{message}) {
        my $message = $data->{message};

        if (exists $data->{errors}) {
            $message .= ': '.join(' - ', map { $_->{message} } grep { exists $_->{message} } @{ $data->{errors} });
        }
        croak $message;
    }
    return $data;
}


sub get_users {
    state $check = compile(Object, Optional[Int]);
    my ($self, $page) = $check->(@_);
    my $path = "$api_path/users";
    $path = "$api_path/users?page=$page" unless @_ == 1;
    return $self->_call('GET', $path);
}

sub get_user {
    state $check = compile(Object, Int);
    my ($self, $userid) = $check->(@_);
    return $self->_call('GET', "$api_path/users/$userid");
}

sub create_user {
    state $check = compile(Object,
    Dict[
        username => Str,
        firstname => Str,
        lastname => Str,
        password1 => Str,
        password2 => Str,
        email => Str,
        timezone => Str,
        account_type => Int,
        domains => Int,
        active => Bool,
        send_report => Bool,
        spam_checks => Bool,
        low_score => Num,
        high_score => Num,
        block_macros => Bool,
    ]);
    my ($self, $data) = $check->(@_);
    return $self->_call('POST', "$api_path/users", $data);
}

sub update_user {
    state $check = compile(Object,
    Dict[
        username => Str,
        firstname => Str,
        lastname => Str,
        email => Str,
        timezone => Str,
        domains => Int,
        active => Bool,
        send_report => Bool,
        spam_checks => Bool,
        low_score => Num,
        high_score => Num,
        block_macros => Bool,
    ]);
    my ($self, $data) = $check->(@_);
    return $self->_call('PUT', "$api_path/users", $data);
}

sub delete_user {
    state $check = compile(Object,
    Dict[
        username => Str,
        firstname => Str,
        lastname => Str,
        email => Str,
        timezone => Str,
        domains => Int,
        active => Bool,
        send_report => Bool,
        spam_checks => Bool,
        low_score => Num,
        high_score => Num,
        block_macros => Bool,
    ]);
    my ($self, $data) = $check->(@_);
    # my ($self, $data) = @_;
    return $self->_call('DELETE', "$api_path/users", $data);
}

sub set_user_passwd {
    state $check = compile(Object, Int,
    Dict[
        password1 => Str,
        password2 => Str,
    ]);
    my ($self, $userid, $data) = $check->(@_);
    return $self->_call('POST', "$api_path/users/chpw/$userid");
}

sub get_aliases {
    state $check = compile(Object, Int);
    my ($self, $addressid) = $check->(@_);
    return $self->_call('GET', "$api_path/aliasaddresses/$addressid");
}

sub create_alias {
    state $check = compile(Object, Int,
    Dict[
        address => Str,
        enabled => Bool,
    ]);
    my ($self, $userid, $data) = $check->(@_);
    return $self->_call('POST', "$api_path/aliasaddresses/$userid", $data);
}

sub update_alias {
    state $check = compile(Object, Int,
    Dict[
        address => Str,
        enabled => Bool,
    ]);
    my ($self, $addressid, $data) = $check->(@_);
    return $self->_call('PUT', "$api_path/aliasaddresses/$addressid", $data);
}

sub delete_alias {
    state $check = compile(Object, Int,
    Dict[
        address => Str,
        enabled => Bool,
    ]);
    my ($self, $addressid, $data) = $check->(@_);
    return $self->_call('DELETE', "$api_path/aliasaddresses/$addressid", $data);
}

sub get_domains {
    state $check = compile(Object, Optional[Int]);
    my ($self, $page) = $check->(@_);
    my $path = "$api_path/domains";
    $path = "$api_path/domains?page=$page" unless @_ == 1;
    return $self->_call('GET', $path);
}

sub get_domain {
    state $check = compile(Object, Int);
    my ($self, $domainid) = $check->(@_);
    return $self->_call('GET', "$api_path/domains/$domainid");
}

sub get_domain_by_name {
    state $check = compile(Object, Str);
    my ($self, $domain_name) = $check->(@_);
    return $self->_call('GET', "$api_path/domains/byname/$domain_name");
}

sub create_domain {
    state $check = compile(Object,
    Dict[
        name => Str,
        site_url => Str,
        status => Bool,
        accept_inbound => Bool,
        discard_mail => Bool,
        smtp_callout => Bool,
        ldap_callout => Bool,
        virus_checks => Bool,
        virus_checks_at_smtp => Bool,
        block_macros => Bool,
        spam_checks => Bool,
        spam_actions => Num,
        highspam_actions => Num,
        virus_actions => Num,
        low_score => Num,
        high_score => Num,
        message_size => Str,
        delivery_mode => Num,
        language => Str,
        timezone => Str,
        report_every => Num,
        organizations => Num
    ]);
    my ($self, $data) = $check->(@_);
    return $self->_call('POST', "$api_path/domains", $data);
}

sub update_domain {
    state $check = compile(Object, Int,
    Dict[
        name => Str,
        site_url => Str,
        status => Bool,
        accept_inbound => Bool,
        discard_mail => Bool,
        smtp_callout => Bool,
        ldap_callout => Bool,
        virus_checks => Bool,
        virus_checks_at_smtp => Bool,
        block_macros => Bool,
        spam_checks => Bool,
        spam_actions => Num,
        highspam_actions => Num,
        virus_actions => Num,
        low_score => Num,
        high_score => Num,
        message_size => Str,
        delivery_mode => Num,
        language => Str,
        timezone => Str,
        report_every => Num,
        organizations => Num
    ]);
    my ($self, $domainid, $data) = $check->(@_);
    return $self->_call('PUT', "$api_path/domains/$domainid", $data);
}

sub delete_domain {
    state $check = compile(Object, Int);
    my ($self, $domainid) = $check->(@_);
    return $self->_call('DELETE', "$api_path/domains/$domainid");
}

sub get_domainaliases {
    state $check = compile(Object, Int, Optional[Int]);
    my ($self, $domainid, $page) = $check->(@_);
    my $path = "$api_path/domainaliases/$domainid";
    $path = "$api_path/domainaliases/$domainid?page=$page" unless @_ == 2;
    return $self->_call('GET', $path);
}

sub get_domainalias {
    state $check = compile(Object, Int, Int);
    my ($self, $domainid, $aliasid) = $check->(@_);
    return $self->_call('GET', "$api_path/domainaliases/$domainid/$aliasid");
}

sub create_domainalias {
    state $check = compile(Object, Int,
    Dict[
        name => Str,
        status => Bool,
        accept_inbound => Bool,
        domain => Int
    ]);
    my ($self, $domainid, $data) = $check->(@_);
    return $self->_call('POST', "$api_path/domainaliases/$domainid", $data);
}

sub update_domainalias {
    state $check = compile(Object, Int, Int,
    Dict[
        name => Str,
        status => Bool,
        accept_inbound => Bool,
        domain => Int
    ]);
    my ($self, $domainid, $aliasid, $data) = $check->(@_);
    return $self->_call('PUT', "$api_path/domainaliases/$domainid/$aliasid", $data);
}

sub delete_domainalias {
    state $check = compile(Object, Int, Int,
    Dict[
        name => Str,
        status => Bool,
        accept_inbound => Bool,
        domain => Int
    ]);
    my ($self, $domainid, $aliasid, $data) = $check->(@_);
    return $self->_call('DELETE', "$api_path/domainaliases/$domainid/$aliasid", $data);
}

sub get_deliveryservers {
    state $check = compile(Object, Int, Optional[Int]);
    my ($self, $domainid, $page) = $check->(@_);
    my $path = "$api_path/deliveryservers/$domainid";
    $path = "$api_path/deliveryservers/$domainid?page=$page" unless @_ == 2;
    return $self->_call('GET', $path);
}

sub get_deliveryserver {
    state $check = compile(Object, Int, Int);
    my ($self, $domainid, $serverid) = $check->(@_);
    return $self->_call('GET', "$api_path/deliveryservers/$domainid/$serverid");
}

sub create_deliveryserver {
    state $check = compile(Object, Int,
    Dict[
     address => Str,
     protocol => Int,
     port => Int,
     require_tls => Bool,
     verification_only => Bool,
     enabled => Bool
    ]);
    my ($self, $domainid, $data) = $check->(@_);
    return $self->_call('POST', "$api_path/deliveryservers/$domainid", $data);
}

sub update_deliveryserver {
    state $check = compile(Object, Int, Int,
    Dict[
     address => Str,
     protocol => Int,
     port => Int,
     require_tls => Bool,
     verification_only => Bool,
     enabled => Bool
    ]);
    my ($self, $domainid, $serverid, $data) = $check->(@_);
    return $self->_call('PUT', "$api_path/deliveryservers/$domainid/$serverid", $data);
}

sub delete_deliveryserver {
    state $check = compile(Object, Int, Int,
    Dict[
        address => Str,
        protocol => Int,
        port => Int,
        require_tls => Bool,
        verification_only => Bool,
        enabled => Bool
    ]);
    my ($self, $domainid, $serverid, $data) = $check->(@_);
    return $self->_call('DELETE', "$api_path/deliveryservers/$domainid/$serverid", $data);
}

sub get_user_deliveryservers {
    state $check = compile(Object, Int, Optional[Int]);
    my ($self, $domainid, $page) = $check->(@_);
    my $path = "$api_path/userdeliveryservers/$domainid";
    $path = "$api_path/userdeliveryservers/$domainid?page=$page" unless @_ == 2;
    return $self->_call('GET', $path);
}

sub get_user_deliveryserver {
    state $check = compile(Object, Int, Int);
    my ($self, $domainid, $serverid) = $check->(@_);
    return $self->_call('GET', "$api_path/userdeliveryservers/$domainid/$serverid");
}

sub create_user_deliveryserver {
    state $check = compile(Object, Int,
    Dict[
     address => Str,
     protocol => Int,
     port => Int,
     require_tls => Bool,
     verification_only => Bool,
     enabled => Bool
    ]);
    my ($self, $domainid, $data) = $check->(@_);
    return $self->_call('POST', "$api_path/userdeliveryservers/$domainid", $data);
}

sub update_user_deliveryserver {
    state $check = compile(Object, Int, Int,
    Dict[
     address => Str,
     protocol => Int,
     port => Int,
     require_tls => Bool,
     verification_only => Bool,
     enabled => Bool
    ]);
    my ($self, $domainid, $serverid, $data) = $check->(@_);
    return $self->_call('PUT', "$api_path/userdeliveryservers/$domainid/$serverid", $data);
}

sub delete_user_deliveryserver {
    state $check = compile(Object, Int, Int,
    Dict[
        address => Str,
        protocol => Int,
        port => Int,
        require_tls => Bool,
        verification_only => Bool,
        enabled => Bool
    ]);
    my ($self, $domainid, $serverid, $data) = $check->(@_);
    return $self->_call('DELETE', "$api_path/userdeliveryservers/$domainid/$serverid", $data);
}

sub get_domain_smarthosts {
    state $check = compile(Object, Int, Optional[Int]);
    my ($self, $domainid, $page) = $check->(@_);
    my $path = "$api_path/domains/smarthosts/$domainid";
    $path = "$api_path/domains/smarthosts/$domainid?page=$page" unless @_ == 2;
    return $self->_call('GET', $path);
}

sub get_domain_smarthost {
    state $check = compile(Object, Int, Int);
    my ($self, $domainid, $serverid) = $check->(@_);
    return $self->_call('GET', "$api_path/domains/smarthosts/$domainid/$serverid");
}

sub create_domain_smarthost {
    state $check = compile(Object, Int,
    Dict[
        address => Str,
        username => Str,
        password => Str,
        port => Int,
        require_tls => Bool,
        enabled => Bool,
        description => Str,
    ]);
    my ($self, $domainid, $data) = $check->(@_);
    return $self->_call('POST', "$api_path/domains/smarthosts/$domainid", $data);
}

sub update_domain_smarthost {
    state $check = compile(Object, Int, Int,
    Dict[
        address => Str,
        username => Str,
        password => Str,
        port => Int,
        require_tls => Bool,
        enabled => Bool,
        description => Str,
    ]);
    my ($self, $domainid, $serverid, $data) = $check->(@_);
    return $self->_call('PUT', "$api_path/domains/smarthosts/$domainid/$serverid", $data);
}

sub delete_domain_smarthost {
    state $check = compile(Object, Int, Int,
    Dict[
        address => Str,
        username => Str,
        password => Str,
        port => Int,
        require_tls => Bool,
        enabled => Bool,
        description => Str,
    ]);
    my ($self, $domainid, $serverid, $data) = $check->(@_);
    return $self->_call('DELETE', "$api_path/domains/smarthosts/$domainid/$serverid", $data);
}

sub get_org_smarthosts {
    state $check = compile(Object, Int, Optional[Int]);
    my ($self, $orgid, $page) = $check->(@_);
    my $path = "$api_path/organizations/smarthosts/$orgid";
    $path = "$api_path/organizations/smarthosts/$orgid?page=$page" unless @_ == 2;
    return $self->_call('GET', $path);
}

sub get_org_smarthost {
    state $check = compile(Object, Int, Int);
    my ($self, $orgid, $serverid) = $check->(@_);
    return $self->_call('GET', "$api_path/organizations/smarthosts/$orgid/$serverid");
}

sub create_org_smarthost {
    state $check = compile(Object, Int,
    Dict[
        address => Str,
        username => Str,
        password => Str,
        port => Int,
        require_tls => Bool,
        enabled => Bool,
        description => Str,
    ]);
    my ($self, $orgid, $data) = $check->(@_);
    return $self->_call('POST', "$api_path/organizations/smarthosts/$orgid", $data);
}

sub update_org_smarthost {
    state $check = compile(Object, Int, Int,
    Dict[
        address => Str,
        username => Str,
        password => Str,
        port => Int,
        require_tls => Bool,
        enabled => Bool,
        description => Str,
    ]);
    my ($self, $orgid, $serverid, $data) = $check->(@_);
    return $self->_call('PUT', "$api_path/organizations/smarthosts/$orgid/$serverid", $data);
}

sub delete_org_smarthost {
    state $check = compile(Object, Int, Int,
    Dict[
        address => Str,
        username => Str,
        password => Str,
        port => Int,
        require_tls => Bool,
        enabled => Bool,
        description => Str,
    ]);
    my ($self, $orgid, $serverid, $data) = $check->(@_);
    return $self->_call('DELETE', "$api_path/organizations/smarthosts/$orgid/$serverid", $data);
}

sub get_fallbackservers {
    state $check = compile(Object, Int, Optional[Int]);
    my ($self, $orgid, $page) = $check->(@_);
    my $path = "$api_path/fallbackservers/list/$orgid";
    $path = "$api_path/fallbackservers/list/$orgid?page=$page" unless @_ == 2;
    return $self->_call('GET', $path);
}

sub get_fallbackserver {
    state $check = compile(Object, Int);
    my ($self, $serverid) = $check->(@_);
    return $self->_call('GET', "$api_path/fallbackservers/$serverid");
}

sub create_fallbackserver {
    state $check = compile(Object, Int,
    Dict[
     address => Str,
     protocol => Int,
     port => Int,
     require_tls => Bool,
     verification_only => Bool,
     enabled => Bool
    ]);
    my ($self, $orgid, $data) = $check->(@_);
    return $self->_call('POST', "$api_path/fallbackservers/$orgid", $data);
}

sub update_fallbackserver {
    state $check = compile(Object, Int,
    Dict[
     address => Str,
     protocol => Int,
     port => Int,
     require_tls => Bool,
     verification_only => Bool,
     enabled => Bool
    ]);
    my ($self, $serverid, $data) = $check->(@_);
    return $self->_call('PUT', "$api_path/fallbackservers/$serverid", $data);
}

sub delete_fallbackserver {
    state $check = compile(Object, Int,
    Dict[
        address => Str,
        protocol => Int,
        port => Int,
        require_tls => Bool,
        verification_only => Bool,
        enabled => Bool
    ]);
    my ($self, $serverid, $data) = $check->(@_);
    return $self->_call('DELETE', "$api_path/fallbackservers/$serverid", $data);
}

sub get_authservers {
    state $check = compile(Object, Int, Optional[Int]);
    my ($self, $domainid, $page) = $check->(@_);
    my $path = "$api_path/authservers/$domainid";
    $path = "$api_path/authservers/$domainid?page=$page" unless @_ == 2;
    return $self->_call('GET', $path);
}

sub get_authserver {
    state $check = compile(Object, Int, Int);
    my ($self, $domainid, $serverid) = $check->(@_);
    return $self->_call('GET', "$api_path/authservers/$domainid/$serverid");
}

sub create_authserver {
    state $check = compile(Object, Int,
    Dict[
        address => Str,
        protocol => Int,
        port => Int,
        enabled => Bool,
        split_address => Bool,
        user_map_template => Str
    ]);
    my ($self, $domainid, $data) = $check->(@_);
    return $self->_call('POST', "$api_path/authservers/$domainid", $data);
}

sub update_authserver {
    state $check = compile(Object, Int, Int,
    Dict[
        address => Str,
        protocol => Int,
        port => Int,
        enabled => Bool,
        split_address => Bool,
        user_map_template => Str
    ]);
    my ($self, $domainid, $serverid, $data) = $check->(@_);
    return $self->_call('PUT', "$api_path/authservers/$domainid/$serverid", $data);
}

sub delete_authserver {
    state $check = compile(Object, Int, Int,
    Dict[
        address => Str,
        protocol => Int,
        port => Int,
        enabled => Bool,
        split_address => Bool,
        user_map_template => Str
    ]);
    my ($self, $domainid, $serverid, $data) = $check->(@_);
    return $self->_call('DELETE', "$api_path/authservers/$domainid/$serverid", $data);
}

sub get_ldapsettings {
    state $check = compile(Object, Int, Int, Int);
    my ($self, $domainid, $serverid, $settingsid) = $check->(@_);
    return $self->_call('GET', "$api_path/ldapsettings/$domainid/$serverid/$settingsid");
}

sub create_ldapsettings {
    state $check = compile(Object, Int, Int,
    Dict[
        basedn => Str,
        nameattribute => Str,
        emailattribute => Str,
        binddn => Str,
        bindpw => Str,
        usetls => Bool,
        usesearch => Bool,
        searchfilter => Str,
        search_scope => Str,
        emailsearchfilter => Str,
        emailsearch_scope => Str
    ]);
    my ($self, $domainid, $serverid, $data) = $check->(@_);
    return $self->_call('POST', "$api_path/ldapsettings/$domainid/$serverid", $data);
}

sub update_ldapsettings {
    state $check = compile(Object, Int, Int, Int,
    Dict[
        basedn => Str,
        nameattribute => Str,
        emailattribute => Str,
        binddn => Str,
        bindpw => Str,
        usetls => Bool,
        usesearch => Bool,
        searchfilter => Str,
        search_scope => Str,
        emailsearchfilter => Str,
        emailsearch_scope => Str
    ]);
    my ($self, $domainid, $serverid, $settingsid, $data) = $check->(@_);
    return $self->_call('PUT', "$api_path/ldapsettings/$domainid/$serverid/$settingsid", $data);
}

sub delete_ldapsettings {
    state $check = compile(Object, Int, Int, Int,
    Dict[
        basedn => Str,
        nameattribute => Str,
        emailattribute => Str,
        binddn => Str,
        bindpw => Str,
        usetls => Bool,
        usesearch => Bool,
        searchfilter => Str,
        search_scope => Str,
        emailsearchfilter => Str,
        emailsearch_scope => Str
    ]);
    my ($self, $domainid, $serverid, $settingsid, $data) = $check->(@_);
    return $self->_call('DELETE', "$api_path/ldapsettings/$domainid/$serverid/$settingsid", $data);
}

sub get_radiussettings {
    state $check = compile(Object, Int, Int, Int);
    my ($self, $domainid, $serverid, $settingsid) = $check->(@_);
    return $self->_call('GET', "$api_path/radiussettings/$domainid/$serverid/$settingsid");
}

sub create_radiussettings {
    state $check = compile(Object, Int, Int,
    Dict[
        secret => Str,
        timeout => Int
    ]);
    my ($self, $domainid, $serverid, $data) = $check->(@_);
    return $self->_call('POST', "$api_path/radiussettings/$domainid/$serverid", $data);
}

sub update_radiussettings {
    state $check = compile(Object, Int, Int, Int,
    Dict[
        secret => Str,
        timeout => Int
    ]);
    my ($self, $domainid, $serverid, $settingsid, $data) = $check->(@_);
    return $self->_call('PUT', "$api_path/radiussettings/$domainid/$serverid/$settingsid", $data);
}

sub delete_radiussettings {
    state $check = compile(Object, Int, Int, Int,
    Dict[
        secret => Str,
        timeout => Int
    ]);
    my ($self, $domainid, $serverid, $settingsid, $data) = $check->(@_);
    return $self->_call('DELETE', "$api_path/radiussettings/$domainid/$serverid/$settingsid", $data);
}

sub get_organizations {
    state $check = compile(Object, Optional[Int]);
    my ($self, $page) = $check->(@_);
    my $path = "$api_path/organizations";
    $path = "$api_path/organizations?page=$page" unless @_ == 1;
    return $self->_call('GET', $path);
}

sub get_organization {
    state $check = compile(Object, Int);
    my ($self, $orgid) = $check->(@_);
    return $self->_call('GET', "$api_path/organizations/$orgid");
}

sub create_organization {
    state $check = compile(Object,
    Dict[
        name => Str,
        domains => ArrayRef,
        admins => ArrayRef
    ]);
    my ($self, $data) = $check->(@_);
    return $self->_call('POST', "$api_path/organizations", $data);
}

sub update_organization {
    state $check = compile(Object, Int,
    Dict[
        name => Str,
        domains => ArrayRef,
        admins => ArrayRef
    ]);
    my ($self, $orgid, $data) = $check->(@_);
    return $self->_call('PUT', "$api_path/organizations/$orgid", $data);
}

sub delete_organization {
    state $check = compile(Object, Int);
    my ($self, $orgid) = $check->(@_);
    return $self->_call('DELETE', "$api_path/organizations/$orgid");
}

sub get_relay {
    state $check = compile(Object, Int);
    my ($self, $relayid) = $check->(@_);
    return $self->_call('GET', "$api_path/relays/$relayid");
}

sub create_relay {
    state $check = compile(Object, Int,
    Dict[
        address => Str,
        username => Str,
        enabled => Bool,
        require_tls => Bool,
        password1 => Str,
        password2 => Str,
        description => Str,
        low_score => Num,
        high_score => Num,
        spam_actions => Int,
        highspam_actions => Int,
        block_macros => Bool,
        ratelimit => Int
    ]);
    my ($self, $orgid, $data) = $check->(@_);
    return $self->_call('POST', "$api_path/relays/$orgid", $data);
}

sub update_relay {
    state $check = compile(Object, Int,
    Dict[
        address => Str,
        username => Str,
        enabled => Bool,
        require_tls => Bool,
        password1 => Str,
        password2 => Str,
        description => Str,
        low_score => Num,
        high_score => Num,
        spam_actions => Int,
        highspam_actions => Int,
        block_macros => Bool,
        ratelimit => Int
    ]);
    my ($self, $relayid, $data) = $check->(@_);
    return $self->_call('PUT', "$api_path/relays/$relayid", $data);
}

sub delete_relay {
    state $check = compile(Object, Int,
    Dict[
        address => Str,
        username => Str,
        enabled => Bool,
        require_tls => Bool,
        password1 => Str,
        password2 => Str,
        description => Str,
        low_score => Num,
        high_score => Num,
        spam_actions => Int,
        highspam_actions => Int,
        block_macros => Bool,
        ratelimit => Int
    ]);
    my ($self, $relayid, $data) = $check->(@_);
    return $self->_call('DELETE', "$api_path/relays/$relayid", $data);
}

sub get_status {
    state $check = compile(Object);
    my ($self) = $check->(@_);
    return $self->_call('GET', "$api_path/status");
}

no Moo;

1;

__END__

=head1 NAME

Net::BaruwaAPI - Perl bindings for Baruwa REST API

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Baruwa Enterprise Edition L<https://www.baruwa.com> is a fully fledged Mail
Security solution, based on best of breed open source software packages.
It provides protection from spam, viruses, phishing attempts and malware.

This distribution provides easy methods to access Baruwa servers via the
REST API.

Check L<https://www.baruwa.com/docs/api> for more details of the REST API.
Read L<Net::BaruwaAPI> for API usage.

    use Net::BaruwaAPI;
    my $api = Net::BaruwaAPI->new(
        api_token => 'oauth token',
        api_url => 'https://baruwa.example.com'
    );

=head1 DESCRIPTION

This module implements Baruwa Enterprise Editions RESTful API.

=head2 ATTRIBUTES

=over

=item api_token

The OAUTH authorization token.

=item api_url

The Baruwa server url

=back

=head1 METHODS

=head2 get_users

    my $data = $api->get_users($page);

    for ($data->{items}) {
        say $_->{username};
    }

Lists user accounts on the server.

More info: L<< https://www.baruwa.com/docs/api/#list-all-accounts >>.

=head2 get_user($userid)

    my $data = $api->get_user($userid);

B<Arguments:>

=over

=item C<Int> $userid

The user id.

=back

Retrieves the specified user account.

More info: L<< https://www.baruwa.com/docs/api/#retrieve-an-existing-account >>.

=head2 create_user($data)

    my $data = $api->create_user($data);

B<Arguments:>

=over

=item C<Str> $data{username}

The username.

=item C<Str> $data{firstname}

The firstname.

=item C<Str> $data{lastname}

The last name.

=item C<Str> $data{email}

The email address

=item C<Str> $data{password1}

The password.

=item C<Str> $data{password2}

The password confirmation.

=item C<Int> $data{account_type}

The account type.

=item C<Str> $data{low_score}

The probable spam score.

=item C<Int> $data{active}

Account status.

=item C<Str> $data{timezone}

The user timezone.

=item C<Str> $data{spam_checks}

Enable spam checks.

=item C<Str> $data{high_score}

Definite spam score.

=item C<Str> $data{send_report}

Send reports.

=item C<Str> $data{domains}

The domains the user belongs to.

=back

Creates a new user account.

More info: L<< https://www.baruwa.com/docs/api/#create-a-new-account >>.

=head2 update_user($data)

    my $data = $api->update_user($data);

B<Arguments:>

=over

=item C<Str> $data{username}

The username.

=item C<Str> $data{firstname}

The firstname.

=item C<Str> $data{lastname}

The last name.

=item C<Str> $data{email}

The email address

=item C<Str> $data{password1}

The password.

=item C<Str> $data{password2}

The password confirmation.

=item C<Int> $data{account_type}

The account type.

=item C<Str> $data{low_score}

The probable spam score.

=item C<Int> $data{active}

Account status.

=item C<Str> $data{timezone}

The user timezone.

=item C<Str> $data{spam_checks}

Enable spam checks.

=item C<Str> $data{high_score}

Definite spam score.

=item C<Str> $data{send_report}

Send reports.

=item C<Str> $data{domains}

The domains the user belongs to.

=back

Updates a user account.

More info: L<< https://www.baruwa.com/docs/api/#update-an-account >>.

=head2 delete_user($data)

    my $data = $api->delete_user($data);

B<Arguments:>

=over

=item C<Str> $data{username}

The username.

=item C<Str> $data{firstname}

The firstname.

=item C<Str> $data{lastname}

The last name.

=item C<Str> $data{email}

The email address

=item C<Str> $data{password1}

The password.

=item C<Str> $data{password2}

The password confirmation.

=item C<Int> $data{account_type}

The account type.

=item C<Str> $data{low_score}

The probable spam score.

=item C<Int> $data{active}

Account status.

=item C<Str> $data{timezone}

The user timezone.

=item C<Str> $data{spam_checks}

Enable spam checks.

=item C<Str> $data{high_score}

Definite spam score.

=item C<Str> $data{send_report}

Send reports.

=item C<Str> $data{domains}

The domains the user belongs to.

=back

Deletes a user account

More info: L<< https://www.baruwa.com/docs/api/#delete-an-account >>.

=head2 set_user_passwd($userid, $data)

    my $data = $api->set_user_passwd($userid, $data);

B<Arguments:>

=over

=item C<Str> $data{password1}

The password.

=item C<Str> $data{password2}

The password confirmation.

=back

Changes a user password.

More info: L<< https://www.baruwa.com/docs/api/#change-a-password >>.

=head2 get_aliases($addressid)

    my $data = $api->get_aliases($addressid);

B<Arguments:>

=over

=item C<Int> $addressid

The alias address id.

=back

Retrieves a user account's email alias addresses.

=head2 create_alias($userid, $data)

my $data = $api->create_alias($userid, $data);

B<Arguments:>

=over

=item C<Int> $userid

The user id.

=item C<Str> $data{enabled}

Enable the address.

=item C<Str> $data{address}

The alias address.

=back

Creates an alias address.

More info: L<< https://www.baruwa.com/docs/api/#create-an-alias-address >>.

=head2 update_alias($addressid, $data)

    my $data = $api->update_alias($addressid, $data);

B<Arguments:>

=over

=item C<Int> $addressid

The alias address id.

=item C<Str> $data{enabled}

Enable the address.

=item C<Str> $data{address}

The alias address.

=back

Updates an alias address.

More info: L<< https://www.baruwa.com/docs/api/#update-an-alias-address >>.

=head2 delete_alias($addressid, $data)

    my $data = $api->delete_alias($addressid, $data);

Deletes an alias address

More info: L<< https://www.baruwa.com/docs/api/#delete-an-alias-address >>.

=head2 get_domains

    my $data = $api->get_domains();

More info: L<< https://www.baruwa.com/docs/api/#list-all-domains >>.

=head2 get_domain($domainid)

    my $data = $api->get_domain($domainid);

=head2 create_domain($data)

    my $data = $api->create_domain($data);

=head2 update_domain($domainid, $data)

    my $data = $api->update_domain($domainid, $data);

=head2 delete_domain($domainid)

    my $data = $api->delete_domain($domainid);

=head2 get_domainaliases($domainid)

    my $data = $api->get_domainaliases($domainid);

=head2 get_domainalias($domainid, $aliasid)

    my $data = $api->get_domainalias($domainid, $aliasid);

=head2 create_domainalias($domainid, $data)

    my $data = $api->create_domainalias($domainid, $data);

=head2 update_domainalias($domainid, $aliasid, $data)

    my $data = $api->update_domainalias($domainid, $aliasid, $data);

=head2 delete_domainalias($domainid, $aliasid, $data)

    my $data = $api->delete_domainalias($domainid, $aliasid, $data);

=head2 get_deliveryservers($domainid)

    my $data = $api->get_deliveryservers($domainid);

=head2 get_deliveryserver($domainid, $serverid)

    my $data = $api->get_deliveryserver($domainid, $serverid);

=head2 create_deliveryserver($domainid, $data)

    my $data = $api->create_deliveryserver($domainid, $data);

=head2 update_deliveryserver($domainid, $serverid, $data)

    my $data = $api->update_deliveryserver($domainid, $serverid, $data);

=head2 delete_deliveryserver($domainid, $serverid, $data)

    my $data = $api->delete_deliveryserver($domainid, $serverid, $data);

=head2 get_user_deliveryservers($domainid)

    my $data = $api->get_user_deliveryservers($domainid);

=head2 get_user_deliveryserver($domainid, $serverid)

    my $data = $api->get_user_deliveryserver($domainid, $serverid);

=head2 create_user_deliveryserver($domainid, $data)

    my $data = $api->create_user_deliveryserver($domainid, $data);

=head2 update_user_deliveryserver($domainid, $serverid, $data)

    my $data = $api->update_user_deliveryserver($domainid, $serverid, $data);

=head2 delete_user_deliveryserver($domainid, $serverid, $data)

    my $data = $api->delete_user_deliveryserver($domainid, $serverid, $data);

=head2 get_authservers($domainid)

    my $data = $api->get_authservers($domainid);

=head2 get_authserver($domainid, $serverid)

    my $data = $api->get_authserver($domainid, $serverid);

=head2 create_authserver($domainid, $data)

    my $data = $api->create_authserver($domainid, $data);

=head2 update_authserver($domainid, $serverid, $data)

    my $data = $api->update_authserver($domainid, $serverid, $data);

=head2 delete_authserver($domainid, $serverid, $data)

    my $data = $api->delete_authserver($domainid, $serverid, $data);

=head2 get_ldapsettings($domainid, $serverid, $settingsid)

    my $data = $api->get_ldapsettings($domainid, $serverid, $settingsid);

=head2 create_ldapsettings($domainid, $serverid, $data)

    my $data = $api->create_ldapsettings($domainid, $serverid, $data);

=head2 update_ldapsettings($domainid, $serverid, $settingsid, $data)

    my $data = $api->update_ldapsettings($domainid, $serverid, $settingsid, $data);

=head2 delete_ldapsettings($domainid, $serverid, $settingsid, $data)

    my $data = $api->delete_ldapsettings($domainid, $serverid, $settingsid, $data);

=head2 get_radiussettings($domainid, $serverid, $settingsid)

    my $data = $api->get_radiussettings($domainid, $serverid, $settingsid);

=head2 create_radiussettings($domainid, $serverid, $data)

    my $data = $api->create_radiussettings($domainid, $serverid, $data);

=head2 update_radiussettings($domainid, $serverid, $settingsid, $data)

    my $data = $api->update_radiussettings($domainid, $serverid, $settingsid, $data);

=head2 delete_radiussettings($domainid, $serverid, $settingsid, $data)

    my $data = $api->delete_radiussettings($domainid, $serverid, $settingsid, $data);

=head2 get_domain_smarthosts($domainid)

    my $data = $api->get_domain_smarthosts($domainid);

=head2 get_domain_smarthost($domainid, $serverid)

    my $data = $api->get_domain_smarthost($domainid, $serverid);

=head2 create_domain_smarthost($domainid, $data)

    my $data = $api->create_domain_smarthost($domainid, $data);

=head2 update_domain_smarthost($domainid, $serverid, $data)

    my $data = $api->update_domain_smarthost($domainid, $serverid, $data);

=head2 delete_domain_smarthost($domainid, $serverid, $data)

    my $data = $api->delete_domain_smarthost($domainid, $serverid, $data);

=head2 get_organizations

    my $data = $api->get_organizations();

=head2 get_organization($orgid)

    my $data = $api->get_organization($orgid);

=head2 create_organization($data)

    my $data = $api->create_organization($data);

=head2 update_organization($orgid, $data)

    my $data = $api->update_organization($orgid, $data);

=head2 delete_organization($orgid)

    my $data = $api->delete_organization($orgid);

=head2 get_fallbackservers($orgid)

    my $data = $api->get_fallbackservers($orgid);

=head2 get_fallbackserver($serverid)

    my $data = $api->get_fallbackserver($serverid);

=head2 create_fallbackserver($orgid, $data)

    my $data = $api->create_fallbackserver($orgid, $data);

=head2 update_fallbackserver($serverid, $data)

    my $data = $api->update_fallbackserver($serverid, $data);

=head2 delete_fallbackserver($serverid, $data)

    my $data = $api->delete_fallbackserver($serverid, $data);

=head2 get_relay($relayid)

    my $data = $api->get_relay($relayid);

=head2 create_relay($orgid, $data)

    my $data = $api->create_relay($orgid, $data);

=head2 update_relay($relayid, $data)

    my $data = $api->update_relay($relayid, $data);

=head2 delete_relay($relayid, $data)

    my $data = $api->delete_relay($relayid, $data);

=head2 get_org_smarthosts($orgid)

    my $data = $api->get_org_smarthosts($orgid);

=head2 get_org_smarthost($orgid, $serverid)

    my $data = $api->get_org_smarthost($orgid, $serverid);

=head2 create_org_smarthost($orgid, $data)

    my $data = $api->create_org_smarthost($orgid, $data);

=head2 update_org_smarthost($orgid, $serverid, $data)

    my $data = $api->update_org_smarthost($orgid, $serverid, $data);

=head2 delete_org_smarthost($orgid, $serverid, $data)

    my $data = $api->delete_org_smarthost($orgid, $serverid, $data);

=head2 get_status

    my $data = $api->get_status();

=head1 AUTHOR

Andrew Colin Kissa, C<< <andrew at topdog.za.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-baruwaapi at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-BaruwaAPI>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::BaruwaAPI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-BaruwaAPI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-BaruwaAPI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-BaruwaAPI>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-BaruwaAPI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015-2019 Andrew Colin Kissa.

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at L<http://mozilla.org/MPL/2.0/>.


=cut
