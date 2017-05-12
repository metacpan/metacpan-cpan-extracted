package Pcore::Core::Guard;

use Pcore -role;
use Variable::Magic;

my $WIZ = Variable::Magic::wizard(
    data => sub {
        return $_[1];
    },
    free => sub {
        if ( ref $_[1] eq 'CODE' ) {
            $_[1]->( $_[0]->$* );
        }
        else {
            my $method = $_[1];

            $_[0]->$*->$method;
        }

        return;
    },
);

sub scope_guard {
    my $self = shift;
    my %args = (
        guard => 'ON_DESTROY',
        @_,
    );

    Variable::Magic::cast( $self, $WIZ, $args{guard} );

    return \$self;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Guard

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
