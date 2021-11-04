package Perl::Critic::Policy::Freenode::OverloadOptions;

use strict;
use warnings;

use parent 'Perl::Critic::Policy::Community::OverloadOptions';

our $VERSION = 'v1.0.1';

sub default_themes { 'freenode' }

1;

=head1 NAME

Perl::Critic::Policy::Freenode::OverloadOptions - Don't use overload without
specifying a bool overload and enabling fallback

=head1 DESCRIPTION

Legacy C<freenode> theme policy alias.

=head1 POLICY MOVED

This policy has been moved to the C<community> theme and renamed to
L<Perl::Critic::Policy::Community::OverloadOptions>.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>, L<Perl::Critic::Community>
