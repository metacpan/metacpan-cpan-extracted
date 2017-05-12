package Net::Launchpad::Model::BugTracker;
BEGIN {
  $Net::Launchpad::Model::BugTracker::AUTHORITY = 'cpan:ADAMJS';
}
$Net::Launchpad::Model::BugTracker::VERSION = '2.101';
# ABSTRACT: BugTracker Model

use Moose;
use namespace::autoclean;

extends 'Net::Launchpad::Model::Base';

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Model::BugTracker - BugTracker Model

=head1 VERSION

version 2.101

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
