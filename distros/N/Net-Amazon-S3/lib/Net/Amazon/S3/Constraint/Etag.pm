package Net::Amazon::S3::Constraint::Etag;
# ABSTRACT: Moose constraint - Etag format
$Net::Amazon::S3::Constraint::Etag::VERSION = '0.99';
use Moose::Util::TypeConstraints;

type __PACKAGE__, where { $_ =~ /^[a-z0-9]{32}(?:-\d+)?$/ };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Constraint::Etag - Moose constraint - Etag format

=head1 VERSION

version 0.99

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
