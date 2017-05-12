package Net::Dynect::REST::Job;
# $Id: Job.pm 175 2010-09-27 07:28:53Z james $
use strict;
use warnings;
use Carp;
our $VERSION = do { my @r = (q$Revision: 175 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=head1 NAME 

Net::Dynect::REST::Job - Get the status of a job

=head1 SYNOPSIS

  use Net::Dynect::REST:Job;
  my @records = Net::Dynect::REST:Job->find(connection => $dynect, job_id => $job_id);

=head1 METHODS

=head2 Creating

=over 4

=item Net::Dynect::REST:Job->new()

This takes optional hashref arguments of connection => $dynect, and job_id => $job_id. It does nothing more than create an jobject to represent the job.

=cut

sub new {
  my $proto = shift;
  my $self = bless {}, ref($proto) || $proto;
  my %args = @_;
  $self->{connection} = $args{connection} if defined $args{connection};
  $self->job_id($args{job_id}) if defined $args{job_id};
  return $self;
}

=item  Net::Dynect::REST:Job->find(connection => $dynect, job_id => $job_id);

This will return the Net::Dynect::REST::Response object for the specified job. 
Note that the "Requested" date on the response will show the requets of the "Job" 
call, but but the jobID returned in the response will matcht he one you supplied 
of the original request. So if you repeatedly ask for the same Job, the request 
date will continue to increment - all other data is as when the job completed.

=cut

sub find {
    my $self = shift;
    my %args  = @_;
    if ( not( defined( $args{connection} ) || defined ($self->{connection} )) )
    {
        carp "Need a connection (connection)";
        return;
    }
    if ( not (defined($args{job_id}) || defined($self->job_id)) ) {
        carp "Need a Job ID (job_id) to look for";
        return;
    }

    my $request = Net::Dynect::REST::Request->new(
        operation => 'read',
        service   => sprintf( "%s/%s", __PACKAGE__->_service_base_uri, $args{job_id} || $self->job_id )
    );
    if ( not $request ) {
        carp "Request not valid: $request";
        return;
    }

    my $response = $args{connection}->execute($request);
    return $response;
}


sub _service_base_uri {
  return "Job";
}

sub job_id {
  my $self = shift;
  if (@_) {
    my $new = shift;
    if ($new !~ /^\d+$/) {
      carp "Invalid Job ID: $new";
      return;
    }
    $self->{job_id} = $new;
  }
  return $self->{job_id};
}

1;

=back

=head1 AUTHOR

James Bromberger, james@rcpt.to

=head1 SEE ALSO

L<Net::Dynect::REST>, L<Net::Dynect::REST::Request>, L<Net::Dynect::REST::Response>, L<Net::Dynect::REST::info>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by James Bromberger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
