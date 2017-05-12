package Pcore::Util::Promise;

use Pcore -class, -export => { PROMISE => [qw[promise]] };
use Pcore::Util::Promise::Request;
use overload    #
  q[&{}] => sub ( $self, @ ) {
    return sub { return _run( $self, @_ ) };
  },
  fallback => 1;

has _method_name => ( is => 'ro', isa => Str );
has _then => ( is => 'ro', isa => Maybe [ ArrayRef [CodeRef] ], default => sub { [] } );

sub promise (@) : prototype(@) {
    my ( $method_name, @code );

    if ( !ref $_[0] ) {
        $method_name = $_[0];

        @code = $_[1]->();
    }
    else {
        @code = @_;
    }

    my $promise = bless {
        _method_name => $method_name,
        _then        => \@code,
      },
      __PACKAGE__;

    if ($method_name) {
        my $caller = scalar caller;

        no strict qw[refs];

        *{"$caller\::$method_name"} = sub { return $promise->_run(@_) };

        return;
    }
    else {
        return $promise;
    }
}

sub _run ( $self, @ ) {
    my $cb = $_[-1];

    my $req = bless {
        _promise   => $self,
        _cb        => $cb,
        _then_idx  => 1,
        _responded => 0,
      },
      'Pcore::Util::Promise::Request';

    $req->{_self} = $_[1] if $self->{_method_name};

    eval { $self->{_then}->[0]->( $req, splice @_, 1, -1 ) };

    if ($@) {
        $@->sendlog;

        $req->done(500);
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 59                   | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Promise

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
