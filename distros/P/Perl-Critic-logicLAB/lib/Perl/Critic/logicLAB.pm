package Perl::Critic::logicLAB;

# Courtesy of Adam Kennedy
# https://metacpan.org/pod/Task

use strict;
use warnings;
use 5.6.0;

our $VERSION = '0.09';

1;

__END__

=pod

=head1 NAME

Perl::Critic::logicLAB - Perl::Critic policies implemented and used by logicLAB

=head1 VERSION

This documentation describes version 0.09

=head1 SYNOPSIS

    % perlcritic --theme logiclab

=head1 DESCRIPTION

Perl::Critic::logicLAB is not a distribution of policies, it is more of a
meta-package, implemented like the L<Task> distributions.

This is not the recommended way of doing things, but it does offer the following
benefits:

=over

=item * Policies can be released separately

=item * Policies can be released without association with Perl::Critic::logicLAB
until their value and correctness has been asserted

=item * You can write a meta-package, listing the policies you want on a policy
by policy level, using the same schema

=back

=head1 POLICIES

=over

=item * L<Perl::Critic::Policy::logicLAB::ProhibitShellDispatch|Perl::Critic::Policy::logicLAB::ProhibitShellDispatch>

=item * L<Perl::Critic::Policy::logicLAB::ProhibitUseLib|Perl::Critic::Policy::logicLAB::ProhibitUseLib>

=item * L<Perl::Critic::Policy::logicLAB::RequireSheBang|Perl::Critic::Policy::logicLAB::RequireSheBang>

=item * L<Perl::Critic::Policy::logicLAB::RequireVersionFormat|Perl::Critic::Policy::logicLAB::RequireVersionFormat>

=item * L<Perl::Critic::Policy::logicLAB::RequirePackageNamePattern|Perl::Critic::Policy::logicLAB::RequirePackageNamePattern>

=item * L<Perl::Critic::Policy::logicLAB::RequireParamsValidate|Perl::Critic::Policy::logicLAB::RequireParamsValidate>

=item * L<Perl::Critic::Policy::logicLAB::ModuleBlacklist|Perl::Critic::Policy::logicLAB::ModuleBlacklist>

=back

=head1 AUTHOR

=over

=item * Jonas B. Nielsen, jonasbn C<< <jonasbn@cpan.org> >>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010-2014 Jonas B. Nielsen (jonasbn), All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
