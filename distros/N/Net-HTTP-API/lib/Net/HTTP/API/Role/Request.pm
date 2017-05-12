package Net::HTTP::API::Role::Request;
BEGIN {
  $Net::HTTP::API::Role::Request::VERSION = '0.14';
}

# ABSTRACT: make HTTP request

use Moose::Role;
use HTTP::Request;
use Net::HTTP::API::Error;
use MooseX::Types::URI qw(Uri);

has api_base_url => (
    is      => 'rw',
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    default => sub {
        my $self         = shift;
        my $api_base_url = $self->meta->get_api_option('api_base_url');
        if (!$api_base_url) {
            die Net::HTTP::API::Error->new(
                reason => "'api_base_url' have not been defined");
        }
        $api_base_url;
    }
);

sub http_request {
    my ($self, $method, $uri, $params_in_url, $args) = @_;

    my $request;

    if ($method =~ /^(?:GET|DELETE)$/) {
        $uri->query_form(%$args);
        $request = HTTP::Request->new($method => $uri);
    }
    elsif ($method =~ /^(?:POST|PUT)$/) {
        my $params = {};
        foreach my $key (@$params_in_url) {
            $params->{$key} = $args->{$key} if exists $args->{$key};
        }
        $uri->query_form(%$params) if $params;

        $request = HTTP::Request->new($method => $uri);
        my $content = $self->serialize($args);
        $request->content($content);
    }
    else {
        die Net::HTTP::API::Error->new(reason => "$method is not defined");
    }

    $request->header(
        'Content-Type' => $self->content_type->{$self->api_format}->{value})
      if $self->api_format_mode eq 'content-type';

    # XXX lwp hook!
    my $result = $self->api_useragent->request($request);
    return $result;
}

1;


__END__
=pod

=head1 NAME

Net::HTTP::API::Role::Request - make HTTP request

=head1 VERSION

version 0.14

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item B<http_request>

=back

=head2 ATTRIBUTES

=over 4

=item B<api_base_url>

=back

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

