use strict;
use warnings;

package MooseX::Role::REST::Consumer;

use MooseX::Role::Parameterized;
use MooseX::Role::REST::Consumer::Response;
use File::Spec;
use REST::Consumer;
use Try::Tiny;
use URI::Escape;
use Module::Load;

our $VERSION = '0.003';

my @HTTP_METHODS = qw(get put post delete);

parameter service_host => (
  lazy    => 1,
  default => '',
);

parameter service_port => ();

parameter resource_path => (
  lazy    => 1,
  default => sub { undef },
);

parameter content_type => (
  isa      => 'Str',
  required => 1,
  default  => 'application/json',
);

parameter header_exclude => (
  isa     => 'HashRef',
  default => sub {{}},
);

parameter retry   => (
  required => 1,
  default  => 0,
);

parameter timeout => (
  default => 1,
);

parameter query_params_mapping => (
  isa     => 'HashRef',
  default => sub {{}},
);

parameter useragent_class => (
  isa => 'Str',
);

role {
  my $p = shift;

  my $service_host         = $p->service_host;
  my $service_port         = $p->service_port;
  my $resource_path        = $p->resource_path;
  my $content_type         = $p->content_type;
  my $retry                = $p->retry;
  my $timeout              = $p->timeout;
  my $query_params_mapping = $p->query_params_mapping;
  my $useragent_class      = $p->useragent_class;

  #Note: since this is a parametrized role then only one class will be closing
  #over this variable and this instance only depends on role parameters
  my $consumer_instance;

  #Note: $class varible in methods of this role can be an instance and a class name
  #For GET requests this is usually a class name, for POST requests
  #this would usually be an instance.
  #Be carefull!

  method 'consumer' => sub {
    my ($class) = @_;
    return $consumer_instance if($consumer_instance);

    my $user_agent;

    if($useragent_class) {
      Module::Load::load($useragent_class);
      $user_agent = $useragent_class->new;
    };

    my $client = REST::Consumer->new(
      host    => $service_host,
      timeout => $timeout,
      ($user_agent ? (ua => $user_agent) : ()),
      ($service_port ? (port => $service_port) : ())
    );

    $client->user_agent->use_eval(0);

    $consumer_instance = $client;
    return $client;
  };

  method 'call' => sub {
    my ($class, $method, %params) = @_;

    my %request_headers = $class->request_headers(
      header_exclude => $p->header_exclude,
      headers        => $params{headers},
      content_type   => $p->content_type,
      method         => $method,
    );

    $content_type = delete $request_headers{'Content-Type'};
    if ($params{access_token}) {
      $request_headers{Authorization} = 'Bearer ' . $params{access_token};
    }

    my %query_params = $class->query_params(
      params               => $params{params},
      query_params_mapping => $query_params_mapping,
    );

    my $path = $class->request_path(
      resource_path => $resource_path,
      route_params  => delete $params{route_params},
      path          => delete $params{path},
    );

    my ($data, $error, $timeout_error) = (undef, '', 0);

    my %request = (
      params       => \%query_params,
      content      => $params{content},
      path         => $path,
      content_type => $content_type,
      headers      => ( %request_headers ? [ %request_headers ] : undef ),
    );

    #my $logger = $class->get_logger
    #$logger->start_request(
    #  type      => $method,
    #  path      => $path,
    #  response  => $data,
    #  request   => \%request
    #);

    my $consumer = $class->consumer; #we want same instance throughout the whole process
    $consumer->host(delete $params{host}) if $params{host};

    if (my $timeout_override = delete $params{timeout} ) {
      $consumer->timeout($timeout_override);
    }

    my $try = 0;
    while ($try <= $retry) {
      my $is_success;
      try {
        $try++;
        $data       = $consumer->$method(%request);
        $is_success = 1;
      } catch {
        $error = $_;
        $timeout_error++ if $error =~ /read timeout/;
      };
      last if $is_success;
   }

    $consumer->timeout($timeout);
    $consumer->host($service_host);

    #$logger->finish($log_entry, {
    #  type      => $method,
    #  path      => $path,
    #  response  => $data,
    #  request   => \%request
    #});

    # TODO: It's confusing as to how we handle errors.
    # ie: message should be called "error_message" and
    # we should inspect the response content for possible error messages
    return MooseX::Role::REST::Consumer::Response->new(
      data          => $data,
      is_success    => !$error,
      error_message => "$error",
      request       => $consumer->last_request,
      content_type  => $content_type,
      response      => $consumer->last_response,
    );
  };

  # Note: REST::Consumer doesn't support OPTIONS/PATCH
  for my $method ( @HTTP_METHODS ) {
      method $method => sub {
        my $class = shift;
        $class->call($method, @_);
      }
  }

  method 'request_headers' => sub {
      my ($class, %params) = @_;
      my %request_headers = ($params{headers} ? %{delete $params{headers}} : ());
      # Strange mutation going on here:
      # 1. First we set the content_type in the headers if we have one set in parameter definition
      # 2. However, we won't override anything that is passed explicitly into a method call Class->post
      # 3. Next we delete anything that needs to be removed from the header
      # 4. Finally we explicltly pull out content-type from the request_headers
      #    to make REST::Consumer happy
      $request_headers{'Content-Type'} = $params{content_type} unless $request_headers{'Content-Type'};
      delete @request_headers{@{$params{header_exclude}->{$params{method}}}} if $params{header_exclude}->{$params{method}};
      return %request_headers;
  };
  method 'request_path' => sub {
    my ($class, %params) = @_;

    my $resource_path = $params{resource_path};
    my $route_params  = $params{route_params};
    my $params_path   = $params{path};
    my @path          = (defined $resource_path ? $resource_path : ());

    if($params_path) {
      if(ref($params_path) eq 'ARRAY') {
        push(@path, @$params_path);
      } else {
        push(@path, $params_path);
      }
    }
    my $path = File::Spec->catfile(@path) . ( $resource_path && $resource_path =~ m{[^/]+/$} ? '/' : '');
    #We support two ways of substituting params here:
    # /:param/ - name has to have '/' or end of string after it
    # /has_:{param}_value - surround param name with '{}'
    #Note: we go through complete incremental parsing/fetching url params to avoid
    #params substituted values being mached against other params names
    #We also verify that all parameters have been substituted
    my $result = '';
    while($path =~ /\G(.*?)(:(?:\{([^}]+?)\}|(\w+)(?=\W|$)))/gc) {
      $result .= $1;
      if($2) {
        my $name = $3 || $4; # only one of them could match
        if(exists $route_params->{$name}) {
          $result .= URI::Escape::uri_escape_utf8($route_params->{$name} // '');
        }
        else {
          die "Found parameter $name in path but it wasn't set in parameters hash";
        }
      }
    }
    if($path =~ /\G(.+)$/g) {
      $result .= $1;
    }
    return $result;
  };

  method 'query_params' => sub {
    my ($class, %params) = @_;

    my %query_params;
    if($params{params}) {
      # TODO: I don't think having this strict mapping in place
      # makes a lot of sense. Ideally we should be able to pass in
      # any query params that we want
      if ( $params{query_params_mapping} ) {
        while(my ($name, $url_name) = each(%{$params{query_params_mapping}})) {
          # Check for method canness here probably
          $query_params{$url_name} = delete($params{params}->{$name});
        }
      } else {
        %query_params = %{$params{params}};
      }
    }
    return %query_params;
  };

  method 'parameters' => sub { $p };

};

__END__

=pod

=head1 NAME

 MooseX::Role::REST::Consumer

=head1 VERSION

 version 0.003

=head1 SYNOPSIS

  package Foo;
  use Moose;
  with 'MooseX::Role::REST::Consumer' => {
    service_host => 'somewhere.over.the.rainbow',
    resource_path => '/path/to/my/resource/:id',
  };

  my $object = Foo->get(route_params => {id => 1});

  if ($object->is_success) {
   print $object->data->{something_that_came_back};
  }

=head2 DESCRIPTION

  At Shutterstock we love REST and we take it so seriously that we think 
  our code should be RESTfully lazy. Now one can have a Moose model
  without needing to deal with all the marshalling details.

=head3 Schema Definitions/Configuration

  When setting up a class the following are the supported
  parameters that L<MooseX::Role::REST::Consumer> will support.

  For example a typical configuration would looke like the following:

  with 'MooseX::Role::REST::Consumer' => {
    service_host  => 'host.name',
    resource_path => '/path/to/my/resource/:id'
    timeout       => 10,
  };

=over

=item content_type

  By default the content type is set to "application/json"

=item header_exclude 

  Acts as a filter, will exclude any header information.

  header_exclude => {
    post => 'X-Foo',
  }

=item resource_path

  This is the path of the resource. IE:

  /foo/bar/:id

  The :id is a route parameter which will be filled in as specified by the
  "route_params" hashref.

=item retry

  This is an explicit retry. Even if the service times out, it will retry
  using this value. This retry is different than what L<REST::Consumer> offers.

=item service_host

  The hostname to the service

=item service_port

  The port for the hostname.

=item timeout

  Configuration level timeout. This is global on each request.

=item useragent_class

  Experimental way of overriding L<REST::Consumer>'s useragent. Right now
  MooseX::REST::Consumer uses L<LWP::UserAgent>

=back

=head3 METHODS

=over

=item get( route_params => {...}, params => {...} )

 Will use REST::Consumer::get to lookup a resource by
 supplied resource_path and substitution of route_params

=item post( route_params => {...}, content => '...' )

 Will perform a POST request with REST::Consumer::post.
 The data will the Content-Type of application/json by default.

=item Other supported HTTP methods

  DELETE and PUT: delete(%params) and put(%params)

=back

=head3 Supported Method Parameters

=over

=item route_params => {...}

 These will be substituted into the package route definition.

=item params => {...}

 Passed into L<REST::Consumer> as a set of key/value
 query parameters.

=item headers => {...}

  Any extra HTTP request headers to send. 

=item content => ''

  Passed into L<REST::Consumer>. This is the body content of a request.

=item timeout => ''

  Timeout override per request.
  
  Note that the 'timeout' is subject to interpretation
  by your underlying UserAgent class.  For example,
  LWP::UserAgent treats the timeout as being
  C<per-request>. This means that if you specify a timeout
  of 5 seconds and issue a request using LWP::UserAgent,
  each request that the UserAgent makes to fulfill your
  request will have its own timeout of 5 seconds.
  
  This becomes important if the API that you are talking to
  starts giving you 3xx redirects: while you might expect a
  timeout to occur within 5 seconds, the API might instruct
  your UserAgent to make a few subsequent requests, and each
  one will have your initial timeout applied to it.
  
  Different UserAgent classes implement timeouts
  differently. L<LWP::UserAgent::Paranoid>, for example,
  has a global timeout value, where all requests must be
  fulfilled within C<timeout> clock seconds.

=back

=head3 Response Object

=over

  The response object is created and passed back whenever
  any of the supported HTTP methods are called. 
  See L<MooseX::Role::REST::Consumer::Response>.

=back

=head2 

=head1 SEE ALSO

L<REST::Consumer>, L<MooseX::Role::Parameterized>, L<Moose>

=head2 AUTHORS

  The Shutterstock Webstack Team and alumni (Logan Bell,
  Jon Hogue, Vishal Kajjam, Belden Lyman, Nikolay Martynov, and
  Kurt Starsinic).

=head2  COPYRIGHT AND LICENSE

 This software is copyright (c) 2014 by Shutterstock Inc.

 This is free software; you can redistribute it and/or modify it under
 the same terms as the Perl 5 programming language system itself.

=cut
