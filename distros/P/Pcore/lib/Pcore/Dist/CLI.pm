package Pcore::Dist::CLI;

use Pcore -role;
use Pcore::Dist;

with qw[Pcore::Core::CLI::Cmd];

has dist => ( is => 'ro', isa => InstanceOf ['Pcore::Dist'], init_arg => undef );

around run => sub ( $orig, $self, @args ) {
    if ( my $dist = Pcore::Dist->new( $ENV->{START_DIR} ) ) {
        $self->{dist} = $dist;
    }
    else {
        say 'Pcore distribution was not found' . $LF;

        exit 3;
    }

    return $self->$orig(@args);
};

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
