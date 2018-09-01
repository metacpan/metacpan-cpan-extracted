package Net::Amazon::S3::Request::Role::Query::Param::Upload_id;
$Net::Amazon::S3::Request::Role::Query::Param::Upload_id::VERSION = '0.85';
use Moose::Role;

with 'Net::Amazon::S3::Request::Role::Query::Param' => {
    param => 'upload_id',
    query_param => 'uploadId',
    constraint => 'Str',
    required => 1,
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::Query::Param::Upload_id

=head1 VERSION

version 0.85

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
