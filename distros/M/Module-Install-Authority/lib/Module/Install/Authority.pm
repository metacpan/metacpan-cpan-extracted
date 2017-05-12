package Module::Install::Authority;
use strict;
use warnings;
use base qw/Module::Install::Base/;

our $VERSION = '0.03';
$VERSION = eval $VERSION;

sub authority {
    my $self = shift;
    my $pause_id = shift;
    $self->Meta->{values}->{x_authority} = $pause_id;
}

1;

=head1 NAME

Module::Install::Authority - Add an x_authority key to META.yml

=head1 SYNOPSIS

    use inc::Module::Install;
    name 'Example';
    all_from 'lib/Example.pm'
    authority 'cpan:BOBTFISH';
    WriteAll;

=head1 DESCRIPTION

If you upload a distribution which contains an C<x_authority> key in the META.yml
then PAUSE will assign 'firstcome' permissions on any packages in that distribution
to the user given by the C<x_authority> key (and assign co-maint to the uploader).

Traditionally, if you uploaded a dist containing A.pm, and then gave someone else
comaint, and they uploaded a subsequent release including B.pm, then you had a problem
as the initial author (you!) has no permissions to release B.pm

Adding the C<x_authority> key to your distribution fixes this, as it ensures that any
subsequent packages uploaded as part of the dist by co-maintainers get their permissions
set so that one person is the canonical source of permissions for the dist.

This makes coordination (and maintainance sharing) much easier for large distributions,
or those maintained by a pool of people.

=head1 METHODS

=head2 authority ($pause_id)

Adds an C<x_authority> key to your META.yml or META.json

=head1 BUGS

This module should be able to take x_authority from the $AUTHORITY variable in the 'main' module
of the dist if present.

=head1 AUTHOR

    Tomas Doran (t0m) <bobtfish@bobtfish.net>

=head1 COPYRIGHT

Copyright (C) 2012 Tomas Doran

=head1 LICENSE

This software is licensed under the same terms as perl itself.

=cut

