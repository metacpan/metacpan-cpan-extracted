package Pcore::Ext::Context::L10N;

use Pcore -const;
use Pcore::Util::Scalar qw[refaddr];

const our $ATTR => {
    ext          => 0,
    is_plural    => 1,
    msgid        => 2,
    domain       => 3,
    msgid_plural => 4,
    num          => 5,
    tied_hash    => 6,
};

use overload    #
  q[""] => sub {
    return $_[0]->to_js->$*;
  },
  q[%{}] => sub {
    my $idx = $ATTR->{tied_hash};

    if ( !defined $_[0]->[$idx] ) {
        tie $_[0]->[$idx]->%*, 'Pcore::Ext::Context::L10N::_l10np', $_[0];
    }

    return $_[0]->[$idx];
  },
  fallback => undef;

sub new ( $self, %args ) {
    my $arr = [];

    while ( my ( $k, $v ) = each %args ) {
        $arr->[ $ATTR->{$k} ] = $v;
    }

    return bless $arr, $self;
}

sub TO_JSON ( $self, @ ) {
    my $id = refaddr $self;

    $self->[ $ATTR->{ext} ]->{js_gen_cache}->{$id} = $self->to_js;

    return "__JS${id}__";
}

sub to_js ( $self, $num = undef ) {
    my $js;

    my $l10n_class_name = $self->[ $ATTR->{ext} ]->{ctx}->{l10n_class_name};

    # quote
    my $msgid  = $self->[ $ATTR->{msgid} ] =~ s/'/\\'/smgr;
    my $domain = $self->[ $ATTR->{domain} ] =~ s/'/\\'/smgr;

    if ( $self->[ $ATTR->{is_plural} ] ) {

        # quote
        my $msgid_plural = $self->[ $ATTR->{msgid_plural} ] =~ s/'/\\'/smgr;

        $num //= $self->[ $ATTR->{num} ];

        $js = qq[$l10n_class_name.l10np('$msgid', '$msgid_plural', $num, '$domain')];
    }
    else {
        $js = qq[$l10n_class_name.l10n('$msgid', '$domain')];
    }

    return \$js;
}

package Pcore::Ext::Context::L10N::_l10np {
    use Pcore::Util::Scalar qw[weaken];

    sub TIEHASH ( $self, $obj ) {
        $self = bless [$obj], $self;

        weaken $self->[0];

        return $self;
    }

    sub FETCH {
        return $_[0]->[0]->to_js( $_[1] )->$*;
    }
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 24                   | Miscellanea::ProhibitTies - Tied variable used                                                                 |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Context::L10N - ExtJS function call generator

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

=cut
