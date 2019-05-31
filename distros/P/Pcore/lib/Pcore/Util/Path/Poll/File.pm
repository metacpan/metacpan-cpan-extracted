package Pcore::Util::Path::Poll::File;

use Pcore -class, -const;
use Pcore::Util::UUID qw[uuid_v1mc_str];

has root     => ( required => 1 );
has interval => ( required => 1 );
has cb       => ( required => 1 );

has id => ( sub {uuid_v1mc_str}, init_arg => undef );
has last_checked => ( 0, init_arg => undef );
has stat         => ( init_arg    => undef );

sub DESTROY ($self) {
    delete $Pcore::Util::Path::Poll::POLL->{ $self->{id} } if ${^GLOBAL_PHASE} ne 'DESTRUCT';

    return;
}

sub BUILD ( $self, $args ) {
    $self->{stat} = [ Time::HiRes::stat( $self->{root}->encoded ) ];

    return;
}

sub scan ($self) {
    my $stat = [ Time::HiRes::stat( $self->{root}->encoded ) ];

    my $change;

    # file is exists
    if ( $stat->@* ) {

        # file was existed
        if ( $self->{stat}->@* ) {

            # last modify time was changed
            if ( $self->{stat}->[9] != $stat->[9] ) {
                $change = $Pcore::Util::Path::Poll::POLL_MODIFIED;

                # store new stat data
                $self->{stat} = $stat;
            }
        }

        # file was created
        else {
            $change = $Pcore::Util::Path::Poll::POLL_CREATED;

            $self->{stat} = $stat;
        }
    }

    # file was removed
    elsif ( $self->{stat}->@* ) {
        $change = $Pcore::Util::Path::Poll::POLL_REMOVED;

        $self->{stat} = $stat;
    }

    # call callback if has changes
    $self->{cb}->( $self->{root}, $change ) if defined $change;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Path::Poll::File

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
