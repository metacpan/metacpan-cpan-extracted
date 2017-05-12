package Perl6::Str;

# for documentation see end of file
# TODO: normalize, index, rindex, pack/unpack (?), quotemeta
# split, comb, sprintf 

use strict;
use warnings;
our $VERSION = '0.0.5';
use Encode qw(encode_utf8);
use Unicode::Normalize qw();

use overload 
    '""'    => \&Str,
    'cmp'   => \&compare,
    ;


sub new {
    my ($class, $str) = @_;
    $class = ref $class ? ref $class : $class;
    utf8::upgrade($str);
    return bless \$str, $class;
}

sub codes {
    return length(${$_[0]});
}

sub bytes {
    return length(encode_utf8(Unicode::Normalize::NFKC(${$_[0]})));
}

sub graphs {
    my $str = shift;
    return scalar(()= $$str =~ m/\X/g);
}

{
    no warnings 'once';
    *chars = \&graphs;
}

sub Str {
    return ${$_[0]};
}

sub compare {
    return $_[2] ? 
              Unicode::Normalize::NFKC($_[1]) cmp Unicode::Normalize::NFKC($_[0])
            : Unicode::Normalize::NFKC($_[0]) cmp Unicode::Normalize::NFKC($_[1]) ;
}

no warnings 'redefine';

sub substr {
    my ($self, @args) = @_;
    my $start = shift @args;
    my $graph_start = $self->_graph_index($start);
    my $res;
    if (@args == 0) {
        $res = CORE::substr $$self, $graph_start;
    } else {
        my $end = $self->_graph_index(shift @args, $graph_start);
        if (@args == 0) {
            $res = substr $$self, $graph_start, $end - $graph_start;
        } else {
            # replacement
            $res = substr $$self, $graph_start, $end - $graph_start, $args[0];
        }
    }
    if (defined $res) {
        return $self->new($res);
    } else {
        return;
    }
}

sub _graph_index {
    # turn a grapheme index into a codepoint index
    # $offest is optional, and ignored if $idx < 0
    my ($self, $idx, $offset) = @_;
    $offset ||= 0;
#    warn "Offset: $offset\n" if $offset;
    $idx = int (0 + $idx);
    my $old_pos = pos $$self;
    my $result;
    my $re;
    if ( $idx >= 0) {
        $idx += $offset;
        $re =  qr{\A\X{$idx}};
    } else {
        $idx = abs($idx);
        $re = qr{(?=\X{$idx}\z)} ;
    }
    if ($$self =~ m/$re/g) {
        $result = pos $$self;
    } else {
        warn "substr outside of string";
        $result = undef;
    }
    pos $$self = $old_pos;
    return $result;
}

sub chop {
    my $self = shift;
    my $copy = $$self;
    $copy =~ s/\X\z//;
    return $self->new($copy);
}

sub chomp {
    # XXX should we check for $/ or \n?
    my $self = shift;
    my $delim = $self->new($/);
    my $dl = $delim->graphs;
    my $sl = $self->graphs;
    return $self->new('') if $sl < $dl;

    if ($self->substr(-$sl) eq $delim){
        return $self->substr(0, $sl - $dl);
    } else {
        # return a copy
        return $self->new($self);
    }
}

sub reverse {
    my $self = shift;
    my $copy = '';
    my $self_pos = pos $self;
    pos $$self = 0;
    while ($$self =~ m/(\X)/g){
        $copy = $1 . $copy;
    }
    pos $$self = $self_pos;
    return $self->new($copy);
}

sub _same_stuff {
    my $func = shift;
    return sub {
        my ($self, $pattern) = @_;
        my $old_self_pos = pos $$self;
        my $old_pattern_pos = pos $pattern;
        return $self unless length $pattern;
        pos $$self = 0;
        pos $pattern = 0;
        my $copy = '';
        my $last_pattern;
        while ($pattern =~ m/(\X)/g){
            $last_pattern = $1;
            last unless $$self =~ m/(\X)/g;
            my $s = $1;
            $copy .= $func->($s, $last_pattern);
        }
        if (pos($$self)){
            # $$self longer than $pattern
            while ($$self =~ m/(\X)/g){
                $copy .= $func->($1, $last_pattern);
            }
        }
        pos $$self = $old_self_pos;
        pos $pattern = $old_pattern_pos;
        return $self->new($copy);
    }
}

BEGIN {

    *samecase   = _same_stuff(\&_copy_case);
    *sameaccent = _same_stuff(\&_copy_markings);

    for (qw(uc lc ucfirst lcfirst)) {
        eval qq{
            sub $_ {
                return \$_[0]->new(CORE::$_ \${\$_[0]});
            }
        };
    }

    for (qw(NFD NFC NFKD NFKC)) {
        eval qq{
            sub $_ {
                return \$_[0]->new(Unicode::Normalize::$_ \${\$_[0]});
            }
        };
    }
}

sub capitalize {
    my $self = shift;
    my $copy = CORE::lc $$self;
    $copy =~ s/(\w+)/CORE::ucfirst $1/eg;
    return $self->new($copy);
}

sub _copy_case {
    my ($chr, $pattern) = @_;
    if ($pattern =~ m/\p{IsTitle}|\p{IsUpper}/){
        return CORE::uc $chr;
    } elsif ($pattern =~ m/\p{IsLower}/){
        return CORE::lc $chr;
    } else {
        return $chr;
    }
}

sub _split_markings {
    my $char = Unicode::Normalize::NFKD(shift);
    return split m//, $char, 2;
}

sub _copy_markings {
    my ($source, $pattern) = @_;
    my (undef, $accents) = _split_markings($pattern);
    my ($base, undef)    = _split_markings($source);
    return $base . $accents;
}

1;

__END__

=head1 NAME

Perl6::Str - Grapheme level string implementation for Perl 5

=head1 SYNOPSIS

    use Perl6::Str;
    use charnames qw(:full);
    my $s = Perl6::Str->new("a\N{COMBINING ACUTE ACCENT}");
    my $other = "\N{LATIN SMALL LETTER A WITH ACUTE}";

    if ($s eq $other) {
        print "Equality compared at grapheme level\n";
    }

    # just one grapheme:
    printf "'%s' has %d logical characters\n", $s, $s->graphs;

    # prints the whole grapheme, not just the accent:
    print $s->substr(-1, 1); 
    print $s->uc;

    # adjust case of characters according to template:
    # prints 'AbcDE'
    print $s->new('abcdE')->samecase('Xy Z');

=head1 DESCRIPTION

Perl 5 offers string manipulation at the byte level (for non-upgraded strings)
and at the codepoint level (for decoded strings). However it fails to provide
string manipulation at the grapheme level, that is it has no easy way of
treating a sequence of codepoints, in which all but the first are combining
characters (like accents, for example) as one character.

C<Perl6::Str> tries to solve this problem by introducing a string object with
an API similar to that of Perl 6 (as far as possible), and emulating common
operations such as C<substr>, C<chomp> and C<chop> at the grapheme level.
It also introduces builtin string methods found in Perl 6 such as C<samecase>.

C<Perl6::Str> is written in pure Perl 5.

For a description of the Perl 6 C<Str> type, please see
L<http://doc.perl6.org/type/Str>.

=head1 CAVEATS

C<Perl6::Str> is implemented in terms of a blessed reference to the
underlying perl 5 string, and all operations are either overloaded operators
or method calls. That means that the objects lose all their magic once they
are interpolated into ordinary strings, and that all overloaded operations
come with a speed penalty.

Also note that it's another layer of abstraction, and as such suffers a speed
limit for all operations. If speed is important to you, benchmark this module
before you use it (and tell me your results please); if it's too slow, consider
writing a C based version of it.

=head1 METHODS

All methods that expect numbers as input (like C<substr>) count them as
graphemes, not as codepoints or bytes.

=over 2

=item new

C<Perl6::Str->new($p5_str)> takes a Perl 5 string, and returns a C<Perl6::Str>
object. You can also use C<new> as an object method, C<$p6s->new($other)>.
Note that the given perl 5 string should be a decoded text string.

=item graphs 

C<< $s->graphs >> returns the number of graphemes in C<$s>. If you think
C<length>, think C<graphs> instead.

=item codes

C<< $s->codes >> returns the number of codepoints in C<$s>.

=item bytes

C<< $s->bytes >> returns the number of bytes of the NFKC-normalized and
UTF-8 encoded C<$s>. This is subject to change.

=item chars

returns the number of characters in the currently chosen Unicode level.
At the moment only grapheme-level is implemented, it's currently an alias to
C<graphs>.

=item substr

=over 5

=item $s->substr(OFFSET)

=item $s->substr(OFFEST, LENGTH)

=item $s->substr(OFFSET, LENGHT, REPLACEMENT)

=back


does the same thing as the builtin C<substr> function

=back

=over 2

=item uc

=item lc

=item ucfirst

=item lcfirst

do the same things as the corresponding builtin functions.

=item capitalize

returns a lower case copy of the string with each first character in a word
as upper case.

=item samecase

C<< $s->samecase($pattern) >> returns a copy of C<$s> with the case
information as pattern, copied on a grapheme-by-grapheme base. If
C<$s> is longer than C<$pattern>, the case information from the last
grapheme of C<$pattern> is copied to the remaining characters of C<$s>.

Characters without case information (like spaces and digits) leave the string
unmodified.

=item chop 

C<< $s->chop >> returns a copy of C<$s> with the last grapheme removed

=item chomp

C<< $s->chomp >> returns a copy of C<$s>, with the contents of C<$/> stripped
from the end of C<$s>.

=item reverse

returns a reversed copy of the string.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008, 2011 by Moritz A. Lenz. This module is free software.
You may use, redistribute and modify it under the same terms as perl itself.

Example code included in this package may be used as if it were Public Domain.

=head1 AUTHOR

Moritz Lenz, moritz@faui2k3.org, L<http://perlgeek.de/>, L<http://perl-6.de/>

=head1 DEVELOPMENT

You can obtain the latest development version via git:

    git clone git://github.com/moritz/Perl6-Str.git

See also: L<https://github.com/moritz/Perl6-Str>.

=cut

