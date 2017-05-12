package Net::Launchpad::Model::Branch;
BEGIN {
  $Net::Launchpad::Model::Branch::AUTHORITY = 'cpan:ADAMJS';
}
# ABSTRACT: Branch Model
$Net::Launchpad::Model::Branch::VERSION = '2.101';
use Moose;
use namespace::autoclean;

extends 'Net::Launchpad::Model::Base';

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Model::Branch - Branch Model

=head1 VERSION

version 2.101

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
