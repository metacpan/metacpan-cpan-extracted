package REST::Neo4p::Agent::Neo4j::Driver;
use v5.10;
use lib '../../../../../lib'; # testing
use base qw/REST::Neo4p::Agent/;
use Neo4j::Driver;
use JSON::ize;
use REST::Neo4p::Agent::Neo4j::DriverActions;
use REST::Neo4p::Exceptions;
use Try::Tiny;
use URI;
# use MIME::Base64;
use Carp qw/carp/;
use HTTP::Response;
use strict;
use warnings;
BEGIN {
  $REST::Neo4p::Agent::Neo4j::Driver::VERSION = '0.4000';
}
my $WARN_ON_ERROR;

BEGIN {
}

sub new {
  my ($class, @args) = @_;
  my $self = {
    _args => (@args ? \@args : undef), # pass args through to driver
   };
  return bless $self, $class;
}

sub credentials  {
  my $self = shift;
  my ($srv, $realm, $user, $pwd) = @_;
  $self->{_user} = $user;
  $self->{_pwd} = $pwd;
  $self->{_userinfo} = "$user:$pwd" if ($user && $pwd);
  $self->{_realm} = $realm;
  return;
}

sub user { shift->{_user} }
sub pwd { shift->{_pwd} }
sub server_uri { shift->{_server_uri} }
sub last_result { shift->{_last_result} }
sub last_errors { shift->{_last_errors} }
sub ssl_opts {
  my $self = shift;
  my %args = @_;
  if (%args) {
    return $self->{_ssl_opts} = \%args;
  }
  else {
    return %{$self->{_ssl_opts}};
  }
}
sub driver { shift->{__driver} }

# these are no-ops
sub default_header { return }
sub add_header { return }
sub remove_header { return }

sub agent {
  my $self = shift;
  return $_[0] ? $self->{_agent} = $_[0] : $self->{_agent};
}

# TODO: pass stream info along to Neo4j::Driver object

sub stream {
  my $self = shift;
  # do sth
}

sub no_stream {
  my $self = shift;
  # do sth
}

# http, https, bolt (if Neo4j::Bolt)...
sub protocols_allowed {
  my $self = shift;
  my ($protocols) = @_;
  push @{$self->{_protocols_allowed}}, @$protocols;
  return;
}

sub timeout {
  my $self=shift;
  return ($_[0] ? $self->{_timeout} = $_[0] : $self->{_timeout});
}

sub tls {
  my $self=shift;
  return ($_[0] ? $self->{_tls} = $_[0] : $self->{_tls});
}

sub tls_ca {
  my $self = shift;
  return ($_[0] ? $self->{_tls_ca} = $_[0] : $self->{_tls_ca});
}

sub database {
  my $self = shift;
  my ($db) = @_;
  if (defined $db) {
    return $self->{_database} = $db;
  }
  else {
    # Neo4j::Driver defaults to Neo v3 endpoints, but switches to v4 endpoints if 'database' is set.
    # so... don't set the attribute if unset (=> v3)
    return $self->{_database};
  }
}

# subclass override 
sub batch_mode {
  return 0; # batch mode not available
}

# subclass override 
sub batch_length {
  REST::Neo4p::LocalException->throw("Batch mode not available with Neo4j::Driver as agent\n");
}
sub execute_batch {
  REST::Neo4p::LocalException->throw("Batch mode not available with Neo4j::Driver as agent\n");
}

# subclass override
# $agent->connect($url [, $dbname])

sub connect {
  my $self = shift;
  my ($server, $dbname) = @_;
  my ($drv, $uri);
  if (defined $server) {
    $uri = $self->{_server_uri} = URI->new($server);
    if ($uri->userinfo) {
      my ($u,$p) = split(/:/,$uri->userinfo);
      $self->credentials($uri->host,'',$u,$p);
    }
    $self->server_url($uri->scheme."://".$uri->host.':'.$uri->port);
  }
  if (defined $dbname) {
    $self->database($dbname);
  }
  unless ($self->server_url) {
    REST::Neo4p::Exception->throw("Server not set\n");
  }
  try {
    $drv = Neo4j::Driver->new($self->server_url);
    $drv->config( @{$self->{_args}} ) if $self->{_args};
  } catch {
    REST::Neo4p::LocalException->throw("Problem creating new Neo4j::Driver: $_");
  };
  if ($self->user || $self->pwd) {
    $drv->basic_auth($self->user, $self->pwd);
  }
  $self->{__driver} = $drv;
  for (my $i = $REST::Neo4p::Agent::RQ_RETRIES; $i>0; $i--) {
    my $f;
    try {
      my $version = $drv->session->server->version;
      $version =~ s|^\S+/||;  # server version strings look like "Neo4j/3.2.1"
      $self->{_actions}{neo4j_version} = $version or
        die "Can't find neo4j_version from server";
      $f=1;
    } catch {
      if ($i > 1) {
	sleep $REST::Neo4p::Agent::RETRY_WAIT;
      }
      else {
	REST::Neo4p::CommException->throw(message => "$_ (after $REST::Neo4p::Agent::RQ_RETRIES retries)");
      }
    };
    last if $f;
  }
  # set actions
  try {
    my $tx = $self->session->begin_transaction;
    my $n = $tx->run('create (n) return n')->single;
    my $actions = $n->{rest}[0];
    $tx->rollback;
    foreach (keys %$actions) {
      next if /^extensions|metadata|self$/;
      # strip any trailing slash
      $actions->{$_} =~ s|/+$||;
      my ($suffix) = $actions->{$_} =~ m|.*node/[0-9]+/(.*)|;
      $self->{_actions}{$_} = $suffix;
    }
  } catch {
    REST::Neo4p::LocalException->throw("While determining actions: $_");
  };
  return 1;
}

sub session {
  my $self = shift;
  unless ($self->driver) {
    REST::Neo4p::LocalException->throw("No driver connection; can't create session ( try \$agent->connect() )\n");
  }
  my $session = $self->driver->session( $self->database ? (database => $self->database) : () );
  if ($self->server_uri->scheme =~ /^http/) {
    if (my $client = $session->{transport}{client}) {
      $client->setTimeout($self->timeout);
      $client->setCa($self->tls_ca);
      if ($self->{_ssl_opts}) {
	$client->getUseragent->ssl_opts($self->ssl_opts);
      }
    }
  }
  elsif ($self->server_uri->scheme =~ /^bolt/) {
    1;
  }
  return $session;
}

# run_in_session( $query_string, { parm => value, ... } )
# run_in_transaction( $driver_txn, $query_string, { parm => value, ... } )
# these throw REST::Neo4p::Exceptions on Neo4j errors
# and otherwise return a Neo4j::Driver::StatementResult

sub run_in_session {
  my $self = shift;
  my ($qry, $params) = @_;
  $self->{_last_result} = $self->{_last_errors} = undef;
  $params = {} unless defined $params;
  try {
    $self->{_last_result} = $self->session->run($qry, $params);
  } catch {
    $self->{_last_errors} = $_;
  };
  $self->maybe_throw_neo4p_error;
  return $self->{_last_result} // 1;
}

sub run_in_transaction {
  my $self = shift;
  my ($tx, $qry, $params) = @_;
  $self->{_last_result} = $self->{_last_errors} = undef;
  $params = {} unless defined $params;
  try {
    $self->{_last_result} = $tx->run($qry, $params);
  } catch {
    $self->{_last_errors} = $_;
  };
  $self->maybe_throw_neo4p_error;
  return $self->{_last_result} // 1;
}

sub maybe_throw_neo4p_error {
  my $self = shift;
  return unless $self->last_errors;
  for ($self->last_errors) {
    /neo4j enterprise/i && do {
      REST::Neo4p::Neo4jTightwadException->throw( code=>599, message => "You must spend thousands of dollars a year to use this feature; see agent->last_errors()");
    };
    /SchemaRuleAlreadyExists/ && do {
      REST::Neo4p::IndexExistsException->throw( code=>599, neo4j_message => $self->last_errors );
    };
    /ConstraintAlreadyExists/ && do {
      REST::Neo4p::SchemaConstraintExistsException->throw( code=>599, neo4j_message => $self->last_errors );
    };
    /ConstraintValidationFailed/ && do {
      REST::Neo4p::ConflictException->throw( code => 409,
					     neo4j_message => $self->last_errors);
    };
    /NotFound/ && do {
      REST::Neo4p::NotFoundException->throw( code => 404,
					     neo4j_message => $self->last_errors );
    };
    /SyntaxError/ && do {
      REST::Neo4p::QuerySyntaxException->throw( code => 400,
						neo4j_message => $self->last_errors);
    };
    do {
      REST::Neo4p::Neo4jException->throw( code => 599, neo4j_message => $self->last_errors );
    };
  }
}


# $rq : [get|post|put|delete]
# $action : {neo4j REST endpt action}
# @args : depends on REST rq
# get|delete : my @url_components = @args;
# post|put : my ($url_components, $content, $addl_headers) = @args;

# emulate rest calls with appropriate queries

1;

