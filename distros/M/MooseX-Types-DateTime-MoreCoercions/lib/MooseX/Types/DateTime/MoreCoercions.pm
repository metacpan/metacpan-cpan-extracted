use strict;
use warnings;
package MooseX::Types::DateTime::MoreCoercions; # git description: v0.14-7-g4f9a1ca
# ABSTRACT: Extensions to L<MooseX::Types::DateTime>
# KEYWORDS: moose types constraints coercions date time datetime timestamp

our $VERSION = '0.15';

use Moose 0.41 ();
use DateTime 0.4302 ();
use DateTime::Duration 0.4302 ();
use DateTimeX::Easy 0.085 ();
use Time::Duration::Parse 0.06 qw(parse_duration);
use MooseX::Types::DateTime 0.07 ();
use MooseX::Types::Moose 0.04 qw/Num HashRef Str/;
use namespace::clean 0.19;

use MooseX::Types 0.04 -declare => [qw( DateTime Duration)];
use if MooseX::Types->VERSION >= 0.42, 'namespace::autoclean';

subtype DateTime, as MooseX::Types::DateTime::DateTime;
coerce( DateTime,
    @{ MooseX::Types::DateTime::DateTime->coercion->type_coercion_map },
    from Str, via { DateTimeX::Easy->new($_) },
);

subtype Duration, as MooseX::Types::DateTime::Duration;
coerce( Duration,
    @{ MooseX::Types::DateTime::Duration->coercion->type_coercion_map },
    from Str, via {
        DateTime::Duration->new(
            seconds => parse_duration($_)
        );
    },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::DateTime::MoreCoercions - Extensions to L<MooseX::Types::DateTime>

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    package MyApp::MyClass;

    use MooseX::Types::DateTime::MoreCoercions qw( DateTime );

    has created => (
        isa => DateTime,
        is => "rw",
        coerce => 1,
    );

    my $instance = MyApp::MyClass->new(created=>'January 1, 1980');
    print $instance->created->year; # is 1980

    ## Coercions from the base type continue to work as normal.
    my $instance = MyApp::MyClass->new(created=>{year=>2000,month=>1,day=>10});

Please see the test case for more example usage.

=head1 DESCRIPTION

This module builds on L<MooseX::Types::DateTime> to add additional custom types and coercions.  Since it builds on an existing type, all coercions and constraints are inherited.

=head1 SUBTYPES

This module defines the following additional subtypes.

=head2 DateTime

Subtype of L<MooseX::Types::DateTime/DateTime>.  Adds an additional coercion from strings.

Uses L<DateTimeX::Easy> to try and convert strings, like "yesterday" into a valid L<DateTime> object.  Please note that due to ambiguity with how different systems might localize their timezone, string parsing may not always return the most expected value.  IN general we try to localize to UTC whenever possible.  Feedback welcomed!

=head2 Duration

Subtype of L<MooseX::Types::DateTime/Duration> that coerces from a string.  We use the module L<Time::Duration::Parse> to attempt this.

=head1 CAVEATS

Firstly, this module uses L<DateTimeX::Easy> which is way more DWIM than any sane person would desire. L<DateTimeX::Easy> works by falling back until something makes sense, this is variable. Furthermore, all the modules that L<DateTimeX::Easy> *can* use aren't required for "proper" function of L<DateTimeX::Easy>. What does this mean? Simple, your mileage may vary in your coercions because L<DateTimeX::Easy> is installation specific.

=head1 SEE ALSO

=over 4

=item * L<MooseX::Types::DateTime> Replacement for this module -- coercions with less voodoo

=item * L<DateTimeX::Easy> Backend of this module

=item * L<Time::Duration::Parse> Duration parsing backend for this module

=back

=head1 AUTHOR

John Napiorkowski E<lt>jjn1056 at yahoo.comE<gt>

Broken into a separate package from L<MooseX::Types::DateTime> by Evan Carroll.

Forked from L<MooseX::Types::DateTimeX> and ported back to use
L<MooseX::Types::DateTime> by Dagfinn Ilmari Mannsåker
E<lt>ilmari@ilmari.orgE<gt>.

=head1 AUTHORS

=over 4

=item *

John Napiorkowski <jjn1056@yahoo.com>

=item *

Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>

=back

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Evan Carroll gregor herrmann

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Evan Carroll <me+cpan@evancarroll.com>

=item *

gregor herrmann <gregoa@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by John Napiorkowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
