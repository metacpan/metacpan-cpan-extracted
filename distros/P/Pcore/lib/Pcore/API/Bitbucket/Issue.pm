package Pcore::API::Bitbucket::Issue;

use Pcore -class, -const, -ansi, -result;

const our $PRIORITY => {
    trivial  => 1,
    minor    => 2,
    major    => 3,
    critical => 4,
    blocker  => 5,
};

const our $PRIORITY_COLOR => {
    trivial  => $WHITE,
    minor    => $BLACK . $ON_WHITE,
    major    => $BLACK . $ON_YELLOW,
    critical => $WHITE . $ON_RED,
    blocker  => $BOLD . $WHITE . $ON_RED,
};

const our $KIND => {
    bug         => [ 'bug',  $WHITE . $ON_RED ],
    enhancement => [ 'enh',  $WHITE ],
    proposal    => [ 'prop', $WHITE ],
    task        => [ 'task', $WHITE ],
};

const our $STATUS_ID => {
    new       => 1,
    open      => 2,
    resolved  => 3,
    closed    => 4,
    'on hold' => 5,
    invalid   => 6,
    duplicate => 7,
    wontfix   => 8,
};

const our $STATUS_COLOR => {
    new       => $BLACK . $ON_WHITE,
    open      => $BLACK . $ON_WHITE,
    resolved  => $WHITE . $ON_RED,
    closed    => $BLACK . $ON_GREEN,
    'on hold' => $WHITE . $ON_BLUE,
    invalid   => $WHITE . $ON_BLUE,
    duplicate => $WHITE . $ON_BLUE,
    wontfix   => $WHITE . $ON_BLUE,
};

has api => ( is => 'ro', isa => InstanceOf ['Pcore::API::Bitbucket'], required => 1 );

has priority_id => ( is => 'lazy', isa => Enum [ values $PRIORITY->%* ], init_arg => undef );
has priority_color => ( is => 'lazy', isa => Str, init_arg => undef );
has status_id => ( is => 'lazy', isa => Enum [ values $STATUS_ID->%* ], init_arg => undef );
has status_color        => ( is => 'lazy', isa => Str, init_arg => undef );
has kind_color          => ( is => 'lazy', isa => Str, init_arg => undef );
has kind_abbr           => ( is => 'lazy', isa => Str, init_arg => undef );
has utc_last_updated_ts => ( is => 'lazy', isa => Int, init_arg => undef );
has url                 => ( is => 'lazy', isa => Str, init_arg => undef );

sub _build_priority_id ($self) {
    return $PRIORITY->{ $self->{priority} };
}

sub _build_priority_color ($self) {
    return $PRIORITY_COLOR->{ $self->{priority} } . " $self->{priority} " . $RESET;
}

sub _build_status_id ($self) {
    return $STATUS_ID->{ $self->{status} };
}

sub _build_status_color ($self) {
    return $STATUS_COLOR->{ $self->{status} } . " $self->{status} " . $RESET;
}

sub _build_kind_color ($self) {
    return $KIND->{ $self->{metadata}->{kind} }->[1] . " @{[$self->kind_abbr]} " . $RESET;
}

sub _build_kind_abbr ($self) {
    return $KIND->{ $self->{metadata}->{kind} }->[0];
}

sub _build_utc_last_updated_ts ($self) {
    return P->date->from_string( $self->{utc_last_updated} =~ s/\s/T/smr )->epoch;
}

sub _build_url ($self) {
    return "https://bitbucket.org/@{[$self->api->id]}/issues/$self->{local_id}/";
}

sub set_status ( $self, $status, $cb ) {
    $self->update( { status => $status }, $cb );

    return;
}

sub set_version ( $self, $ver, $cb ) {
    $self->update( { version => $ver }, $cb );

    return;
}

sub set_milestone ( $self, $milestone, $cb ) {
    $self->update( { milestone => $milestone }, $cb );

    return;
}

# https://confluence.atlassian.com/bitbucket/issues-resource-296095191.html#issuesResource-Updateanexistingissue
sub update ( $self, $args, $cb ) {
    P->http->put(    #
        "https://bitbucket.org/api/1.0/repositories/@{[$self->api->id]}/issues/$self->{local_id}/",
        headers => {
            AUTHORIZATION => $self->api->auth,
            CONTENT_TYPE  => 'application/x-www-form-urlencoded; charset=UTF-8',
        },
        body      => P->data->to_uri($args),
        on_finish => sub ($res) {
            if ( !$res ) {
                my $data = eval { P->data->from_json( $res->body ) };

                $cb->( result [ $res->status, $data->{error}->{message} || $res->reason ] );
            }
            else {
                my $data = eval { P->data->from_json( $res->body ) };

                if ($@) {
                    $cb->( result [ 500, 'Error decoding respnse' ] );
                }
                else {
                    $self->@{ keys $data->%* } = values $data->%*;

                    $cb->( result 200, $self );
                }
            }

            return;
        },
    );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Bitbucket::Issue

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
