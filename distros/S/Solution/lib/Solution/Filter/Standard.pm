package Solution::Filter::Standard;
{
    use strict;
    use warnings;
    our $VERSION = '0.9.1';
    Solution->register_filter() if $Solution::VERSION;

    sub date {
        $_[0] = time() if lc $_[0] eq 'now' || lc $_[0] eq 'today';
        $_[1] = defined $_[1] ? $_[1] : '%c';
        return $_[0]->strftime($_[1]) if ref $_[0] && $_[0]->can('strftime');
        return if $_[0] !~ m[^\d+$];
        require POSIX;
        return POSIX::strftime($_[1], gmtime($_[0]));
    }
    sub capitalize { return ucfirst lc $_[0]; }
    sub upcase     { return uc $_[0] }
    sub downcase   { return lc $_[0] }
    sub first      { return @{$_[0]}[0] if ref $_[0] eq 'ARRAY'; }
    sub last       { return @{$_[0]}[-1] if ref $_[0] eq 'ARRAY'; }

    sub join {
        $_[1] = defined $_[1] ? $_[1] : ' ';
        return CORE::join($_[1], @{$_[0]})      if ref $_[0] eq 'ARRAY';
        return CORE::join($_[1], keys %{$_[0]}) if ref $_[0] eq 'HASH';
        return $_[0];
    }
    sub split { [split $_[1], $_[0]] }

    sub sort {
        return [sort { $a <=> $b } @{$_[0]}] if ref $_[0] eq 'ARRAY';
        return sort keys %{$_[0]} if ref $_[0] eq 'HASH';
        return $_[0];
    }

    sub size {
        return scalar @{$_[0]} if ref $_[0] eq 'ARRAY';
        return scalar keys %{$_[0]} if ref $_[0] eq 'HASH';
        return length $_[0];
    }

    sub strip_html {
        $_[0] =~ s[<.*?>][]g;
        $_[0] =~ s[<!--.*?-->][]g;
        $_[0] =~ s[<script.*?<\/script>][]g;
        return $_[0];
    }
    sub strip_newlines { $_[0] =~ s[\n][]g;         return $_[0]; }
    sub newline_to_br  { $_[0] =~ s[\n][<br />\n]g; return $_[0]; }

    sub replace {
        $_[2] = defined $_[2] ? $_[2] : '';
        $_[0] =~ s{$_[1]}{$_[2]}g if $_[1];
        return $_[0];
    }

    sub replace_first {
        $_[2] = defined $_[2] ? $_[2] : '';
        $_[0] =~ s{$_[1]}{$_[2]};
        return $_[0];
    }
    sub remove       { $_[0] =~ s{$_[1]}{}g; return $_[0] }
    sub remove_first { $_[0] =~ s{$_[1]}{};  return $_[0] }

    sub truncate {
        my ($data, $length, $truncate_string) = @_;
        $length = defined $length ? $length : 50;
        $truncate_string
            = defined $truncate_string ? $truncate_string : '...';
        return if !$data;
        my $l = $length - length($truncate_string);
        $l = 0 if $l < 0;
        return
            length($data) > $length ?
            substr($data, 0, $l) . $truncate_string
            : $data;
    }

    sub truncatewords {
        my ($data, $words, $truncate_string) = @_;
        $words = defined $words ? $words : 15;
        $truncate_string
            = defined $truncate_string ? $truncate_string : '...';
        return if !$data;
        my @wordlist = split ' ', $data;
        my $l = $words - 1;
        $l = 0 if $l < 0;
        return $#wordlist > $l
            ?
            CORE::join(' ', @wordlist[0 .. $l]) . $truncate_string
            : $data;
    }
    sub prepend { return (defined $_[1] ? $_[1] : '') . $_[0]; }
    sub append { return $_[0] . (defined $_[1] ? $_[1] : ''); }

    sub minus {
        return $_[0] =~ m[^\d+$] && $_[1] =~ m[^\d+$] ? $_[0] - $_[1] : ();
    }

    sub plus {
        return $_[0] =~ m[^\d+$]
            && $_[1] =~ m[^\d+$] ? $_[0] + $_[1] : $_[0] . $_[1];
    }

    sub times {
        return $_[0] if $_[1] !~ m[^\d+$];
        return $_[0] x $_[1] if $_[0] !~ m[^\d+$];
        return $_[0] * $_[1];
    }
    sub divided_by { return $_[0] / $_[1]; }

    sub modulo {
        return ((!defined $_[0] && $_[0] =~ m[[^\d\.]]) ? '' : (!defined $_[1]
                               && $_[1] =~ m[[^\d\.]]) ? $_[0] : $_[0] % $_[1]
        );
    }

    #
    # TODO
    #sub escape {...}    # Escape's HTML
    #sub escape_once {
    #    ...;
    #} # returns an escaped version of html without affecting existing escaped entities
    #sub map {...}    # map/collect on a given property
}
1;

=pod

=head1 NAME

Solution::Filter::Standard - Default Filters Based on Liquid's Standard Set

=head1 Standard Filters

These are the current default filters. They have been written to behave
exactly like their Ruby Liquid counterparts accept where Perl makes improvment
irresistable.

=head2 C<date>

Reformat a date...

=over 4

=item * ...by calling the object's C<strftime> method. This is tried first so
dates may be defined as a L<DateTime|DateTime/"strftime Patterns"> or
L<DateTimeX::Lite|DateTimeX::Lite> object...

    # On my dev machine where obj is an object built with DateTime->now()
    {{ obj  | date:'%c' }} => Dec 14, 2009 2:05:31 AM

=item * ...with the L<POSIX> module's L<strftime|POSIX/"strftime"> function.
This is the last resort and flags may differ by system so... Buyer beware.

    # On my dev machine where date contains the current epoch as an integer
    {{ date | date:'%c' }} => 12/14/2009 2:05:31 AM

=back

The C<date> filter also supports simple replacements of C<'now'> and
C<'today'> with the current time. For example:

    {{ 'now' | date :'%Y' }}

...would print the current year.

=head2 C<capitalize>

Capitalize words in the input sentence. This filter first applies Perl's C<lc>
function and then the C<ucfirst> function.

    {{ 'this is ONLY a test.' | capitalize }} => This is only a test.

=head2 C<downcase>

Convert an input string to lowercase using Perl's C<lc> function.

    {{ 'This is HUGE!' | downcase }} => This is huge!

=head2 C<upcase>

Convert a input string to uppercase using Perl's C<uc> function.

=head2 C<first>

Get the first element of the passed in array

    # Where array is [1..6]
    {{ array | first }} => 1

=head2 C<last>

Get the last element of the passed in array.

    # Where array is [1..6]
    {{ array | last }} => 6

=head2 C<join>

Joins elements of the array with a certain character between them.

    # Where array is [1..6]
    {{ array | join }}      => 1 2 3 4 5 6
    {{ array | join:', ' }} => 1, 2, 3, 4, 5, 6

=head2 C<split>

Split input string into an array of substrings separated by given pattern.

    # Where values is 'foo,bar,baz'
    {{ values | split ',' | last }} => baz

=head2 C<sort>

Sort elements of the array.

    # Where array is defined as [3, 5, 7, 2, 8]
    {{ array | sort }} => 2, 3, 5, 7, 8

=head2 C<size>

Return the size of an array, the length of a string, or the number of keys in
a hash.

    # Where array is [1..6] and hash is { child => 'blarg'}
    {{ array     | size }} => 6
    {{ 'Testing' | size }} => 7
    {{ hash      | size }} => 1

=head2 C<strip_html>

Strip html from string. Note that this filter uses C<s[<.*?>][]g> in
emmulation of the Ruby Liquid library's strip_html function. ...so don't email
me if you (correcly) think this is a braindead way of stripping html.

    {{ '<div>Hello, <em id="whom">world!</em></div>' | strip_html }}  => Hello, world!
    '{{ '<IMG SRC = "foo.gif" ALT = "A > B">'        | strip_html }}' => ' B">'
    '{{ '<!-- <A comment> -->'                       | strip_html }}' => ' -->'

=head2 C<strip_newlines>

Strips all newlines (C<\n>) from string using the regular expression
C<s[\n][]g>.

=head2 C<newline_to_br>

Replaces each newline (C<\n>) with html break (C<< <br />\n >>).

=head2 C<replace>

Replace all occurrences of a string with another string. The replacement value
is optional and defaults to an empty string (C<''>).

    {{ 'foofoo'                 | replace:'foo','bar' }} => barbar
    {% assign this = 'that' %}
    {{ 'Replace that with this' | replace:this,'this' }} => Replace this with this
    {{ 'I have a listhp.'       | replace:'th' }}        => I have a lisp.

=head1 C<replace_first>

Replaces the first occurrence of a string with another string. The replacement
value is optional and defaults to an empty string (C<''>).

    {{ 'barbar' | replace_first:'bar','foo' }} => 'foobar'

=head2 C<remove>

Remove each occurrence of a string.

    {{ 'foobarfoobar' | remove:'foo' }} => 'barbar'

=head2 C<remove_first>

Remove the first occurrence of a string.

    {{ 'barbar' | remove_first:'bar' }} => 'bar'

=head2 C<truncate>

Truncate a string down to C<x> characters.

    {{ 'Running the halls!!!' | truncate:19 }}         => Running the hall..
    {% assign blarg = 'STOP!' %}
    {{ 'Any Colour You Like' | truncate:10,blarg }}    => Any CSTOP!
    {{ 'Why are you running away?' | truncate:4,'?' }} => Why?
    {{ 'Ha' | truncate:4 }}                            => Ha
    {{ 'Ha' | truncate:1,'Laugh' }}                    => Laugh
    {{ 'Ha' | truncate:1,'...' }}                      => ...

...and...

    {{ 'This is a long line of text to test the default values for truncate' | truncate }}

...becomes...

    This is a long line of text to test the default...

=head2 C<truncatewords>

Truncate a string down to C<x> words.

    {{ 'This is a very quick test of truncating a number of words' | truncatewords:5,'...' }}
    {{ 'This is a very quick test of truncating a number of words where the limit is fifteen' | truncatewords: }}

...becomes...

    This is a very quick...
    This is a very quick test of truncating a number of words where the limit...

=head2 C<prepend>

Prepend a string.

    {{ 'bar' | prepend:'foo' }} => 'foobar'

=head2 C<append>

Append a string.

    {{ 'foo' | append:'bar' }} => 'foobar'

=head2 C<minus>

Simple subtraction.

    {{ 4       | minus:2 }}  => 2
    '{{ 'Test' | minus:2 }}' => ''

=head2 C<plus>

Simple addition or string contatenation.

    {{ 154    | plus:1183 }}  => 1337
    {{ 'What' | plus:'Uhu' }} => WhatUhu

=head3 MATHFAIL!

Please note that integer behavior differs with Perl vs. Ruby
so...

    {{ '1' | plus:'1' }}

...becomes C<11> in Ruby but C<2> in Perl.

=head2 C<times>

Simple multiplication or string repetion.

    {{ 'foo' | times:4 }} => foofoofoofoo
    {{ 5     | times:4 }} => 20

=head2 C<divided_by>

Simple division.

    {{ 10 | divided_by:2 }} => 5

=head2 C<modulo>

Simple modulo operation.

    {{ 10 | modulo:3 }} => 1

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2009-2012 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

=cut
