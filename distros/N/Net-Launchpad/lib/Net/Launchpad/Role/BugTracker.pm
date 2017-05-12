package Net::Launchpad::Role::BugTracker;
BEGIN {
  $Net::Launchpad::Role::BugTracker::AUTHORITY = 'cpan:ADAMJS';
}
$Net::Launchpad::Role::BugTracker::VERSION = '2.101';
# ABSTRACT: Bug tracker roles

use Moose::Role;
use Function::Parameters;

with 'Net::Launchpad::Role::Common';


method watches {
    return $self->collection('watches');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Role::BugTracker - Bug tracker roles

=head1 VERSION

version 2.101

=head1 METHODS

=head2 watches

Returns remote watches collection

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
