package Project::Euler::Lib::Types;

use Modern::Perl;


#  Declare our types
use MooseX::Types
    -declare => [qw/
        ProblemLink     ProblemName
        PosInt          PosIntArray
        NegInt          NegIntArray
        MyDateTime
/];


#  Import builtin types
use MooseX::Types::Moose qw/ Str  Int  ArrayRef /;

=head1 NAME

Project::Euler::Lib::Types - Type definitions for L<< Project::Euler >>

=head1 VERSION

Version v0.1.1

=cut

use version 0.77; our $VERSION = qv("v0.1.1");


=head1 SYNOPSIS

    use Project::Euler::Lib::Types  qw/ (types to import) /;

=head1 DESCRIPTION

(Most) all of the types that our modules use are defined here so that they can
be reused and tested.  This also helps prevent all of the namespace pollution
from the global declarations.


=head1 SUBTYPES

Create the subtypes that we will use to validate the arguments defined by the
extending classes

    m_ \A \Qhttp://projecteuler.net/index.php?section=problems&id=\E \d+ \z _xms
    Base::prob_name = str  &&  10 < len < 80

We also tell Moose how to coerce a given string into a DateTime object

=cut

=head2 ProblemLink

A url pointing to a problem setup on L<< http://projecteuler.net >>

    as Str,
    message { "$_ is not a a valid link" },
    where { $_ =~ m{
                \A
                \Qhttp://projecteuler.net/index.php?section=problems&id=\E
                \d+
                \z
            }xms
    };

=cut

subtype ProblemLink,
    as Str,
    message { sprintf(q{'%s' is not a valid link}, $_ // '#UNDEFINED#') },
    where { $_ =~ m{
                \A
                \Qhttp://projecteuler.net/index.php?section=problems&id=\E
                \d+
                \z
            }xms;
    };


=head2 ProblemName

In an effort to limit text runoff, the problem name is limited to 80
characters.  Similarly, the length must also be greater than 10 to ensure it is
a usefull name.

    as Str,
    message { qq{'$_' must be a a string between 10 and 80 characters long} },
    where {
        length $_ > 10  and  length $_ < 80;
    };

=cut

subtype ProblemName,
    as Str,
    message { sprintf(q{'%s' must be a string between 10 and 80 characters long}, $_ // '#UNDEFINED#') },
    where {
        length $_ > 10  and  length $_ < 80;
    };


=head2 PosInt

An integer greater than 0

    as Int,
    where {
        $_ > 0
    }

=head3 PosIntArray

An array of PosInts

=cut

subtype PosInt,
    as Int,
    message { sprintf(q{'%s' is not greater than 0}, $_ // '#UNDEFINED#') },
    where {
        $_ > 0;
    };
subtype PosIntArray, as ArrayRef[PosInt];


=head2 NegInt

An integer less than 0

    as Int,
    where {
        $_ < 0
    }

=head3 NegIntArray

An array of NegInts

=cut

subtype NegInt,
    as Int,
    message { sprintf(q{'%s' is not less than 0}, $_ // '#UNDEFINED#') },
    where {
        $_ < 0;
    };
subtype NegIntArray, as ArrayRef[NegInt];


=head2 MyDateTime

A L<< DateTime >> object parsed using L<< DateTime::Format::DateParse >>

    class_type MyDateTime, { class => 'DateTime' };
    coerce MyDateTime,
        from Str,
        via {
            DateTime::Format::DateParse->parse_datetime( $_ );
        };

=cut

use DateTime;
use DateTime::Format::DateParse;

class_type MyDateTime, { class => 'DateTime' };
coerce MyDateTime,
    from Str,
    via {
        DateTime::Format::DateParse->parse_datetime( $_ );
    };

=head1 AUTHOR

Adam Lesperance, C<< <lespea at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-project-euler at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Project-Euler>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Project::Euler::Lib::Common


=head1 COPYRIGHT & LICENSE

Copyright 2009 Adam Lesperance.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Project::Euler::Lib::Types
