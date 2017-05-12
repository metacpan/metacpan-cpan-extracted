use strict;
use warnings;
use utf8;
use v5.10;

package Object::String;
use Unicode::Normalize;
use List::Util;

our $VERSION = '0.11'; # VERSION

# ABSTRACT: A string object for Perl 5

use Moo;
use namespace::clean;



has 'string' => ( is => 'ro' );


sub to_string { shift->string; }


sub to_lower {
    my $self = shift;
    $self->{string} = lc $self->{string};
    return $self;
}


sub to_lower_first {
    my $self = shift;
    $self->{string} = lcfirst $self->{string};
    return $self;
}


sub to_upper {
    my $self = shift;
    $self->{string} = uc $self->{string};
    return $self;
}


sub to_upper_first {
    my $self = shift;
    $self->{string} = ucfirst $self->{string};
    return $self;
}


sub capitalize { shift->to_lower->to_upper_first; }


sub Object::String::length { return CORE::length shift->string; }


sub ensure_left {
    my ($self, $prefix) = @_;
    $self->{string} = $self->prefix($prefix)->string 
        unless($self->starts_with($prefix));     
    return $self;
}


sub ensure_right {
    my ($self, $suffix) = @_;
    $self->{string} = $self->suffix($suffix)->string 
        unless($self->ends_with($suffix));
    return $self;
}


sub trim_left {
    my $self = shift;
    $self->{string} =~ s/^(\s|\t)+//;
    return $self;
}


sub trim_right {
    my $self = shift;
    $self->{string} =~ s/(\s|\t)+$//;
    return $self;
}


sub trim { shift->trim_left->trim_right; }


sub clean { 
    my $self = shift;
    $self->{string} =~ s/(\s|\t)+/ /g;
    return $self->trim;
}


sub collapse_whitespace { shift->clean; }


sub repeat {
    my ($self, $n) = @_;
    $self->{string} = $self->string x $n;
    return $self;
}


sub times { shift->repeat(@_); }


sub starts_with {
    my ($self, $str) = @_;
    return ($self->string =~ /^$str/);
}


sub ends_with {
    my ($self, $str) = @_;
    return ($self->string =~ /$str$/);
}


sub contains {
    my ($self, $str) = @_;
    return index $self->string, $str;
}


sub include { shift->contains(@_); }


sub chomp_left { 
    my $self = shift;
    if($self->starts_with(" ") || $self->starts_with("\t")) {
        return $self->chop_left;
    }
    return $self;
}


sub chomp_right {
    my $self = shift;
    if($self->ends_with(" ") || $self->ends_with("\t")) {
        return $self->chop_right;
    }
    return $self;
}


sub chop_left {
    my $self = shift;
    $self->{string} = substr $self->{string}, 1, CORE::length $self->{string};
    return $self;

}


sub chop_right {
    my $self = shift;
    chop $self->{string};
    return $self;
}


sub is_numeric { shift->string =~ /^\d+$/; }


sub is_alpha { shift->string =~ /^[a-zA-Z]+$/; }


sub is_alpha_numeric { shift->string =~ /^[a-zA-Z0-9]+$/; }


sub is_lower {
    my $self = shift;
    return $self->string eq lc $self->string;
}


sub is_upper {
    my $self = shift;
    return $self->string eq uc $self->string;
}


sub to_boolean {
    my $self = shift;
    return 1 if $self->string =~ /^(on|yes|true)$/i;
    return 0 if $self->string =~ /^(off|no|false)$/i;
    return;
}


sub to_bool { shift->to_boolean }


sub is_empty {
    my $self = shift;
    return 1 if $self->string =~ /\s+/ || $self->string eq '';
    return 0;
}


sub count {
    my ($self, $str) = @_;
    return () = $self->string =~ /$str/g;
}


sub left {
    my ($self, $count) = @_;
    if($count < 0) { 
        $self->{string} = substr $self->string, $count, abs($count); 
        return $self;
    }
    $self->{string} = substr $self->string, 0, $count;
    return $self;
}


sub right {
    my ($self, $count) = @_;
    if($count < 0) { 
        $self->{string} = substr $self->string, 0, abs($count); 
        return $self;
    }
    $self->{string} = substr $self->string, -$count, $count;
    return $self;
}


sub underscore {
    my $self = shift;
    $self->{string} = $self->transliterate(' -', '_')->string;
    $self->{string} =~ s/::/\//g;
    $self->{string} =~ s/^([A-Z])/_$1/;
    $self->{string} =~ s/([A-Z]+)([A-Z][a-z])/$1_$2/g;
    $self->{string} =~ s/([a-z\d])([A-Z])/$1_$2/g;
    return $self->to_lower;
}


sub underscored { shift->underscore; }


sub dasherize { shift->underscore->transliterate('_', '-'); }


sub camelize {
    my $self = shift;
    my $begins_underscore = $self->underscore->starts_with('_');
    $self->{string} = join '', map { ucfirst $_ } split /_/, $self->underscore->string;
    $self->{string} = join '::', map { ucfirst $_ } split /\//, $self->string;
    return ($begins_underscore ? $self : $self->to_lower_first);
}


sub latinise {
    my $self = shift;
    $self->{string} = NFKD($self->string);
    $self->{string} =~ s/\p{NonspacingMark}//g;
    return $self;
}


sub escape_html {
    return shift->replace_all('&', '&amp;')
                ->replace_all('"', '&quot;')
                ->replace_all("'", '&#39;')
                ->replace_all('<', '&lt;')
                ->replace_all('>', '&gt;');
}


sub unescape_html {
    return shift->replace_all('&amp;', '&')
                ->replace_all('&quot;', '"')
                ->replace_all('&#39;', "'")
                ->replace_all('&lt;', '<')
                ->replace_all('&gt;', '>');
}


sub index_left {
    my ($self, $substr, $position) = @_;
    return index $self->string, $substr, $position if defined $position;
    return index $self->string, $substr;
}


sub index_right {
    my ($self, $substr, $position) = @_;
    return rindex $self->string, $substr, $position if defined $position;
    return rindex $self->string, $substr;
}


sub replace_all {
    my ($self, $substr1, $substr2) = @_;
    $substr1 = quotemeta $substr1;
    $self->{string} =~ s/$substr1/$substr2/g;
    return $self;
}


sub humanize {
    return shift->underscore
                ->replace_all('_', ' ')
                ->trim
                ->capitalize;
}


sub pad_left {
    my ($self, $count, $char) = @_;
    $char = ' ' unless defined $char;
    return $self if $count <= $self->length;
    $self->{string} = $char x ($count - $self->length) . $self->string;
    return $self;
}


sub pad_right {
    my ($self, $count, $char) = @_;
    $char = ' ' unless defined $char;
    return $self if $count <= $self->length;
    $self->{string} = $self->string . $char x ($count - $self->length);
    return $self;
}


sub pad {
    my ($self, $count, $char) = @_;
    $char = ' ' unless defined $char;
    return $self if $count <= $self->length;
    my $count_left = 1 + int(($count - $self->length) / 2);
    my $count_right = $count - $self->length - $count_left;
    $self->{string} = $char x $count_left . $self->string;
    $self->{string} = $self->string . $char x $count_right;
    return $self;
}


sub next {
    my $self = shift;
    $self->{string}++;
    return $self;
}


sub slugify {
    return shift->trim
                ->humanize
                ->latinise
                ->strip_punctuation
                ->to_lower
                ->dasherize;
}


sub strip_punctuation {
    my $self = shift;
    $self->{string} =~ s/[[:punct:]]//g;
    return $self;
}


sub swapcase { shift->transliterate('a-zA-Z', 'A-Za-z'); }


sub concat {
    my ($self, @strings) = @_;
    $self->{string} = $self->string . join '', @strings;
    return $self;
}


sub suffix { shift->concat(@_); }


sub prefix {
    my ($self, @strings) = @_;
    $self->{string} = join('', @strings) . $self->string;
    return $self;
}


sub reverse {
    my $self = shift;
    $self->{string} = join '', reverse split //, $self->string;
    return $self;
}


sub count_words {
    my @arr = split /\s/, shift->clean->string;
    return $#arr + 1;
}


sub quote_meta {
    my $self = shift;
    $self->{string} = quotemeta $self->string;
    return $self;
}


sub rot13 { shift->transliterate('A-Za-z', 'N-ZA-Mn-za-m'); }


sub say { CORE::say shift->string; }


sub titleize {
    my $self = shift;
    $self->{string} = join ' ', map { str($_)->capitalize->string } 
                                    split / /, 
                                          $self->clean
                                               ->strip_punctuation
                                               ->string;
    return $self;
}


sub titlecase { shift->titleize }


sub squeeze {
    my ($self, $keep) = @_;
    $keep = '' unless defined $keep;
    $self->{string} =~ eval "\$self->{string} =~ tr/$keep//cs";
    return $self;
}


sub shuffle {
    my $self = shift;
    $self->{string} = join '', List::Util::shuffle split //, $self->string;
    return $self;
}


sub transliterate { 
    my ($self, $str1, $str2) = @_;
    $self->{string} =~ eval "\$self->{string} =~ tr/$str1/$str2/";
    return $self;
}

no Moo;

use base 'Exporter';

our @EXPORT = qw {
    str
};


sub str {
    my $string = join ' ', @_;
    return Object::String->new(string => $string);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Object::String - A string object for Perl 5

=head1 VERSION

version 0.11

=head1 DESCRIPTION

A string object for Perl 5.

C<Object::String> have a lot of "modern" features and supports method chaining. A helper is also provided to 
help to build a string object.

C<Object::String> is heavily inspired by stringjs a Ruby string object.

    # Normal way to build a string object
    my $string = Object::String->new(string => 'test');

    # With the helper
    my $string = str('test');

    # Display the string
    say $string->string;

    # Method chaining 
    say $string->chomp_right->to_upper->string;
    say str('testZ')->chop_right->to_upper->string; # TEST

=head1 METHODS

=head2 string

Converts the object into a string scalar.
Aliases: C<to_string>

=head2 to_string

An alias to C<string>.

=head2 to_lower

Converts the string to lower case.

    say str('TEST')->to_lower->string; # test

=head2 to_lower_first

Lower case the first letter of a string.

    say str('TEST')->to_lower_first->string; # tEST

=head2 to_upper

Converts the string to upper case.

    say str('test')->to_upper->string; # TEST

=head2 to_upper_first

Upper case the first letter of a string.

    say str('test')->to_upper_first->string; # Test

=head2 capitalize

Capitalizes a string.

    say str('TEST')->capitalize->string; # Test

=head2 length

Returns the length of a string.

    say str('test')->length; # 4

=head2 ensure_left($prefix)

Ensures the string is beginning with C<$prefix>.

    say str('dir')->ensure_left('/')->string;   # /dir
    say str('/dir')->ensure_left('/')->string;  # /dir

=head2 ensure_right($suffix)

Ensures the string is ending with C<$suffix>.

    say str('/dir')->ensure_right('/')->string;     # /dir/
    say str('/dir/')->ensure_right('/')->string;    # /dir/

=head2 trim_left

Trim string from left.

    say str("  \t test")->trim_left->string; # test

=head2 trim_right

Trim string from right.

    say str("test \t   \t")->trim_right->string; # test

=head2 trim

Trim string from left and from right.

    say str("\t  \ttest \t\t")->trim->string; # test

=head2 clean

Deletes unuseful whitespaces.

    say str("This\t   \tis  \t a     \t test")->clean->string; # This is a test

Aliases: C<collapse_whitespace>

=head2 collapse_whitespace

An alias to C<clean>.

=head2 repeat($n)

Repeats a string C<$n> times.
Aliases: C<times>

    say str('test')->repeat(3)->string; # testtesttest

=head2 times($n)

An alias to C<repeat>.

=head2 starts_with($str)

Tests if the string starts with C<$str>.

    str('test')->starts_with('te');     # true
    str('test')->starts_with('z');      # false

=head2 ends_with($str)

Tests if the string ends with C<$str>.

    str('test')->ends_with('st');   # true
    str('test')->ends_with('z');    # false

=head2 contains($str)

Tests if the string contains C<$str>.
Aliases: C<include>

    str('test')->contains('es');    # true
    str('test')->contains('z');     # false

=head2 include($str)

An alias to C<contains>.

=head2 chomp_left

Chomp left the string. If the string begins by a space or a tab, it is removed.

=head2 chomp_right

Chomp right the string. Same as the Perl's C<chomp> function.

=head2 chop_left

Deletes the first character of the string.

    say str('test')->chop_left->string; # est

=head2 chop_right

Deletes the last character of the string. Same function as Perl's C<chop> function.

    say str('test')->chop_right->string; # tes

=head2 is_numeric

Tests if the string is composed by numbers.

    str('123')->is_numeric;     # true
    str('1.23')->is_numeric;    # false
    str('ab1')->is_numeric;     # false

=head2 is_alpha

Tests if the string is composed by alphabetic characters.

    str('abc')->is_alpha;       # true
    str('a1b2c3')->is_alpha;    # false

=head2 is_alpha_numeric

Tests if the string is composed only by letters and numbers.

    str('abc')->is_alpha_numeric;       # true
    str('a1b2c3')->is_alpha_numeric;    # true
    str('1.3e10')->is_alpha_numeric;    # false

=head2 is_lower

Tests if a string is lower case.

    str('TEST')->is_lower; # false
    str('test')->is_lower; # true

=head2 is_upper

Tests if the string is upper case.

    str('TEST')->is_upper; # true
    str('test')->is_upper; # false

=head2 to_boolean

Returns a boolean if the string is ON|OFF, YES|NO, TRUE|FALSE upper or lower case.
Aliases: C<to_bool>

    str('on')->to_boolean;      # true
    str('off')->to_boolean;     # false
    str('yes')->to_boolean;     # true
    str('no')->to_boolean;      # false
    str('true')->to_boolean;    # true
    str('false')->to_boolean;   # false
    str('test')->to_boolean;    # undef

=head2 to_bool

An alias to C<to_boolean>.

=head2 is_empty

Tests if a string is empty. 

    str('')->is_empty;          # true
    str('   ')->is_emtpy;       # true
    str("  \t\t  ")->is_empty;  # true
    str("aaa")->is_empty;       # false

=head2 count($str)

Counts the occurrences of C<$str> in the string.

    say str('This is a test')->count('is'); # 2

=head2 left($count)

Returns a substring of C<$count> characters from the left.

    say str('This is a test')->left(3)->string;     # Thi
    say str('This is a test')->left(-3)->string;    # est

=head2 right($count)

Returns a substring of C<$count> characters from the right.

    say str('This is a test')->right(3)->string;    # est
    say str('This is a test')->right(-3)->string;   # Thi

=head2 underscore

Converts the string to snake case.
Aliases: C<underscored>

    say str('thisIsATest')->underscore->string;     # this_is_a_test
    say str('ThisIsATest')->underscore->string;     # _this_is_a_test
    say str('This::IsATest')->underscore->string;   # _this/is_a_test
    say str('This Is A Test')->underscore->string;  # this_is_a_test

=head2 underscored

An alias to underscore.

=head2 dasherize

Converts the string to a dasherized one.

    say str('thisIsATest')->dasherize->string;      # thisr-is-a-test
    say str('ThisIsATest')->dasherize->string;      # -this-is-a-test
    say str('This::IsATest')->dasherize->string;    # -this/is-a-test
    say str('This Is A Test')->dasherize->string;   # this-is-a-test

=head2 camelize

Converts the string to a camelized one.

    say str('this-is-a-test')->camelize->string;    # thisIsATest
    say str('_this_is_a_test')->camelize->string;   # ThisIsATest
    say str('_this/is/a-test')->camelize->string;   # This::Is::ATest
    say str('this is a test')->camelize->string;    # thisIsATest

=head2 latinise

Removes accents from Latin characters.

    say str('où es-tu en été ?')->latinise->string; # ou es-tu en ete ?

=head2 escape_html

Escapes some HTML entities : &"'<>

    # &lt;h1&gt;l&#39;été sera beau &amp; chaud&lt;/h1&gt;
    say str("<h1>l'été sera beau & chaud</h1>")->escape_html->string;

    #&lt;h1&gt;entre &quot;guillemets&quot;&lt;/h1&gt;
    say str('<h1>entre "guillemets"</h1>')->escape_html->string    

=head2 unescape_html

Unescapes some HTML entities : &"'<>

=head2 index_left($substr[, $position])

Searches for a substring within another from a position. If C<$position> is
not specified, it begins from 0.

    say str('this is a test')->index_left('is');        # 2
    say str('this is a test')->index_right('is', 3);    # 5

=head2 index_right($substr[, $position])

Searches from right for a substring within another from a position. If C<$position> 
is not specified, it begins from 0.

    say str('this is a test')->index_right('is');       # 5
    say str('this is a test')->index_right('is', 5);    # 2

=head2 replace_all($substr1, $substr2)

Replaces all occurrences of a substring within the string.

    say str('This is a test')->replace_all(' ', '_'); # this_is_a_test

=head2 humanize

Transforms the input into a human friendly form.

    say str('-this_is a test')->humanize->string; # This is a test

=head2 pad_left($count[, $char])

Pad left the string with C<$count> C<$char>. 
If C<$char> is not specified, a space is used.

    say str('hello')->pad_left(3)->string;          # hello
    say str('hello')->pad_left(5)->string;          # hello
    say str('hello')->pad_left(10)->string;         #      hello
    say str('hello')->pad_left(10, '.')->string;    # .....hello

=head2 pad_right($count[, $char])

Pad right the string with C<$count> C<$char>.
If C<$char> is not specified, a space is used.

    say str('hello')->pad_right(3)->string;         # hello
    say str('hello')->pad_right(5)->string;         # hello
    say str('hello')->pad_right(10)->string;        # "hello     "
    say str('hello')->pad_left(10, '.')->string;    # hello.....

=head2 pad($count[, $char])

Pad the string with C<$count> C<$char>.
If C<$char> is not specified, a space is used.

    say str('hello')->pad(3)->string;       # hello
    say str('hello')->pad(5)->string;       # hello
    say str('hello')->pad(10)->string;      # "   hello  "
    say str('hello')->pad(10, '.')->string; # ...hello..

=head2 next

Increments the string.

    say str('a')->next->string; # b
    say str('z')->next->string; # aa

=head2 slugify

Transfoms the input into an url slug.

    say str('En été, il fera chaud')->slugify->string; # en-ete-il-fera-chaud

=head2 strip_punctuation

Strips punctuation from the string.

    say str('this. is, %a (test)'); # this is a test

=head2 swapcase

Swaps the case of the string.

    say str('TeSt')->swapcase->string; # tEsT

=head2 concat($str1[, ...])

Concats multiple strings.
Aliases: C<suffix>

    say str('test')->concat('test')->string;            # testtest
    say str('test')->concat('test', 'test')->string;    # testtesttest

=head2 suffix($str1[, ...])

An alias to C<concat>.

=head2 prefix($str1[, ...])

Prefix the string with C<$str1, ...>

    say str('test')->prefix('hello')->string;           # hellotest
    say str('test')->prefix('hello', 'world')->string;  # helloworldtest

=head2 reverse

Reverses a string.

    say str('test')->reverse->string; # tset

=head2 count_words

Counts the words in a string.

    say str("this\tis a \t test")->count_words; # 4

=head2 quote_meta

Quotes meta characters.

    # hello\ world\.\ \(can\ you\ hear\ me\?\)
    say str('hello world. (can you hear me?)')->quote_meta->string; 

=head2 rot13

ROT13 transformation on the string.

    say str('this is a test')->rot13->string;           # guvf vf n grfg
    say str('this is a test')->rot13->rot13->string;    # this is a test

=head2 say

Says the string.

    str('this is a test')->say; # displays "this is a test\n"

=head2 titleize

Strips punctuation and capitalizes each word.
Aliases: C<titlecase>

    say str('this is a test')->titleize->string; # This Is A Test

=head2 titlecase

An alias to C<titleize>.

=head2 squeeze([$keep])

Deletes all consecutive same characters with exceptions.

    say str('woooaaaah, balls')->squeeze->string;         # woah, bals

    # keep consecutive 'a' characters
    say str('woooaaaah, balls')->squeeze->string;         # woaaaah, balls

    # keep characters from 'l' to 'o'
    say str('woooaaaah, balls')->squeze('l-o')->string;   # woooah, balls

=head2 shuffle

Shuffles a string.

    say str('this is a test')->shuffle->string; # tsi  ssati the

=head2 transliterate

Transliterates a string into an another one. It wraps the C<tr()> Perl function.

    say str('test')->transliterate('a-z', 'A-Z')->string; # TEST

=head2 str

Creates and returns a string object.

    str("test")->string                     # test
    str("test")->to_upper->string           # TEST
    str('this', 'is', 'a', 'test')->string; # this is a test

=head1 AUTHOR

Vincent BERZIN <berzinv@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Vincent BERZIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
