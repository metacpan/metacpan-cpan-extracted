package MooX::Cmd::ChainedOptions::Role;

# ABSTRACT: generate per-command roles to handle chained options

use strict;
use warnings;

our $VERSION = '0.04';

use Package::Variant
  importing => ['Moo::Role'],
  subs      => [ 'has', 'with' ];

use namespace::clean -except => [ 'build_variant' ];

#pod =pod
#pod
#pod =for pod-coverage
#pod
#pod =head2 make_variant
#pod
#pod =head2 build_variant
#pod
#pod =cut
sub make_variant {

    my ( $class, $target, $parent, $role ) = @_;

    with $role;

    has '+_parent' => (
        is      => 'lazy',
        handles => [ keys %{ { $parent->_options_data } } ],
    );

}

1;

#
# This file is part of MooX-Cmd-ChainedOptions
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

=pod

=head1 NAME

MooX::Cmd::ChainedOptions::Role - generate per-command roles to handle chained options

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This role factory builds upon L<MooX::Cmd::ChainedOptions::Base>.  It
creates a role for each command which augments the C<_parent>
attribute from the similar role for the next higher command in the
command chain to handle the options from that next higher command.

=begin pod-coverage




=end pod-coverage

=head2 make_variant

=head2 build_variant

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-Cmd-ChainedOptions>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooX::Cmd::ChainedOptions|MooX::Cmd::ChainedOptions>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__

#pod =head1 DESCRIPTION
#pod
#pod This role factory builds upon L<MooX::Cmd::ChainedOptions::Base>.  It
#pod creates a role for each command which augments the C<_parent>
#pod attribute from the similar role for the next higher command in the
#pod command chain to handle the options from that next higher command.
