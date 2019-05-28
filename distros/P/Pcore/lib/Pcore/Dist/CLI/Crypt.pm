package Pcore::Dist::CLI::Crypt;

use Pcore -class;

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {
        abstract => 'Crypt perl files',
        cmd      => 'Pcore::Dist::CLI::Crypt::'
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Crypt - crypt perl files

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
