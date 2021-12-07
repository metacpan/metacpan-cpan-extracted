package Net::Amazon::S3::Operation::Bucket::Create::Response;
# ABSTRACT: An internal class to handle bucket create response
$Net::Amazon::S3::Operation::Bucket::Create::Response::VERSION = '0.99';
use Moose;
extends 'Net::Amazon::S3::Response';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Bucket::Create::Response - An internal class to handle bucket create response

=head1 VERSION

version 0.99

=head1 DESCRIPTION

Implements operation L<< CreateBucket|https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html >>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
