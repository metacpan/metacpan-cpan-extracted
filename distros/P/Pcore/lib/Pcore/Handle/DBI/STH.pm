package Pcore::Handle::DBI::STH;

use Pcore -class;

has id    => ( required => 1 );        # Str
has query => ( required => 1 );        # Str
has dbh   => ( init_arg => undef );    # ArrayRef

sub DESTROY ( $self ) {
    if ( ${^GLOBAL_PHASE} ne 'DESTRUCT' ) {
        for my $dbh ( $self->{dbh}->@* ) {
            my $id = $self->{id};

            $dbh->destroy_sth($id) if defined $dbh;
        }
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::DBI::STH

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
