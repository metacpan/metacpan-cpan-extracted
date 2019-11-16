package Pcore::Lib::File1::TempFile;

use Pcore -class;

extends qw[Pcore::Lib::Path];

has temp => ( init_arg => undef );
has pid  => ( init_arg => undef );

our @DEFERRED_UNLINK;

END { unlink @DEFERRED_UNLINK if @DEFERRED_UNLINK }    ## no critic qw[InputOutput::RequireCheckedSyscalls]

sub DESTROY ($self) {
    return if !defined $self->{temp} || !defined $self->{pid} || $self->{pid} != $$;

    unlink $self->{temp};                              ## no critic qw[InputOutput::RequireCheckedSyscalls]

    push @DEFERRED_UNLINK, $self->{temp} if -f $self->{temp};

    return;
}

around new => sub ( $orig, $self, $path, %args ) {
    if ( delete $args{temp} ) {
        $self = $self->SUPER::new( $path, %args )->to_abs;

        $self->{temp} = $self->encoded;

        $self->{pid} = $$;
    }
    else {
        $self = $self->SUPER::new( $path, %args );
    }

    return $self;
};

sub clone ($self) {
    my $clone = Clone::clone($self);

    delete $clone->{temp};
    delete $clone->{pid};

    return $clone;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::File1::TempFile

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
