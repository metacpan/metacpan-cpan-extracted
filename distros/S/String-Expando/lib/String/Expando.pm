package String::Expando;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '0.04';

sub new {
    my $cls = shift;
    my $self = bless { @_ }, $cls;
    $self->init;
}

sub init {
    my ($self) = @_;
    if (defined $self->{'expando'}) {
        my $rx = qr/(?gc)\G$self->{'expando'}/;
        $self->{'consume_expando'} = sub {
            $_ =~ $rx ? (defined $2 ? $2 : $1) : ()
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
        my $rx = qr/(?gc)\G$self->{'literal'}/;
        $self->{'consume_literal'} = sub {
            $_ =~ $rx ? ($1) : ()
        }
    }
    else {
        $self->{'consume_literal'} ||= sub {
            m{ \G (.) }xgc ? ($1) : ()
        }
    }
    if (defined $self->{'escaped_literal'}) {
        my $rx = qr/(?gc)\G$self->{'escaped_literal'}/;
        $self->{'consume_escaped_literal'} = sub {
            $_ =~ $rx ? ($1) : ()
        }
    }
    else {
        $self->{'consume_escaped_literal'} ||= sub {
            m{ \G \\ (.) }xgc ? ($1) : ()
        }
    }
    $self->{'decoder'}   ||= \&decode;
    $self->{'stash'}     ||= {};
    $self->{'functions'} ||= {};
    return $self;
}

sub stash { @_ > 1 ? $_[0]->{'stash'} = $_[1] : $_[0]->{'stash'} }
sub functions { @_ > 1 ? $_[0]->{'functions'} = $_[1] : $_[0]->{'functions'} }

sub expand {
    my ($self, $str, $stash) = @_;
    $stash ||= $self->{'stash'};
    my $mat = $self->{'consume_expando'};
    my $lit = $self->{'consume_literal'};
    my $esc = $self->{'consume_escaped_literal'};
    my $dec = $self->{'decoder'};
    my $out = '';
    local $_ = $str;
    pos($_) = 0;
    while (pos($_) < length($_)) {
        my $res;
        if (my ($code, $fmt) = $mat->()) {
            $res = $dec->($self, $code, $stash);
            $res = '' if !defined $res;
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
    my $val = $stash->{$code};
    $val = &$val if ref($val) eq 'CODE';
    $val = join('', @$val) if ref($val) eq 'ARRAY';
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

=back

=cut

