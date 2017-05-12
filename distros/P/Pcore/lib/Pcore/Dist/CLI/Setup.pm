package Pcore::Dist::CLI::Setup;

use Pcore -class;

with qw[Pcore::Core::CLI::Cmd];

sub CLI ($self) {
    return { abstract => 'setup pcore.perl', };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    $self->new->run;

    return;
}

sub run ($self) {
    state $init = !!require Pcore::Dist::Build;

    Pcore::Dist::Build->new->setup;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Setup - setup pcore.perl

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
