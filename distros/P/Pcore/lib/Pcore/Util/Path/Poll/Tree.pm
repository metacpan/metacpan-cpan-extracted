package Pcore::Util::Path::Poll::Tree;

use Pcore -class, -const;
use Pcore::Util::UUID qw[uuid_v1mc_str];

has root     => ( required => 1 );
has interval => ( required => 1 );
has cb       => ( required => 1 );
has read_dir => ();

has id => ( uuid_v1mc_str, init_arg => undef );
has last_checked => ( 0, init_arg => undef );
has stat         => ( sub { {} }, init_arg => undef );

const our $STAT_ID   => 0;
const our $STAT_PATH => 1;
const our $STAT_DATA => 2;

sub DESTROY ($self) {
    delete $Pcore::Util::Path::Poll::POLL->{ $self->{id} } if ${^GLOBAL_PHASE} ne 'DESTRUCT';

    return;
}

sub BUILD ( $self, $args ) {
    if ( -d $self->{root} && ( my $paths = $self->{root}->read_dir( $self->{read_dir}->%* ) ) ) {
        for my $path ( $paths->@* ) {
            my $path_abs_encoded = $path->{is_abs} ? $path->encoded : $self->{root}->encoded . '/' . $path->encoded;

            $self->{stat}->{$path_abs_encoded}->@[ $STAT_ID, $STAT_PATH, $STAT_DATA ] = ( \$path_abs_encoded, $path, [ Time::HiRes::stat($path_abs_encoded) ] );
        }
    }

    return;
}

sub scan ($self) {
    my $stats;

    # scan
    if ( -d $self->{root} && ( my $paths = $self->{root}->read_dir( $self->{read_dir}->%* ) ) ) {
        for my $path ( $paths->@* ) {
            my $path_abs_encoded = $path->{is_abs} ? $path->encoded : $self->{root}->encoded . '/' . $path->encoded;

            $stats->{$path_abs_encoded}->@[ $STAT_ID, $STAT_PATH, $STAT_DATA ] = ( \$path_abs_encoded, $path, [ Time::HiRes::stat($path_abs_encoded) ] );
        }
    }

    my @changes;

    my $old_stats = $self->{stat};

    # scan created / modified paths
    for my $stat ( values $stats->%* ) {

        # path is already exists
        if ( my $old_stat = $old_stats->{ $stat->[$STAT_ID]->$* } ) {

            # last modify time was changed
            if ( $old_stat->[$STAT_DATA]->[9] != $stat->[$STAT_DATA]->[9] ) {
                push @changes, [ $stat->[$STAT_PATH], $Pcore::Util::Path::Poll::POLL_MODIFIED ];

                # store new stat data
                $old_stat->[$STAT_DATA] = $stat->[$STAT_DATA];
            }
        }

        # new path was created
        else {
            push @changes, [ $stat->[$STAT_PATH], $Pcore::Util::Path::Poll::POLL_CREATED ];

            # store stat
            $old_stats->{ $stat->[$STAT_ID]->$* } = $stat;
        }
    }

    # scan removed paths
    for my $old_stat ( values $old_stats->%* ) {

        # path was removed
        if ( !exists $stats->{ $old_stat->[$STAT_ID]->$* } ) {
            push @changes, [ $old_stat->[$STAT_PATH], $Pcore::Util::Path::Poll::POLL_REMOVED ];

            delete $old_stats->{ $old_stat->[$STAT_ID]->$* };
        }
    }

    # call callback if has changes
    $self->{cb}->( $self->{root}, \@changes ) if @changes;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Path::Poll::Tree

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
