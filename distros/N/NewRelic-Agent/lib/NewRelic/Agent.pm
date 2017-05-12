package NewRelic::Agent;
use strict;
use warnings;

our $VERSION = '0.0532';

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub new {
    my ($self, %args) = @_;

    my $license_key          = delete $args{license_key}
                            || $ENV{NEWRELIC_LICENSE_KEY}
                            || '';
    my $app_name             = delete $args{app_name}
                            || $ENV{NEWRELIC_APP_NAME}
                            || 'AppName';
    my $app_language         = delete $args{app_language}
                            || $ENV{NEWRELIC_APP_LANGUAGE}
                            || 'perl';
    my $app_language_version = delete $args{app_language_version}
                            || $ENV{NEWRELIC_APP_LANGUAGE_VERSION}
                            || $];

    if (%args) {
        require Carp;
        Carp::croak("Invalid arguments: @{[ keys %args ]}");
    }

    return $self->_new($license_key, $app_name, $app_language, $app_language_version);
}

1;

# ABSTRACT: Perl Agent for NewRelic APM

__END__

=pod

=encoding UTF-8

=head1 NAME

NewRelic::Agent - Perl Agent for NewRelic APM

=head1 VERSION

version 0.0532

=head1 SYNOPSIS

    use NewRelic::Agent;

    my $agent = NewRelic:Agent->new(
        license_key => 'abc123',
        app_name    => 'REST API',
    );

    $agent->embed_collector;
    $agent->init;
    my $txn_id = $agent->begin_transaction;
    ...
    my $err_id = $agent->end_transaction($txn_id);

=head1 DESCRIPTION

This module provides bindings for the L<NewRelic|https://docs.newrelic.com/docs/agents/agent-sdk/getting-started/new-relic-agent-sdk> Agent SDK.

=for markdown [![Build Status](https://travis-ci.org/aanari/NewRelic-Agent.svg?branch=master)](https://travis-ci.org/aanari/NewRelic-Agent)

=head1 METHODS

=head2 new

Instantiates a new NewRelic::Agent client object.

    my $agent = NewRelic::Agent->new(
        license_key          => $license_key,
        app_name             => $app_name,
        app_language         => $app_language,         #optional
        app_language_version => $app_language_version, #optional
    );

B<Parameters>

=over 4

=item - C<license_key>

A valid NewRelic license key for your account.

This value is also automatically sourced from the C<NEWRELIC_LICENSE_KEY> environment variable.

=item - C<app_name>

The name of your application.

This value is also automatically sourced from the C<NEWRELIC_APP_NAME> environment variable.

=item - C<app_language>

The language that your application is written in.

This value defaults to C<perl>, and can also be automatically sourced from the C<NEWRELIC_APP_LANGUAGE> environment variable.

=item - C<app_language_version>

The version of the language that your application is written in.

This value defaults to your perl version, and can also be automatically sourced from the C<NEWRELIC_APP_LANGUAGE_VERSION> environment variable.

=back

=head2 embed_collector

Embeds the collector agent for harvesting NewRelic data. This should be called before C<init>, if the agent is being used in Embedded mode and not Daemon mode.

B<Example:>

    $agent->embed_collector;

=head2 init

Initialize the connection to NewRelic.

B<Example:>

    $agent->init;

=head2 begin_transaction

Identifies the beginning of a transaction, which is a timed operation consisting of multiple segments. By default, transaction type is set to C<WebTransaction> and transaction category is set to C<Uri>.

Returns the transaction's ID on success, else negative warning code or error code.

B<Example:>

    my $txn_id = $agent->begin_transaction;

=head2 set_transaction_name

Sets the transaction's name.

Returns C<0> on success, else negative warning code or error code.

B<Example:>

    my $err_id = $agent->set_transaction_name($txn_id, 'Create Account');

=head2 set_transaction_request_url

Sets the transaction's request url. The query part of the url is automatically stripped from the url.

Returns C<0> on success, else negative warning code or error code.

B<Example:>

    my $err_id = $agent->set_transaction_request_url($txn_id, 'api.myapp.com/users/123');

=head2 set_transaction_max_trace_segments

Sets the maximum number of trace segments allowed in a transaction trace. By default, the maximum is set to C<2000>, which means the first 2000 segments in a transaction will create trace segments if the transaction exceeds the trace theshold (4 x apdex_t).

Returns C<0> on success, else negative warning code or error code.

B<Example:>

    my $err_id = $agent->set_transaction_max_trace_segments($txn_id, 5000);

=head2 set_transaction_category

Sets the transaction's category name (.e.g C<Uri> in "WebTransaction/Uri/<txn_name>").

Returns C<0> on success, else negative warning code or error code.

B<Example:>

    my $err_id = $agent->set_transaction_category($txn_id, 'Custom');

=head2 set_transaction_type_web

Sets the transaction type to C<WebTransaction>. This will automatically change the category to C<Uri>.

Returns C<0> on success, else negative warning code or error code.

B<Example:>

    my $err_id = $agent->set_transaction_type_web($txn_id);

=head2 set_transaction_type_other

Sets the transaction type to C<OtherTransaction>. This will automatically change the category to C<Custom>.

Returns C<0> on success, else negative warning code or error code.

B<Example:>

    my $err_id = $agent->set_transaction_type_other($txn_id);

=head2 add_transaction_attribute

Sets a transaction attribute. Up to the first 50 attributes added are sent with each transaction.

Returns C<0> on success, else negative warning code or error code.

B<Example:>

    my $err_id = $agent->add_transaction_attribute($txn_id, 'User-Agent', 'Mozilla/5.0 ...');

=head2 notice_transaction_error

Identify an error that occurred during the transaction. The first identified error is sent with each transaction.

Returns C<0> on success, else negative warning code or error code.

B<Example:>

    my $err_id = $agent->notice_transaction_error(
        $txn_id,
        'Runtime error',
        'Illegal division by zero',
        "Illegal division by zero at div0.pl line 4.\nmain::run() called at div0.pl line7",
        "\n",
    );

=head2 end_transaction

Identify the end of a transaction.

Returns C<0> on success, else negative warning code or error code.

B<Example:>

    my $err_id = $agent->end_transaction($txn_id);

=head2 record_metric

Record a custom metric.

Returns C<0> on success, else negative warning code or error code.

B<Example:>

    my $err_id = $agent->record_metric('cache_miss_timing', 0.333333);

=head2 record_cpu_usage

Record CPU user time in seconds and as a percentage of CPU capacity.

Returns C<0> on success, else negative warning code or error code.

B<Example:>

    my $err_id = $agent->record_cpu_usage(2.1, 0.85);

=head2 record_memory_usage

Record the current amount of memory (in megabytes) being used.

Returns C<0> on success, else negative warning code or error code.

B<Example:>

    my $err_id = $agent->record_memory_usage(745);

=head2 begin_generic_segment

Identify the beginning of a segment that performs a generic operation. This type of segment does not create metrics, but can show up in a transaction trace if a transaction is slow enough.

Returns the segment's ID on success, else negative warning code or error code.

B<Example:>

    my $seg_id = $agent->begin_generic_segment($txn_id, undef, 'Parse zip codes');

=head2 begin_datastore_segment

Identify the beginning of a segment that performs a database operation. This uses the default sql_obfuscator that strips the SQL string literals and numeric sequences, replacing them with the C<?> character.

Returns the segment's ID on success, else negative warning code or error code.

B<Example:>

    my $seg_id = $agent->begin_datastore_segment(
        $txn_id,
        undef,
        'users',
        'selecting user',
        'SELECT * FROM users WHERE id=?',
        'get_user_account',
    );

=head2 begin_external_segment

Identify the beginning of a segment that performs an external service.

Returns the segment's ID on success, else negative warning code or error code.

B<Example:>

    my $seg_id = $agent->begin_external_segment(
        $txn_id,
        undef,
        'http://api.stripe.com/v1',
        'tokenize credit card',
    );

=head2 end_segment

Identify the end of a segment.

Returns C<0> on success, else negative warning code or error code.

B<Example:>

    my $err_id = $agent->end_segment($txn_id, $seg_id);

=head2 get_license_key

Returns the license key that the agent has loaded. This is useful for diagnostic purposes.

B<Example:>

    my $license_key = $agent->get_license_key;

=head2 get_app_name

Returns the application name that the agent has loaded. This is useful for diagnostic purposes.

B<Example:>

    my $app_name = $agent->get_app_name;

=head2 get_app_language

Returns the application language that the agent has loaded. This is useful for diagnostic purposes.

B<Example:>

    my $app_language = $agent->get_app_language;

=head2 get_app_language_version

Returns the application language's version that the agent has loaded. This is useful for diagnostic purposes.

B<Example:>

    my $app_language_version = $agent->get_app_language_version;

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/aanari/NewRelic-Agent/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Ali Anari <ali@anari.me>

=head1 CONTRIBUTORS

=for stopwords Slobodan Mišković Tatsuhiko Miyagawa Tim Bunce

=over 4

=item *

Slobodan Mišković <slobodan@miskovic.ca>

=item *

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

=item *

Tim Bunce <tim.bunce@pobox.com>

=item *

Tim Bunce <tim@tigerlms.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ali Anari.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
