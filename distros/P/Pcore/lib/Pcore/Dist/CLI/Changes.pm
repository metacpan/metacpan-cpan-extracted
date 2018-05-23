package Pcore::Dist::CLI::Changes;

use Pcore -class;

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {    #
        abstract => 'show unreleased changes',
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    my $dist = $self->get_dist;

    if ( !$dist->scm ) {
        say 'No SCM found';

        exit 3;
    }

    # get changesets since latest release
    my $changesets = $dist->scm->scm_get_changesets( $dist->version eq 'v0.0.0' ? undef : 'latest' );

    my ( $log, $summary_idx );

    for my $changeset ( $changesets->{data}->@* ) {
        if ( !exists $summary_idx->{ $changeset->{summary} } ) {
            $summary_idx->{ $changeset->{summary} } = undef;

            next if $changeset->{summary} =~ /\Arelease v[\d.]+\z/sm;

            next if $changeset->{summary} =~ /\AAdded tag/sm;

            $log .= "- $changeset->{summary}\n";
        }
    }

    say q[Changelog since release: ] . $dist->version . $LF;
    say $log;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Changes - show unreleased changes

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
