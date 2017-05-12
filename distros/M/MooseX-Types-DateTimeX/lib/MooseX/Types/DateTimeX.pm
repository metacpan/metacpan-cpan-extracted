package MooseX::Types::DateTimeX;
use strict;
use warnings;

use DateTime;
use DateTime::Duration;
use DateTimeX::Easy; 
use Time::Duration::Parse qw(parse_duration);
use MooseX::Types::DateTime::ButMaintained ();
use MooseX::Types::Moose qw/Num HashRef Str/;

use namespace::clean;

our $VERSION = '0.10';

use MooseX::Types -declare => [qw( DateTime Duration)];

subtype DateTime, as MooseX::Types::DateTime::ButMaintained::DateTime;
coerce( DateTime,
    @{ $MooseX::Types::DateTime::ButMaintained::coercions{DateTime} },
    from Str, via { DateTimeX::Easy->new($_) },
);

subtype Duration, as MooseX::Types::DateTime::ButMaintained::Duration;
coerce( Duration,
    @{ $MooseX::Types::DateTime::ButMaintained::coercions{"DateTime::Duration"} },
    from Str, via { 
        DateTime::Duration->new( 
            seconds => parse_duration($_)
        );
    },
);

1;

__END__

=head1 NAME

MooseX::Types::DateTimeX - Extensions to L<MooseX::Types::DateTime::ButMaintained>

=head1 SYNOPSIS

    package MyApp::MyClass;

    use MooseX::Types::DateTimeX qw( DateTime );

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

The package name is left as is for legacy reasons: this module is really a Type with coercions for L<DateTimeX::Easy>. DateTimeX is just a namespace for non-core or less-official L<DateTime> modules.

=head1 SUBTYPES

This module defines the following additional subtypes.

=head2 DateTime

Subtype of 'DateTime'.  Adds an additional coercion from strings.

Uses L<DateTimeX::Easy> to try and convert strings, like "yesterday" into a valid L<DateTime> object.  Please note that due to ambiguity with how different systems might localize their timezone, string parsing may not always return the most expected value.  IN general we try to localize to UTC whenever possible.  Feedback welcomed!

=head2 Duration

Subtype of 'DateTime::Duration' that coerces from a string.  We use the module L<Time::Duration::Parse> to attempt this.

=head1 CAVEATS

Firstly, this module uses L<DateTimeX::Easy> which is way to more DWIM than any sane person would desire. L<DateTimeX::Easy> works by falling back until something makes sense, this is variable. Furthermore, all the modules that L<DateTimeX::Easy> *can* use aren't required for "proper" function of L<DateTimeX::Easy>. What does this mean? Simple, your mileage may vary in your coercions because L<DateTimeX::Easy> is installation specific.

=head1 SEE ALSO

=over 4

=item * L<MooseX::Types::DateTime::ButMaintained> Replacement for this module -- coercions with less voodoo

=item * L<DateTimeX::Easy> Backend of this module

=back

=head1 AUTHOR

John Napiorkowski E<lt>jjn1056 at yahoo.comE<gt>

Broken into a seperate package from L<MooseX::Types::DateTime> by Evan Carroll.

=head1 LICENSE

    Copyright (c) 2008 John Napiorkowski.

    This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.
