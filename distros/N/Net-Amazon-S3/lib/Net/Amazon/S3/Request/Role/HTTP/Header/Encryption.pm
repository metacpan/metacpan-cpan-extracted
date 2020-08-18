package Net::Amazon::S3::Request::Role::HTTP::Header::Encryption;
# ABSTRACT: x-amz-server-side-encryption header role
$Net::Amazon::S3::Request::Role::HTTP::Header::Encryption::VERSION = '0.90';
use Moose::Role;

with 'Net::Amazon::S3::Request::Role::HTTP::Header' => {
    name => 'encryption',
    header => 'x-amz-server-side-encryption',
    isa => 'Maybe[Str]',
    required => 0,
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::HTTP::Header::Encryption - x-amz-server-side-encryption header role

=head1 VERSION

version 0.90

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
