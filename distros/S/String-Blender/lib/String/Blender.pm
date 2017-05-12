#$Id: Blender.pm,v 0.04 2009/07/22 12:42:18 askorikov Exp $

package String::Blender;

use 5.008;
use warnings;
use strict;
use version; our $VERSION = '0.04';

use Carp;
use Moose 0.74;
use Moose::Util::TypeConstraints;

subtype 'VocabStr'
    => as 'Str'
    => where   { length && $_ !~ /[\n[:cntrl:]]+/msx };

subtype 'Natural'
    => as 'Int'
    => where   { $_ > 0 }
    => message { "this number ($_) is not positive" };

has 'vocabs' => (
    is => 'rw',
    isa => 'ArrayRef[ArrayRef[VocabStr]]',
    predicate => 'has_vocabs',
);
has 'vocab_files' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => undef,
    trigger => \&load_vocabs,
    predicate => 'has_vocab_files',
);
has 'quantity'         => (is => 'rw', isa => 'Natural', default => 10);
has 'max_tries_factor' => (is => 'rw', isa => 'Natural', default => 4);
has 'min_length'       => (is => 'rw', isa => 'Natural', default => 5);
has 'max_length'       => (is => 'rw', isa => 'Natural', default => 20);
has 'min_elements'     => (is => 'rw', isa => 'Natural', default => 2);
has 'max_elements'     => (is => 'rw', isa => 'Natural', default => 5);
has 'strict_order'     => (is => 'rw', isa => 'Bool',    default => 0);
has 'delimiter'        => (is => 'rw', isa => 'Str',     default => q{});
has 'prefix'           => (is => 'rw', isa => 'Str',     default => q{});
has 'postfix'          => (is => 'rw', isa => 'Str',     default => q{});

sub BUILD
{
    my $self = shift;
    $self->has_vocabs || $self->_load_vocabs;
    return 1;
}

sub _read_lists
{
    my @filenames = @_;
    my @list = ();
    my $line;
    for my $file_name (@filenames) {
        open my $fh_lst, '<', $file_name
            or confess qq(Could not open file "$file_name");
        while ($line = <$fh_lst>) {
            $line =~ s/\n+$//msx;
            push @list, $line
        }
        close $fh_lst or confess qq(Could not close file "$file_name");
    }
    return \@list;
}

sub load_vocabs
{
    my $self = shift;
    my @vocabs = ();

    ( $self->has_vocab_files && @{ $self->vocab_files } )
        or confess 'There are no vocabulary files specified';

    for my $elem ( @{ $self->vocab_files } ) {
        my $list = ('ARRAY' eq ref $elem) ?
            _read_lists(@{ $elem }) : _read_lists($elem);
        push @vocabs, $list;
    }

    $self->vocabs(\@vocabs);
    return scalar @vocabs;
}

sub blend
{
    my ($self, $quantity) = @_;
    $quantity ||= $self->quantity;
    my @result = ();
    my $vocabs_top = $#{ $self->vocabs };
    my $numelems_range = $self->max_elements - $self->min_elements;
    my $permalen = length $self->prefix; $permalen += length $self->postfix;
    my $delimiterlen = length $self->delimiter;
    my $max_tries = $quantity * $self->max_tries_factor;
    my $tries = 0;

    MULTIPLE:
    for (1..$quantity) {
        $tries++;
        if ($max_tries < $tries) {
            carp "Maximum tries limit exceeded ($max_tries)";
            last MULTIPLE;
        }

        my @match = ();
        my $match_top = $self->min_elements - 1 + int rand $numelems_range;
        my $length = $permalen + $delimiterlen * $match_top;

        MATCH:
        for my $i (0..$match_top) {
            srand;

            my $vocab = $self->vocabs->[
                ($i <= $vocabs_top) ? $i : int rand $vocabs_top
            ];
            my $element = @{ $vocab }[ int rand $#{ $vocab } ];

            my $new_length = $length + length $element;
            redo MULTIPLE if $new_length > $self->max_length;
            $length = $new_length;

            int $self->strict_order || int rand() ?
                push @match, $element : unshift @match, $element;
        }

        redo MULTIPLE if ($length < $self->min_length);
        my $complete_string = join $self->delimiter, @match;
        $complete_string = $self->prefix . $complete_string . $self->postfix;

        redo MULTIPLE if scalar grep {$_ eq $complete_string} @result;
        push @result, $complete_string;
    }

    return @result;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

String::Blender - flexible vocabulary-based generator of compound words (e.g. domain names).

=head1 VERSION

This document describes String::Blender version 0.04

=head1 SYNOPSIS

    use String::Blender;
    
    my $blender = String::Blender->new(
        vocab_files => [
            './vocab/hacker-jargon.txt',  # load into vocab #0
            [
                './vocab/places.txt',     # load both files
                './vocab/boosters.txt',   # into vocab #1
            ]
        ],
        quantity => 10,
        max_length => 20,
        max_elements => 3,
        postfix => '.com',
    );
    
    my @result = $blender->blend;
    
    # The @result will look like this:
    # (
    #      'tastybitshandler.com',
    #      'bubblesortcore.com',
    #      'regexpkingdom.com',
    #      'bigslashbase.com',
    #      'powerslurp.com',
    #      'pipestacklabel.com',
    #      'metaspoofzone.com',
    #      'randomsubshell.com',
    #      'forehandleroot.com',
    #      'pragmaware.com'
    # );
    
    # Vocabularies can be also specified directly, e.g.:
    my $blender = String::Blender->new(
        vocabs => [
            [qw/web net host site list archive core base switch/],
            [qw/candy honey muffin sugar sweet yammy/],
            [qw/area city club dominion empire field land valley world/],
        ],
        strict_order => 1,
        min_elements => 3,
        max_elements => 3,
        max_length => 20,
        delimiter => "-",
    );
    
    my @result = $blender->blend(5);
    
    # Then the @result will look like this:
    # (
    #      'base-honey-field',
    #      'list-candy-dominion',
    #      'web-sugar-land',
    #      'archive-muffin-field',
    #      'web-yammy-area'
    # );


=head1 DESCRIPTION

C<String::Blender> is an OO implementation of random generator of compound
words based on one or more priority driven word vocabularies. Originally the
module was created for the purpose of constructing new attractive thematic domain
names. Later it was used to improve dictionary attack tool.

Each vocabulary itself represents an array of single words not necessarily sorted.
All vocabularies are stored in an array within predefined order. C<String::Blender>
provides ability to load vocabularies from plain text files or set them manually.

Resulting compound words are represented as an array of uniq strings which consist
of one or more vocabulary words placed in serial or random order; probably
prefixed, followed and/or separated by defined strings.

Construction of one compound word can be briefly described like this:

=over

=item * Define random number of elements within a given set of constraints.

=item * Address each vocabulary list in a row up to the defined number of
elements and take one random word per vocabulary. Once the number of future
component words exceeds the number of vocabularies, then take each next word
from random vocabulary.

=item * Concatenate selected words and/or join them with delimiter, add
prefix and postfix if defined.

=item * Check the length of the resulting word. Retry attempt if it's too long
or too short.

=back


=head1 SUBROUTINES/METHODS

=head2 Class methods

=over 4

=item * B<new (%config)>

The C<new> constructor method instantiates a new C<String::Blender> object.
A hash array of configuration attributes may be passed as a parameter.
See the </ATTRIBUTES> section.

=back


=head2 Object methods

=over 4

=item * B<blend ($quantity)>

Generates and returns list of C<$quantity> or less compound words in the manner
explained in L</DESCRIPTION> accordingly to constraints and options being set as
the object attributes described below. If C<$quantity> is omitted, then value of
the object attribute with the same name will be used.

=item * B<load_vocabs>

Loads vocabulary lists from plain text files collecting one element per line and
stores the L</vocabs> attribute. Takes lists of files from the L</vocab_files>
attribute. Returns number of vocabularies loaded. Note that  this method invokes
automatically after object creation if L</vocabs> is empty and after each setting
of the L</vocab_files> attribute, so you will not have to call it manually.

=item * B<BUILD>

Normally, you will not have to invoke this method directly, but you might want
to override it. The C<BUILD> method is called after the object is constructed and
in the C<String::Blender> object it attempts to load vocabularies from files
specified in the L</vocab_files> attribute when no vocabularies provided directly
through the L</vocabs> attribute.

=back


=head1 CONFIGURATION AND ENVIRONMENT

The following list gives a short summary of each C<String::Blender> object
attribute. All of them can be defined on object creation (see L</new>)
or set separately like follows.

    $blender->max_elements(30);
    $blender->vocabs(\@my_vocabs);


=head2 Vocabularies

=over 4

=item * B<vocabs>

Contains reference to an array of vocabularies. Each vocabulary is represented
by a reference to an array of strings, one per element. Any of those strings
should not be empty and should not contain newlines and control characters.
Being left undefined on object creation, this attribute will be set by the
L</load_vocabs> method automatically. In this case you are supposed to have the
L</vocab_files> attribute set properly.

=item * B<vocab_files>

Defines filenames and lists of filenames to read vocabularies from. Contains
reference to an array of filenames and/or references to arrays of filenames.
The L</load_vocabs> method will merge vocabularies loaded from united filenames
into a single vocabulary. After object creation this method will be invoked every
time the L</vocab_files> attribute is set. Each vocabulary file should consist
of word per line in plain text format.

=back


=head2 Constraints

=over 4

=item * B<min_length, max_length>

Define the minimum and the maximum length in characters of the resulting string.
Positive integers, dafault: 5 and 20 respectively.

=item * B<min_elements, max_elements>

Define the minimum and the maximum number of elements the resulting string should
consist of. Positive integers, dafault: 2 and 5 respectively.

=item * B<max_tries_factor>

Defines the maximum number of generation loops per </blend> as the product of
</quantity> and C<max_tries_factor> values. Positive integer, dafault: 4. For
example, if the </quantity> equals to 10, the number of generation loops will be
limited to 40.

=back


=head2 Options

=over 4

=item * B<quantity>

Defines the quantity of strings to be generated per one invocation of the L</blend>
method. Positive integer, default: 10.

=item * B<strict_order>

Concatenate string elements according to the strict order of vocabularies they
were taken from. Boolean, default: false.

=item * B<delimiter>

String to separate string elements with in each resulting string. Empty by default.

=item * B<prefix>

String to prefix each resulting string with. Empty by default.

=item * B<postfix>

String to follow each resulting string by. Empty by default.

=back


=head1 DIAGNOSTICS

There are some exceptional situations worth consideration.

=over

=item C<< Maximum tries limit exceeded (%s) >>

Normally the size of resulting list returned by the L</blend> method should be
equal to C<$quantity>. But having in mind that the method is intended to provide
a list of unique strings within certain restrictions, it becomes clear that in
some conditions there is a chance to fall into infinite loop. That's what the
L</max_tries_factor> limitation attribute stands for. When the generator runs
into narrow constraints and/or poor vocabularies, the resulting list may turn out
to be shoter then expected or even empty. In this case relevant warning will follow.
In order to avoid this you might want to increase value of the L</max_tries_factor>
attribute or weaken generation constraints such as L</min_elements>,
L</max_elements>, L</min_length>, L</max_length>.

=item C<< There are no vocabulary files specified >>

The C<load_vocabs> method will die once the L</vocab_files> attribute is not
defined or refers to an empty list.

=item C<< Could not open (close) file %s >>

L</load_vocabs> will also die being unable to open any file specified in the
L</vocab_files> attribute.

=item C<< Attribute (%s) does not pass the type constraint because: %s >>

Assigning any object attribute to a value which does not match the attribute's
type constraints will cause relevant fatal error.

=back


=head1 DEPENDENCIES

C<String::Blender> depends on the L<Moose> object system (version 0.74 or newer)
which must be installed separately.

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.
The API is not stable yet and can be changed in future.

Please report any bugs or feature requests to
C<bug-string-blender@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Alexey Skorikov  C<< <alexey@skorikov.name> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Alexey Skorikov C<< <alexey@skorikov.name> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
