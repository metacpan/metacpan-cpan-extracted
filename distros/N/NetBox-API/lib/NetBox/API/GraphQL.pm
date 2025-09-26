package NetBox::API::GraphQL;
use strict;
use warnings 'FATAL' => 'all';
no warnings qw(experimental::signatures);
use feature qw(signatures);
use parent qw(NetBox::API::Common);

use Data::Dumper;
use GraphQL::Client;

BEGIN {
    #{{{
    require Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT = qw();
    our @EXPORT_OK = qw();
} #}}}

our $VERSION = $NetBox::API::Common::VERSION;

sub __call :prototype($$$$$) ($class, $self, $method, $query, $vars = {}) {
    #{{{
    my $graphql = GraphQL::Client->new('url' => $self->baseurl, 'unpack' => 0);
    my $headers = $self->headers;
    my $response = {};
    my $q = '';
    if (defined $vars->{'raw'}) {
        $q = $vars->{'raw'};
        $vars = {};
    } elsif ($query !~ /_list$/) {
        my $fields = join ', ', @{$vars->{'fields'}};
        delete $vars->{'fields'};
        $q = sprintf 'query %s ($id: ID!) { %s(id: $id) { %s } }', $query, $query, $fields;
    } else {
        $self->__seterror(NetBox::API::Common::E_NOTIMPLEMENTED);
        return qw();
    }
    eval {
        local $SIG{'ALRM'} = sub { die "operation timed out\n" };
        alarm $self->timeout;
        $response = $graphql->execute($q, $vars, $query, { 'headers' => $headers });
        alarm 0;
    };
    if ($@) {
        $self->__seterror(NetBox::API::Common::E_TIMEOUT);
        return qw();
    }
    if (defined $response->{'data'} and defined $response->{'data'}{$query}) {
        return @{$response->{'data'}{$query}};
    } else {
        my $line    = 'N/A';
        my $column  = 'N/A';
        my $errmsg  = 'no additional details provided';
        if (defined $response->{'errors'} and defined $response->{'errors'}[0]) {
            $line   = $response->{'errors'}[0]{'locations'}[0]{'line'};
            $column = $response->{'errors'}[0]{'locations'}[0]{'column'};
            $errmsg = $response->{'errors'}[0]{'message'};
        }
        $self->__seterror(NetBox::API::Common::E_BADQUERY, $line, $column, $errmsg);
        return qw();
    }
} #}}}

sub GET {}

1;
