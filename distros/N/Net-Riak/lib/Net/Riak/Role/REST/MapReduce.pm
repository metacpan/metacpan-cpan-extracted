package Net::Riak::Role::REST::MapReduce;
{
  $Net::Riak::Role::REST::MapReduce::VERSION = '0.1702';
}
use Moose::Role;
use JSON;
use Data::Dumper;

sub execute_job {
    my ($self, $job, $timeout) = @_;

    # save existing timeout value.
    my $ua_timeout = $self->useragent->timeout();

    if ($timeout) {
        if ($ua_timeout < ($timeout/1000)) {
            $self->useragent->timeout(int($timeout/1000));
        }
        $job->{timeout} = $timeout;
    }

    my $content = JSON::encode_json($job);

    my $request = $self->new_request(
        'POST', [$self->mapred_prefix]
    );
    $request->content($content);

    my $response = $self->send_request($request);

    # restore time out value
    if ( $timeout && ( $ua_timeout != $self->useragent->timeout() ) ) {
        $self->useragent->timeout($ua_timeout);
    }

    unless ($response->is_success) {
        die "MapReduce query failed: ".$response->status_line;
    }

    return JSON::decode_json($response->content);
}

1;

__END__

=pod

=head1 NAME

Net::Riak::Role::REST::MapReduce

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
