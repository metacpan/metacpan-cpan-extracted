#!/usr/bin/env perl
use strict;
use warnings;

=pod

Generates RTM API files from the official documentation.

There are too many events for me to be bothered typing them all out,
and things are almost consistent enough for autogeneration to be useful.

=cut

use Path::Tiny;
use Scalar::Util qw(blessed);
use Template;
use JSON::MaybeUTF8 qw(:v1);
use Log::Any qw($log);
use Log::Any::Adapter qw(Stderr), log_level => 'debug';
use List::UtilsBy qw(extract_by);

my $tt = Template->new;
my $data = decode_json_text(path('slack_web.json')->slurp_utf8);

my @methods;
my %endpoints = (
    "oauth" => "https://slack.com/oauth/authorize{?client_id,scope,redirect_uri,state,team}",
    "apps_connections_open" => "https://slack.com/api/apps.connections.open",
);
for my $path (sort keys $data->{paths}->%*) {
    my $spec = $data->{paths}->{$path};
    my $method = $path =~ s{\.}{_}gr;
    $method =~ s{/}{}g;
    $method =~ s{([A-Z]+)}{_\L$1}g;
    $log->infof('%s => path [%s]', $method, $path);
    $log->errorf('>> %s has multiple HTTP methods: %s', $path, join ', ', sort keys $spec->%*) if keys $spec->%* > 1;
    my ($x) = values $spec->%*;
    extract_by { $_->{name} eq 'token' } $x->{parameters}->@*;
    my $def = {
        path => $path,
        method => $method,
        http_method => (keys $spec->%*)[0],
        spec => $x,
        args => {
            query => [ map { $_->{name} } grep { $_->{in} eq 'query' } $x->{parameters}->@* ],
            form => [ map { $_->{name} } grep { $_->{in} eq 'formData' } $x->{parameters}->@* ],
            header => [ map { $_->{name} } grep { $_->{in} eq 'header' } $x->{parameters}->@* ],
        }
    };
    $def->{http_method} = 'post' if grep { m{application/json} } $x->{consumes}->@*;
    push $def->{args}{form}->@*, splice $def->{args}{query}->@* if $def->{http_method} eq 'post';
    $log->infof('Def %s', $def);
    $tt->process(\<<'EOF', $def, \my $out) or die $tt->error;
=head2 [% method %]

[% spec.description %]

L<[% spec.externalDocs.description %]|[% spec.externalDocs.url %]>

[% IF spec.parameters.size -%]
Takes the following named parameters:

=over 4

[% FOREACH param IN spec.parameters -%]
=item * C<[% param.name %]> - [% param.description %] ([% param.type %], [% param.required ? 'required' : 'optional' %])

[% END -%]
=back

[% END -%]
Resolves to a structure representing the response.

=cut

async sub [% method %] {
    my ($self, %args) = @_;
    my $uri = $self->endpoint(
        '[% method %]',
[% IF args.query.size -%]
        %args{grep { exists $args{$_} } qw([% args.query.join(' ') %])}
[% END -%]
    );
[% IF args.form.size -%]
    my $content = encode_json_utf8({
        %args{grep { exists $args{$_} } qw([% args.form.join(' ') %])}
    });
[% END -%]
[% IF args.header.size -%]
    my $headers = {
        %args{grep { exists $args{$_} } qw([% args.header.join(' ') %])}
    };
[% END -%]
    my ($res) = await $self->http_[% http_method %](
        $uri,
[% IF args.form.size -%]
        $content,
        content_type => 'application/json; charset=utf-8',
[% END -%]
[% IF args.header.size -%]
        headers => $headers,
[% END -%]
    );
[% IF spec.responses.200.schema.properties.ok -%]
    die $res unless $res->{ok};
[% END -%]
    return $res;
}

EOF
    push @methods, $out;
    $endpoints{$method} = "https://slack.com/api" . $path . ($def->{args}{query}->@* ? '{?' . join(',', $def->{args}{query}->@*) . '}' : '');
    # $log->debugf('%s', $out);
}
path('methods.pm')->spew_utf8(join "\n", @methods);
my $json = JSON::MaybeXS->new(
    pretty => 1,
    canonical => 1
);
path('share/endpoints.json')->spew_utf8($json->encode(\%endpoints));

__END__

    $tt->process(\<<'EOF', $data, $output_filename) or die $tt->error;
package Net::Async::Slack::Event::[% classname %];

use strict;
use warnings;

# VERSION

use Net::Async::Slack::EventType;

=encoding UTF-8

=head1 NAME

Net::Async::Slack::Event::[% classname %] - [% description %]

=head1 DESCRIPTION

Example input data:

[% example | indent('    ') %]

=cut

sub type { '[% type %]' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2019. Licensed under the same terms as Perl itself.
EOF
}
