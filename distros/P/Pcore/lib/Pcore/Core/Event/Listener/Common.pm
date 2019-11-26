package Pcore::Core::Event::Listener::Common;

use Pcore -class;
use Pcore::Util::UUID qw[uuid_v1mc_str];

with qw[Pcore::Core::Event::Listener];

has cb  => ( required => 1 );
has uri => ( required => 0 );

sub _build_id ($self) { return uuid_v1mc_str }

sub forward_event ( $self, $ev ) {
    $self->{cb}->($ev);

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Event::Listener::Common

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
