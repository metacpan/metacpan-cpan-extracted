package <: $module_name ~ "::Node::Log" :>;

use Pcore -class, -const, -sql;
use Pcore::Util::Data qw[to_json];
use <: $module_name ~ "::Const qw[:CONST]" :>;

with qw[<: $module_name ~ "::Node" :>];

const our $NODE_REQUIRES => { '*' => 'log.#', };

sub NODE_ON_EVENT ( $self, $ev ) {
    P->forward_event($ev);

    return;
}

sub BUILD ( $self, $args ) {

    # create event listener
    P->bind_events(
        ['log.#'],
        sub ( $ev ) {
            my $data = ref $ev->{data} ? to_json( $ev->{data}, readable => 1 )->$* : $ev->{data};

            my $values->@{qw[created channel level title data]} = ( SQL [ 'to_timestamp(', \$ev->{timestamp}, ')' ], $ev->@{qw[channel level title]}, $data );

            $self->{util}->{dbh}->do( [ q[INSERT INTO "log"], VALUES [$values] ] );

            return;
        }
    );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1, 5                 | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 50                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 54 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name ~ "::Node::Log" :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
