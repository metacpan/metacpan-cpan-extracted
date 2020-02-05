package Net::Amazon::S3::Request::Role::HTTP::Header::Acl_short;
# ABSTRACT: x-amz-acl header role
$Net::Amazon::S3::Request::Role::HTTP::Header::Acl_short::VERSION = '0.88';
use Moose::Role;

with 'Net::Amazon::S3::Request::Role::HTTP::Header' => {
    name => 'acl_short',
    header => 'x-amz-acl',
    isa => 'Maybe[AclShort]',
    required => 0,
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::HTTP::Header::Acl_short - x-amz-acl header role

=head1 VERSION

version 0.88

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
