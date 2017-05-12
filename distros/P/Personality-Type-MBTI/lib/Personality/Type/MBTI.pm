package Personality::Type::MBTI;

use warnings;
use strict;

=head1 NAME

Personality::Type::MBTI - Myers-Briggs Type Indicator (MBTI)

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

The Myers-Briggs Type Indicator (MBTI) is a personality test designed
to assist a person in identifying some significant personal
preferences.

The Indicator is frequently used in the areas of pedagogy, group
dynamics, employee training, leadership training, marriage counseling,
and personal development.

The types the MBTI sorts for, known as dichotomies, are extraversion
/ introversion, sensing / intuition, thinking / feeling and judging
/ perceiving. Each of the sixteen types is referred to by a four-letter
abbreviation, such as ESTJ or INFP, indicating that type's preference
in each dichotomy.

The MBTI includes 93 forced-choice questions, which means there are
only two options. Participants may skip questions if they feel they
are unable to choose. Using psychometric techniques, such as item
response theory, the MBTI will then be scored and will attempt to
identify which dichotomy the participant prefers. After taking the
MBTI, participants are given a readout of their score, which will
include a bar graph and number of how many points they received on
a certain scale.

This module calculates the MBTI scores on each scale and, eventually,
will provide integration with other personality type theories (e.g.
Keirsey, Big5).

    use Personality::Type::MBTI;

    my $mbti = Personality::Type::MBTI->new();

    # sample results from a questionnaire
    my @test = qw/i e i e i n s n s n t f t f t p j p j p/;

    # calculate type
    my $type = $mbti->type( @test );

    print "Your type is '$type'\n";

=head1 FUNCTIONS

=head2 new

Creates a new Personality::Type::MBTI object.

=cut

sub new {
    my $self = shift;
    bless {@_}, $self;
}

=head2 type

Receives an array containing the results of a questinnaire (letters
[eisnftpj]).

Returns:

=over 4

=item * scalar context

In scalar context, it returns the lower-case mbti type (e.g. "intp").

If any dimension cannot be correctly identified (e.g., same score for
"extroversion" and "introversion") it will be marked with an "x" (e.g.
"xntp")

=item * list context

In list context, it returns a hash containing the count for each
dimension.

=back

=cut

sub type {
    my ( $self, @letters ) = @_;

    my %count = map( { $_ => 0 } qw/e i s n f t p j/ );

    foreach (@letters) {
        $_ = lc($_);

        if ( my ($weight, $letter) = /^([+-]?\d*)\s*(\w)$/ ) {
            $weight ||= 1;
            $count{$letter} += $weight;
        }
    }

    my $result =
          _preference( e => $count{e}, i => $count{i} )
        . _preference( s => $count{s}, n => $count{n} )
        . _preference( f => $count{f}, t => $count{t} )
        . _preference( p => $count{p}, j => $count{j} );

    return wantarray ? %count : $result;
}

sub _preference {
    my %count = @_;

    my ( $a, $b ) = keys %count;

    return
        $count{$a} > $count{$b} ? $a
      : $count{$b} > $count{$a} ? $b
      :                         'x';
}

=head2 dominant

Receives a personality type (e.g. "infp") and returns its dominant
function (in this case, "fi" - introverted feeling).

=cut

sub dominant {
    my ( $self, $type ) = @_;
    my ( $ei, $ns, $ft, $jp ) = split(//, $type);

    my $orient = $ei; # always

    my $function;
    if ( $jp eq 'p' and $ei eq 'i' or $jp eq 'j' and $ei eq 'e' ) {
        $function = $ft;
    } elsif ( $jp eq 'p' and $ei eq 'e' or $jp eq 'j' and $ei eq 'i') {
        $function = $ns;
    }

    return "$function$orient";
}

=head2 auxiliary

Receives a personality type (e.g. "infp") and returns its auxiliary
function (in this case, "ne" - extroverted intuition).

=cut

sub auxiliary {
    my ( $self, $type ) = @_;
    my ( $ei, $ns, $ft, $jp ) = split(//, $type);

    my $orient = $ei eq 'i' ? 'e' : 'i'; # the opposite, always

    my $function;
    if ( $jp eq 'p' and $ei eq 'i' or $jp eq 'p' and $ei eq 'e' ) {
        $function = $ft;
    } elsif ( $jp eq 'j' and $ei eq 'e' or $jp eq 'j' and $ei eq 'i') {
        $function = $ns;
    }

    return "$function$orient";
}

sub _keirsey {
    my ( $self, $type ) = @_;

    my %keirsey = (
        esfj => 'provider',
        enfj => 'teacher',
        isfp => 'composer',
        infp => 'healer',
        enfp => 'champion',
        entp => 'inventor',
        infj => 'counselor',
        intj => 'mastermind',
        esfp => 'performer',
        estp => 'promoter',
        isfj => 'protector',
        istj => 'inspector',
        estj => 'supervisor',
        entj => 'field marshal',
        istp => 'crafter',
        intp => 'architect',
    );

    return wantarray ? %keirsey : $keirsey{$type};
}

sub _function {
    my ( $self, $function ) = @_;

    my %function = (
        'e' => 'Extraversion',
        'i' => 'Introversion',
        's' => 'Sensing',
        'n' => 'iNtuition',
        'f' => 'Feeling',
        't' => 'Thinking',
        'p' => 'Perceiving',
        'j' => 'Judging',
    );

    return wantarray ? %function : $function{$function};
}

=head1 AUTHOR

Nelson Ferraz, C<< <nferraz at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-personality-type-mbti at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Personality-Type-MBTI>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Personality::Type::MBTI

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Personality-Type-MBTI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Personality-Type-MBTI>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Personality-Type-MBTI>

=item * Search CPAN

L<http://search.cpan.org/dist/Personality-Type-MBTI>

=back

=head1 SEE ALSO

=over 4

=item * Myers-Briggs Type Indicator on Wikipedia

L<http://en.wikipedia.org/wiki/Myers-Briggs>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Nelson Ferraz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Personality::Type::MBTI
