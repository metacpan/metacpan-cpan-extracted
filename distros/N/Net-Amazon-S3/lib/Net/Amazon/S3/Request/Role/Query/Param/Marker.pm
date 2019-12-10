package Net::Amazon::S3::Request::Role::Query::Param::Marker;
# ABSTRACT: marker query param role
$Net::Amazon::S3::Request::Role::Query::Param::Marker::VERSION = '0.87';
use Moose::Role;

with 'Net::Amazon::S3::Request::Role::Query::Param' => {
    param => 'marker',
    constraint => 'Maybe[Str]',
    required => 0,
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::Query::Param::Marker - marker query param role

=head1 VERSION

version 0.87

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
