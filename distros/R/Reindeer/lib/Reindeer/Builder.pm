#
# This file is part of Reindeer
#
# This software is Copyright (c) 2017, 2015, 2014, 2012, 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Reindeer::Builder;
our $AUTHORITY = 'cpan:RSRCHBOY';
$Reindeer::Builder::VERSION = '0.019';
# ABSTRACT: Easily build a new 'Reindeer' style class

use strict;
use warnings;

use Carp;
use Moose::Exporter;
use Moose::Autobox;
use Sub::Install;

use Reindeer ();
use Reindeer::Util;

# Look at our args, figure out what needs to be added/filtered

sub import {
    my ($class, %config) = @_;

    # figure out if we're supposed to be for a role
    my $target = caller(0); # let's start out simple
    my $for_role = ($target =~ /::Role$/) ? 1 : 0;

    my $also = [];
    if (exists $config{also}) {

        my $also_config = $config{also};

        $also        = [ Reindeer::Util::also_list() ];
        my $exclude  = $config{also}->{exclude} || [];
        my $add      = $config{also}->{add}     || [];

        $also = $also->grep(sub { !$exclude->any($_) })
            if @$exclude > 0;

        $also->push(@$add);
    }

    $also->unshift($for_role ? 'Moose::Role' : 'Moose');

    # create our methods...
    #my ($import, $unimport, $init_meta) = Moose::Exporter->build_import_methods(
    my %methods;
    @methods{qw/ import unimport init_meta /} =
        Moose::Exporter->build_import_methods(
            also => $also,
        );

    my $_install = sub {
        Sub::Install::reinstall_sub({
            code => $methods{$_[0]},
            into => $target,
            as   => $_[0],
        });
    };

    do { $_install->($_) if defined $methods{$_} }
        for keys %methods;

    return;
}

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Alex Balhatchet metaclass

=head1 NAME

Reindeer::Builder - Easily build a new 'Reindeer' style class

=head1 VERSION

This document describes version 0.019 of Reindeer::Builder - released June 09, 2017 as part of Reindeer.

=head1 SYNOPSIS

    package My::Reindeer;
    use Reindeer::Builder
        also => {
            exclude => [ ... ], # packages from also
            add     => [ ... ],
        };

    package My::Class;
    use My::Reindeer;

    # profit!
    has foo => (...);

=head1 DESCRIPTION

Sometimes you need more than what L<Reindeer> provides...  And sometime less.
Or there's a conflict with a default extension (e.g. a Catalyst controller
with a config that will end up with unrecognized arguments passed to the
constructor will blow up if L<MooseX::StrictConstructor> is used).

Reindeer::Builder provides a simple interface to add additional extensions --
or filter the list of default extensions.  It's intended to be used in a
package of its own that can then be used in the same way L<Moose> or
L<Reindeer> is in a package, to set up the metaclass and sugar.

=head1 ROLE OR CLASS?

If the package you're using Reindeer::Builder in ends with '::Role', we set up
role metaclass and sugar.

=head1 ARGUMENTS

We take a set of name / hashref pairs.  Right now we only support 'also' for
names.

It is legal and supported to add and exclude at the same time.

=head2 also / exclude

If given, we expect exclude to be an arrayref of package names to be excluded
from the list of extensions.  (e.g. this filters what is passed to
L<Moose::Exporter>'s 'also' argument.

e.g.

    use Reindeer::Builder also => { exclude => 'MooseX::Something' };

=head2 also / add

If given, we expect add to be an arrayref of package names to be added
to the list of extensions.  (e.g. this augments what is passed to
L<Moose::Exporter>'s 'also' argument.

e.g.

    use Reindeer::Builder also => { add => 'MooseX::SomethingElse' };

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reindeer|Reindeer>

=item *

L<L<Reindeer>, L<Moose::Exporter>.|L<Reindeer>, L<Moose::Exporter>.>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/RsrchBoy/reindeer/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017, 2015, 2014, 2012, 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
