package String::Expando;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '0.07';

sub new {
    my $cls = shift;
    my $self = bless { @_ }, $cls;
    $self->init;
}

sub init {
    my ($self) = @_;
    if (defined $self->{'expando'}) {
        my $rx = qr/\G$self->{'expando'}/;
        $self->{'consume_expando'} = sub {
            $_ =~ /$rx/gc ? (defined $2 ? $2 : $1) : ()
        }
    }
    else {
        $self->{'consume_expando'} ||= sub {
            m{ \G \% ([^%()]*) \( ([^\s()]+) \) }xgc
                ? ($2, $1)
                : ()
        };
    }
    if (defined $self->{'literal'}) {
        my $rx = qr/\G$self->{'literal'}/;
        $self->{'consume_literal'} = sub {
            $_ =~ /$rx/gc ? ($1) : ()
        }
    }
    else {
        $self->{'consume_literal'} ||= sub {
            m{ \G (.) }xgc ? ($1) : ()
        }
    }
    if (defined $self->{'escaped_literal'}) {
        my $rx = qr/\G$self->{'escaped_literal'}/;
        $self->{'consume_escaped_literal'} = sub {
            $_ =~ /$rx/gc ? ($1) : ()
        }
    }
    else {
        $self->{'consume_escaped_literal'} ||= sub {
            m{ \G \\ (.) }xgc ? ($1) : ()
        }
    }
    if (defined $self->{'dot_separator'}) {
        my $dot = $self->{'dot_separator'};
        my $rx;
        if (ref($dot) eq '') {
            $rx = qr/\Q$dot\E/;
        }
        elsif (ref($dot) eq 'Regexp') {
            $rx = $dot;
        }
        else {
            $rx = qr/$dot/;
        }
        my $part_decoder = $self->{'decoder'} || \&decode;
        $self->{'decoder'} ||= sub {
            my ($self, $code, $stash) = @_;
            my @parts = split $rx, $code;
            my $val = $stash;
            foreach my $part (@parts) {
                $val = $part_decoder->($self, $part, $val);
                last if !defined $val;
            }
            return $val;
        };
    }
    else {
        $self->{'decoder'} ||= \&decode;
    }
    $self->{'stringify'} ||= \&stringify;
    $self->{'stash'}     ||= {};
    $self->{'functions'} ||= {};
    $self->{'default_hash_keys'} ||= [q{}, q{""}, q{'}];
    return $self;
}

sub stash { @_ > 1 ? $_[0]->{'stash'} = $_[1] : $_[0]->{'stash'} }
sub functions { @_ > 1 ? $_[0]->{'functions'} = $_[1] : $_[0]->{'functions'} }
sub default_hash_keys { @_ > 1 ? $_[0]->{'default_hash_keys'} = $_[1] : $_[0]->{'default_hash_keys'} }

sub expand {
    my ($self, $str, $stash) = @_;
    $stash ||= $self->{'stash'};
    my $mat = $self->{'consume_expando'};
    my $lit = $self->{'consume_literal'};
    my $esc = $self->{'consume_escaped_literal'};
    my $dec = $self->{'decoder'};
    my $sfy = $self->{'stringify'};
    my $out = '';
    local $_ = $str;
    pos($_) = 0;
    while (pos($_) < length($_)) {
        my $res;
        if (my ($code, $fmt) = $mat->()) {
            my $val = $dec->($self, $code, $stash);
            $res = $sfy->($self, $val);
            $res = sprintf($fmt, $res) if defined $fmt && length $fmt;
        }
        elsif (!defined ($res = &$lit)
            && !defined ($res = &$esc)) {
            die "Unparseable: $_";
        }
        $out .= $res;
    }
    return $out;
}

sub decode {
    my ($self, $code, $stash) = @_;
    my $sr = ref $stash;
    return if $sr eq '';
    my $val;
    eval { $val = $stash->{$code}; 1 }
        or
    eval { $val = $stash->[$code]; 1 }
        or die "unable to decode $code given stash type $sr";
    return value($val);
}

sub value {
    my ($val) = @_;
    $val = $val->() if ref($val) eq 'CODE';
    return '' if !defined $val;
    return $val;
}

sub old_decode {
    my ($self, $code, $stash) = @_;
    # XXX Not quite working fancy-dancy decoding follows...
    my $val = $stash || $self->stash;
    my $func = $self->functions;
    my $rval = ref($val);
    $code =~ s/^\.?/./ if $rval eq 'HASH';
    $func ||= {};
    while ($code =~ s{
        ^
        (?:
            \[ (-?\d+) (?: \.\. (-?\d+) )? \]
            |
            \. ([^\s.:\[\]\(\)]+)
            |
            :: ([^\s.:\[\]\(\)]+)
        )
    }{}xg) {
        my ($l, $r, $k, $f) = ($1, $2, $3, $4);
        if (defined $f) {
            die "No such function: $f" if !$func->{$f} ;
            $val = $func->{$f}->($val);
        }
        elsif ($rval eq 'HASH') {
            die if defined $l or defined $r;
            $val = $val->{$k};
        }
        elsif ($rval eq 'ARRAY') {
            die if defined $k;
            $val = defined $r ? [ @$val[$l..$r] ] : $val->[$l];
        }
        else {
            die "Can't subval: ref = '$rval'";
        }
        $rval = ref $val;
    }
    die if length $code;
    return join('', @$val) if $rval eq 'ARRAY';
    return join('', values %$val) if $rval eq 'HASH';
    return $val;
}

sub stringify {
    # For backward compatibility, we allow $self-less calls...
    my $val = pop;
    my ($self) = @_;
    return '' if !defined $val;
    my $r = ref $val;
    return $val if $r eq '';
    # ...and we don't recurse if we don't have $self
    return '' if !$self;
    my $sfy = $self->{'stringify'};
    return join('', map { $sfy->($self, $_) } @$val)    if $r eq 'ARRAY';
    return join('', map { $sfy->($self, $_) } $val->()) if $r eq 'CODE';
    if ($r eq 'HASH') {
        foreach (@{ $self->default_hash_keys }) {
            return $sfy->($self, $val->{$_}) if defined $val->{$_};
        }
    }
    return '';
}

1;

=pod

=head1 NAME

String::Expando - expand %(foo) codes in strings

=head1 SYNOPSIS

    $e = String::Expando->new;
    print $e->expand('%(foo) %(bar)', { foo => 'Hello', bar => 'world!' }), "\n";
    print $e->expand(
        '### %04d(year)-%02d(month)-%02d(day)
        { year => 2011, month => 3, day => 9 }
    ), "\n";
    ### 2011-03-09

=head1 METHODS

=over 4

=item B<new>

    $e = String::Expando->new;
    $e = String::Expando->new(
        # "[% foo %]" -> $stash->{foo}
        'expando' => qr/\[%\s*([^%]+?)\s*%\]/,
        # "%%" -> "%"
        'escaped_literal' => qr/%(%)/,
        # etc.
        'literal' => qr/(.)/,
    );
    $e = String::Expando->new(
        # "%[.2f]L" => sprintf('%.2f', $stash->{L})
        'expando' => qr{
            (?x)
            %
                # Optional format string
                (?:
                    \[
                        ([^\]]+)
                    \]
                )?
                # Stash key
                ( [A-Za-z0-9] )
        },
        'stash' => { A => 1, B => 2, ... },
    );

Create a new expando object.  Arguments allowed are as follows.

=over 4

=item B<stash>

The hash from which expando values are obtained.  An expando C<%(xyz)> expanded
using stash C<$h> will yield the value of C<$h->{'xyz'}> (or the empty string,
if the value of C<$h->{'xyz'}> is undefined).

=item B<expando>

The regexp (or simple scalar) to use to identify expando codes when parsing the
input.  It must contain a capture group for what will become the key into the
stash.  If it contains two capture groups and $2 is defined (and not empty)
after matching, the value of $1 will be used with sprintf to produce the final
output.

The default is:

    qr/
        (?x)
        \%
        ([^%()]*j
        \(
            ([^\s()]+)
        \)
    /

In other words, C<%(...)> with an optional format string between C<%> and C<(>.

=back

=item B<stash>

    $h = $e->stash;
    $e->stash(\%hash);

Get or set the stash from which expando values will be obtained.

=item B<decoder>

A reference to a function with the signature C<($expando, $k, $stash)> that
is called to obtain a value from C<$stash> using code C<$k>.

The default is to call C<$expando->decode($code, $stash)>, which returns:

=over 4

=item *

The empty string if C<$stash> is scalar value.

=item *

=item *

C<$stash->{$code}> if C<$stash> is a hash reference and C<$stash->{$k}> is a scalar.

=item *

C<$stash->[$code]> if C<$stash> is an array
reference and C<$stash->[$k]> is a scalar; C<< $stash->{$code}->() >> if
C<$stash> is a hash reference and C<$stash->{$k}> is a code reference; or C<<
$stash->[$code]->() >> if C<$stash> is an array reference and C<$stash->[$k]>
is a code reference. 

=back

=item B<dot_separator> B<STRING|REGEXP>

A separator to use in expando codes in order to access values not at the top
level of the stash.  Decoding happens

For example, if B<dot_separator> is set to C<.> or C<qr/\./> then the expando
C<foo.bar.baz> expanded using stash C<$h> will yield the same value as the expando C<baz> expanded using stash C<$h->{foo}{bar}> (or the empty string, if said value is undefined).  This may or may not be the same value as C<$h->{foo}{bar}{baz}>, depending on the B<decoder>.

For example, if C<$h> is this:

    {
        'foo' => {
            'bar' => sub { return { 'baz' => 123 } },
        },
    }
    
Then C<foo.bar.baz> will expand to C<123>.

By default, no dot separator is defined.

=item B<consume_escaped_literal>
=item B<consume_expando>
=item B<consume_literal>
=item B<default_hash_keys>

When expanding, the result of the expansion

=item B<escaped_literal>
=item B<functions>
=item B<literal>
=item B<stash>
=item B<stringify>

A coderef that will be used to stringify an expanded value.  The code will be
called with two arguments: the String::Expando object and the datum to stringify:

    $stringify->($expando, $val);

=back

=cut

