package Solution::Condition;
{
    use strict;
    use warnings;
    our $VERSION = '0.9.1';
    use lib '../../lib';
    use Solution::Error;
    our @ISA = qw[Solution::Block];

    # Makes life easy
    use overload 'bool' => \&is_true, fallback => 1;

    sub new {
        my ($class, $args) = @_;
        raise Solution::ContextError {message => 'Missing template argument',
                                      fatal   => 1
            }
            if !defined $args->{'template'};
        raise Solution::ContextError {message => 'Missing parent argument',
                                      fatal   => 1
            }
            if !defined $args->{'parent'};
        my ($lval, $condition, $rval)
            = ((defined $args->{'attrs'} ? $args->{'attrs'} : '')
               =~ m[("[^"]+"|'[^']+'|(?:[\S]+))]g);
        if (defined $lval) {
            if (!defined $rval && !defined $condition) {
                return
                    bless {lvalue    => $lval,
                           condition => undef,
                           rvalue    => undef,
                           template  => $args->{'template'},
                           parent    => $args->{'parent'}
                    }, $class;
            }
            elsif ($condition =~ m[^(?:==|!=|<|>|contains|&&|\|\|)$]) {
                $condition = 'eq'   if $condition eq '==';
                $condition = 'ne'   if $condition eq '!=';
                $condition = 'gt'   if $condition eq '>';
                $condition = 'lt'   if $condition eq '<';
                $condition = '_and' if $condition eq '&&';
                $condition = '_or'  if $condition eq '||';
                return
                    bless {lvalue    => $lval,
                           condition => $condition,
                           rvalue    => $rval,
                           template  => $args->{'template'},
                           parent    => $args->{'parent'}
                    }, $class;
            }
            raise Solution::ContextError 'Unknown operator ' . $condition;
        }
        return Solution::ContextError->new(
                            'Bad conditional statement: ' . $args->{'attrs'});
    }
    sub ne { return !$_[0]->eq }    # hashes

    sub eq {
        my ($self) = @_;
        my $l = $self->resolve($self->{'lvalue'})
            || $self->{'lvalue'};
        my $r = $self->resolve($self->{'rvalue'})
            || $self->{'rvalue'};
        return _equal($l, $r);
    }

    sub _equal {    # XXX - Pray we don't have a recursive data structure...
        my ($l, $r) = @_;
        my $ref_l = ref $l;
        return !1 if $ref_l ne ref $r;
        if (!$ref_l) {
            return
                  !!(grep {defined} $l, $r)
                ? (grep {m[\D]} $l, $r)
                    ? $l eq $r
                    : $l == $r
                : !1;
        }
        elsif ($ref_l eq 'ARRAY') {
            return !1 unless scalar @$l == scalar @$r;
            for my $index (0 .. $#{$l}) {
                return !1 if !_equal($l->[$index], $r->[$index]);
            }
            return !!1;
        }
        elsif ($ref_l eq 'HASH') {
            my %temp = %$r;
            for my $key (keys %$l) {
                return 0
                    unless exists $temp{$key}
                        and defined($l->{$key}) eq defined($temp{$key})
                        and (defined $temp{$key}
                             ? _equal($temp{$key}, $l->{$key})
                             : !!1
                        );
                delete $temp{$key};
            }
            return !keys(%temp);
        }
    }

    sub gt {
        my ($self) = @_;
        my ($l, $r)
            = map { $self->resolve($_) || $_ }
            ($$self{'lvalue'}, $$self{'rvalue'});
        return
              !!(grep {defined} $l, $r)
            ? (grep {m[\D]} $l, $r)
                ? $l gt $r
                : $l > $r
            : 0;
    }
    sub lt { return !$_[0]->gt }

    sub contains {
        my ($self) = @_;
        my $l      = $self->resolve($self->{'lvalue'});
        my $r      = quotemeta $self->resolve($self->{'rvalue'});
        return if defined $r && !defined $l;
        return defined($l->{$r}) ? 1 : !1 if ref $l eq 'HASH';
        return (grep { $_ eq $r } @$l) ? 1 : !1 if ref $l eq 'ARRAY';
        return $l =~ qr[${r}] ? 1 : !1;
    }

    sub _and {
        my ($self) = @_;
        my $l = $self->resolve($self->{'lvalue'})
            || $self->{'lvalue'};
        my $r = $self->resolve($self->{'rvalue'})
            || $self->{'rvalue'};
        return (($l && $r) ? 1 : 0);
    }

    sub _or {
        my ($self) = @_;
        my $l = $self->resolve($self->{'lvalue'})
            || $self->{'lvalue'};
        my $r = $self->resolve($self->{'rvalue'})
            || $self->{'rvalue'};
        return (($l || $r) ? 1 : 0);
    }
    {    # Compound inequalities support

        sub and {
            my ($self) = @_;
            my $l      = $self->{'lvalue'};
            my $r      = $self->{'rvalue'};
            return (($l && $r) ? 1 : 0);
        }

        sub or {
            my ($self) = @_;
            my $l      = $self->{'lvalue'};
            my $r      = $self->{'rvalue'};
            return (($l || $r) ? 1 : 0);
        }
    }

    sub is_true {
        my ($self) = @_;
        if (!defined $self->{'condition'} && !defined $self->{'rvalue'}) {
            return !!($self->resolve($self->{'lvalue'}) ? 1 : 0);
        }
        my $condition = $self->can($self->{'condition'});
        raise Solution::ContextError {
                           message => 'Bad condition ' . $self->{'condition'},
                           fatal   => 1
            }
            if !$condition;

        #return !1 if !$condition;
        return $self->$condition();
    }
}
1;

=pod


=head1 Supported Inequalities

=head2 C<==> / C<eq>

=head2 C<!=> / C<ne>

=head2 C<< > >> / C<< < >>

=head2 C<contains>

=head3 Strings

matches qr[${string}] # case matters

=head3 Lists

grep list

=head3 Hashes

if key exists



=head1 Known Bugs



=cut
