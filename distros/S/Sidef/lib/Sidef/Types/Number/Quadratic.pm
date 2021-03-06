package Sidef::Types::Number::Quadratic {

    # Reference:
    #   https://en.wikipedia.org/wiki/Quadratic_integer

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Types::Number::Number
      );

    use overload
      q{bool} => sub { (@_) = ($_[0]); goto &__boolify__ },
      q{""}   => sub { (@_) = ($_[0]); goto &__stringify__ },
      q{0+}   => \&to_n,
      q{${}}  => \&to_n;

    sub new {
        my (undef, $x, $y, $w) = @_;

        $x //= Sidef::Types::Number::Number::ZERO;
        $y //= Sidef::Types::Number::Number::ZERO;
        $w //= Sidef::Types::Number::Number::ONE;

        $x = Sidef::Types::Number::Number->new($x) if !UNIVERSAL::isa($x, 'Sidef::Types::Number::Number');
        $y = Sidef::Types::Number::Number->new($y) if !UNIVERSAL::isa($y, 'Sidef::Types::Number::Number');
        $w = Sidef::Types::Number::Number->new($w) if !UNIVERSAL::isa($w, 'Sidef::Types::Number::Number');

        bless {a => $x, b => $y, w => $w};
    }

    *call = \&new;

    sub a {
        $_[0]->{a};
    }

    *real = \&a;

    sub b {
        $_[0]->{b};
    }

    *imag = \&b;

    sub w {
        $_[0]->{w};
    }

    *order = \&w;

    sub reals {
        ($_[0]->{a}, $_[0]->{b});
    }

    sub __boolify__ {
        $_[0]->{a};
    }

    sub __numify__ {
        $_[0]->{a};
    }

    sub __stringify__ {
        my ($x) = @_;
        '(' . join(', ', $x->{a}->dump, $x->{b}->dump, $x->{w}->dump) . ')';
    }

    sub to_s {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__stringify__);
    }

    sub dump {
        my ($x) = @_;
        Sidef::Types::String::String->new('Quadratic' . $x->__stringify__);
    }

    sub to_n {
        my ($x) = @_;
        $x->{a}->add($x->{b}->mul($x->{w}->sqrt));
    }

    *to_c = \&to_n;

    sub abs {
        my ($x) = @_;
        $x->norm->sqrt;
    }

    sub norm {
        my ($x) = @_;
        $x->{a}->sqr->sub($x->{b}->sqr->mul($x->{w}));
    }

    sub sgn {
        my ($x) = @_;
        $x->div($x->abs);
    }

    sub neg {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->neg, $x->{b}->neg, $x->{w});
    }

    sub conj {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}, $x->{b}->neg, $x->{w});
    }

    sub sqr {
        my ($x) = @_;
        $x->mul($x);
    }

    sub add {
        my ($x, $y) = @_;

        # (x + y√d) + (z + w√d) = (x + z) + (y + w)√d

        if (ref($y) eq __PACKAGE__) {
            return __PACKAGE__->new($x->{a}->add($y->{a}), $x->{b}->add($y->{b}), $x->{w});
        }

        __PACKAGE__->new($x->{a}->add($y), $x->{b}, $x->{w});
    }

    sub sub {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            return __PACKAGE__->new($x->{a}->sub($y->{a}), $x->{b}->sub($y->{b}), $x->{w});
        }

        __PACKAGE__->new($x->{a}->sub($y), $x->{b}, $x->{w});
    }

    sub mul {
        my ($x, $y) = @_;

        # (x + y√d) (z + w√d) = (xz+ ywd) + (xw + yz)√d

        if (ref($y) eq __PACKAGE__) {
            return __PACKAGE__->new(

                # Quadratic(a*a' + b*b'*w, a*b' + b*a', w)

                $x->{a}->mul($y->{a})->add($x->{b}->mul($y->{b})->mul($x->{w})),
                $x->{a}->mul($y->{b})->add($x->{b}->mul($y->{a})),
                $x->{w},
            );
        }

        __PACKAGE__->new($x->{a}->mul($y), $x->{b}->mul($y), $x->{w});
    }

    sub div {
        my ($x, $y) = @_;
        $x->mul($y->inv);
    }

    sub float {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->float, $x->{b}->float, $x->{w});
    }

    sub floor {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->floor, $x->{b}->floor, $x->{w});
    }

    sub ceil {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->ceil, $x->{b}->ceil, $x->{w});
    }

    sub round {
        my ($x, $r) = @_;
        __PACKAGE__->new($x->{a}->round($r), $x->{b}->round($r), $x->{w});
    }

    sub mod {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            return __PACKAGE__->new($x->{a}->mod($y), $x->{b}->mod($y), $x->{w});
        }

        # mod(a, b) = a - b * floor(a/b)
        $x->sub($y->mul($x->div($y)->floor));
    }

    sub inv {
        my ($x) = @_;

        # 1/(a + b*sqrt(w)) = (a - b*sqrt(w)) / (a^2 - b^2*w)
        #                   = a/(a^2 - b^2*w) - b/(a^2 - b^2*w) * sqrt(w)

        my $t = $x->{a}->sqr->sub($x->{b}->sqr->mul($x->{w}));

        __PACKAGE__->new($x->{a}->div($t), $x->{b}->div($t)->neg, $x->{w});
    }

    sub invmod {
        my ($x, $m) = @_;

        $x = $x->ratmod($m);
        my $t = $x->{a}->sqr->sub($x->{b}->sqr->mul($x->{w}))->invmod($m);

        __PACKAGE__->new($x->{a}->mul($t)->mod($m), $x->{b}->mul($t)->neg->mod($m), $x->{w});
    }

    sub is_zero {
        my ($x) = @_;
        my $bool = $x->{a}->is_zero;
        $bool || return $bool;
        $x->{b}->is_zero;
    }

    sub is_one {
        my ($x) = @_;
        my $bool = $x->{b}->is_zero;
        $bool || return $bool;
        $x->{a}->is_one;
    }

    sub is_mone {
        my ($x) = @_;
        my $bool = $x->{b}->is_zero;
        $bool || return $bool;
        $x->{a}->is_mone;
    }

    sub is_real {
        my ($x) = @_;
        $x->{b}->is_zero;
    }

    sub is_imag {
        my ($x) = @_;
        my $bool = $x->{b}->is_zero;
        $bool && return $bool->not;
        $x->{a}->is_zero;
    }

    sub is_coprime {
        my ($n, $k) = @_;
        _valid(\$k);
        $n->norm->gcd($k->norm)->is_one;
    }

    sub ratmod {
        my ($x, $m) = @_;
        __PACKAGE__->new($x->{a}->ratmod($m), $x->{b}->ratmod($m), $x->{w});
    }

    sub inc {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->inc, $x->{b}, $x->{w});
    }

    sub dec {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->dec, $x->{b}, $x->{w});
    }

    sub pow {
        my ($x, $n) = @_;

        my $negative_power = 0;

        if ($n->is_neg) {
            $n              = $n->abs;
            $negative_power = 1;
        }

        my ($X, $Y) = (Sidef::Types::Number::Number::ONE, Sidef::Types::Number::Number::ZERO);
        my ($A, $B, $w) = ($x->{a}, $x->{b}, $x->{w});

        foreach my $bit (reverse split(//, $n->as_bin)) {

            if ($bit) {
                ($X, $Y) = ($A->mul($X)->add($B->mul($Y)->mul($w)), $A->mul($Y)->add($B->mul($X)));
            }

            my $t = $A->mul($B);
            ($A, $B) = ($A->sqr->add($B->sqr->mul($w)), $t->add($t));
        }

        my $c = __PACKAGE__->new($X, $Y, $w);

        if ($negative_power) {
            $c = $c->inv;
        }

        return $c;
    }

    sub powmod {
        my ($x, $n, $m) = @_;

        $x = $x->ratmod($m);

        my $negative_power = 0;

        if ($n->is_neg) {
            $n              = $n->abs;
            $negative_power = 1;
        }

        my ($X, $Y) = (Sidef::Types::Number::Number::ONE, Sidef::Types::Number::Number::ZERO);
        my ($A, $B, $w) = ($x->{a}, $x->{b}, $x->{w});

        foreach my $bit (reverse split(//, $n->as_bin)) {

            if ($bit) {
                ($X, $Y) = ($A->mul($X)->add($B->mul($Y)->mul($w))->mod($m), $A->mul($Y)->add($B->mul($X))->mod($m));
            }

            my $t = $A->mul($B);
            ($A, $B) = ($A->sqr->add($B->sqr->mul($w))->mod($m), $t->add($t)->mod($m));
        }

        my $c = __PACKAGE__->new($X, $Y, $w);

        if ($negative_power) {
            $c = $c->invmod($m);
        }

        return $c;
    }

    sub cmp {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            my $cmp = $x->{a}->cmp($y->{a}) // return undef;
            $cmp && return $cmp;
            $cmp = $x->{b}->cmp($y->{b}) // return undef;
            $cmp && return $cmp;
            return $x->{w}->cmp($y->{w});
        }

        my $cmp = $x->{a}->cmp($y) // return undef;
        $cmp && return $cmp;
        $x->{b}->cmp(Sidef::Types::Number::Number::ZERO);
    }

    sub eq {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            my $bool = $x->{a}->eq($y->{a}) // return undef;
            $bool || return $bool;
            $bool = $x->{b}->eq($y->{b}) // return undef;
            $bool || return $bool;
            return $x->{w}->eq($y->{w});
        }

        my $bool = $x->{a}->eq($y) // return undef;
        $bool || return $bool;
        $x->{b}->is_zero;
    }

    sub ne {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            my $bool = $x->{a}->ne($y->{a});
            $bool && return $bool;
            $bool = $x->{b}->ne($y->{b});
            $bool && return $bool;
            return ($x->{w}->new($y->{w}));
        }

        my $bool = $x->{a}->ne($y);
        $bool && return $bool;
        $x->{b}->is_zero->not;
    }

    sub shift_left {    # x * 2^n
        my ($x, $n) = @_;
        $x->mul(Sidef::Types::Number::Number::TWO->pow($n));
    }

    *lsft = \&shift_left;

    sub shift_right {    # x / 2^n
        my ($x, $n) = @_;
        $x->div(Sidef::Types::Number::Number::TWO->pow($n));
    }

    *rsft = \&shift_right;

    {
        no strict 'refs';

        foreach my $method (qw(ge gt lt le)) {
            *{__PACKAGE__ . '::' . $method} = sub {
                my ($x, $y) = @_;
                ($x->cmp($y) // return undef)->$method(Sidef::Types::Number::Number::ZERO);
            };
        }

        foreach my $method (qw(and xor or)) {
            *{__PACKAGE__ . '::' . $method} = sub {
                my ($x, $y) = @_;

                if (ref($y) eq __PACKAGE__) {
                    return __PACKAGE__->new($x->{a}->$method($y->{a}), $x->{b}->$method($y->{b}), $x->{w});
                }

                return __PACKAGE__->new($x->{a}->$method($y), $x->{b}, $x->{w});
            };
        }

        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '÷'}   = \&div;
        *{__PACKAGE__ . '::' . '*'}   = \&mul;
        *{__PACKAGE__ . '::' . '%'}   = \&mod;
        *{__PACKAGE__ . '::' . '+'}   = \&add;
        *{__PACKAGE__ . '::' . '-'}   = \&sub;
        *{__PACKAGE__ . '::' . '**'}  = \&pow;
        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '--'}  = \&dec;
        *{__PACKAGE__ . '::' . '<'}   = \&lt;
        *{__PACKAGE__ . '::' . '>'}   = \&gt;
        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '<<'}  = \&lsft;
        *{__PACKAGE__ . '::' . '>>'}  = \&rsft;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '<='}  = \&le;
        *{__PACKAGE__ . '::' . '≤'}   = \&le;
        *{__PACKAGE__ . '::' . '>='}  = \&ge;
        *{__PACKAGE__ . '::' . '≥'}   = \&ge;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
    }
}

1
