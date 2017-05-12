package Net::GrowthForecast;

use strict;
use warnings;
use Carp;

use List::MoreUtils qw//;

use Furl;
use JSON::XS;

use Try::Tiny;

our $VERSION = '0.02';

#TODO: basic authentication support

sub new {
    my ($this, %opts) = @_;
    my $prefix = $opts{prefix} || '/';
    $prefix = '/' . $prefix unless $prefix =~ m!^/!;
    $prefix =~ s!/$!!;

    my $self = +{
        host => $opts{host} || 'localhost',
        port => $opts{port} || 5125,
        prefix => $prefix,
        timeout => $opts{timeout} || 30,
        useragent => 'Net::GrowthForecast',
    };
    $self->{furl} = Furl::HTTP->new(agent => $self->{useragent}, timeout => $self->{timeout}, max_redirects => 0);
    $self->{debug} = $opts{debug} || 0;

    bless $self, $this;
    $self;
}

sub _url {
    my ($self, $path) = @_;
    my $base = 'http://' . $self->{host} . ($self->{port} == 80 ? '' : ':' . $self->{port}) . $self->{prefix};
    $path ||= '/';
    $base . $path;
}

sub _request {
    my ($self, $method, $path, $headers, $content) = @_;
    my $url = $self->_url($path);
    my @res;
    my $list = undef;
    if ($method eq 'GET') {
        @res = $self->{furl}->get( $url, $headers || [], $content );
    } elsif ($method eq 'GET_LIST') {
        @res = $self->{furl}->get( $url, $headers || [], $content );
        $list = 1;
    } elsif ($method eq 'POST') {
        @res = $self->{furl}->post( $url, $headers || [], $content );
    } else {
        die "not implemented here.";
    }
    # returns a protocol minor version, status code, status message, response headers, response body
    my ($protocol_ver, $code, $message, $h, $c) = @res;
    $self->_check_response($url, $method, $code, $c, $list);
}

sub _check_response {
    # check response body with "$c->render_json({ error => 1 , message => '...' })" style error status
    my ($self, $url, $method, $code, $content, $list_flag) = @_;
    return [] if $list_flag and $code eq '404';
    if ($code ne '200') {
        # TODO fix GrowthForecast::Web not to return 500 when graph not found (or other case...)
        if ($self->{debug}) {
            carp "GrowthForecast returns response code $code";
            carp " request ($method) $url";
            carp " with content $content";
        }
        return undef;
    }
    return 1 unless $content;
    my $error;
    my $obj;
    try {
        $obj = decode_json($content);
        if (defined($obj) and ref($obj) eq 'ARRAY') {
            return $obj;
        } elsif (defined($obj) and $obj->{error}) {
            warn "request ended with error:";
            foreach my $k (keys %{$obj->{messages}}) {
                warn "  $k: " . $obj->{messages}->{$k};
            }
            warn "  request(" . $method . "):" .  $url;
            warn "  request body:" . $content;
            $error = 1;
        }
    } catch { # failed to parse json
        warn "failed to parse response content as json, with error: $_";
        warn "  content:" . $content;
        $error = 1;
    };
    return undef if $error;
    return $obj if ref($obj) eq 'ARRAY';
    if (defined $obj->{error}) {
        return $obj->{data} if $obj->{data};
        return 1;
    }
    $obj;
}

sub post { # options are 'mode' and 'color' available
    my ($self, $service, $section, $name, $value, %options) = @_;
    $self->_request('POST', "/api/$service/$section/$name", [], [ number => $value, %options ] );
}

sub by_name {
    my ($self, $service, $section, $name) = @_;
    my $tree = $self->tree();
    (($tree->{$service} || {})->{$section} || {})->{$name};
}

sub graph {
    my ($self, $id) = @_;
    if (ref($id) and ref($id) eq 'Hash' and defined $id->{id}) {
        $id = $id->{id};
    }
    $self->_request('GET', "/json/graph/$id");
}

sub complex {
    my ($self, $id) = @_;
    if (ref($id) and ref($id) eq 'Hash' and defined $id->{id}) {
        $id = $id->{id};
    }
    $self->_request('GET', "/json/complex/$id");
}

sub graphs {
    my ($self) = @_;
    $self->_request('GET_LIST', "/json/list/graph");
}

sub complexes {
    my ($self) = @_;
    $self->_request('GET_LIST', "/json/list/complex");
}

sub all {
    my ($self) = @_;
    $self->_request('GET_LIST', "/json/list/all");
}

sub tree {
    my ($self) = @_;
    my $services = {};
    my $all = $self->all();
    foreach my $node (@$all) {
        $services->{$node->{service_name}} ||= {};
        $services->{$node->{service_name}}->{$node->{section_name}} ||= {};
        $services->{$node->{service_name}}->{$node->{section_name}}->{$node->{graph_name}} = $node;
    }
    $services;
}

sub edit {
    my ($self, $spec) = @_;
    unless (defined $spec->{id}) {
        croak "cannot edit graph without id (get graph data from GrowthForecast at first)";
    }
    my $path;
    if (defined $spec->{complex} and $spec->{complex}) {
        $path = "/json/edit/complex/" . $spec->{id};
    } else {
        $path = "/json/edit/graph/" . $spec->{id};
    }
    $self->_request('POST', $path, [], encode_json($spec));
}

sub delete {
    my ($self, $spec) = @_;
    unless (defined $spec->{id}) {
        croak "cannot delete graph without id (get graph data from GrowthForecast at first)";
    }
    my $path;
    if (defined $spec->{complex} and $spec->{complex}) {
        $path = "/delete_complex/" . $spec->{id};
    } else {
        $path = join('/', "/delete", $spec->{service_name}, $spec->{section_name}, $spec->{graph_name});
    }
    $self->_request('POST', $path);
}

my @ADDITIONAL_PARAMS = qw(description sort gmode ulimit llimit sulimit sllimit type stype adjust adjustval unit);
sub add {
    my ($self, $spec) = @_;
    if (defined $spec->{complex} and $spec->{complex}) {
        return $self->_add_complex($spec);
    }
    if (List::MoreUtils::any { defined $spec->{$_} } @ADDITIONAL_PARAMS) {
        carp "cannot specify additional parameters for basic graph creation (except for 'mode' and 'color')";
    }
    $self->add_graph($spec->{service_name}, $spec->{section_name}, $spec->{graph_name}, $spec->{number}, $spec->{color}, $spec->{mode});
}

sub add_graph {
    my ($self, $service, $section, $graph_name, $initial_value, $color, $mode) = @_;
    unless (List::MoreUtils::all { defined($_) and length($_) > 0 } $service, $section, $graph_name) {
        croak "service, section, graph_name must be specified";
    }
    $initial_value = 0 unless defined $initial_value;
    my %options = ();
    if (defined $color) {
        croak "color must be specified like #FFFFFF" unless $color =~ m!^#[0-9a-fA-F]{6}!;
        $options{color} = $color;
    }
    if (defined $mode) {
        $options{mode} = $mode;
    }
    $self->post($service, $section, $graph_name, $initial_value, %options)
        and 1;
}

sub add_complex {
    my ($self, $service, $section, $graph_name, $description, $sumup, $sort, $type, $gmode, $stack, @data_graph_ids) = @_;
    unless ( List::MoreUtils::all { defined($_) } ($service,$section,$graph_name,$description,$sumup,$sort,$type,$gmode,$stack)
          and scalar(@data_graph_ids) > 0 ) {
        croak "all arguments must be specified, but missing";
    }
    croak "sort must be 0..19" unless $sort >= 0 and $sort <= 19;
    croak "type must be one of AREA/LINE1/LINE2, but '$type'" unless $type eq 'AREA' or $type eq 'LINE1' or $type eq 'LINE2';
    croak "gmode must be one of gauge/subtract" unless $gmode eq 'gauge' or $gmode eq 'subtract';
    my $spec = +{
        complex => JSON::XS::true,
        service_name => $service,
        section_name => $section,
        graph_name => $graph_name,
        description => $description,
        sumup => ($sumup ? JSON::XS::true : JSON::XS::false),
        sort => int($sort),
        data => [ map { +{ graph_id => $_, type => $type, gmode => $gmode, stack => $stack } } @data_graph_ids ],
    };
    $self->_add_complex($spec);
}

sub _add_complex { # used from add_complex() and also from add() directly (with spec format argument)
    my ($self, $spec) = @_;
    $self->_request('POST', "/json/create/complex", [], encode_json($spec) );
}

sub debug {
    my ($self, $mode) = @_;
    if (scalar(@_) == 2) {
        $self->{debug} = $mode ? 1 : 0;
        return;
    }
    # To use like this; $gf->debug->add(...)
    Net::GrowthForecast->new(%$self, debug => 1);
}

1;
__END__

=encoding utf8

=head1 NAME

Net::GrowthForecast - A client library for awesome visualization tool GrowthForecast

=head1 SYNOPSIS

    use Net::GrowthForecast;

    my $gf = Net::GrowthForecast->new( host => 'localhost', port => 5125 );

    $gf->post( 'serviceName', 'sectionName', 'graphName', $update_value );

    $gf->graphs();   #=> arrayref of hashref
    $gf->complexes();
    $gf->all();

    $gf->graph( $graph_id );   # hashref
    $gf->complex( $complex_id );
    $gf->by_name( $service_name, $section_name, $graph_name );

    my $graph = $gf->all()->[0];
    $graph->{description} = 'update description of your graph';
    $gf->edit($graph);

    my $spec = $gf->all()->[0];
    $graph->{graph_name} = 'copy_of_' . $graph->{graph_name};
    $gf->add($graph);

    my $graph = pop @{ $gf->all() };
    $gf->delete($graph);

=head1 DESCRIPTION

Net::GrowthForecast is a client library for GrowthForecast JSON API. This supports GET/LIST/EDIT/ADD/REMOVE simple graphs and complex graphs.

USE GrowthForecast v0.33 or later

=head1 METHODS

=over 4

=item my $gf = Net::GrowthForecast->new( %opts )

Create client instance for growhtforecast. All options are optional.

host: Your growthforecast hostname as string (default: 'localhost')

port: Port number (default: 5125)

prefix: URI path prefix string if you use reverse-proxy and mounts growthforecast on sub directory. (default: none)

timeout: HTTP timeout seconds (default: 30)

debug: Debug mode for HTTP request/response (default: false)

=item $gf->post( $service, $section, $name, $value, %opts )

Update graph (specified by service, section, name) number value as $value. %opts (optional) are:

mode: 'gauge', 'count', 'modified', or 'derive' (default: 'gauge')

color: update graph color like '#FF8800' (default: not changed, or random (when creation))

=item $gf->graphs()

Return arrayref of hashref, includes list of basic graph, like:

    [ { id => 1, service_name => '...', section_name => '...', graph_name => '...' }, { id => 2, ... }, ... ]

=item $gf->complexes()

Return arrayref of hashref, includes list of complex graph, like:

    [ { id => 1, service_name => '...', section_name => '...', graph_name => '...' }, { id => 2, ... }, ... ]

You should take care that 'id' of complex graph and basic graph is not unique - basic graph id '1' and complex graph id '1' may also exists at the same time. 'service/section/graph' name is unique key of graphs.

=item $gf->graph( $graph_id )

Return graph detail as hashref like:

    {
      id => 13,
      
      service_name => 'example',
      section_name => 'test',
      graph_name   => 'sample1',
      
      complex => 0,
      
      description => '',
      mode    => 'gauge',
      sort    => 0,
      color   => '#ff0000',
      gmode   => 'gauge',
      type    => 'LINE2',
      ulimit  => 1000000000,
      llimit  => -1000000000,
      stype   => 'AREA',
      sulimit => 100000,
      sllimit => -100000,
      adjust  => '*',
      adjustval => 1,
      unit    => '',
      
      number  => 0,
      data    => [],
      created_at => '2012/12/31 10:57:46',
      updated_at => '2012/12/31 10:57:46'
    }

=item $gf->complex( $complex_id )

Return graph detail as hashref like:

    {
      id => 2,
      
      section_name => 'test',
      service_name => 'example',
      graph_name   => 'sample2',
      
      complex  => 1,
      
      data => [
                {
                  gmode    => 'gauge',
                  graph_id => 1,
                  stack    => \0,
                  type     => 'LINE1'
                },
                {
                  gmode    => 'gauge',
                  graph_id => 45,
                  stack    => 1,
                  type     => 'LINE1'
                },
                {
                  gmode    => 'gauge',
                  graph_id => 46,
                  stack    => 1,
                  type     => 'LINE1'
                }
              ],
      
      description => 'testing now',
      sort  => 19,
      sumup => 1,
      
      number => 0,
      created_at => '2012/12/31 11:32:22',
      updated_at => '2012/12/31 11:32:22'
    }

=item $gf->all()

Returns arrayref of both detail basic graph hashref and detail complex graph hashref.

=item $gf->tree()

Returns hashref, contains serice - section - graph_name as directory tree, for both of graph and complex. Value of $tree->{$service}->{$section}->{$graph_name} is detail graph infomation.

=item $gf->by_name( $service, $section, $graph_name )

Returns detail graph info for complex or not. (Relatively heavy: you should use cached $gf->tree() result for many queries)

=item $gf->edit( $graph || $complex )

Update graph data with specified object's values. Returns success or not.

=item $gf->delete( $graph || $complex )

Delete graph data with specified object's id. Returns success or not.

=item $gf->add( $spec )

Add graph or complex graph, with specified detail graph object's spec. 'id' is ignored if exits. Request will fail with non-unique'service/section/graph' values.

Returns success or not.

=item $gf->add_graph( $service, $section, $graph_name, $init_value [, $color, $mode] )

Add basic graph with specified service/section/name and value. 'color' and 'mode' are optional.

mode: You should specify $mode at graph creation if you want 'derive' graph.

Returns success or not.

=item $gf->add_complex( $service, $section, $graph_name, $description, $sumup, $sort, $type, $gmode, $stack, @data_graph_ids )

Add complex graph with specified options. All arguments are reequired, and type/gmode/stack will used for all sub data graphs. Returns success or not.

=back

=head1 AUTHOR

tagomoris (TAGOMORI Satoshi) E<lt>tagomoris {at} gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modifyit under the same terms as Perl itself.

=cut
