package Pcore::Core::Event::Listener;

use Pcore -class;
use Pcore::Util::UUID qw[uuid_v1mc_str];

has broker => ( is => 'ro', isa => InstanceOf ['Pcore::Core::Event'], required => 1 );
has masks => ( is => 'ro', isa => ArrayRef, required => 1 );
has cb => ( is => 'ro', isa => CodeRef | Object, required => 1 );

has id => ( is => 'ro', isa => Str, init_arg => undef );

sub BUILD ( $self, $args ) {
    $self->{id} = uuid_v1mc_str;

    return;
}

sub DEMOLISH ( $self, $global ) {
    $self->remove if !$global;

    return;
}

sub remove ($self) {
    for my $mask ( $self->{masks}->@* ) {
        delete $self->{broker}->{listeners}->{$mask}->{ $self->{id} };

        if ( !$self->{broker}->{listeners}->{$mask}->%* ) {
            delete $self->{broker}->{listeners}->{$mask};

            delete $self->{broker}->{mask_re}->{$mask};
        }
    }

    # remove listener from senders
    for my $sender ( values $self->{broker}->{senders}->%* ) {
        delete $sender->{ $self->{id} };
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Event::Listener

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
