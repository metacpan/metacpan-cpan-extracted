#
# This file is part of Reindeer
#
# This software is Copyright (c) 2017, 2015, 2014, 2012, 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Reindeer::Role;
our $AUTHORITY = 'cpan:RSRCHBOY';
$Reindeer::Role::VERSION = '0.019';
# ABSTRACT: Reindeer in role form

use strict;
use warnings;

use Reindeer::Util;
use Moose::Exporter;
use Import::Into;

my (undef, undef, $init_meta) = Moose::Exporter->build_import_methods(
    install => [ qw{ import unimport } ],

    also          => [ 'Moose::Role', Reindeer::Util::also_list() ],
    trait_aliases => [ Reindeer::Util::trait_aliases()            ],
    as_is         => [ Reindeer::Util::as_is()                    ],
);

sub init_meta {
    my ($class, %options) = @_;
    my $for_class = $options{for_class};

    if ($] >= 5.010) {

        eval 'use feature';
        feature->import(':5.10');
    }

    ### $for_class
    Moose::Role->init_meta(for_class => $for_class);
    Reindeer::Util->import_type_libraries({ -into => $for_class });
    Path::Class->export_to_level(1);
    Try::Tiny->import::into(1);
    MooseX::Params::Validate->import({ into => $for_class });
    Moose::Util::TypeConstraints->import(
        { into => $for_class },
        qw{ class_type role_type duck_type },
    );
    MooseX::MarkAsMethods->import({ into => $for_class }, autoclean => 1);

    goto $init_meta if defined $init_meta;
}

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Alex Balhatchet

=head1 NAME

Reindeer::Role - Reindeer in role form

=head1 VERSION

This document describes version 0.019 of Reindeer::Role - released June 09, 2017 as part of Reindeer.

=head1 SYNOPSIS

    # ta-da!
    use Reindeer::Role;

=head1 DESCRIPTION

For now, see the L<Reindeer> docs for information about what meta extensions
are automatically applied.

=for Pod::Coverage     init_meta

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reindeer|Reindeer>

=item *

L<Moose::Role>

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
