package Net::HTTP::API::Error;
BEGIN {
  $Net::HTTP::API::Error::VERSION = '0.14';
}

# ABSTRACT: Throw error

use Moose;
use JSON;
use Moose::Util::TypeConstraints;
use overload '""' => \&error;

subtype error => as 'Str';
coerce error => from 'HashRef' => via { JSON::encode_json $_};

has http_error => (
    is      => 'ro',
    isa     => 'HTTP::Response',
    handles => { http_message => 'message', http_code => 'code' }
);
has reason => (
    is        => 'ro',
    isa       => 'error',
    predicate => 'has_reason',
    coerce    => 1
);

sub error {
    my $self = shift;
    return
           ( $self->has_reason && $self->reason )
        || ( $self->http_message . ": " . $self->http_code )
        || 'unknown';
}

1;


__END__
=pod

=head1 NAME

Net::HTTP::API::Error - Throw error

=head1 VERSION

version 0.14

=head1 SYNOPSIS

    Net::HTTP::API::Error->new(reason => "'useragent' is required");

or

    Net::HTTP::API::Error->new()

=head1 DESCRIPTION

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

