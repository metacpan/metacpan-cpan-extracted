package Net::Hadoop::Oozie::Constants;
$Net::Hadoop::Oozie::Constants::VERSION = '0.113';
use 5.010;
use strict;
use warnings;
use parent qw( Exporter );

use Carp qw( confess );

use constant JOB_OPTIONS => qw(
    action
    len
    offset
    order
    show
);

use constant COORD_STATUS => qw(
    DONWITHERROR
    FAILED
    KILLED
    PAUSED
    PREP
    PREPPAUSED
    PREPSUSPENDED
    READY
    RUNNING
    SUBMITTED
    SUCCEEDED
    SUSPENDED
    WAITING
);

use constant WF_STATUS => qw(
    FAILED
    KILLED
    PREP
    RUNNING
    SUCCEEDED
    SUSPENDED
);

our $RE_VALID_COORD_STATUS = do {
    my $s = join '|', COORD_STATUS;
    qr/^$s$/;
};

our $RE_VALID_WF_STATUS = do {
    my $s = join '|', WF_STATUS;
    qr/^$s$/;
};

our $RE_VALID_STATUS = do {
    my $s = join '|', COORD_STATUS, WF_STATUS;
    qr/^$s$/;
};

our $RE_VALID_ENDPOINT = _build_valid_regex({
    v1 => {
        admin => {
            map { $_ => 1 } qw(
                build-version
                configuration
                instrumentation
                os-env
                status
                sys-props
                systems
            ),
        },
        jobs => 1,
        job  => 'dynamic',
    },
    v2 => {
        admin => {
            map { $_ => 1 } qw(
                build-version
                configuration
                instrumentation
                jmsinfo
                os-env
                status
                sys-props
                systems
            ),
        },
        jobs => 1,
        job  => 'dynamic',
    },
});

our $RE_BAD_REQUEST = qr{
    \QThe request sent by the client was syntactically incorrect. 400 Bad Request\E
}xms;

our %IS_VALID_SHOW = map { $_ => 1 } qw(
    definition
    info
    log
);

our %IS_VALID_ACTION = map { $_ => 1 } qw(
    coord-rerun
    kill
    rerun
    resume
    start
    suspend
);

our @EXPORT_OK = qw(
    COORD_STATUS
    JOB_OPTIONS
    WF_STATUS

    $RE_BAD_REQUEST
    $RE_VALID_COORD_STATUS
    $RE_VALID_ENDPOINT
    $RE_VALID_STATUS
    $RE_VALID_WF_STATUS
    %IS_VALID_ACTION
    %IS_VALID_SHOW
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

sub _build_valid_regex {
    my $valid = shift || confess "No valid definition specified";
    my %rv;
    foreach my $version ( keys %{ $valid } ) {
        my $ep = $valid->{ $version };
        my @patterns;
        foreach my $base ( keys %{ $ep } ) {
            my $subs = $ep->{ $base };
            my $val;
            if ( ref $subs eq 'HASH' ) {
                $val = sprintf '(?:%s)/(?:%s)?',
                                    $base,
                                    join( '|',
                                            map quotemeta( $_ ), keys %{ $subs } ),
                                ;
            }
            else {
                $val = $ep->{ $base } eq 'dynamic'
                     ? $base . "(?:/[\@a-zA-Z0-9_\-]+)?"
                     : $base
                     ;
            }
            push @patterns, $val;
        }
        my $pattern = sprintf '\A%s\z',
                                join '|', map { sprintf '(?:%s)', $_ } @patterns;
        $rv{ $version } = qr{$pattern}xms;
    }
    return \%rv;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Net::Hadoop::Oozie::Constants - Constants for Oozie

=head1 VERSION

version 0.113

=head1 DESCRIPTION

Part of the Perl Oozie interface.

=head1 SYNOPSIS

    use Net::Hadoop::Constants;
    # TODO

=cut
