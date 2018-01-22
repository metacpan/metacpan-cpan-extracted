package Pcore::Dist::CLI::Pause;

use Pcore -class, -ansi;

with qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return { abstract => 'work with perl PAUSE' };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    require Pcore::API::PAUSE;

    my $pause = Pcore::API::PAUSE->new( {
        username => $ENV->user_cfg->{PAUSE}->{username},
        password => $ENV->user_cfg->{PAUSE}->{password},
    } );

    print 'clean PAUSE ... ';

    say $pause->clean( keep => 2 );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Pause - work with perl PAUSE

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
