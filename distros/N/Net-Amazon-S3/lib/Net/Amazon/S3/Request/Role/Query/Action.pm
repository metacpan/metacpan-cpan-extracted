package Net::Amazon::S3::Request::Role::Query::Action;
# ABSTRACT: query action role
$Net::Amazon::S3::Request::Role::Query::Action::VERSION = '0.86';
use MooseX::Role::Parameterized;

parameter action => (
    is => 'ro',
    isa => 'Str',
);

role {
    my ($params) = @_;
    my $action = $params->action;

    method '_request_query_action' => sub { $action };
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::Query::Action - query action role

=head1 VERSION

version 0.86

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
