package Odoo::Database::Manager;
use v5.20;
use strict;
use warnings;

our $VERSION = '0.03';

use JSON::RPC2::Client;
use JSON::XS;
use LWP::UserAgent;
use HTTP::Request;


use failures qw/odoo::rpc::http odoo::rpc::http::connection odoo::rpc::response odoo::rpc::method odoo::nopassword/;

use Moose;
use namespace::autoclean;

has url => (is => 'ro', isa => 'Str', default => 'http://localhost:8069');
has password => (is => 'ro', required => 0, isa => 'Str', default => 'admin');

has ua => (is => 'ro', lazy => 1, builder => 'build_ua');
has json_rpc_client => (is => 'ro', lazy => 1, builder => 'build_json_rpc_client');

sub build_ua {
    return LWP::UserAgent->new();
}

sub build_json_rpc_client {
    return JSON::RPC2::Client->new();
}

sub list_databases {
    my ($self) = @_;
    my $dbs = $self->_execute('/web/database/get_list', 'call');
    return @$dbs;
}

sub createdb {
    my ($self, %params) = @_;
    my $dbname = $params{dbname} or die 'must specify dbname';
    my $lang = $params{lang} or die 'must specify lang';
    my $admin_password = $params{admin_password} or die 'must specify admin_password';
    failure::odoo::nopassword->throw('password not specified')
        unless defined $self->password;
    # TODO support demo option
    $self->_execute('/web/database/create', 'call', [$self->_cvt_params(
        super_admin_pwd => $self->password,
        db_name => $dbname,
        db_lang => $lang,
        create_admin_pwd => $admin_password,
        create_confirm_pwd => $admin_password,
    )]);
    # {"jsonrpc":"2.0","method":"call","params":{"fields":[{"name":"super_admin_pwd","value":"admin"},{"name":"db_name","value":"another"},{"name":"db_lang","value":"en_GB"},{"name":"create_admin_pwd","value":"password"},{"name":"create_confirm_pwd","value":"password"}]},"id":776199543}
}

sub _cvt_params {
    my ($self, %params) = @_;
    return (fields => [ map { { name => $_, value => $params{$_} } } keys(%params) ]);
}

sub dropdb {
    my ($self, $dbname) = @_;
    die 'must specify $dbname' unless $dbname;
    failure::odoo::nopassword->throw('password not specified')
        unless defined $self->password;
    $self->_execute('/web/database/drop', 'call', [
        $self->_cvt_params( drop_db => $dbname, drop_pwd => $self->password ),
    ]);
    #{"jsonrpc":"2.0","method":"call","params":{"fields":[{"name":"drop_db","value":"another"},{"name":"drop_pwd","value":"wrongpass"}]},"id":692816518}
}

sub _execute {
    my ($self, $urlpart, $method, @args) = @_;

    my $url = $self->url . $urlpart;  # TODO Use a URI library
    my $jsonreq = $self->json_rpc_client->call($method, @args);
    my $json = decode_json($jsonreq);
    $json->{params} //= {};
    $jsonreq = encode_json($json);
    my $request = HTTP::Request->new(POST => $url);
    $request->content_type('application/json');
    $request->header(Accept => 'application/json, text/javascript, */*; q=0.01');
    $request->content($jsonreq);

    my $res = $self->ua->request($request);

    unless ($res->is_success) {
        my $subclass = ($res->status_line =~ /^500 Can't connect to/) ? "::connection" : "";
        "failure::odoo::rpc::http$subclass"->throw({
            msg => $res->status_line,
            payload => { result => $res }
        });
    }

    my ($failed, $result, $error) = $self->json_rpc_client->response($res->content);
    failure::odoo::rpc::response->throw($failed)
        if $failed;

    if ($error) {
        my $code = $error->{code};
        my $message = $error->{message};
        failure::odoo::rpc::method->throw({
            msg => qq/method $method failed with code=$code: $message/,
            payload => $error,
        });
    }
    return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Odoo::Database::Manager

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use v5.20;
    use Odoo::Database::Manager;

    my $dbman = Odoo::Database::Manager->new(
        url => 'http://localhost:8069',
        password => 'manager_admin_password');

    say "Current databases:";
    say for $dbman->list_databases;

    say "Creating new database foo:";
    $dbman->createdb(dbname => 'foo', lang => 'en_GB', admin_password => 'admin'); 

    say "Dropping foo again:";
    $dbman->dropdb('foo');

=head1 DESCRIPTION

Create and drop Odoo databases from your Perl scripts

=head1 NAME

Odoo::Database::Manager - database management for Odoo (EXPERIMENTAL)

=head1 STATUS

EXPERIMENTAL

=head1 METHODS

=head2 list_databases

Return list of Odoo databases.

    my @dbs = $dbman->list_databases;

=head2 createdb

Create a database.  No meaningful return value as yet.

    $dbman->createdb(dbname => 'my_db', lang => 'en_GB', admin_password => 'password');

=head2 dropdb

Drop the database.  No meaningful return value as yet.

    $dbman->dropdb('my_db');

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 Nick Booker

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Nicholas Booker <nmb+cpan@nickbooker.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Nicholas Booker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
