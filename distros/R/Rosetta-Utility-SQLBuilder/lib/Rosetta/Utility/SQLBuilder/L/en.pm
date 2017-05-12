#!perl
use 5.008001; use utf8; use strict; use warnings;

package Rosetta::Utility::SQLBuilder::L::en;
use version; our $VERSION = qv('0.3.0');

######################################################################

my $CSB = 'Rosetta::Utility::SQLBuilder';

my %text_strings = (
    'ROS_U_SB_METH_ARG_UNDEF' =>
        $CSB . q[.{METH}(): ]
        . q[undefined (or missing) {ARGNM} argument],
    'ROS_U_SB_METH_ARG_NO_ARY' =>
        $CSB . q[.{METH}(): ]
        . q[invalid {ARGNM} argument; ]
        . q[it is not a Array ref, but rather is "{ARGVL}"],
    'ROS_U_SB_METH_ARG_NO_HASH' =>
        $CSB . q[.{METH}(): ]
        . q[invalid {ARGNM} argument; ]
        . q[it is not a Hash ref, but rather is "{ARGVL}"],
    'ROS_U_SB_METH_ARG_NO_NODE' =>
        $CSB . q[.{METH}(): ]
        . q[invalid {ARGNM} argument; ]
        . q[it is not a Node object, but rather is "{ARGVL}"],

    'ROS_U_SB_METH_ARG_WRONG_NODE_TYPE' =>
        $CSB . q[.{METH}(): ]
        . q[invalid {ARGNM} argument; ]
        . q[it is not a "{EXPNTYPE}" Node, but rather is a "{ARGNTYPE}" Node],

    'ROS_U_SB_IDENT_STYLE_ARG_INVAL' =>
        $CSB . q[.identifier_style(): ]
        . q[invalid NEW_VALUE argument; ]
        . q[it is not one of "{EXPVLS}", but rather is "{ARGVL}"],
);

######################################################################

sub get_text_by_key {
    my (undef, $msg_key) = @_;
    return $text_strings{$msg_key};
}

######################################################################

1;
__END__

=encoding utf8

=head1 NAME

Rosetta::Utility::SQLBuilder::L::en - Localization of Rosetta::Utility::SQLBuilder for English

=head1 VERSION

This document describes Rosetta::Utility::SQLBuilder::L::en version 0.3.0.

=head1 SYNOPSIS

    use Locale::KeyedText;
    use Rosetta::Utility::SQLBuilder;

    # do work ...

    my $translator = Locale::KeyedText->new_translator(
        ['Rosetta::Utility::SQLBuilder::L::', 'Rosetta::Model::L::'], ['en'] );

    # do work ...

    eval {
        # do work with Rosetta::Utility::SQLBuilder, which may throw an exception ...
    };
    if (my $error_message_object = $@) {
        # examine object here if you want and programmatically recover...

        # or otherwise do the next few lines...
        my $error_user_text = $translator->translate_message( $error_message_object );
        # display $error_user_text to user by some appropriate means
    }

    # continue working, which may involve using Rosetta::Utility::SQLBuilder some more ...

=head1 DESCRIPTION

The Rosetta::Utility::SQLBuilder::L::en Perl 5 module contains localization
data for Rosetta::Utility::SQLBuilder.  It is designed to be interpreted by
Locale::KeyedText.  Besides localizing generic error messages that
Rosetta::Utility::SQLBuilder produces itself, this file also provides a
ready-made set of generic database error strings that can be thrown by any
Rosetta::Utility::SQLBuilder Engine.

This class is optional and you can still use Rosetta::Utility::SQLBuilder
effectively without it, especially if you plan to either show users
different error messages than this class defines, or not show them anything
because you are "handling it".

=head1 FUNCTIONS

=head2 get_text_by_key( MSG_KEY )

    my $user_text_template = Rosetta::Utility::SQLBuilder::L::en->get_text_by_key( 'foo' );

This function takes a Message Key string in MSG_KEY and returns the
associated user text template string, if there is one, or undef if not.

=head1 DEPENDENCIES

This module requires any version of Perl 5.x.y that is at least 5.8.1.

It also requires the Perl module L<version>, which would conceptually be
built-in to Perl, but isn't, so it is on CPAN instead.

This module has no enforced dependencies on L<Locale::KeyedText>, which is
on CPAN, or on L<Rosetta::Utility::SQLBuilder>, which is in the current
distribution, but it is designed to be used in conjunction with them.

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

L<perl(1)>, L<Locale::KeyedText>, L<Rosetta::Utility::SQLBuilder>.

=head1 BUGS AND LIMITATIONS

The structure of this module is trivially simple and has no known bugs.

However, the locale data that this module contains may be subject to large
changes in the future; you can determine the likeliness of this by
examining the development status and/or BUGS AND LIMITATIONS documentation
of the other module that this one is localizing; there tends to be a high
correlation in the rate of change between that module and this one.

=head1 AUTHOR

Darren R. Duncan (C<perl@DarrenDuncan.net>)

=head1 LICENCE AND COPYRIGHT

This file is part of the Rosetta::Utility::SQLBuilder reference implementation
of a SQL:2003 string builder that uses the Rosetta::Model database
portability library.

Rosetta::Utility::SQLBuilder is Copyright (c) 2002-2005, Darren R. Duncan.  All
rights reserved.  Address comments, suggestions, and bug reports to
C<perl@DarrenDuncan.net>, or visit L<http://www.DarrenDuncan.net/> for more
information.

Rosetta::Utility::SQLBuilder is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License (GPL) as
published by the Free Software Foundation (L<http://www.fsf.org/>); either
version 2 of the License, or (at your option) any later version.  You
should have received a copy of the GPL as part of the
Rosetta::Utility::SQLBuilder distribution, in the file named "GPL"; if not,
write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
Boston, MA  02110-1301, USA.

Linking Rosetta::Utility::SQLBuilder statically or dynamically with other
modules is making a combined work based on Rosetta::Utility::SQLBuilder.  Thus,
the terms and conditions of the GPL cover the whole combination.  As a
special exception, the copyright holders of Rosetta::Utility::SQLBuilder give
you permission to link Rosetta::Utility::SQLBuilder with independent modules,
regardless of the license terms of these independent modules, and to copy
and distribute the resulting combined work under terms of your choice,
provided that every copy of the combined work is accompanied by a complete
copy of the source code of Rosetta::Utility::SQLBuilder (the version of
Rosetta::Utility::SQLBuilder used to produce the combined work), being
distributed under the terms of the GPL plus this exception.  An independent
module is a module which is not derived from or based on
Rosetta::Utility::SQLBuilder, and which is fully useable when not linked to
Rosetta::Utility::SQLBuilder in any form.

Any versions of Rosetta::Utility::SQLBuilder that you modify and distribute
must carry prominent notices stating that you changed the files and the
date of any changes, in addition to preserving this original copyright
notice and other credits.  Rosetta::Utility::SQLBuilder is distributed in the
hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

While it is by no means required, the copyright holders of
Rosetta::Utility::SQLBuilder would appreciate being informed any time you
create a modified version of Rosetta::Utility::SQLBuilder that you are willing
to distribute, because that is a practical way of suggesting improvements
to the standard version.

=cut
