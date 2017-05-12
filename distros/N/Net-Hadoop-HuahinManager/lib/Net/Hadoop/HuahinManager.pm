package Net::Hadoop::HuahinManager;

use strict;
use warnings;
use Carp;

use URI::Escape qw//;
use JSON::XS qw//;

use Furl;

our $VERSION = "0.03";

sub new {
    my ($this, %opts) = @_;
    croak "Huahin Manager server name missing" unless $opts{server};

    my $self = +{
        server => $opts{server},
        port => $opts{port} || 9010,
        useragent => $opts{useragent} || "Furl Net::Hadoop::HuahinManager $VERSION",
        timeout => $opts{timeout} || 10,
    };
    $self->{furl} = Furl::HTTP->new(agent => $self->{useragent}, timeout => $self->{timeout});
    return bless $self, $this;
}

sub list {
    my ($self, $op) = @_;
    $op ||= 'all';
    my $path = '/job/list'; # for all
    if ($op eq 'failed') {
        $path = '/job/list/failed';
    } elsif ($op eq 'killed') {
        $path = '/job/list/killed';
    } elsif ($op eq 'prep') {
        $path = '/job/list/prep';
    } elsif ($op eq 'running') {
        $path = '/job/list/running';
    } elsif ($op eq 'succeeded') {
        $path = '/job/list/succeeded';
    }
    return $self->request('GET', $path);
}

sub status {
    my ($self, $jobid) = @_;
    return $self->request('GET', '/job/status/' . URI::Escape::uri_escape($jobid));
}

sub detail {
    my ($self, $jobid) = @_;
    return $self->request('GET', '/job/detail/' . URI::Escape::uri_escape($jobid));
}

sub kill {
    my ($self, $jobid) = @_;
    return $self->request('DELETE', '/job/kill/id/' . URI::Escape::uri_escape($jobid));
}

sub kill_by_name {
    my ($self, $jobname) = @_;
    return $self->request('DELETE', '/job/kill/name/' . URI::Escape::uri_escape($jobname));
}

sub request {
    my ($self, $method, $path) = @_;
    my @request_params = (
        method => $method,
        host => $self->{server},
        port => $self->{port},
        path_query => $path,
    );
    my ($ver, $code, $msg, $headers, $body) = $self->{furl}->request(@request_params);
    my $content_type = undef;
    for (my $i = 0; $i < scalar(@$headers); $i += 2) {
        if ($headers->[$i] =~ m!\Acontent-type\Z!i) {
            $content_type = $headers->[$i+1];
        }
    }

    if ($code == 200) {
        if ($content_type =~ m!^application/json! and length($body) > 0) {
            return JSON::XS::decode_json($body);
        }
        return 1;
    }
    # error
    carp "Huahin Manager returns error: $code";
    return undef;
}

1;

__END__

=head1 NAME

Net::Hadoop::HuahinManager - Client library for Huahin Manager.

=head1 SYNOPSIS

  use Net::Hadoop::HuahinManager;
  my $client = Net::Hadoop::HuahinManager->new(server => 'manager.local');

  my $all_jobs = $client->list();

  my $failed_jobs = $client->list('failed');

  my $status = $client->status($jobid);
  my $detail = $client->detail($jobid);

  $client->kill($jobid)
    or die "failed to kill jobid: $jobid";

=head1 DESCRIPTION

This module is for systems with Huahin Manager, REST API proxy tool for Hadoop JobTracker.

About Huahin Manager: http://huahin.github.com/huahin-manager/

At just now, Net::Hadoop::HuahinManager supports only list/status/kill (not register).

=head1 METHODS

Net::Hadoop::HuahinManager class method and instance methods.

=head2 CLASS METHODS

=head3 C<< Net::Hadoop::HuahinManager->new( %args ) :Net::Hadoop::HuahinManager >>

Creates and returns a new client instance with I<%args>, might be:

=over

=item server :Str = "manager.local"

=item port :Int = 9010 (default)

=item useragent :Str

=item timeout :Int = 10

=back

=head2 INSTANCE METHODS

=head3 C<< $client->list( [ $op ] ) :ArrayRef >>

Get list of jobs and returns these as arrayref.

=over

=item op :String (optional, one of 'all' (default), 'failed', 'killed', 'prep', 'running' and 'succeeded')

=back

=head3 C<< $client->status( $jobid ) :HashRef >>

Gets job status specified by I<$jobid> string, and returns it.

=head3 C<< $client->detail( $jobid ) :HashRef >>

Gets job detail status specified by I<$jobid> string, and returns it.

=head3 C<< $client->kill( $jobid ) :Bool >>

Kill the job of I<$jobid>.

=head3 C<< $client->kill_by_name( $jobname ) :Bool >>

Kill the job specified by job name I<$jobname>.

=head1 AUTHOR

TAGOMORI Satoshi E<lt>tagomoris {at} gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

