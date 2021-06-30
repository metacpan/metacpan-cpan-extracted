#!/usr/local/bin/perl

use strict;
use warnings;

use utf8;

=encoding UTF8

=head1 NAME

C<crawl-api-doc.pl> - Script to read Spotify documentation page and generate classes based on endpoints and objects.

=head1 SYNOPSIS

    perl scripts/crawl-api-doc.pl -e -o

=head1 DESCRIPTION

This script gets Spotify documentation page and parse it to extract available endpoints and objects
that Spotify API supports.

=cut

=head1 OPTIONS

=over 4

=item B<-d> I<https://spotify/doc/web-api/>, B<--docs-uri>=I<Docs URI>

Spotify API documentation URI, default https://developer.spotify.com/documentation/web-api/reference/

=item B<-e>, B<--endpoint-gen>

If exists it will generate endpoint classes based on parsed response.

=item B<-o>, B<--object-gen>

If exists it will generate object classes based on parsed response.

=item B<-i>, B<--init-class>

If exists it will Generate/Overwrite Main classes for objects and endpoint
Caution only use this option to rewrite main classes.

=item B<-j>, B<--only-json>

If exists it will only print out Spotify enpoints and object structure as JSON.
Good to be piped to `jq` in order to view Spotify API structure

=item B<-l> I<debug>, B<--log-level>=I<info>

Log level used.

=back

=cut

use Pod::Usage;
use Getopt::Long;
use IO::Async::Loop;
use Future::AsyncAwait;
use Syntax::Keyword::Try;
use Log::Any qw($log);
use Net::Async::HTTP;
use URI;
use Mojo::DOM;
use Template;
use Module::Runtime qw(require_module);
use Path::Tiny;
use Data::Dumper;
use JSON::MaybeUTF8 qw(:v1);


GetOptions(
    'd|docs-uri=s'      => \(my $docs_uri = 'https://developer.spotify.com/documentation/web-api/reference/'),
    'e|endpoint-gen'    => \my $endpoint_gen,
    'o|object-gen'      => \my $object_gen,
    'i|init-class'      => \my $init_class,
    'l|log-level=s'     => \(my $log_level = 'info'),
    'j|only-json'       => \my $only_json,
    'h|help'            => \my $help,
);

require Log::Any::Adapter;
Log::Any::Adapter->set( qw(Stdout), log_level => $log_level );

pod2usage(
    {
        -verbose  => 99,
        -sections => "NAME|SYNOPSIS|DESCRIPTION|OPTIONS",
    }
) if $help;



my $loop = IO::Async::Loop->new;
my $http = Net::Async::HTTP->new(
    fail_on_error            => 1,
    close_after_request      => 0,
    max_connections_per_host => 2,
    pipeline                 => 1,
    max_in_flight            => 4,
    decode_content           => 1,
    stall_timeout            => 15,
    user_agent               => 'Mozilla/4.0 (perl; Net::Async::Spotify; VNEALV@cpan.org)',
);
$loop->add($http);

my $docs_resonse = await $http->do_request(uri => URI->new($docs_uri));

my $docs_dom = Mojo::DOM->new($docs_resonse->content);

my $endpoints;
my $objects;

$docs_dom->find('[id]')->map(attr => 'id')->each(sub {
    my $id = $_;
    if ( $id =~ /^endpoint/ ) {
        $log->infof('found an endpoint: %s', $id) unless $only_json;
        $id =~ /^endpoint-(.*)/;
        my ($ep_name) = $1 =~ s/-/_/gr;
        my $element = $docs_dom->at('#'.$id);
        my ($api_cat) =  split ' ', $element->preceding('h1[id]')->last->content;
        $endpoints->{$api_cat}{$ep_name}{short_description} = $element->text;
        @{$endpoints->{$api_cat}{$ep_name}}{qw(method uri)} = split ' ', $element->next->children->first->at('code')->content;
        chomp( $endpoints->{$api_cat}{$ep_name}{long_description} = $element->next->next->all_text );

        my $request_dom = $element->following("h5")->first;
        # Make sure it's request details.
        if ( $request_dom->content eq 'Request') {
            my $next = $request_dom->next;
            # Check all available tables.
            # header, path parameters, and query parameters
            while ( $next->tag eq 'table' ) {
                my $keys = $next->find('thead tr th')->map('content')->map(sub { lc $_ =~ s/ /_/rg; })->to_array;
                $next->find('tbody tr')->each(sub {
                    my $row = $_->children('td');
                    my $field_name = $keys->[0];
                    my $param_name = $row->first->at('code')->content =~ s/{|}//gr;
                    chomp( $endpoints->{$api_cat}{$ep_name}{request}{$field_name}{$param_name}{description} = $row->first->at('small')->all_text ) if $row->first->at('small');
                    my $c = 1;
                    $row->tail(-1)->each(sub {
                        my $r = shift;
                        my $k = $keys->[$c++];
                        $endpoints->{$api_cat}{$ep_name}{request}{$field_name}{$param_name}{$k} = lc $r->child_nodes->first->content;
                    });
                });
                $next = $next->next;
            }
        } else {
            $log->warnf('Expecting to parse Request DOM for element ID: %s', $id);
        }

        my $response_dom = $element->following("h5")->tail(-1)->first;
        if ( $response_dom->content eq 'Response') {
            my $next = $response_dom->next;
            while ( $next->tag ne 'h2' and $next->tag ne 'h1' ) {
                chomp($endpoints->{$api_cat}{$ep_name}{response}{raw} .= $next->all_text =~ s/^\s|\s$//rgm );
                push $endpoints->{$api_cat}{$ep_name}{response}{objects}->@*, ($next->content =~ /(\w+ object)/);
                $next = $next->next;
            }
        } else {
            $log->warnf('Expecting to parse Response DOM for element ID: %s', $id);
        }
        $log->tracef('API Category: %s, name: %s | element: %s | request: %s', $api_cat, $ep_name, Dumper($endpoints->{$api_cat}{$ep_name}), $request_dom);
    } elsif ( $id =~ /^object-/ ) {
        $log->infof('found an object: %s', $id) unless $only_json;
        my $element = $docs_dom->at('#'.$id);
        my $o_name = $element->content =~ s/Object//r;
        $log->tracef('Class %s', $o_name);

        my $next = $element->next;
        if ( $next->tag eq 'table' ) {
            $next->find('tbody tr')->each(sub {
                my $row = $_->children('td');
                my $field_name = $row->first->at('code')->content;
                chomp( $objects->{$o_name}{$field_name}{description} = $row->first->at('small')->all_text ) if $row->first->at('small');
                $objects->{$o_name}{$field_name}{type} = $row->tail(-1)->first->content;
            });
        } else {
            $log->warnf('Expected table for Object details, %s', $id);
        }
        $log->tracef('Object %s | %s', $o_name, Dumper($objects->{$o_name}));
    }
});

push @INC, path('lib/')->absolute->stringify;

sub gen_from_template {
    my ($template, $vars, $output, $module) = @_;
    my $tt = Template->new;
    $tt->process(
        $template, $vars, $output
    ) or die $tt->error;
    $log->infof('Testing generated Class %s for compiling...', $module) unless $only_json;
    try {
        require_module($module);
        $log->info('Compiled fine.') unless $only_json;
    } catch ($e) {
        $log->warnf('Failed compiling generate API %s | error: %s', $module, $e);
    }
}

sub generate_api_classes {
    for my $api (keys %$endpoints) {
        $log->infof('Generating API %s', $api) unless $only_json;
        my $vars = {endpoints => $endpoints->{$api}, api_name => $api,};
        gen_from_template('scripts/SpotifyAPI_pm.tt2', $vars, "lib/Net/Async/Spotify/API/Generated/$api.pm", "Net::Async::Spotify::API::Generated::$api");
        if ( !path("lib/Net/Async/Spotify/API/$api.pm")->exists or $init_class) {
            $log->infof('Generating Main API %s', $api) unless $only_json;
            gen_from_template('scripts/SpotifyAPI_main_pm.tt2', $vars, "lib/Net/Async/Spotify/API/$api.pm", "Net::Async::Spotify::API::$api");
        }
    }
}

sub generate_obj_classes {
    for my $obj (keys %$objects) {
        $log->infof('Generating Object %s', $obj) unless $only_json;
        my $vars = {fields => $objects->{$obj}, obj_name => $obj,};
        gen_from_template('scripts/SpotifyObj_pm.tt2', $vars, "lib/Net/Async/Spotify/Object/Generated/$obj.pm", "Net::Async::Spotify::Object::Generated::$obj");
        if ( !path("lib/Net/Async/Spotify/Object/$obj.pm")->exists or $init_class) {
            $log->infof('Generating Main Object %s', $obj) unless $only_json;
            gen_from_template('scripts/SpotifyObj_main_pm.tt2', $vars, "lib/Net/Async/Spotify/Object/$obj.pm", "Net::Async::Spotify::Object::$obj");
        }
    }
}

$log->infof('%s', encode_json_utf8({enpoints => $endpoints, objects => $objects})) if $only_json;
generate_api_classes() if $endpoint_gen;
generate_obj_classes() if $object_gen;

$log->info('FINISHED;') unless $only_json;
