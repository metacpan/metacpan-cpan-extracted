package Pcore::API::AntiCaptcha::Result;

use Pcore -class;
use Pcore::Util::Scalar qw[weaken];
use overload
  bool     => sub { ( $_[0]->{is_finished} // 0 ) && ( $_[0]->{is_resolved} // 0 ) },
  fallback => 1;

with qw[Pcore::Util::Result::Role];

has api => ( required => 1 );

has id          => ( init_arg => undef );
has result      => ( init_arg => undef );
has is_finished => ( init_arg => undef );
has is_resolved => ( init_arg => undef );
has is_reported => ( init_arg => undef );

sub DESTROY ($self) {
    delete $self->{api}->{_queue}->{ $self->{id} } if ${^GLOBAL_PHASE} ne 'DESTRUCT' && defined $self->{id} && defined $self->{api};

    return;
}

sub BUILD ( $self, $args ) {
    weaken $self->{api};

    return;
}

sub resolve ( $self, $cb = undef ) {
    return defined $self->{api} ? $self->{api}->resolve( $self, $cb ) : undef;
}

sub report_invalid ($self) {
    return defined $self->{api} ? $self->{api}->report_invalid($self) : undef;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::AntiCaptcha::Result

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
