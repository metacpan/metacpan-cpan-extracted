package Pcore::Dist::CLI::Log;

use Pcore -class;

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {    #
        abstract => 'show unreleased changes',
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    my $dist = $self->get_dist;

    if ( !$dist->git ) {
        say 'Git was not found.';

        exit 3;
    }

    my $id = $dist->id;

    # get changesets since latest release
    my $log = $dist->get_changesets_log( $id->{release} );

    if ($log) {
        $log = join "\n", $log->@*;
    }
    else {
        $log = 'no changes';
    }

    print qq[Changelog since release "@{[ $id->{release} // 'v0.0.0' ]}":\n$log\n];

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Log - show unreleased changes

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
