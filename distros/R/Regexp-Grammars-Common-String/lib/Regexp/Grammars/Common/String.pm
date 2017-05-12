use 5.010000;
use strict;
use warnings;
use utf8;

package Regexp::Grammars::Common::String;

our $VERSION = '1.000002';

# ABSTRACT: Some basic String parsing Rules for Regexp::Grammars

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Regexp::Grammars;

# Needs to be declared and R:G:1.043 forgets to
# Unrelated to English.pm $MATCH
our $MATCH;    ## no critic (Variables::ProhibitMatchVars)

## no critic (RegularExpressions Documentation Variables::ProhibitUnusedVarsStricter)
my $grammar = qr{
    <grammar: Regexp::Grammars::Common::String>

    <token: String>
        "
        <[MATCH=([^"\\]*)]>+
        (
            \\<[MATCH=(.)]>
            <[MATCH=([^"\\]*)]>
        )*
        "
        <MATCH=(?{ join q{}, @{ $MATCH }})>

}x;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Grammars::Common::String - Some basic String parsing Rules for Regexp::Grammars

=head1 VERSION

version 1.000002

=head1 SYNOPSIS

    use Regex::Grammars;
    use Regexp::Grammars::Common::String;

    my $re = qr{

        (.*<[String]>)+

        <extends: Regexp::Grammars::Common::String>

    }x; #  don't forget the x!

        ...

    if( $content =~ $re ){
        print Dumper( \%/ ); # Praying Mantis operator!?
    }

=head1 DESCRIPTION

L<Regexp::Grammars|Regexp::Grammars> is just too useful to not use, but too pesky and confusing for new people.

Some of the more complex things involve string extraction and escape-handling, and I seriously spent the better part 2 hours
learning how to make this work. So, even if this module is not immediately useful, it may serve as an educational tool for
others.

I probably should have delved deeper into the L<Regexp::Common|Regexp::Common> Family, but I couldn't find one in there that
did exactly what I wanted.

At present, this module only provides one rule, L</String>, but I will probably add a few more later.

=head1 GRAMMARS

=head2 Regexp::Grammars::Common::String

    <extends: Regexp::Grammars::Common::String>

=head1 RULES

=head2 String

For parsing strings like so:

    "Hello"     => 'Hello'
    "Hel\lo"    => 'Hello'
    "Hel\\lo"   => 'Hel\lo'
    "Hel\"lo"   => 'Hel"lo'

It should do a reasonable job of picking up strings from files and properly returning their parsed contents.

It made sense to me to drop the excess C<\>'s that are used for escaping, in order to get a copy of the string as
it would be seen to anything else that parsed it properly and evaluated the escapes into characters.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
