package Pcore::Ext::App::Class::Ctx::L10N;

use Pcore -class;
use Pcore::Lib::Scalar qw[refaddr is_ref weaken];
use Pcore::Lib::Data qw[to_json];

has class => ( required => 1 );
has buf   => ( required => 1 );

sub BUILD ( $self, $args ) {
    weaken $self->{class};

    return;
}

use overload    #
  '""' => sub ( $self, @ ) { return $self->to_js_func },
  '.'  => sub ( $self, $str, $pos ) {
    return __PACKAGE__->new(
        class => $self->{class},
        buf   => $pos ? [ is_ref $str ? $str->{buf}->@* : $str, $self->{buf}->@* ] : [ $self->{buf}->@*, is_ref $str ? $str->{buf}->@* : $str ],
    );
  },
  '&{}' => sub ( $self, @ ) {
    die 'Invalid plural form usage' if $self->{buf}->@* > 1;

    return sub ($num) {
        my $clone = __PACKAGE__->new(
            class => $self->{class},
            buf   => [ [ $self->{buf}->[0]->@* ] ],
        );

        $clone->{buf}->[0]->[3] = $num;

        return $clone;
    };
  },
  fallback => 1;

sub TO_JSON ( $self ) {
    my $id = '__JS_' . refaddr($self) . '__';

    $self->{class}->{build_cache}->{$id} = $self;

    return $id;
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

    return $buf;
}

sub generate ( $self, $quote ) {
    return qq[new Ext.L10N.string(@{[ to_json $self->{buf} ]})];
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 61                   | Variables::ProhibitLocalVars - Variable declared as "local"                                                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::App::Class::Ctx::L10N - ExtJS function call generator

=head1 SYNOPSIS

    my $str = l10n('singular form', 'plural form', 5);

    {
        text => 'prefix' . l10n('singular form') . 'suffix',
        text => 'prefix' . l10n('singular form', 'plural form', 5) . 'suffix',

        method => func <<"JS",
            console.log('prefix' + $l10n{'singular form'} + 'suffix');

            console.log('prefix' + $str + 'suffix');

            // redefine num for the predefined l10n string
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
