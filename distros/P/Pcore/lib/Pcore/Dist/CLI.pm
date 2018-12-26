package Pcore::Dist::CLI;

use Pcore -class;

extends qw[Pcore::Core::CLI::Cmd];

sub get_dist ($self) {
    require Pcore::Dist;

    if ( my $dist = Pcore::Dist->new( $ENV->{START_DIR} ) ) {
        return $dist;
    }
    else {
        print "Pcore distribution was not found\n\n";

        exit 3;
    }
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
