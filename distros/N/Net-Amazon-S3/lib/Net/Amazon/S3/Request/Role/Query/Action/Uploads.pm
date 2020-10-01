package Net::Amazon::S3::Request::Role::Query::Action::Uploads;
# ABSTRACT: uploads query action role
$Net::Amazon::S3::Request::Role::Query::Action::Uploads::VERSION = '0.94';
use Moose::Role;

with 'Net::Amazon::S3::Request::Role::Query::Action' => { action => 'uploads' };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::Query::Action::Uploads - uploads query action role

=head1 VERSION

version 0.94

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
