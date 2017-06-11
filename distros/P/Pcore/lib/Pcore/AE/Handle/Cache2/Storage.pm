package Pcore::AE::Handle::Cache2::Storage;

use Pcore;

sub new ($self) {
    return bless {
        el       => {},
        first_el => undef,
        last_el  => undef,
    }, $self;
}

sub has_items ($self) {
    return defined $self->{first_el};
}

sub push ( $self, $id ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    return if exists $self->{el}->{$id};

    my $item = [ $id, undef, undef ];

    if ( defined $self->{last_el} ) {
        my $last_el = $self->{el}->{ $self->{last_el} };

        $last_el->[2] = $id;

        $item->[1] = $last_el->[0];
    }
    else {
        $self->{first_el} = $id;
    }

    $self->{el}->{$id} = $item;

    $self->{last_el} = $id;

    return;
}

sub pop ($self) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my $last_el = $self->{last_el};

    $self->delete( $self->{last_el} ) if defined $last_el;

    return $last_el;
}

sub shift ($self) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    return if !defined $self->{first_el};

    my $first_el = delete $self->{el}->{ $self->{first_el} };

    if ( defined $first_el->[2] ) {    # has next el
        my $next_el = $self->{el}->{ $first_el->[2] };

        $next_el->[1] = undef;

        $self->{first_el} = $next_el->[0];
    }
    else {
        $self->{first_el} = undef;

        $self->{last_el} = undef;
    }

    return $first_el->[0];
}

sub unshift ( $self, $id ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    return if exists $self->{el}->{$id};

    my $item = [ $id, undef, undef ];

    if ( defined $self->{first_el} ) {
        my $first_el = $self->{el}->{ $self->{first_el} };

        $first_el->[1] = $id;

        $item->[2] = $first_el->[0];
    }
    else {
        $self->{last_el} = $id;
    }

    $self->{el}->{$id} = $item;

    $self->{first_el} = $id;

    return;
}

sub delete ( $self, $id ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my $item = delete $self->{el}->{$id};

    return if !defined $item;

    my $prev = defined $item->[1] ? $self->{el}->{ $item->[1] } : undef;

    my $next = defined $item->[2] ? $self->{el}->{ $item->[2] } : undef;

    if ( defined $prev ) {
        if ( defined $next ) {
            $prev->[2] = $next->[0];

            $next->[1] = $prev->[0];
        }
        else {    # last el was deleted
            $self->{last_el} = $prev->[0];
        }
    }
    else {
        if ( defined $next ) {    # first el was deleted
            $self->{first_el} = $next->[0];
        }
        else {                    # latest el was deleted
            $self->{first_el} = undef;

            $self->{last_el} = undef;
        }
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::AE::Handle::Cache2::Storage

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
