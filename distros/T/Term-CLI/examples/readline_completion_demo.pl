#!/usr/bin/perl

# See https://robots.thoughtbot.com/tab-completion-in-gnu-readline

use Modern::Perl;
use lib qw( ../lib );
use File::Basename qw( fileparse );
use Data::Dumper;
use Text::ParseWords qw( shellwords );
use Term::ReadLine;
use Term::ReadLine::Gnu;

use FindBin;

my $prog = $FindBin::Script;
my $term = Term::ReadLine->new("readline_completion_demo");

sub complete_word {
    my ($term, $text, $line, $start, $end) = @_;

    my @list = (
        "Lucky Luke", "Jolly Jumper", "Joe Dalton",
        "William Dalton", "Jack Dalton", "Averell Dalton"
    );

    if (length $term->Attribs->{completion_quote_character}
        && $term->Attribs->{completion_quote_character} ne "\000"
    ) {
        return @list;
    }
    else {
        return map { s/(\s)/\\$1/gr } @list;
    }
}

# BOOL = is_escaped($line, $index);
#
# The character at $index in $line is a possible word break
# character. Check if it is perhaps escaped.
#
sub is_escaped {
    my ($line, $index) = @_;
    return (
        $index > 0 &&
        substr($line, $index-1, 1) eq '\\' &&
        !is_escaped($line, $index-1)
    );
}

sub escape_string {
    my $s = shift;
    $s =~ s/\n/\\n/g;
    $s =~ s/\t/\\t/g;
    $s =~ s/\r/\\r/g;
    $s =~ s/(\000-\017)/sprintf("%03o", ord($1))/ge;
    return $s;
}

$term->Attribs->{completion_function} = sub { complete_word($term, @_) };
$term->Attribs->{completer_quote_characters} = q{"'};

# Default: \n\t\\ "'`@$><=;|&{(
#$term->Attribs->{completer_word_break_characters} =~ s{\\}{}g;
$term->Attribs->{completer_word_break_characters} = "\t\n ";

$term->Attribs->{char_is_quoted_p} = \&is_escaped;

for my $k (qw(
    completer_quote_characters
    completer_word_break_characters
)) {
    say "$k = <", escape_string($term->Attribs->{$k} // ''), ">";
}

while (1) {
    my $input = $term->readline('~> ');
    last if !defined $input;

    next if $input =~ /^\s*(?:#.*)?$/;
    my @words = shellwords($input);
    say "input:", map { " <$_>" } @words;
is_escaped
