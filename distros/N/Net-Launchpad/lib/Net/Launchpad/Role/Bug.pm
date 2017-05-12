package Net::Launchpad::Role::Bug;
BEGIN {
  $Net::Launchpad::Role::Bug::AUTHORITY = 'cpan:ADAMJS';
}
$Net::Launchpad::Role::Bug::VERSION = '2.101';
# ABSTRACT: Bug roles

use Moose::Role;
use Function::Parameters;

with 'Net::Launchpad::Role::Common';


method tasks {
    return $self->collection('bug_tasks');
}


method watches {
    return $self->collection('bug_watches');
}


method attachments {
    return $self->collection('attachments');
}


method activity {
    return $self->collection('activity');
}


method duplicate_of {
    return $self->resource('duplicate_of');
}


method messages {
    return $self->collection('messages');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Role::Bug - Bug roles

=head1 VERSION

version 2.101

=head1 METHODS

=head2 tasks

Returns a list of entries in the tasks object.

=head2 watches

Returns bug watch collection

=head2 attachments

Returns list of bug attachments

=head2 activity

Returns a bug activity collection

=head2 duplicate_of

Returns a bug resource that the specific bug is a duplicate of

=head2 messages

Returns bug messages associated with Bug.

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
