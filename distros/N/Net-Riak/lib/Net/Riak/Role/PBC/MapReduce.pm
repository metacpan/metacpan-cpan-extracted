package Net::Riak::Role::PBC::MapReduce;
{
  $Net::Riak::Role::PBC::MapReduce::VERSION = '0.1702';
}
use Moose::Role;
use JSON;
use List::Util 'sum';

sub execute_job {
    my ($self, $job, $timeout, $returned_phases) = @_;

    $job->{timeout} = $timeout;

    my $job_request = JSON::encode_json($job);

    my $results;

    my $resp = $self->send_message( MapRedReq => {
            request => $job_request,
            content_type => 'application/json'
        }, sub { push @$results, $self->decode_phase(shift) })
        or
    die "MapReduce query failed!";


    return $returned_phases == 1 ? $results->[0] : $results;
}

sub decode_phase {
    my ($self, $resp) = @_;

    if (defined $resp->response && length($resp->response)) {
        return JSON::decode_json($resp->response);
    }

    return;
}

1;

__END__

=pod

=head1 NAME

Net::Riak::Role::PBC::MapReduce

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
