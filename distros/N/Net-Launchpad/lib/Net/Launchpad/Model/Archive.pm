package Net::Launchpad::Model::Archive;
BEGIN {
  $Net::Launchpad::Model::Archive::AUTHORITY = 'cpan:ADAMJS';
}
# ABSTRACT: Archive Model
$Net::Launchpad::Model::Archive::VERSION = '2.101';
use Moose;
use namespace::autoclean;

extends 'Net::Launchpad::Model::Base';

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Model::Archive - Archive Model

=head1 VERSION

version 2.101

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
