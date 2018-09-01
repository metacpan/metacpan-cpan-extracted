package Net::Amazon::S3::Request::Role::HTTP::Method;
$Net::Amazon::S3::Request::Role::HTTP::Method::VERSION = '0.85';
use MooseX::Role::Parameterized;

use Net::Amazon::S3::HTTPRequest;

parameter method => (
    is => 'ro',
    isa => 'HTTPMethod',
    required => 0,
);

role {
    my ($params) = @_;

    has _http_request_method => (
        is => 'ro',
        isa => 'HTTPMethod',
        $params->method
            ? (
                init_arg => undef,
                default => $params->method,
            )
            : (
                init_arg => 'method',
                required => 1
            ),
    );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::HTTP::Method

=head1 VERSION

version 0.85

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
