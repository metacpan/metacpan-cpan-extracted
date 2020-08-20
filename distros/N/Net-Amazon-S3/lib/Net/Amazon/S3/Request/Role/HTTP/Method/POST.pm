package Net::Amazon::S3::Request::Role::HTTP::Method::POST;
# ABSTRACT: HTTP POST method role
$Net::Amazon::S3::Request::Role::HTTP::Method::POST::VERSION = '0.91';
use Moose::Role;

with 'Net::Amazon::S3::Request::Role::HTTP::Method' => { method => 'POST' };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::HTTP::Method::POST - HTTP POST method role

=head1 VERSION

version 0.91

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
