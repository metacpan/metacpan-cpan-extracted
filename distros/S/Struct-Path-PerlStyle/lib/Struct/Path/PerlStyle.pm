package Struct::Path::PerlStyle;

use 5.010;
use strict;
use warnings FATAL => 'all';
use parent 'Exporter';
use utf8;

use Carp 'croak';
use Safe;
use Text::Balanced qw(extract_bracketed extract_quotelike);
use re qw(is_regexp regexp_pattern);

require Struct::Path::PerlStyle::Functions;

our @EXPORT_OK = qw(
    path2str
    str2path
);

=encoding utf8

=head1 NAME

Struct::Path::PerlStyle - Perl-style syntax frontend for L<Struct::Path|Struct::Path>.

=begin html

<a href="https://travis-ci.org/mr-mixas/Struct-Path-PerlStyle.pm"><img src="https://travis-ci.org/mr-mixas/Struct-Path-PerlStyle.pm.svg?branch=master" alt="Travis CI"></a>
<a href='https://coveralls.io/github/mr-mixas/Struct-Path-PerlStyle.pm?branch=master'><img src='https://coveralls.io/repos/github/mr-mixas/Struct-Path-PerlStyle.pm/badge.svg?branch=master' alt='Coverage Status'/></a>
<a href="https://badge.fury.io/pl/Struct-Path-PerlStyle"><img src="https://badge.fury.io/pl/Struct-Path-PerlStyle.svg" alt="CPAN version"></a>

=end html

=head1 VERSION

Version 0.93

=cut

our $VERSION = '0.93';

=head1 SYNOPSIS

    use Struct::Path qw(path);
    use Struct::Path::PerlStyle qw(path2str str2path);

    my $nested = {
        a => {
            b => ["B0", "B1", "B2"],
            c => ["C0", "C1"],
            d => {},
        },
    };

    my @found = path($nested, str2path('{a}{}[0,2]'), deref => 1, paths => 1);

    while (@found) {
        my $path = shift @found;
        my $data = shift @found;

        print "path '" . path2str($path) . "' refer to '$data'\n";
    }

    # path '{a}{b}[0]' refer to 'B0'
    # path '{a}{b}[2]' refer to 'B2'
    # path '{a}{c}[0]' refer to 'C0'

=head1 EXPORT

Nothing is exported by default.

=head1 PATH SYNTAX

Path is a sequence of 'steps', each represents nested level in the structure.

=head2 Hashes

Like in perl hash keys should be specified using curly brackets

    {}                  # all values from a's subhash
    {foo}               # value for 'foo' key
    {foo,bar}           # slicing: 'foo' and 'bar' values
    {"space inside"}    # key must be quoted unless it is a simple word
    {"multi\nline"}     # special characters interpolated when double quoted
    {/pattern/mods}     # keys regexp match

=head2 Arrays

Square brackets used for array indexes specification

    []                  # all array items
    [9]                 # 9-th element
    [0,1,2,5]           # slicing: 0, 1, 2 and 5 array items
    [0..2,5]            # same, but using ranges
    [9..0]              # descending ranges allowed

=head2 Hooks

Expressions enclosed in parenthesis treated as hooks and evaluated using
L<Safe> compartment. Almost all perl operators and core functions available,
see L<Safe> for more info. Some path related functions provided by
L<Struct::Path::PerlStyle::Functions>.

    [](/pattern/mods)           # match array values by regular expression
    []{foo}(eq "bar" && BACK)   # select hashes which have pair 'foo' => 'bar'

There are two global variables available whithin safe compartment: C<$_> which
refers to value and C<%_> which provides current path via key C<path> (in
L<Struct::Path> notation) and structure levels refs stack via key C<refs>.

=head2 Aliases

String in angle brackets is an alias - shortcut mapped into sequence of
steps. Aliases resolved iteratively, so alias may also refer into path with
another aliases.

Aliases may be defined via global variable

    $Struct::Path::PerlStyle::ALIASES = {
        foo => '{some}{long}{path}',
        bar => '{and}{few}{steps}{more}'
    };

and then

    <foo><bar>      # expands to '{some}{long}{path}{and}{few}{steps}{more}'

or as option for C<str2path>:

    str2path('<foo>', {aliases => {foo => '{long}{path}'}});

=head1 SUBROUTINES

=cut

our $ALIASES;

my %ESCP = (
    '"'  => '\"',
    "\a" => '\a',
    "\b" => '\b',
    "\t" => '\t',
    "\n" => '\n',
    "\f" => '\f',
    "\r" => '\r',
    "\e" => '\e',
);
my $ESCP = join('', sort keys %ESCP);

my %INTP = map { $ESCP{$_} => $_ } keys %ESCP; # swap keys <-> values
my $INTP = join('|', map { "\Q$_\E" } sort keys %INTP);

# $_ will be substituted (if omitted) as first arg if placed on start of
# hook expression
my $COMPL_OPS = join('|', (
    '==',
    '!=',
    '=~',
    '!~',
    'eq',
    'ne',
    '<',
    '>',
    '<=',
    '>=',
    'lt',
    'gt',
    'le',
    'ge',
    '~~',
));

my $HASH_KEY_CHARS = qr/[\p{Alnum}_\.\-\+]/;

our $HOOK_STRICT = 1;

my $SAFE = Safe->new;
$SAFE->share_from(
    'Struct::Path::PerlStyle::Functions',
    \@Struct::Path::PerlStyle::Functions::EXPORT_OK
);
$SAFE->deny('warn');

my $QR_MAP = {
    ''   => sub { qr/$_[0]/ },
    i    => sub { qr/$_[0]/i },
    m    => sub { qr/$_[0]/m },
    s    => sub { qr/$_[0]/s },
    x    => sub { qr/$_[0]/x },
    im   => sub { qr/$_[0]/im },
    is   => sub { qr/$_[0]/is },
    ix   => sub { qr/$_[0]/ix },
    ms   => sub { qr/$_[0]/ms },
    mx   => sub { qr/$_[0]/mx },
    sx   => sub { qr/$_[0]/sx },
    ims  => sub { qr/$_[0]/ims },
    imx  => sub { qr/$_[0]/imx },
    isx  => sub { qr/$_[0]/isx },
    msx  => sub { qr/$_[0]/msx },
    imsx => sub { qr/$_[0]/imsx },
};

=head2 str2path

Convert perl-style string to L<Struct::Path|Struct::Path> path structure

    $struct = str2path($string);

=cut

sub _push_hash {
    my ($steps, $text) = @_;
    my ($body, $delim, $mods, %step, $token, $type);

    # extract_quotelike fails to parse bare zero as a string
    push @{$step{K}}, $text if $text eq '0';

    while ($text) {
        ($token, $text, $type, $delim, $body, $mods) =
            (extract_quotelike($text))[0,1,3,4,5,10];

        if (not defined $delim) { # bareword
            push @{$step{K}}, $token = $1
                if ($text =~ s/^\s*($HASH_KEY_CHARS+)//);
        } elsif (!$type and $delim eq '"') {
            $body =~ s/($INTP)/$INTP{$1}/gs; # interpolate
            push @{$step{K}}, $body;
        } elsif (!$type and $delim eq "'") {
            push @{$step{K}}, $body;
        } elsif ($delim eq '/' and !$type or $type eq 'm') {
            $mods = join('', sort(split('', $mods)));
            eval { push @{$step{K}}, $QR_MAP->{$mods}->($body) };
            if ($@) {
                (my $err = $@) =~ s/ at .+//s;
                croak "Step #" . scalar @{$steps} . " $err";
            }
        } else { # things like qr, qw and so on
            substr($text, 0, 0, $token);
            undef $token;
        }

        croak "Unsupported key '$text', step #" . @{$steps}
            if (!defined $token);

        $text =~ s/^\s+//; # discard trailing spaces

        if ($text ne '') {
            if ($text =~ s/^,//) {
                croak "Trailing delimiter at step #" . @{$steps}
                    if ($text eq '');
            } else {
                croak "Delimiter expected before '$text', step #" . @{$steps};
            }
        }
    }

    push @{$steps}, \%step;
}

sub _push_hook {
    my ($steps, $text) = @_;

    # substitute default value if omitted
    $text =~ s/^\s*($COMPL_OPS)/\$_ $1/;

    my $hook = 'sub {' .
        '$^W = 0; ' .
        'local %_ = ("path", $_[0], "refs", $_[1]); ' .
        'local $_ = (ref $_[1] eq "ARRAY" and @{$_[1]}) ? ${$_[1]->[-1]} : undef; ' .
        $text .
    '}';

    open (local *STDERR,'>', \(my $stderr)); # catch compilation errors

    unless ($hook = $SAFE->reval($hook, $HOOK_STRICT)) {
        if ($stderr) {
            $stderr =~ s/ at \(eval \d+\) .+//s;
            $stderr = " ($stderr)";
        } else {
            $stderr = "";
        }

        (my $err = $@) =~ s/ at \(eval \d+\) .+//s;
        croak "Failed to eval hook '$text': $err, step #" . @{$steps} . $stderr;
    }

    push @{$steps}, $hook;
}

sub _push_list {
    my ($steps, $text) = @_;
    my (@range, @step);

    for my $i (split /\s*,\s*/, $text, -1) {
        @range = grep {
            croak "Incorrect array index '$i', step #" . @{$steps}
                unless (eval { $_ == int($_) });
        } ($i =~ /^\s*(-?\d+)\s*\.\.\s*(-?\d+)\s*$/) ? ($1, $2) : $i;

        push @step, $range[0] < $range[-1]
            ? $range[0] .. $range[-1]
            : reverse $range[-1] .. $range[0];
    }

    push @{$steps}, \@step;
}

sub str2path($;$) {
    my ($path, $opts) = @_;

    croak "Undefined path passed" unless (defined $path);

    local $ALIASES = $opts->{aliases} if (exists $opts->{aliases});

    my (@steps, $step, $type);

    while ($path) {
        # separated match: to be able to have another brackets inside;
        # currently mostly for hooks, for example: '( $x > $y )'
        for ('{"}', '["]', '(")', '<">') {
            ($step, $path) = extract_bracketed($path, $_, '');
            last if ($step);
        }

        croak "Unsupported thing in the path, step #" . @steps . ": '$path'"
            unless ($step);

        $type = substr $step,  0, 1, ''; # remove leading bracket
                substr $step, -1, 1, ''; # remove trailing bracket

        if ($type eq '{') {
            _push_hash(\@steps, $step);
        } elsif ($type eq '[') {
            _push_list(\@steps, $step);
        } elsif ($type eq '(') {
            _push_hook(\@steps, $step);
        } else { # <>
            croak "Unknown alias '$step'" unless (exists $ALIASES->{$step});

            substr $path, 0, 0, $ALIASES->{$step};
            redo;
        }
    }

    return \@steps;
}

=head2 path2str

Convert L<Struct::Path|Struct::Path> path structure to perl-style string

    $string = path2str($struct);

=cut

sub path2str($) {
    my $path = shift;

    croak "Arrayref expected for path" unless (ref $path eq 'ARRAY');
    my $out = '';
    my $sc = 0; # step counter

    for my $step (@{$path}) {
        my @items;

        if (ref $step eq 'ARRAY') {
            for my $i (@{$step}) {
                croak "Incorrect array index '" . ($i // 'undef') . "', step #$sc"
                    unless (eval { int($i) == $i });
                if (@items and (
                    $items[-1][0] < $i and $items[-1][-1] == $i - 1 or   # ascending
                    $items[-1][0] > $i and $items[-1][-1] == $i + 1      # descending
                )) {
                    $items[-1][1] = $i; # update range
                } else {
                    push @items, [$i]; # new range
                }
            }

            for (@{items}) {
                $_ = abs($_->[0] - $_->[-1]) < 2
                    ? join(',', @{$_})
                    : "$_->[0]..$_->[-1]"
            }

            $out .= "[" . join(",", @{items}) . "]";
        } elsif (ref $step eq 'HASH') {
            my $keys;

            if (exists $step->{K}) {
                croak "Unsupported hash keys definition, step #$sc"
                    unless (ref $step->{K} eq 'ARRAY');
                croak "Unsupported hash definition (extra keys), step #$sc"
                    if (keys %{$step} > 1);
                $keys = $step->{K};
            } elsif (keys %{$step}) {
                croak "Unsupported hash definition (unknown keys), step #$sc";
            } else {
                $keys = [];
            }

            for my $k (@{$keys}) {
                if (is_regexp($k)) {
                    my ($patt, $mods) = regexp_pattern($k);
                    $mods =~ s/[dlu]//g; # for Perl's internal use (c) perlre
                    push @items, "/$patt/$mods";

                } elsif (defined $k and ref $k eq '') {
                    push @items, $k;

                    unless ($k =~ /^$HASH_KEY_CHARS+$/) {
                        $items[-1] =~ s/([\Q$ESCP\E])/$ESCP{$1}/gs;    # escape
                        $items[-1] = qq("$items[-1]");                 # quote
                    }
                } else {
                    croak "Unsupported hash key type '" .
                        (ref($k) || 'undef') . "', step #$sc"
                }
            }

            $out .= "{" . join(",", @items) . "}";
        } else {
            croak "Unsupported thing in the path, step #$sc";
        }
        $sc++;
    }

    return $out;
}

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-struct-path-perlstyle at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path-PerlStyle>. I
will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Struct::Path::PerlStyle

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Struct-Path-PerlStyle>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Struct-Path-PerlStyle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Struct-Path-PerlStyle>

=item * Search CPAN

L<http://search.cpan.org/dist/Struct-Path-PerlStyle/>

=back

=head1 SEE ALSO

L<Struct::Path>, L<Struct::Path::JsonPointer>, L<Struct::Diff>
L<perldsc>, L<perldata>, L<Safe>

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2019 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Struct::Path::PerlStyle
