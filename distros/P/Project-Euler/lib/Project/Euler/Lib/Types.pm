use strict;
use warnings;
package Project::Euler::Lib::Types;
BEGIN {
  $Project::Euler::Lib::Types::VERSION = '0.20';
}

use Modern::Perl;
use namespace::autoclean;

#ABSTRACT: Type definitions for L<< Project::Euler >>


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




subtype ProblemName,
    as Str,
    message { sprintf(q{'%s' must be a string between 10 and 80 characters long}, $_ // '#UNDEFINED#') },
    where {
        length $_ >= 10  and  length $_ <= 80  and  $_ =~ /\A[\w\d \-_!@#\$%^&*(){}[\]<>,.\\\/?;:'"]+\z/;
    };




subtype PosInt,
    as Int,
    message { sprintf(q{'%s' is not greater than 0}, $_ // '#UNDEFINED#') },
    where {
        $_ > 0;
    };
subtype PosIntArray, as ArrayRef[PosInt];




subtype NegInt,
    as Int,
    message { sprintf(q{'%s' is not less than 0}, $_ // '#UNDEFINED#') },
    where {
        $_ < 0;
    };
subtype NegIntArray, as ArrayRef[NegInt];




use DateTime;
use DateTime::Format::DateParse;

class_type MyDateTime, { class => 'DateTime' };
coerce MyDateTime,
    from Str,
    via {
        DateTime::Format::DateParse->parse_datetime( $_ );
    };





1; # End of Project::Euler::Lib::Types

__END__
=pod

=head1 NAME

Project::Euler::Lib::Types - Type definitions for L<< Project::Euler >>

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    use Project::Euler::Lib::Types  qw/ ProblemLink  PosInt /;

=head1 DESCRIPTION

(Most) all of the types that our modules use are defined here so that they can
be reused and tested.  This also helps prevent all of the namespace pollution
from the global declarations.

=head1 SUBTYPES

Create the subtypes that we will use to validate the arguments defined by the
extending classes.

=head2 ProblemLink

A URL pointing to a problem definition on L<< http://projecteuler.net >>.

=head3 Definition

    as Str,
    message { sprintf(q{'%s' is not a valid link}, $_ // '#UNDEFINED#') },
    where { $_ =~ m{
                \A
                \Qhttp://projecteuler.net/index.php?section=problems&id=\E
                \d+
                \z
            }xms
    };

=head2 ProblemName

In an effort to limit text runoff, the problem name is limited to 80 characters.
Similarly, the length must also be greater than 10 to ensure it is something
useful.  Also, only characters, numbers, spaces, and some punctuation
(!@#$%^&*(){}[]<>,.\\/?;:'") are allowed

=head3 Definition

    as Str,
    message { sprintf(q{'%s' must be a string between 10 and 80 characters long}, $_ // '#UNDEFINED#') },
    where {
        length $_ > 10  and  length $_ < 80;
    };

=head2 PosInt

An integer greater than 0.

=head3 Definition

    as Int,
    message { sprintf(q{'%s' is not greater than 0}, $_ // '#UNDEFINED#') },
    where {
        $_ > 0
    }

=head2 PosIntArray

An array of PosInts.

=head2 NegInt

An integer less than 0.

=head3 Definition

    as Int,
    message { sprintf(q{'%s' is not less than 0}, $_ // '#UNDEFINED#') },
    where {
        $_ < 0
    }

=head2 NegIntArray

An array of NegInts.

=head2 MyDateTime

A L<< DateTime:: >> object coerced using L<< DateTime::Format::DateParse >>

=head3 Definition

    class_type MyDateTime, { class => 'DateTime' };
    coerce MyDateTime,
        from Str,
        via {
            DateTime::Format::DateParse->parse_datetime( $_ );
        };

=head1 ACKNOWLEDGEMENTS

=over 4

=item *

L<< MooseX::Types >>

=back

=head1 AUTHOR

Adam Lesperance <lespea@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Adam Lesperance.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

