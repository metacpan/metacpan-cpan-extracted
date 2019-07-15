package Pcore::Lib::File1::TempDir;

use Pcore -class;
use File::Path qw[];    ## no critic qw[Modules::ProhibitEvilModules]
use Clone qw[];

extends qw[Pcore::Lib::Path];

has temp => ();

our @DEFERRED_UNLINK;

END {
    for my $path (@DEFERRED_UNLINK) {
        File::Path::remove_tree( $path, safe => 0 );
    }
}

sub DESTROY ($self) {
    return if !defined $self->{temp};

    File::Path::remove_tree( $self->{temp}, safe => 0 );

    push @DEFERRED_UNLINK, $self->{temp} if -d $self->{temp};

    return;
}

around new => sub ( $orig, $self, $path, %args ) {
    if ( delete $args{temp} ) {
        $self = $self->SUPER::new( $path, %args )->to_abs;

        $self->{temp} = $self->encoded;
    }
    else {
        $self = $self->SUPER::new( $path, %args );
    }

    return $self;
};

sub clone ($self) {
    my $clone = Clone::clone($self);

    delete $clone->{temp};

    return $clone;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::File1::TempDir

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
