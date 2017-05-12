#!/usr/bin/env perl

use 5.008001;
use utf8;
use strict;
use warnings;

use version; our $VERSION = qv('v0.0.3');

use PPI::Token::Word;
use PPIx::Grep;
use Readonly;


use Test::More tests => 9;


Readonly my $CHOMPED_WORD_CONTENT       => 'test_word';
Readonly my $WORD_CONTENT_TO_BE_CHOMPED => "$CHOMPED_WORD_CONTENT\n";
Readonly my $WORD                       => PPI::Token::Word->new($WORD_CONTENT_TO_BE_CHOMPED);

Readonly my $STRIPPED_WORD_CONTENT       => 'test word';
Readonly my $WORD_CONTENT_TO_BE_STRIPPED => " \ttest  \nword\n   ";
Readonly my $STRIPPED_WORD               => PPI::Token::Word->new($WORD_CONTENT_TO_BE_STRIPPED);

Readonly my $FILENAME               => 'an example file name';
Readonly my $TEST_LINE_NUMBER       => 53;
Readonly my $TEST_CHARACTER_NUMBER  => 194;
Readonly my $TEST_COLUMN_NUMBER     => 396;
Readonly my $LOCATION => [
    $TEST_LINE_NUMBER,
    $TEST_CHARACTER_NUMBER,
    $TEST_COLUMN_NUMBER,
];


## no critic (Subroutines::ProtectPrivateSubs)

PPIx::Grep::set_print_format('x');
is(
    PPIx::Grep::_format_element($WORD, $FILENAME, $LOCATION),
    'x',
    'format with no substitutable value returns the format.',
);


PPIx::Grep::set_print_format('%f');
is(
    PPIx::Grep::_format_element($WORD, $FILENAME, $LOCATION),
    $FILENAME,
    q<"%f" returns the filename.>,
);


PPIx::Grep::set_print_format('%l');
is(
    PPIx::Grep::_format_element($WORD, $FILENAME, $LOCATION),
    $TEST_LINE_NUMBER,
    q<"%l" returns the line number.>,
);


PPIx::Grep::set_print_format('%c');
is(
    PPIx::Grep::_format_element($WORD, $FILENAME, $LOCATION),
    $TEST_CHARACTER_NUMBER,
    q<"%c" returns the character number.>,
);


PPIx::Grep::set_print_format('%C');
is(
    PPIx::Grep::_format_element($WORD, $FILENAME, $LOCATION),
    $TEST_COLUMN_NUMBER,
    q<"%C" returns the column number.>,
);


PPIx::Grep::set_print_format('%s');
is(
    PPIx::Grep::_format_element($WORD, $FILENAME, $LOCATION),
    $WORD_CONTENT_TO_BE_CHOMPED,
    q<"%s" returns the element content.>,
);


PPIx::Grep::set_print_format('%t');
is(
    PPIx::Grep::_format_element($WORD, $FILENAME, $LOCATION),
    $CHOMPED_WORD_CONTENT,
    q<"%t" returns the chomped element content.>,
);


PPIx::Grep::set_print_format('%w');
is(
    PPIx::Grep::_format_element($STRIPPED_WORD, $FILENAME, $LOCATION),
    $STRIPPED_WORD_CONTENT,
    q<"%w" returns the stripped element content for a simple Word.>,
);

Readonly my $EXCEPTION_CLASS => <<'END_EXCEPTION_CLASS';
    use Exception::Class (
    'Perl::Critic::Exception' => {
        isa         => 'Exception::Class::Base',
        description => 'A problem discovered by Perl::Critic.',
    },
);
END_EXCEPTION_CLASS

## no critic (RestrictLongStrings)
Readonly my $STRIPPED_EXCEPTION_CLASS =>
    q[use Exception::Class ( 'Perl::Critic::Exception' => { isa => 'Exception::Class::Base', description => 'A problem discovered by Perl::Critic.', }, );];
## use critic
## no critic (Subroutines::ProtectPrivateSubs)
is(
    PPIx::Grep::_format_element(
        PPI::Token::Word->new($EXCEPTION_CLASS),
        $FILENAME,
        $LOCATION,
    ),
    $STRIPPED_EXCEPTION_CLASS,
    q<"%w" returns the stripped element content for "use Exception::Class".>,
);

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
