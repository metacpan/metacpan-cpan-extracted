package TPath::AttributeTest;
$TPath::AttributeTest::VERSION = '1.007';
# ABSTRACT: compares an attribute value to another value


use v5.10;
no if $] >= 5.018, warnings => "experimental";

use Scalar::Util qw(refaddr looks_like_number);
use MooseX::SingletonMethod;
use TPath::TypeConstraints;
use overload;
use namespace::autoclean;


with 'TPath::Stringifiable';


has op => ( is => 'ro', isa => 'Str', required => 1 );


has left => ( is => 'ro', isa => 'ATArg', required => 1 );


has right => ( is => 'ro', isa => 'ATArg', required => 1 );

sub BUILD {
    my $self = shift;
    my ( $l, $r ) = $self->_types;
    my $func;

    # some coderefs to turn operators into functions
    state $ge_n = sub { $_[0] >= $_[1]           or undef };
    state $ge_s = sub { ( $_[0] cmp $_[1] ) >= 0 or undef };
    state $le_n = sub { $_[0] <= $_[1]           or undef };
    state $le_s = sub { ( $_[0] cmp $_[1] ) <= 0 or undef };
    state $g_n  = sub { $_[0] > $_[1]            or undef };
    state $g_s  = sub { ( $_[0] cmp $_[1] ) > 0  or undef };
    state $l_n  = sub { $_[0] < $_[1]            or undef };
    state $l_s  = sub { ( $_[0] cmp $_[1] ) < 0  or undef };
    state $ne_n = sub { $_[0] != $_[1]           or undef };
    state $ne_s = sub { $_[0] ne $_[1]           or undef };

    # construct the appropriate function
    for ( $self->op ) {
        when ('=')  { $func = $self->_e_func( $l, $r, \&_se ) }
        when ('==') { $func = $self->_e_func( $l, $r, \&_de ) }
        when ('<=') { $func = $self->_c_func( $l, $r, $le_s, $le_n ) }
        when ('<')  { $func = $self->_c_func( $l, $r, $l_s,  $l_n ) }
        when ('>=') { $func = $self->_c_func( $l, $r, $ge_s, $ge_n ) }
        when ('>')  { $func = $self->_c_func( $l, $r, $g_s,  $g_n ) }
        when ('!=') { $func = $self->_c_func( $l, $r, $ne_s, $ne_n ) }
        when ('=~') { $func = $self->_m_func( $r, 1 ) }
        when ('!~') { $func = $self->_m_func( $r, 0 ) }
        when ('|=')  { $func = $self->_i_func( $l, $r, 0 ) }
        when ('=|=') { $func = $self->_i_func( $l, $r, 1 ) }
        when ('=|')  { $func = $self->_i_func( $l, $r, 2 ) }
    }

    # store it
    $self->add_singleton_method( test => $func );
}

# a bunch of private methods that construct custom test methods based on string indices
sub _i_func {

    # type of right value; whether the match is positive (=~)
    my ( $self, $l_type, $r_type, $i_type ) = @_;
    if ( $r_type =~ /n|s/ ) {
        my $v      = $self->right;
        my $s_func = _s_func( $self->left );
        for ($i_type) {
            when (0) {
                my $l = length $v;
                return sub {
                    my ( $self, $ctx ) = @_;
                    my $lv = $self->$s_func($ctx);
                    return undef unless length $lv >= $l;
                    $lv = substr $lv, 0, $l;
                    return $lv eq $v ? 1 : undef;
                };
            }
            when (1) {
                return sub {
                    my ( $self, $ctx ) = @_;
                    my $lv = $self->$s_func($ctx);
                    return undef unless defined $lv;
                    my $index = index $lv, $v;
                    return $index > -1 ? 1 : undef;
                };
            }
            when (2) {
                my $l = length $v;
                return sub {
                    my ( $self, $ctx ) = @_;
                    my $lv = $self->$s_func($ctx);
                    return undef unless defined $lv;
                    return undef unless length $lv >= $l;
                    $lv = substr $lv, -$l;
                    return $lv eq $v ? 1 : undef;
                };
            }
        }
    }
    elsif ( $l_type =~ /n|s/ ) {
        my $v      = $self->left;
        my $s_func = _s_func( $self->right );
        for ($i_type) {
            when (0) {
                return sub {
                    my ( $self, $ctx ) = @_;
                    my $rv = $self->$s_func($ctx);
                    my $index = index $v, $rv;
                    return $index == 0 ? 1 : undef;
                };
            }
            when (1) {
                return sub {
                    my ( $self, $ctx ) = @_;
                    my $rv = $self->$s_func($ctx);
                    my $index = index $v, $rv;
                    return $index > -1 ? 1 : undef;
                };
            }
            when (2) {
                my $ll = length $v;
                return sub {
                    my ( $self, $ctx ) = @_;
                    my $rv = $self->$s_func($ctx);
                    my $index = index $v, $rv;
                    return $index > -1
                      && $index == $ll - length($rv) ? 1 : undef;
                };
            }
        }
    }
    else {
        my $ls_func = _s_func( $self->left );
        my $rs_func = _s_func( $self->right );
        for ($i_type) {
            when (0) {
                return sub {
                    my ( $self, $ctx ) = @_;
                    my $lv    = $self->$ls_func($ctx);
                    my $rv    = $self->$rs_func($ctx);
                    my $index = index $lv, $rv;
                    return $index == 0 ? 1 : undef;
                };
            }
            when (1) {
                return sub {
                    my ( $self, $ctx ) = @_;
                    my $lv    = $self->$ls_func($ctx);
                    my $rv    = $self->$rs_func($ctx);
                    my $index = index $lv, $rv;
                    return $index > -1 ? 1 : undef;
                };
            }
            when (2) {
                return sub {
                    my ( $self, $ctx ) = @_;
                    my $lv    = $self->$ls_func($ctx);
                    my $rv    = $self->$rs_func($ctx);
                    my $index = index $lv, $rv;
                    return $index > -1
                      && $index == length($lv) - length($rv) ? 1 : undef;
                };
            }
        }
    }
}

# a bunch of private methods that construct custom test methods
sub _m_func {

    # type of right value; whether the match is positive (=~)
    my ( $self, $r_type, $positive ) = @_;
    for ($r_type) {
        when (/n|s/) {
            my $v      = $self->right;
            my $re     = qr/$v/;
            my $s_func = _s_func( $self->left );
            return $positive
              ? sub {
                my ( $self, $ctx ) = @_;
                my $lv = $self->$s_func($ctx);
                $lv =~ $re ? 1 : undef;
              }
              : sub {
                my ( $self, $ctx ) = @_;
                my $lv = $self->$s_func($ctx);
                $lv =~ $re ? undef : 1;
              };
        }
        default {
            my $ls_func = _s_func( $self->left );
            my $rs_func = _s_func( $self->right );
            return $positive
              ? sub {
                my ( $self, $ctx ) = @_;
                my $lv = $self->$ls_func($ctx);
                my $rv = $self->$rs_func($ctx);
                ( $lv // '' ) =~ /$rv/ ? 1 : undef;
              }
              : sub {
                my ( $self, $ctx ) = @_;
                my $lv = $self->$ls_func($ctx);
                my $rv = $self->$rs_func($ctx);
                $lv =~ /$rv/ ? undef : 1;
              };
        }
    }
}

# generates a stringification function for a value
sub _s_func {
    my $v = shift;
    for ( _type($v) ) {
        when ('a') {
            return sub {
                my ( undef, $ctx ) = @_;
                $v->apply($ctx);
            };
        }
        when ('c') {
            return sub {
                my ( undef, $ctx ) = @_;
                $v->concatenate($ctx);
            };
        }
        when ('e') {
            return sub {
                my ( undef, $ctx ) = @_;
                my $c = $v->_select( $ctx, 1 );
                join '', map { $_->n } @$c;
            };
        }
        when ('t') {
            return sub {
                my ( undef, $ctx ) = @_;
                $v->test($ctx);
            };
        }
        when ('f') {
            return sub {
                my ( undef, $ctx ) = @_;
                $v->to_num($ctx);
            };
        }
        when (/[ns]/) {
            return sub { $v };
        }
    }
}

# generate = test
sub _e_func {

    # left type, right type, the equality function
    my ( $self, $l, $r, $ef ) = @_;

    my $lv = $self->left;
    my $rv = $self->right;

    # non-silly functions
    for ($l) {
        when ('n') {
            for ($r) {
                when ('a') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v = $rv->apply($ctx);
                        return $ef->( $lv, $v );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v = $rv->test($ctx);
                        return $ef->( $lv, $v );
                      }
                }
                when ('e') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c = [ map { $_->n } @{ $rv->_select( $ctx, 1 ) } ];
                        return $ef->( $lv, $c );
                      }
                }
                when ('f') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        return $ef->( $lv, $rv->to_num($ctx) );
                      }
                }
                when ('c') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v = $rv->concatenate($ctx);
                        return $ef->( $lv, $v );
                    };
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('s') {
            for ($r) {
                when ('a') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v = $rv->apply($ctx);
                        return $ef->( $lv, $v );
                    };
                }
                when ('c') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v = $rv->concatenate($ctx);
                        return $ef->( $lv, $v );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v = $rv->test($ctx);
                        return $ef->( $lv, $v );
                      }
                }
                when ('e') {
                    my ( undef, $ctx ) = @_;
                    my $c = $rv->_select( $ctx, 1 );
                    return $ef->( $lv, [ map { $_->n } @$c ] );
                }
                when ('f') {
                    my ( undef, $ctx ) = @_;
                    return $ef->( $lv, $rv->to_num($ctx) );
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('a') {
            for ($r) {
                when (/[ns]/) {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v = $lv->apply($ctx);
                        return $ef->( $rv, $v );
                    };
                }
                when ('a') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->apply($ctx);
                        my $v2 = $rv->apply($ctx);
                        return $ef->( $v1, $v2 );
                    };
                }
                when ('c') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->apply($ctx);
                        my $v2 = $rv->concatenate($ctx);
                        return $ef->( $v1, $v2 );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->apply($ctx);
                        my $v2 = $rv->test($ctx);
                        return $ef->( $v1, $v2 );
                      }
                }
                when ('e') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->apply($ctx);
                        my $c  = $rv->_select($ctx);
                        return $ef->( $v1, $c );
                    };
                }
                when ('f') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->apply($ctx);
                        my $n  = $rv->to_num($ctx);
                        return $ef->( $v1, $n );
                    };
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('t') {
            for ($r) {
                when ('n') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->test($ctx);
                        return $ef->( $v1, $rv );
                    };
                }
                when ('s') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->test($ctx);
                        return $ef->( $v1, $rv );
                    };
                }
                when ('a') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->test($ctx);
                        my $v2 = $rv->apply($ctx);
                        return $ef->( $v1, $v2 );
                    };
                }
                when ('c') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->test($ctx);
                        my $v2 = $rv->concatenate($ctx);
                        return $ef->( $v1, $v2 );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->test($ctx);
                        my $v2 = $rv->test($ctx);
                        return $ef->( $v1, $v2 );
                      }
                }
                when ('e') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->test($ctx);
                        my $c = [ map { $_->n } @{ $lv->_select( $ctx, 1 ) } ];
                        return $ef->( $v1, $c );
                      }
                }
                when ('f') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->test($ctx);
                        my $n  = $lv->to_num($ctx);
                        return $ef->( $v1, $n );
                      }
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('e') {
            for ($r) {
                when ('n') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c = [ map { $_->n } @{ $lv->_select( $ctx, 1 ) } ];
                        return $ef->( $c, $rv );
                    };
                }
                when ('s') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c = [ map { $_->n } @{ $lv->_select( $ctx, 1 ) } ];
                        return $ef->( $rv, $c );
                    };
                }
                when ('a') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c = [ map { $_->n } @{ $lv->_select( $ctx, 1 ) } ];
                        my $v2 = $rv->apply($ctx);
                        return $ef->( $c, $v2 );
                    };
                }
                when ('c') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c = [ map { $_->n } @{ $lv->_select( $ctx, 1 ) } ];
                        my $v2 = $rv->concatenate($ctx);
                        return $ef->( $c, $v2 );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c = [ map { $_->n } @{ $lv->_select( $ctx, 1 ) } ];
                        my $v2 = $rv->test($ctx);
                        return $ef->( $c, $v2 );
                      }
                }
                when ('e') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c1 = [ map { $_->n } @{ $lv->_select( $ctx, 1 ) } ];
                        my $c2 = [ map { $_->n } @{ $rv->_select( $ctx, 1 ) } ];
                        return $ef->( $c1, $c2 );
                      }
                }
                when ('f') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c = [ map { $_->n } @{ $lv->_select( $ctx, 1 ) } ];
                        my $n = $rv->to_num($ctx);
                        return $ef->( $c, $n );
                      }
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('f') {
            for ($r) {
                when (/[ns]/) {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        return $ef->( $lv->to_num($ctx), $rv );
                    };
                }
                when ('a') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $n  = $lv->to_num($ctx);
                        my $v2 = $rv->apply($ctx);
                        return $ef->( $n, $v2 );
                    };
                }
                when ('c') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $n  = $lv->to_num($ctx);
                        my $v2 = $rv->concatenate($ctx);
                        return $ef->( $n, $v2 );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $n  = $lv->to_num($ctx);
                        my $v2 = $rv->test($ctx);
                        return $ef->( $n, $v2 );
                      }
                }
                when ('e') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $n = $lv->to_num($ctx);
                        my $c = [ map { $_->n } @{ $rv->_select($ctx) } ];
                        return $ef->( $n, $c );
                    };
                }
                when ('f') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $n1 = $lv->to_num($ctx);
                        my $n2 = $rv->to_num($ctx);
                        return $ef->( $n1, $n2 );
                    };
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        default { confess "fatal logic error! unexpected argument type $l" }
    }
}

sub _c_func {

# left type, right type, the string comparison function, the number comparison function
    my ( $self, $l, $r, $sf, $nf ) = @_;

    my $lv = $self->left;
    my $rv = $self->right;

    for ($l) {
        when ('n') {
            for ($r) {
                when ('a') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v = $rv->apply($ctx);
                        return unless defined $v;
                        if ( my $type = ref $v ) {
                            for ($type) {
                                when ('ARRAY') {
                                    return $nf->( $rv, scalar @$v );
                                }
                                default { return }
                            }
                        }
                        $nf->( $lv, $v );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v = $rv->test($ctx);
                        $nf->( $lv, $v );
                      }
                }
                when ('e') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c = $rv->_select( $ctx, 1 );
                        $nf->( $lv, scalar @$c );
                      }
                }
                when ('f') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $n = $rv->to_num($ctx);
                        $nf->( $lv, $n );
                      }
                }
                when ('c') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $n = $rv->concatenate($ctx);
                        $nf->( $lv, $n );
                      }
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('s') {
            for ($r) {
                when ('a') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v = $rv->apply($ctx);
                        return unless defined $v;
                        return $sf->( $lv, $v );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v = $rv->test($ctx);
                        $sf->( $lv, $v );
                      }
                }
                when ('e') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c = $rv->_select( $ctx, 1 );
                        $sf->( $lv, join '', map { $_->n } @$c );
                    };
                }
                when ('f') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $n = $rv->to_num($ctx);
                        $sf->( $lv, $n );
                    };
                }
                when ('c') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $n = $rv->concatenate($ctx);
                        $sf->( $lv, $n );
                    };
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('a') {
            for ($r) {
                when ('n') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v = $lv->apply($ctx);
                        return unless defined $v;
                        if ( my $type = ref $v ) {
                            for ($type) {
                                when ('ARRAY') {
                                    return $nf->( scalar @$v, $rv );
                                }
                                default { return }
                            }
                        }
                        $nf->( $v, $rv );
                    };
                }
                when ('s') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v = $lv->apply($ctx);
                        return unless defined $v;
                        return $sf->( $v, $rv );
                    };
                }
                when ('c') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->apply($ctx);
                        my $v2 = $rv->concatenate($ctx);
                        return $sf->( $v1, $v2 );
                    };
                }
                when ('a') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->apply($ctx);
                        my $v2 = $rv->apply($ctx);
                        return _reduce( $v1, $v2, $sf, $nf, $ctx );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->apply($ctx);
                        my $v2 = $rv->test($ctx);
                        return _reduce( $v1, $v2, $sf, $nf, $ctx );
                    };
                }
                when ('e') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->apply($ctx);
                        my $c = $rv->_select( $ctx, 1 );
                        return _reduce( $v1, [ map { $_->n } @$c ], $sf, $nf,
                            $ctx );
                    };
                }
                when ('f') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->apply($ctx);
                        my $n  = $rv->to_num($ctx);
                        return _reduce( $v1, $n, $sf, $nf, $ctx );
                    };
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('t') {
            for ($r) {
                when ('n') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->test($ctx);
                        return $nf->( $v1, $rv );
                    };
                }
                when ('s') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->test($ctx);
                        return $sf->( $v1, $rv );
                    };
                }
                when ('c') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->test($ctx);
                        my $v2 = $rv->concatenate($ctx);
                        return $sf->( $v1, $v2 );
                    };
                }
                when ('a') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->test($ctx);
                        my $v2 = $rv->apply($ctx);
                        return _reduce( $v1, $v2, $sf, $nf, $ctx );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->test($ctx);
                        my $v2 = $rv->test($ctx);
                        return $nf->( $v1, $v2 );
                      }
                }
                when ('e') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->test($ctx);
                        my $c = $rv->_select( $ctx, 1 );
                        return $nf->( $v1, scalar @$c );
                    };
                }
                when ('f') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $v1 = $lv->test($ctx);
                        my $n  = $rv->to_num($ctx);
                        return $nf->( $v1, $n );
                    };
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('e') {
            for ($r) {
                when ('n') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c = $lv->_select( $ctx, 1 );
                        return $nf->( scalar @$c, $rv );
                    };
                }
                when ('s') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c = $lv->_select( $ctx, 1 );
                        return $sf->( join( '', @$c ), $rv );
                    };
                }
                when ('c') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c = $lv->_select( $ctx, 1 );
                        my $v2 = $rv->concatenate($ctx);
                        return $sf->( join( '', @$c ), $v2 );
                    };
                }
                when ('a') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c = $lv->_select( $ctx, 1 );
                        my $v2 = $rv->apply($ctx);
                        return _reduce( [ map { $_->n } @$c ], $v2, $sf, $nf,
                            $ctx );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c = $lv->_select( $ctx, 1 );
                        my $v2 = $rv->test($ctx);
                        return $nf->( scalar @$c, $v2 );
                      }
                }
                when ('e') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c1 = $lv->_select( $ctx, 1 );
                        my $c2 = $rv->_select( $ctx, 1 );
                        return $nf->( scalar @$c1, scalar @$c2 );
                    };
                }
                when ('f') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $c = $lv->_select( $ctx, 1 );
                        my $n = $rv->to_num($ctx);
                        return $nf->( scalar @$c, $n );
                    };
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        when ('f') {
            for ($r) {
                when ('n') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $n = $lv->to_num($ctx);
                        return $nf->( $n, $rv );
                    };
                }
                when ('s') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $n = $lv->to_num($ctx);
                        return $nf->( $n, $rv );
                    };
                }
                when ('c') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $n = $lv->to_num($ctx);
                        my $v2 = $rv->concatenate($ctx);
                        return $nf->( $n, $v2 );
                    };
                }
                when ('a') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $n  = $lv->to_num($ctx);
                        my $v2 = $rv->apply($ctx);
                        return _reduce( $n, $v2, $sf, $nf, $ctx );
                    };
                }
                when ('t') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $n  = $lv->to_num($ctx);
                        my $v2 = $rv->test($ctx);
                        return $nf->( $n, $v2 );
                      }
                }
                when ('e') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $n = $lv->to_num($ctx);
                        my $c = $rv->_select( $ctx, 1 );
                        return $nf->( $n, scalar @$c );
                    };
                }
                when ('f') {
                    return sub {
                        my ( undef, $ctx ) = @_;
                        my $n1 = $lv->to_num($ctx);
                        my $n2 = $rv->to_num($ctx);
                        return $nf->( $n1, $n2 );
                    };
                }
                default {
                    confess "fatal logic error! unexpected argument type $r"
                }
            }
        }
        default { confess "fatal logic error! unexpected argument type $l" }
    }
}

sub _reduce {
    my ( $v1, $v2, $sf, $nf, $ctx ) = @_;
    my ( $l, $r ) = map { _type($_) } $v1, $v2;
    for ("$l$r") {
        when ('nn') { return $nf->( $v1, $v2 ) }
        when (/[sn]{2}/) { return $sf->( $v1, $v2 ) }
        when ('nh') { return $nf->( $v1,              scalar keys %$v2 ) }
        when ('hn') { return $nf->( scalar keys %$v1, $v2 ) }
        when ('nr') { return $nf->( $v1,              scalar @$v2 ) }
        when ('rn') { return $nf->( scalar @$v1,      $v2 ) }
        when ('sr') { return $sf->( $v1, join '', @$v2 ) }
        when ('rs') { return $sf->( join( '', @$v1 ), $v2 ) }
        when (/[etafc].|.[etafc]/) {
            my ( $v3, $v4 ) = ( $v1, $v2 );
            for ($l) {
                when ('e') {
                    $v3 = [ map { $_->n } @{ $v1->_select( $ctx, 1 ) } ];
                }
                when ('t') { $v3 = $v1->test($ctx) }
                when ('a') { $v3 = $v1->apply($ctx) }
                when ('f') { $v3 = $v1->to_num($ctx) }
                when ('c') { $v3 = $v1->concatenate($ctx) }
            }
            for ($r) {
                when ('e') {
                    $v4 = [ map { $_->n } @{ $v2->_select( $ctx, 1 ) } ];
                }
                when ('t') { $v4 = $v2->test($ctx) }
                when ('a') { $v4 = $v2->apply($ctx) }
                when ('f') { $v4 = $v2->to_num($ctx) }
                when ('c') { $v4 = $v2->concatenate($ctx) }
            }
            return _reduce( $v3, $v4, $sf, $nf, $ctx );
        }
        default { return $sf->( $v1, $v2 ) }
    }
}

# single equals
sub _se {
    my ( $v1, $v2 ) = @_;

    return undef if defined $v1 ^ defined $v2;
    return 1 unless defined $v1;
    my ( $l, $r ) = map { _type($_) } $v1, $v2;
    my $lr = "$l$r";
    for ($lr) {
        when (/so|os|ss/) { return $v1 eq $v2  ? 1 : undef }
        when ('nn')       { return $v1 == $v2  ? 1 : undef }
        when ('nr')       { return $v1 == @$v2 ? 1 : undef }
        when ('rn')       { return @$v1 == $v2 ? 1 : undef }
        when ('sr') { return $v1 eq join( '', @$v2 ) ? 1 : undef }
        when ('rs') { return join( '', @$v1 ) eq $v2 ? 1 : undef }
        when ('rr') {
            my @a1 = @$v1;
            my @a2 = @$v2;
            return undef unless @a1 == @a2;
            for my $i ( 0 .. $#a1 ) {
                return undef unless _se( $a1[$i], $a2[$i] );
            }
            return 1;
        }
        when ('hh') {
            my @keys = keys %$v1;
            return undef unless @keys == ( keys %$v2 );
            for my $k (@keys) {
                my ( $o1, $o2 ) = ( $v1->{$k}, $v2->{$k} );
                return undef unless _se( $o1, $o2 );
            }
            return 1;
        }
        when ('oo') {
            my $f = $v1->can('equals') || overload::Method( $v1, '==' );
            return $v1->$f($v2) ? 1 : undef if $f;
            $f = $v2->can('equals') || overload::Method( $v2, '==' );
            return $v2->$f($v1) ? 1 : undef if $f;
            return refaddr $v1 == refaddr $v2 ? 1 : undef;
        }
        when (/o./) {
            my $f = $v1->can('equals') || overload::Method( $v1, '==' );
            return $v1->$f->($v2) ? 1 : undef if $f;
            return undef;
        }
        when (/.o/) {
            my $f = $v2->can('equals') || overload::Method( $v2, '==' );
            return $v2->$f($v1) ? 1 : undef if $f;
            return undef;
        }
        default { return undef }
    }
}

# double equals
sub _de {
    my ( $v1, $v2 ) = @_;
    return if defined $v1 ^ defined $v2;
    return 1 unless defined $v1;
    my ( $l, $r ) = map { _type($_) } $v1, $v2;
    my $lr = "$l$r";
    for ($lr) {
        when ('ss') { return $v1 eq $v2       ? 1 : undef }
        when ('nn') { return $v1 == $v2       ? 1 : undef }
        when ('hn') { return keys %$v1 == $v2 ? 1 : undef }
        when ('nh') { return $v1 == keys %$v2 ? 1 : undef }
        when ('nr') { return $v1 == @$v2      ? 1 : undef }
        when ('rn') { return @$v1 == $v2      ? 1 : undef }
        default {
            return ( refaddr $v1 || 0 ) == ( refaddr $v2 || 0 )
              ? 1
              : undef;
        }
    }
}

sub _types {
    my $self = shift;
    _type( $self->left ), _type( $self->right );
}

# tests type of argument
sub _type {
    my $arg = shift;
    if ( my $type = ref $arg ) {
        return 'h' if $type eq 'HASH';
        return 'r' if $type eq 'ARRAY';
        return 'a' if $arg->isa('TPath::Attribute');
        return 'e' if $arg->isa('TPath::Expression');
        return 't' if $arg->isa('TPath::AttributeTest');
        return 'c' if $arg->isa('TPath::Concatenation');
        return 'f' if $arg->DOES('TPath::Numifiable');
        return 'o';
    }
    return 'n' if looks_like_number $arg;
    return 's';
}

sub to_string {
    my $self = shift;
    $self->_stringify( $self->left, 1 ) . ' '
      . $self->op . ' '
      . $self->_stringify( $self->right, 1 );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::AttributeTest - compares an attribute value to another value

=head1 VERSION

version 1.007

=head1 DESCRIPTION

Implements predicates such as C<//foo[@a < @b]> or C<ancestor::*[@bar = 1]>. That is, predicates
where an attribute is tested against some value. Actually, there need not be an attribute on either
side of the operator since the code was refactored to allow general math in these expressions, so
C<AttributeTest> is now a misnomer. All the following are also acceptable

  //foo[1 = 1]
  //foo["bar" = 0]
  //foo[bar = 1]
  //foo[bar = 1 = 1]

The last of these is of questionable utility, but it is parsable. And note that parsing is in effect
left-associative, so this expression will be equivalent to

  //foo[(bar = 1) = 1]

Expressions which analytically must have a constant value will be evaluated during parsing. If they
are necessarily false, an error will be thrown. If they are analytically true, they will be eliminated
from the respective step's predicate list, so

  //foo[1 = 1]

is logically equivalent to C<//foo> and in fact will be structurally identical to C<//foo>, as the
predicate will be eliminated during compilation.

This class if for internal consumption only.

=head1 ATTRIBUTES

=head2 op

The comparison operator between the two values.

=head2 left

The left value.

=head2 right

The right value.

=head1 METHODS

=head2 test

The test function applied to the values. This method is constructed in C<BUILD> and
assigned to the attribute test as a singleton method.

Expects a node, an index, and a collection.

=head1 ROLES

L<TPath::Stringifiable>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
