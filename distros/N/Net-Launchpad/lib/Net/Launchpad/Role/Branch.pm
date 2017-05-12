package Net::Launchpad::Role::Branch;
BEGIN {
  $Net::Launchpad::Role::Branch::AUTHORITY = 'cpan:ADAMJS';
}
$Net::Launchpad::Role::Branch::VERSION = '2.101';
# ABSTRACT: Branch Roles

use Moose::Role;
use Function::Parameters;

with 'Net::Launchpad::Role::Common';


method dependent_branches {
    return $self->collection('dependent_branches');
}


method landing_candidates {
    return $self->collection('landing_candidates');
}


method landing_target {
    return $self->collection('landing_targets');
}

method reviewer {
    return $self->resource('reviewer');
}


method sourcepackage {
  return $self->resource('sourcepackage');
}

method subscribers {
  return $self->collection('subscribers');
}

method subscriptions {
  return $self->collection('subscriptions');
}

method spec {
  return $self->collection('spec');
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Role::Branch - Branch Roles

=head1 VERSION

version 2.101

=head1 METHODS

=head2 dependent_branches

Collection of merge proposals that are dependent on this branch

=head2 landing_candidates

Collection of merge proposals where this branch is target branch

=head2 landing_targets

Collection of merge proposals where this branch is source branch

=head2 reviewer

Reviewer team associated with this branch

=head2 sourcepackage

Source package that this branch belongs too

=head2 subscribers

Persons subscribed to this branch

=head2 subscriptions

Branch subscriptions related to this branch

=head2 spec

Specification linked to this branch

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
