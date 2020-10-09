package Net::Amazon::S3::Request::Role::Query::Param::Version_id;
# ABSTRACT: version_id query param role
$Net::Amazon::S3::Request::Role::Query::Param::Version_id::VERSION = '0.97';
use Moose::Role;

with 'Net::Amazon::S3::Request::Role::Query::Param' => {
	param => 'version_id',
	query_param => 'versionId',
	constraint => 'Str',
	required => 0,
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::Query::Param::Version_id - version_id query param role

=head1 VERSION

version 0.97

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
