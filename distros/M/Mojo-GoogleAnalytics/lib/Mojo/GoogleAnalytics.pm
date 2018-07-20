package Mojo::GoogleAnalytics;
use Mojo::Base -base;

use Mojo::Collection;
use Mojo::File 'path';
use Mojo::GoogleAnalytics::Report;
use Mojo::JSON qw(decode_json false true);
use Mojo::Promise;
use Mojo::JWT;
use Mojo::UserAgent;

use constant DEBUG => $ENV{MOJO_GA_DEBUG} || 0;

our $VERSION = '0.04';

our %QUERY_SORT_ORDER = (asc => 'ASCENDING', desc => 'DESCENDING', x => 'SORT_ORDER_UNSPECIFIED');

our %QUERY_TRANSLATOR = (
  'eq'     => [qw(dimension EXACT)],
  '^'      => [qw(dimension BEGINS_WITH)],
  '$'      => [qw(dimension ENDS_WITH)],
  '=~'     => [qw(dimension REGEXP)],
  'substr' => [qw(dimension PARTIAL)],
  '=='     => [qw(metric EQUAL)],
  '>'      => [qw(metric GREATER_THAN)],
  '<'      => [qw(metric LESS_THAN)],
);

has authorization => sub { +{} };
has client_email  => sub { Carp::confess('client_email is required') };
has client_id     => sub { Carp::confess('client_id is required') };
has private_key   => sub { Carp::confess('private_key is required') };
has ua            => sub { Mojo::UserAgent->new(max_redirects => 3) };
has view_id => '';

sub authorize {
  my ($self, $cb) = @_;
  my @ua_args = $self->_authorize_ua_args or return $self;

  if ($cb) {
    $self->ua->post(@ua_args, sub { $self->$cb($self->_process_authorize_response($_[1])) });
  }
  else {
    my ($err, $res) = $self->_process_authorize_response($self->ua->post(@ua_args));
    die $err if $err;
  }

  return $self;
}

sub authorize_p {
  my $self = shift;

  return Mojo::Promise->new->resolve unless my @ua_args = $self->_authorize_ua_args;
  return $self->ua->post_p(@ua_args)->then(sub {
    my $err = $self->_process_authorize_response($_[0]);
    return $err ? Mojo::Promise->new->reject($err) : ();
  });
}

sub batch_get {
  my ($self, $query, $cb) = @_;
  my @ua_args;

  @ua_args = (Mojo::URL->new($self->{batch_get_uri}), {},
    json => {reportRequests => ref $query eq 'ARRAY' ? $query : [$query]});

  if ($cb) {
    my $p = $self->authorize_p->then(sub {
      warn "[GoogleAnalytics] Getting analytics data from $ua_args[0] ...\n", if DEBUG;
      $ua_args[1] = {Authorization => $self->authorization->{header}};
      return $self->ua->post_p(@ua_args);
    })->then(sub {
      my $res = $self->_process_batch_get_response($query, shift);
      return ref $cb ? $self->$cb('', $res) : $res;
    })->catch(sub {
      return ref $cb ? $self->$cb(shift, {}) : shift;
    });

    return ref $cb ? $self : $p;
  }
  else {
    $ua_args[1] = {Authorization => $self->authorize->authorization->{header}};
    warn "[GoogleAnalytics] Getting analytics data from $ua_args[0] ...\n", if DEBUG;
    my ($err, $res) = $self->_process_batch_get_response($query, $self->ua->post(@ua_args));
    die $err if $err;
    return $res;
  }
}

sub batch_get_p {
  shift->batch_get(shift, 1);
}

sub from_file {
  my ($self, $file) = @_;
  my $attrs = decode_json(path($file)->slurp);

  for my $attr (keys %$attrs) {
    $self->{$attr} ||= $attrs->{$attr};
    warn qq([Mojo::GoogleAnalytics] Read "$attr" from $file\n) if DEBUG;
  }

  return $self;
}

sub get_report {
  my ($self, $query, $cb) = @_;
  return $self->batch_get($self->_query_translator(%$query), $cb);
}

sub get_report_p {
  my ($self, $query) = @_;
  $self->batch_get_p($self->_query_translator(%$query));
}

sub new {
  my $class = shift;
  my $file  = @_ % 2 ? shift : undef;
  my $self  = $class->SUPER::new(@_);

  $self->from_file($file) if $file;
  $self->{token_uri}     ||= 'https://accounts.google.com/o/oauth2/token';
  $self->{auth_scope}    ||= 'https://www.googleapis.com/auth/analytics.readonly';
  $self->{batch_get_uri} ||= 'https://analyticsreporting.googleapis.com/v4/reports:batchGet';
  $self->mock if $ENV{TEST_MOJO_GA_BATCH_GET_DIR};

  return $self;
}

sub mock {
  my ($self, $args) = @_;
  $self->{batch_get_dir} = $args->{batch_get_dir} // $ENV{TEST_MOJO_GA_BATCH_GET_DIR} // File::Spec->tmpdir;

  require Mojolicious;
  my $server = $self->ua->server;
  $server->app(Mojolicious->new) unless $server->app;

  my $mock_r = $server->app->routes;
  Scalar::Util::weaken($self);
  for my $name (qw(batch_get_uri token_uri)) {
    my $cb = $self->can("_mocked_action_$name");
    $self->{$name} = sprintf '/mocked/ga%s', Mojo::URL->new($self->{$name})->path;
    $mock_r->any($self->{$name} => $args->{$name} || sub { $self->$cb(@_) })->name($name) unless $mock_r->lookup($name);
  }

  return $self;
}

sub _authorize_ua_args {
  my $self = shift;
  my $time = time;
  my $prev = $self->authorization;
  my ($jwt, @ua_args);

  warn "[GoogleAnalytics] Authorization exp: @{[$prev->{exp} ? $prev->{exp} : -1]} < $time\n" if DEBUG;
  return if $prev->{exp} and $time < $prev->{exp};

  $ua_args[0] = Mojo::URL->new($self->{token_uri});
  $jwt = Mojo::JWT->new->algorithm('RS256')->secret($self->private_key);

  $jwt->claims({
    aud   => $ua_args[0]->to_string,
    exp   => $time + 3600,
    iat   => $time,
    iss   => $self->client_email,
    scope => $self->{auth_scope},
  });

  push @ua_args, (form => {grant_type => 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion => $jwt->encode});
  warn "[GoogleAnalytics] Authenticating with $ua_args[0] ...\n", if DEBUG;

  return @ua_args;
}

sub _mocked_action_batch_get_uri {
  my ($self, $c) = @_;
  my $file = Mojo::File::path($self->{batch_get_dir}, sprintf '%s.json', Mojo::Util::md5_sum($c->req->text));

  warn "[GoogleAnalytics] Reading dummy response file $file (@{[-r $file ? 1 : 0]})\n" if DEBUG;
  return $c->render(data => $file->slurp) if -r $file;
  return $c->render(json => {error => {message => qq(Could not read dummy response file "$file".)}}, status => 500);
}

sub _mocked_action_token_uri {
  my ($self, $c) = @_;
  $c->render(json => {access_token => 'some-dummy-token', expires_in => 3600, token_type => 'Bearer'});
}

sub _process_authorize_response {
  my ($self, $tx) = @_;
  my $err = $tx->error;
  my $res = $tx->res->json;
  my $url = $tx->req->url;

  if ($err) {
    $err = sprintf '%s >>> %s (%s)', $url, $res->{error_description} || $err->{message} || 'Unknown error',
      $err->{code} || 0;
    warn "[GoogleAnalytics] $err\n", if DEBUG;
  }
  else {
    warn "[GoogleAnalytics] Authenticated with $url\n", if DEBUG;
    $self->authorization(
      {exp => time + ($res->{expires_in} - 600), header => "$res->{token_type} $res->{access_token}"});
  }

  return $err // '';
}

sub _process_batch_get_response {
  my ($self, $query, $tx) = @_;
  my $as_list = ref $query eq 'ARRAY';
  my $url     = $tx->req->url;
  my $res     = $tx->res->json || {};
  my $err     = $res->{error} || $tx->error;
  my $reports = $res->{reports} || ($as_list ? $query : [{}]);

  @$reports = map {
    $_->{error} = $err;
    $_->{query} = $as_list ? shift @$query : $query, $_->{tx} = $tx;
    Mojo::GoogleAnalytics::Report->new($_);
  } @$reports;

  if ($err) {
    $err = sprintf '%s >>> %s (%s)', $url, $err->{message} || 'Unknown error', $err->{code} || 0;
  }

  return $err || '', $as_list ? Mojo::Collection->new(@$reports) : $reports->[0];
}

sub _query_translator {
  my ($self, %query) = @_;

  for my $filter (@{delete($query{filters}) || []}) {
    my ($not, $op) = $filter->[1] =~ /^(\!)?(.*)$/;
    my $group_op = $QUERY_TRANSLATOR{$op} || [dimension => $op];

    if ($group_op->[0] eq 'metric') {
      push @{$query{metricFilterClauses}[0]{filters}},
        {
        metricName      => $filter->[0],
        not             => $not ? true : false,
        operator        => $group_op->[1],
        comparisonValue => "$filter->[2]",
        };
    }
    else {
      push @{$query{dimensionFilterClauses}[0]{filters}},
        {
        dimensionName => $filter->[0],
        not           => $not ? true : false,
        operator      => $group_op->[1],
        expressions   => $filter->[2],
        };
    }
  }

  for my $order_by (@{delete($query{order_by}) || []}) {
    my ($field, $order) = $order_by =~ /^(\S+)\s*(asc|desc)?$/;
    $order = $QUERY_SORT_ORDER{$order || 'x'} || $QUERY_SORT_ORDER{x};
    push @{$query{orderBys}}, {fieldName => $1, sortOrder => $order};
  }

  if (my $d = delete $query{interval}) {
    $query{dateRanges} = [{startDate => $d->[0], endDate => $d->[1] || '1daysAgo'}];
  }

  $query{dimensions} = [map { +{name => $_} } split /,/, $query{dimensions}]
    if $query{dimensions} and not ref $query{dimensions};
  $query{metrics} = [map { +{expression => $_} } split /,/, $query{metrics}]
    if $query{metrics} and not ref $query{metrics};
  $query{pageSize} = delete $query{rows} if exists $query{rows};
  $query{viewId} ||= $self->view_id;

  return \%query;
}

1;

=encoding utf8

=head1 NAME

Mojo::GoogleAnalytics - Extract data from Google Analytics using Mojo UserAgent

=head1 SYNOPSIS

  my $ga     = Mojo::GoogleAnalytics->new("/path/to/credentials.json");
  my $report = $ga->batch_get({
    viewId     => "ga:123456789",
    dateRanges => [{startDate => "7daysAgo", endDate => "1daysAgo"}],
    dimensions => [{name => "ga:country"}, {name => "ga:browser"}],
    metrics    => [{expression => "ga:pageviews"}, {expression => "ga:sessions"}],
    orderBys   => [{fieldName => "ga:pageviews", sortOrder => "DESCENDING"}],
    pageSize   => 10,
  });

  print $report->rows_to_table(as => "text");

=head1 DESCRIPTION

L<Mojo::GoogleAnalytics> is a Google Analytics client which allow you to
extract data non-blocking.

This module is work in progress and currently EXPERIMENTAL. Let me know if you
start using it or has any feedback regarding the API.

=head1 ATTRIBUTES

=head2 authorization

  $hash_ref = $self->authorization;

Holds authorization data, extracted by L</authorize>. This can be useful to set
from a cache if L<Mojo::GoogleAnalytics> objects are created and destroyed
frequently, but with the same credentials.

=head2 client_email

  $str = $self->client_email;

Example: "some-app@some-project.iam.gserviceaccount.com".

=head2 client_id

  $str = $self->client_id;

Example: "103742165385019792511".

=head2 private_key

  $str = $self->private_key;

Holds the content of a pem file that looks like this:

  -----BEGIN PRIVATE KEY-----
  ...
  ...
  -----END PRIVATE KEY-----

=head2 ua

  $ua = $self->ua;
  $self = $self->ua(Mojo::UserAgent->new);

Holds a L<Mojo::UserAgent> object.

=head2 view_id

  $str = $self->view_id;
  $self = $self->view_id("ga:123456789");

Default C<viewId>, used by L</get_report>.

=head1 METHODS

=head2 authorize

  $self = $self->authorize;
  $self = $self->authorize(sub { my ($self, $err) = @_; });

This method will set L</authorization>. Note that this method is automatically
called from inside of L</batch_get>, unless already authorized.

=head2 authorize_p

  $promise = $self->authorize_p;

Same as L</authorize>, but returns a L<Mojo::Promise>.

=head2 batch_get

  $report = $self->batch_get(\%query);
  $self = $self->batch_get(\%query, sub { my ($self, $err, $report) = @_ });

Used to extract data from Google Analytics. C<$report> will be a
L<Mojo::Collection> if C<$query> is an array ref, and a single
L<Mojo::GoogleAnalytics::Report> object if C<$query> is a hash.

C<$err> is a string on error and false value on success.

=head2 batch_get_p

  $promise = $self->batch_get_p(\%query);

Same as L</batch_get>, but returns a L<Mojo::Promise>.

=head2 from_file

  $self = $self->from_file("/path/to/credentials.json");

Used to load attributes from a JSON credentials file, generated from
L<https://console.developers.google.com/apis/credentials>. Example file:

  {
    "type": "service_account",
    "project_id": "cool-project-238176",
    "private_key_id": "01234abc6780dc2a3284851423099daaad8cff92",
    "private_key": "-----BEGIN PRIVATE KEY-----...\n-----END PRIVATE KEY-----\n",
    "client_email": "some-name@cool-project-238176.iam.gserviceaccount.com",
    "client_id": "103742165385019792511",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://accounts.google.com/o/oauth2/token",
  }

Note: The JSON credentials file will probably contain more fields than is
listed above.

=head2 get_report

  $report = $self->get_report(\%query);
  $self = $self->get_report(\%query, sub { my ($self, $err, $report) = @_ });

This method is the same as L</batch_get>, but will do some translations on the
input queries before passing it on to L</batch_get>. Example:

  $self->get_report({
    dimensions => "ga:productName",
    metrics    => "ga:productListClicks,ga:productListViews",
    interval   => [qw(7daysAgo 1daysAgo)],
    order_by   => ["ga:productListClicks desc"],
    filters    => [ ["ga:currencyCode" => "eq" => ["USD"]] ],
  });

=over 2

=item * dimensions

C<dimensions> will be translated from a comma separated string, or passed on
directly to Google Analytics if not. The example above results in this query:

  dimensions => [{name => "ga:productName"}]

=item * filters

C<filters> is a simpler version of C<dimensionFilterClauses> and
C<metricFilterClauses>. The format is:

  filters => [ [$fieldName, $operator, $value] ]

The C<$operator> will be used to determine if the expression should go into
C<dimensionFilterClauses> or C<metricFilterClauses>.

  Input operator | Filter group          | Analytics operator
  ---------------|-----------------------|----------------------
  eq             | dimensionFilterClause | EXACT
  ^              | dimensionFilterClause | BEGINS_WITH
  $              | dimensionFilterClause | ENDS_WITH
  =~             | dimensionFilterClause | REGEXP
  substr         | dimensionFilterClause | PARTIAL
  ==             | metricFilterClause    | EQUAL
  >              | metricFilterClause    | GREATER_THAN
  <              | metricFilterClause    | LESS_THAN

The filter will be "NOT" if the operator is prefixed with "!".

=item * interval

C<interval> can be used as a simpler version of C<dateRanges>. The example above
results in:

  dateRanges => [{startDate => "7daysAgo", endDate => "1daysAgo"}]

Note that C<endDate> will default to "1daysAgo" if not present.

=item * metrics

C<metrics> will be translated from a comma separated string, or passed on
directly to Google Analytics if not. The example above results in this query:

  metrics => [{name => "ga:productListClicks"}, {name => "ga:productListViews"}]

=item * order_by

C<order_by> can be used as a simpler version to C<orderBys>. The example above
results in:

  orderBys => [{fieldName => "ga:productListClicks", sortOrder => "DESCENDING'}]

The sort order can be "asc" or "desc". Will result in "SORT_ORDER_UNSPECIFIED"
unless present.

=item * rows

Alias for C<pageSize>.

=item * viewId

C<viewId> will be set from L</view_id> if not present in the query.

=back

=head2 get_report_p

  $promise = $selfg->get_report_p(\%query);

Same as L</get_report>, but returns a L<Mojo::Promise>.

=head2 new

  $self = Mojo::GoogleAnalytics->new(%attrs);
  $self = Mojo::GoogleAnalytics->new(\%attrs);
  $self = Mojo::GoogleAnalytics->new("/path/to/credentials.json");

Used to construct a new L<Mojo::GoogleAnalytics> object. Calling C<new()> with
a single argument will cause L</from_file> to be called with that argument.

=head2 mock

  $self = $self->mock;
  $self = $self->mock({batch_get_dir => "/path/to/some/dir"});
  $self = $self->mock({batch_get_uri => sub { my ($self, $c) = @_; }, token_uri => sub { my ($self, $c) = @_; }});

This method is useful when you want to test your application, but you don't
want to ask Google for reports. C<mock()> will be automatically called by
L</new> if the C<TEST_MOJO_GA_BATCH_GET_DIR> environment variable i set. The
arguments passed on to this method can be:

=over 2

=item * batch_get_dir

Need to be an absolute path to a directory with the dummy response files for
L</batch_get>.

Defaults to C<TEST_MOJO_GA_BATCH_GET_DIR> environment variable.

=item * batch_get_uri

A code ref that is used as an L<Mojolicious> action. The default code ref
provided by this module will look for a response file in C<batch_get_dir> with
the name C<$md5_sum.json>, where the MD5 sum is calculated from the JSON
request body. It will respond with an error message with the full path of the
expected file, unless the file could be read.

=item * token_uri

A code ref that is used as an L<Mojolicious> action. The default code ref will
respond with a dummy bearer token and log you in.

=back

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
