# Author: Matthew Mallard
# Website: www.q-technologies.com.au
# Date: 6th October 2016

# ABSTRACT: Connects to the Puppet Orchestrator API (i.e. Puppet Tasks)




package Puppet::Orchestrator;

use JSON;
use LWP::UserAgent;
use HTTP::Request;
use Log::MixedColor;
use 5.10.0;
use Moose;
use Moose::Exporter;
use Module::Load::Conditional qw[ check_install ];
use Data::Dumper;
use YAML::XS qw(Dump Load LoadFile);

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  if ( @_ == 1 && !ref $_[0] ) {
      return $class->$orig( server_name => $_[0], puppet_db => Puppet::DB->new($_[0]) );
  }
  else {
      return $class->$orig(@_);
  }
};

if( check_install( module => 'MooseX::Storage' )){
    require MooseX::Storage;
    MooseX::Storage->import();
    with Storage('format' => 'JSON', 'io' => 'File', traits => ['DisableCycleDetection']);
}
my $log = Log::MixedColor->new;




has 'server_name' => (
    is => 'rw', 
    isa => 'Str',
    required => 1,
    default => 'localhost',
    predicate => 'has_server_name',
);




has 'server_port' => (
    is => 'rw', 
    isa => 'Int',
    required => 1,
    default => 8143,
    predicate => 'has_server_port',
);





has 'access_token' => (
    is => 'rw', 
    isa => 'Str',
    required => 0,
    builder => 'load_access_token',
    predicate => 'has_access_token',
);





has 'environment' => (
    is => 'rw', 
    isa => 'Str',
    required => 1,
    default => 'production',
    predicate => 'has_environment',
);




# Use a certificate by this name
has 'cert_name' => (
    is => 'rw', 
    isa => 'Maybe[Str]',
    required => 0,
    predicate => 'has_cert_name',
);





has 'puppet_ssl_path' => (
    is => 'rw', 
    isa => 'Str',
    required => 1,
    default => '/etc/puppetlabs/puppet/ssl',
    predicate => 'has_puppet_ssl_path',
);





has 'timeout' => (
    is => 'rw', 
    isa => 'Int',
    required => 1,
    default => 360, # seconds
    predicate => 'has_timeout',
);






has 'puppet_db' => (
    is => 'rw', 
    isa => 'Puppet::DB',
    required => 1,
    predicate => 'has_puppet_db',
);








# The list of nodes the job is running on
has 'nodes' => (
    is => 'rw', 
    isa => 'ArrayRef[Str]',
    default => sub { [] },
    required => 1,
    predicate => 'has_nodes',
);







# The job id number
has 'job_id' => (
    is => 'rw', 
    isa => 'Int',
    required => 1,
    default => 0,
    predicate => 'has_job_id',
);









sub wait_for_job {
    my $self = shift;
    my $jobid = shift;
    my $timeout = shift || 0;

    my $start = time;
    my $now = $start;

    my $path = "jobs/$jobid";
    my $data = $self->get_data( $path );
    while( ( $data->{state} eq "running" ) and ($timeout == 0 or ($now - $start) < $timeout) ){
        sleep 1;
        $data = $self->get_data( $path );
        $now = time;
    }

}








sub submit_task {
    my $self = shift;
    my $task = shift;
    my $params = shift;
    my $nodes = shift;

    $self->nodes($nodes);

    my $task_data = {
                 "environment" => $self->environment,
                 "task" => $task,
                 "params" => $params,
                 "scope" => {
                              "nodes" => $nodes,
                            }
               };
    my $path = "command/task";
    my $data;
    $data = $self->push_data( $path, $task_data );
    $self->jobid( $data->{job}{name} );
    return $self->jobid;
}








sub is_job_finished {
    my $self = shift;
    my $jobid = shift;

    my $path = "jobs/$jobid";
    my $data = $self->get_data( $path );
    if( $data->{state} eq "running" ) {
        return 0;
    } else {
        return 1;
    }

}








sub print_output_wait {
    my $self = shift;
    my $jobid = shift;

    my ( $data, $path );

    $path = "jobs/$jobid/nodes";
    $data = $self->get_data( $path );
    my $node_status = {};
    #for my $node ( @{ $self->nodes } ){
    for my $node ( @{ $data->{items} } ){
        $node_status->{ $node->{name} } = {};
    }

    $path = "jobs/$jobid/events";
    my $keep_running = 1;
    while( $keep_running ){
        $data = $self->get_data( $path );
        #say Dump( $data );
        for my $event ( @{ $data->{items} } ){
            my $output = $event->{details}{detail}{_output};
            my $node = $event->{details}{node};
            my $status = $event->{type};
            my $printed = $node_status->{ $node }{printed};
            if ( $output and $status ne "node_running" and not $printed ){
                for my $line ( split /\n+/, $output ){
                    say $event->{details}{node}.": ".$line;
                }
                $node_status->{ $node }{printed} = 1;
            }
        }
        #say "Checking if we are finished";
        $keep_running = ! $self->is_job_finished( $jobid );
    }
}


# The following are really only used internally

sub load_access_token {
    my $token_file = $ENV{"HOME"} . "/.puppetlabs/token";
    my $token = '';
    if ( -r $token_file ) {
        open INFILE, "<$token_file" or die $!;
        while( <INFILE> ){
            $token .= $_;
        }
        close INFILE;
    }
    return $token;
}

sub do_web_request {
    my $self = shift;
    my $type = shift;
    my $action = shift;
    my $data = shift;
    my $uri = "https://".$self->server_name.":".$self->server_port."/orchestrator/v1/$action";
    my $req = HTTP::Request->new( $type, $uri );
    my $ssl_opts = { verify_hostname => 1, SSL_ca_file => $self->puppet_ssl_path."/certs/ca.pem" };
    $req->header( 'X-Authentication' => $self->access_token );
    my $ua = LWP::UserAgent->new( timeout => $self->timeout, ssl_opts => $ssl_opts );
    if( $type eq 'POST' ){
        $data = encode_json( $data ) if ref $data;
        $req->header( 'Content-Type' => 'application/json' );
        $req->content( $data );
    }
    my $response = $ua->request( $req );
    my $output;
    #if ($response->is_success) {
    if ($response->is_redirect( 303 ) or $response->is_success( 201 )) {
        $output =  $response->decoded_content;
    } else {
        die $response->status_line."\n".$response->decoded_content;
    }
    if( $output ){
        return decode_json( $output );
    } else {
        return;
    }
}

sub push_data {
    my $self = shift;
    my $action = shift;
    my $data = shift;
    return $self->do_web_request( 'POST', $action, $data );
}
sub get_data {
    my $self = shift;
    my $action = shift;
    return $self->do_web_request( 'GET', $action );
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Puppet::Orchestrator - Connects to the Puppet Orchestrator API (i.e. Puppet Tasks)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

This module interacts with the Puppet Orchestrator API (i.e. Puppet Tasks)

    use Puppet::DB;
    use Puppet::Orchestrator;
    use Puppet::Classify;

    # Create a Puppet DB object
    my $puppet_db = Puppet::DB->new(
        server_name => $config->{puppetdb_host},
        server_port => $config->{puppetdb_port},
    );

    # Create a Puppet classification object
    my $classify = Puppet::Classify->new(
                      cert_name       => $config->{puppet_classify_cert},
                      server_name     => $config->{puppet_classify_host},
                      server_port     => $config->{puppet_classify_port},
                      puppet_ssl_path => $config->{puppet_ssl_path},
                      puppet_db       => $puppet_db,
                    );

    # Create a Puppet orchestrator object
    my $orchestrator = Puppet::Orchestrator->new( 
                                          cert_name       => $config->{puppet_orch_cert},
                                          server_name     => $config->{puppet_orch_host},
                                          server_port     => $config->{puppet_orch_port},
                                          puppet_ssl_path => $config->{puppet_ssl_path},
                                          puppet_db       => $puppet_db,
                                        );

    $group = "All Nodes";
    my $nodes = $classify->get_nodes_matching_group( $group );
    my $jobid = $orchestrator->submit_task( "profile::check_id", { "id" => "836" }, $nodes );

    $orchestrator->print_output_wait($jobid);

It requires the I<Puppet::DB> module. The I<Puppet::Classify> is recommended as it allows
looking up group membership.

=head2 server_name

The puppet master that is running the Orchestrator API. Connects to L<localhost> by default.

    $orchestrator->server_name('puppet.example.com');

=head2 server_port

Connect to the Puppet Orchestrator server on port 8143 by default - this can be overidden when consumed.

    $orchestrator->server_port(8754);

=head2 access_token

Use an access_token instead of a certificate to connect to the API.
This loads the authentication token saved in your home, but it can be set manually if it is not stored there.

    say $orchestrator->access_token;

=head2 environment

The environment to look in for the task to be run - this can be overidden when consumed. Defaults to 'production'.

    $orchestrator->environment('test');

=head2 cert_name

the basename of the certificate to be used for authentication.  This is a certificate that has been generated on the
Puppet Master and added to the whitelist.  This can be used instead of using an auth token.

    $orchestrator->cert_name('api_access');

=head2 puppet_ssl_path

Set the path to the Puppet SSL certs, it uses the Puppet enterprise path by default.

    $orchestrator->server_name('puppet.example.com');

=head2 timeout

The connection timeout.  Defaults to 360 seconds.

    $orchestrator->timeout(30);

=head2 puppet_db

The puppet DB object used to interact with the Puppet DB.

    $orchestrator->puppet_db(Puppet::DB->new);

=head2 nodes

A list of nodes to perform the task on

    my $nodes = [ qw( node1 node2 ) ];
    $orchestrator->nodes($nodes);

=head2 job_id

The job ID number

    say $orchestrator->job_id;

=head2 wait_for_job

This method sleeps until the job is finished or the timeout in seconds is reached.  The timeout is optional,
if not specified, it will sleep indefinately.

    $orchestrator->wait_for_job( $jobid, $timeout );

=head2 submit_task

Submit a new task

    my $task_name = "package",
    my $params = {
                   action => "install",
                   name   => "httpd",
                 }
    my $nodes = [ qw( node1 node2 ) ];
    my $jobid = $orchestrator->submit_task( $task_name, $params, $nodes );

    my $timeout = 20;
    $orchestrator->wait_for_job( $jobid, $timeout );

=head2 is_job_finished

Simply returns true or false based on whether the job is finished

    say "Done" if $is_job_finished->job_id;

=head2 print_output_wait

This will print the job output as it becomes available and wait until the job is finished.

    $orchestrator->print_output_wait;

=head1 AUTHOR

Matthew Mallard <mqtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Matthew Mallard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
