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
        say 'Git not found';

        exit 3;
    }

    # get changesets since latest release
    my $log = $dist->git->git_get_log( $dist->id->{release} );

    if ($log) {
        if ( $log->{data} ) {
            $log = join "\n", $log->{data}->@*;
        }
        else {
            $log = 'no changes';
        }
    }

    print "Changelog since release: @{[ $dist->id->{release} ]}\n$log\n";

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
