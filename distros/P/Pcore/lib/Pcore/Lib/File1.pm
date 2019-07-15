package Pcore::Lib::File1;

use Pcore;
use Pcore::Lib::UUID qw[uuid_v4_hex];

# prefix, name, mode, umask
# TODO
sub tempfile (%args) {
    require Pcore::Lib::File1::TempFile;

    $args{prefix} //= $ENV->{TEMP_DIR};

    P->path( $args{prefix} )->mkpath if !-e $args{prefix};

    my $path = Pcore::Lib::File1::TempFile->new( "$args{prefix}/" . ( $args{name} // uuid_v4_hex ) . ( defined $args{suffix} ? ".$args{suffix}" : $EMPTY ), temp => 1 );

    $path->touch( mode => $args{mode}, umask => $args{umask} );

    return $path;
}

# TODO
sub tempdir (%args) {
    require Pcore::Lib::File1::TempDir;

    my $path = Pcore::Lib::File1::TempDir->new( ( $args{prefix} // $ENV->{TEMP_DIR} ) . '/' . ( $args{name} // uuid_v4_hex ), temp => 1 );

    $path->mkpath;

    return $path;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::File1

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
