package Pcore::Ext::Context::L10N;

use Pcore -class;
use Pcore::Util::Scalar qw[refaddr is_ref];
use Pcore::Util::Data qw[to_json];

has ctx => ();
has buf => ();

use overload    #
  q[""] => sub ( $self, @ ) {
    return $self->to_js_func->$*;
  },
  q[.] => sub ( $self, $str, $pos ) {
    return bless {
        ctx => $self->{ctx},
        buf => $pos ? [ is_ref $str ? $str->{buf}->@* : $str, $self->{buf}->@* ] : [ $self->{buf}->@*, is_ref $str ? $str->{buf}->@* : $str ],
      },
      __PACKAGE__;
  },
  q[&{}] => sub ( $self, @ ) {
    die 'Invalid plural form usage' if $self->{buf}->@* > 1;

    return sub ($num) {
        my $clone = bless {
            ctx => $self->{ctx},
            buf => [ [ $self->{buf}->[0]->@* ] ],
          },
          __PACKAGE__;

        $clone->{buf}->[0]->[3] = $num;

        return $clone;
    };
  },
  fallback => 1;

sub TO_JSON ( $self ) {
    my $id = refaddr $self;

    $self->{ctx}->{_js_gen_cache}->{$id} = $self->to_js_object;

    return "__JS${id}__";
}

sub to_js_func ($self) {
    my $buf;

    for my $item ( $self->{buf}->@* ) {
        if ( !is_ref $item) {
            $buf .= $item;
        }
        else {
            my $json;

            if ( defined $item->[2] ) {
                my $num = $item->[2];

                local $item->[2] = P->uuid->v1mc_str;

                $json = to_json $item;

                $json =~ s/"$item->[2]"/$num/sm;
            }
            else {
                $json = to_json $item;
            }

            $buf .= qq[Ext.L10N.l10n($json)];
        }
    }

    return \$buf;
}

sub to_js_object ( $self ) {
    return \qq[new Ext.L10N.string(@{[ to_json $self->{buf} ]})];
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 59                   | Variables::ProhibitLocalVars - Variable declared as "local"                                                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Context::L10N - ExtJS function call generator

=head1 SYNOPSIS

    my $str = l10n('singular form', 'plural form', 5);

    {
        text => 'prefix' . l10n('singular form') . 'suffix',
        text => 'prefix' . l10n('singular form', 'plural form', 5) . 'suffix',

        method => func [], <<"JS",
            console.log('prefix' + $l10n->{'singular form'} + 'suffix');

            console.log('prefix' + $str + 'suffix');

            // redefine num for predefined l10n string
            var num = 10;
            console.log('prefix' + @{[ $str->('num') ]} + 'suffix');
    JS
    }

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

=cut
