package Pcore::Handle::DBI::Response;

use Pcore;
use Hash::Util::FieldHash qw[id idhashes register];

idhashes my ( \%status, \%rows, \%data );

use overload    #
  q[bool] => sub {
    return $status{ id $_[0] };
  },
  q[""] => sub {
    return $status{ id $_[0] };
  },
  q[0+] => sub {
    return $rows{ id $_[0] };
  },
  q[@{}] => sub {
    return $data{ id $_[0] };
  },
  q[%{}] => sub {
    return $data{ id $_[0] }->[0];
  },
  fallback => 1;

sub new ( $self, $status, $rows = undef, $data = undef ) {
    my $obj;

    $self = bless \$obj, $self;

    my $id = id $self;

    $status{$id} = $status;
    $rows{$id}   = $rows // 0;
    $data{$id}   = $data // [];

    register( $self, \%status, \%rows, \%data );

    return $self;
}

sub rows ($self) {
    return $rows{ id $self};
}

sub data ($self) {
    return $data{ id $self};
}

sub TO_DUMP ( $self, $dumper, @ ) {
    my %args = (
        path => undef,
        splice @_, 2,
    );

    my $tags;

    my $res = $dumper->_dump( $data{ id $self}, path => $args{path} );

    return $res, $tags;
}

*TO_JSON = *TO_CBOR = sub ($self) {
    return $data{ id $self};
};

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::DBI::Response

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
