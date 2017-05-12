#!perl
use 5.008001; use utf8; use strict; use warnings;

package Rosetta::Engine::Generic::L::en;
use version; our $VERSION = qv('0.14.0');

######################################################################

my $CG = 'Rosetta::Engine::Generic';

my %text_strings = (
    'ROS_G_NO_DBI_DRIVER_HINT_MATCH' =>
        $CG . q[ - can't find any installed DBI driver with a name like "{NAME}"],

    'ROS_G_RAW_SQLSTATE' =>
        $CG . q[ - following the most recent externally invocated procedure, the returned ]
        . q["SQLSTATE" 5-character-string value was "{SQLSTATE_NUM}" (zero is success)],
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

Rosetta::Engine::Generic::L::en - Localization of Rosetta::Engine::Generic for English

=head1 VERSION

This document describes Rosetta::Engine::Generic::L::en version 0.14.0.

=head1 SYNOPSIS

    use Locale::KeyedText;
    use Rosetta;

    # do work ...

    my $translator = Locale::KeyedText->new_translator(
        ['Rosetta::Engine::Generic::L::', 'Rosetta::Utility::SQLBuilder::L::',
        'Rosetta::Utility::SQLParser::L::', 'Rosetta::L::', 'Rosetta::Model::L::'], ['en'] );

    # do work ...

    eval {
        # do work with Rosetta, which may throw an exception ...
    };
    if (my $error_message_object = $@) {
        # examine object here if you want and programmatically recover...

        # or otherwise do the next few lines...
        my $error_user_text = $translator->translate_message( $error_message_object );
        # display $error_user_text to user by some appropriate means
    }

    # continue working, which may involve using Rosetta some more ...

=head1 DESCRIPTION

The Rosetta::Engine::Generic::L::en Perl 5 module contains localization
data for the Rosetta::Engine::Generic module.  It complements the
Rosetta::L::en module, which should interpret most messages that Generic
throws; Generic::L just contains extra or overridden messages specific to
Generic.  It is designed to be interpreted by Locale::KeyedText.

This class is optional and you can still use Rosetta::Engine::Generic
effectively without it, especially if you plan to either show users
different error messages than this class defines, or not show them anything
because you are "handling it".

=head1 FUNCTIONS

=head2 get_text_by_key( MSG_KEY )

    my $user_text_template = Rosetta::Engine::Generic::L::en->get_text_by_key( 'foo' );

This function takes a Message Key string in MSG_KEY and returns the
associated user text template string, if there is one, or undef if not.

=head1 DEPENDENCIES

This module requires any version of Perl 5.x.y that is at least 5.8.1.

It also requires the Perl module L<version>, which would conceptually be
built-in to Perl, but isn't, so it is on CPAN instead.

This module has no enforced dependencies on L<Locale::KeyedText>, which is
on CPAN, or on L<Rosetta::Engine::Generic>, which is in the current
distribution, but it is designed to be used in conjunction with them.

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

L<perl(1)>, L<Locale::KeyedText>, L<Rosetta::Engine::Generic>.

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

This file is part of the Rosetta::Engine::Generic feature reference
implementation of the Rosetta database portability library.

Rosetta::Engine::Generic is Copyright (c) 2002-2005, Darren R. Duncan.  All
rights reserved.  Address comments, suggestions, and bug reports to
C<perl@DarrenDuncan.net>, or visit L<http://www.DarrenDuncan.net/> for more
information.

Rosetta::Engine::Generic is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License (GPL) as
published by the Free Software Foundation (L<http://www.fsf.org/>); either
version 2 of the License, or (at your option) any later version.  You
should have received a copy of the GPL as part of the
Rosetta::Engine::Generic distribution, in the file named "GPL"; if not,
write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
Boston, MA  02110-1301, USA.

Linking Rosetta::Engine::Generic statically or dynamically with other
modules is making a combined work based on Rosetta::Engine::Generic.  Thus,
the terms and conditions of the GPL cover the whole combination.  As a
special exception, the copyright holders of Rosetta::Engine::Generic give
you permission to link Rosetta::Engine::Generic with independent modules,
regardless of the license terms of these independent modules, and to copy
and distribute the resulting combined work under terms of your choice,
provided that every copy of the combined work is accompanied by a complete
copy of the source code of Rosetta::Engine::Generic (the version of
Rosetta::Engine::Generic used to produce the combined work), being
distributed under the terms of the GPL plus this exception.  An independent
module is a module which is not derived from or based on
Rosetta::Engine::Generic, and which is fully useable when not linked to
Rosetta::Engine::Generic in any form.

Any versions of Rosetta::Engine::Generic that you modify and distribute
must carry prominent notices stating that you changed the files and the
date of any changes, in addition to preserving this original copyright
notice and other credits.  Rosetta::Engine::Generic is distributed in the
hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

While it is by no means required, the copyright holders of
Rosetta::Engine::Generic would appreciate being informed any time you
create a modified version of Rosetta::Engine::Generic that you are willing
to distribute, because that is a practical way of suggesting improvements
to the standard version.

=cut
