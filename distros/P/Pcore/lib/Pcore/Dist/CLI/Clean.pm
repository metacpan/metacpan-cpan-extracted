package Pcore::Dist::CLI::Clean;

use Pcore -class;

with qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return { abstract => 'clean dist directory from known build garbage', };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    my $dist = $self->get_dist;

    $dist->build->clean;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Clean - clean dist directory from known build garbage

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
