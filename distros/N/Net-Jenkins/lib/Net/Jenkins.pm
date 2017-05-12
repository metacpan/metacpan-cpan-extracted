package Net::Jenkins;
use strict;
use warnings;
our $VERSION = '0.07';
use Net::Jenkins::Job;
use Net::Jenkins::Job::Build;
use Net::HTTP;
use LWP::UserAgent;
use Moose;
use methods;
use URI;
use JSON;

has scheme => ( is => 'rw', isa => 'Str', default => 'http' );

has host => ( 
            is => 'rw', 
            isa => 'Str' , 
            default => sub {  
                return $ENV{JENKINS_HOST} ? $ENV{JENKINS_HOST} : 'localhost';
            });

has port => ( is => 'rw', isa => 'Int' , 
            default => sub {  
                return $ENV{JENKINS_PORT} ? $ENV{JENKINS_PORT} : 8080;
            });

has user_agent => ( is => 'rw' , default => sub { 
    return LWP::UserAgent->new;
});

method get_base_url {
    return $self->scheme 
                . '://' . $self->host 
                . ':' . $self->port;
}


method post_url ($uri,%args) {
    return $self->user_agent->post( $uri , \%args );
}

method get_url ($uri) {
    return $self->user_agent->get($uri);
}

method get_json ( $uri ) {
    my $response = $self->user_agent->get($uri);
    return decode_json $response->decoded_content if $response->is_success;
}

method summary {
    my $uri = $self->get_base_url . '/api/json';
    return $self->get_json( $uri );
}

method mode {
    return $self->summary->{mode};
}

method jobs {
    return map { Net::Jenkins::Job->new( %$_ , api => $self ) } @{ $self->summary->{jobs} };
}

method use_security {
    return $self->summary->{useSecurity};
}

method use_crumbs {
    return $self->summary->{useCrumbs};
}

method views {
    return @{ $self->summary->{views} };
}

method restart {
    my $uri = $self->get_base_url . '/restart';
    return $self->get_url( $uri )->is_success;
}


method create_job ($job_name,$xml) {
    my $uri = URI->new( $self->get_base_url . '/createItem' );
    $uri->query_form( name => $job_name );
    my $response = $self->user_agent->post( $uri , "Content-Type" => "application/xml" , Content => $xml );
    return $response->code == 200;
}

method update_job ($job_name,$xml) {
    my $uri = URI->new( $self->job_url($job_name) . '/config.xml' );
    my $response = $self->user_agent->post( $uri , "Content-Type" => "application/xml" , Content => $xml );
    return $response->code == 200;
}

method copy_job ($job_name, $from_job_name) {
    my $uri = URI->new( $self->get_base_url . '/createItem' );

    # name=NEWJOBNAME&mode=copy&from=FROMJOBNAME
    $uri->query_form( name => $job_name , from => $from_job_name , mode => 'copy' );
    my $response = $self->user_agent->post( $uri );
    return $response->code == 302 ? 1 : 0;
}

method delete_job ($job_name) {
    my $uri = $self->job_url($job_name) . '/doDelete';
    return $self->post_url( $uri )->code == 302 ? 1 : 0;
}

method disable_job ($job_name) {
    my $uri = $self->job_url($job_name) . '/disable';
    return $self->post_url( $uri )->code == 302 ? 1 : 0;
}

method enable_job ($job_name) {
    my $uri = $self->job_url($job_name) . '/enable';
    return $self->post_url( $uri )->code == 302 ? 1 : 0;
}

method build_job ($job_name) {
    my $uri = $self->job_url($job_name) . '/build';
    return $self->post_url( $uri )->code == 302 ? 1 : 0;
}


method get_job_details ($job_name) {
    return $self->get_json(
        $self->job_url($job_name) . '/api/json'
    );
}




method get_builds ($job_name) {
    my $config = $self->get_job_details($job_name);
    return @{ $config->{builds} };
}

method get_build_details ($job_name, $number) {
    my $uri = $self->job_build_url($job_name,$number) . '/api/json';
    return $self->get_json($uri);
}


# Which returns a FH::Handle
method get_build_console_handle ($job_name, $number) {
    my $uri = URI->new( $self->job_build_url($job_name,$number) . '/consoleText' );

    # http://localhost:8080/job/Phifty/1/consoleText

    my $s = Net::HTTP->new(Host => $self->host ) || die $@;
    $s->write_request(GET => $uri->path , 'User-Agent' => "Perl/Net::Jenkins");
    my($code, $mess, %h) = $s->read_response_headers;

    return $s if $code == 200;
}

method get_build_console ($job_name, $number) {
    my $s = $self->get_build_console_handle( $job_name, $number );
    return unless $s;

    my $body = '';;
    while (1) {
        my $buf;
        my $n = $s->read_entity_body($buf, 1024);
        die "build console of $job_name #$number read failed: $!" unless defined $n;
        last unless $n;
        $body .= $buf;
    }
    return $body;
}

# ================================
# URL methods
# ================================
method job_url ($job_name) {
    return $self->get_base_url . '/job/' . $job_name;
}

method job_build_url ($job_name,$number) {
    # http://localhost:8080/job/Phifty/2/api/json
    return $self->job_url($job_name) . '/' . $number;
}

1;
__END__

=head1 NAME

Net::Jenkins -

=head1 SYNOPSIS

    my $jenkins = Net::Jenkins->new;
    my $jenkins = Net::Jenkins->new( host => 'ci.machine.dev' , port => 1234 );

    my $summary = $jenkins->summary;
    my @views = $jenkins->views;
    my $mode = $jenkins->mode;

    my $xml = read_file 'xt/config.xml'; 
    if( $jenkins->create_job( 'Phifty', $xml ) ) {
        $jenkins->copy_job( 'test2' , 'Phifty' );
    }

    my @jobs = $jenkins->jobs;   # [ Net::Jenkins::Job , ... ]

    for my $job ( $jenkins->jobs ) {

        # trigger a build
        $job->build;

        my $details = $job->details;
        my $queue = $job->queue_item;

        sleep 1 while $job->in_queue ;

        if( $job->last_build ) {
            $job->last_build->console;
        }

        # Net::Jenkins::Job::Build
        for my $build ( $job->builds ) {
            my $d = $build->details;
            $build->name;
            $build->id;
            $build->created_at;  # DateTime object
        }

        $job->delete;
    }
    $jenkins->restart;  # returns true if success



=head1 DESCRIPTION

Net::Jenkins is

=head1 AUTHOR

Yo-An Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

L<Jenkins::Trigger>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
