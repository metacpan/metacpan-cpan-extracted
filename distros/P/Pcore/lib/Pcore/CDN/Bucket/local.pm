package Pcore::CDN::Bucket::local;

use Pcore -class;

with qw[Pcore::CDN::Bucket];

has lib => ();

has is_local => ( 1, init_arg => undef );

sub BUILD ( $self, $args ) {
    $self->{prefix} = '';

    # load libs
    for my $lib ( $self->{lib}->@* ) { P->class->load( $lib =~ s/-/::/smgr ) }

    return;
}

# TODO maybe create local temp bucket automatically
# P->file->mkpath( "$ENV->{DATA_DIR}share", mode => 'rwxr-xr-x' ) if !-e "$ENV->{DATA_DIR}share/";
# $ENV->{share}->register_lib( 'autostars', "$ENV->{DATA_DIR}share/" );
sub get_nginx_cfg ($self) {
    my @buf;

    my $locations;

    for my $lib ( $self->{lib}->@* ) {
        my $storage = $ENV->{share}->get_storage( $lib, 'www' );

        next if !$storage || !-d "$storage/static";

        push $locations->@*, $storage;
    }

    # add_header    Cache-Control "public, private, must-revalidate, proxy-revalidate";

    for ( my $i = 0; $i <= $locations->$#*; $i++ ) {
        my $location = $i == 0 ? '/static/' : "\@$locations->[$i]";

        my $next = $i < $locations->$#* ? "\@$locations->[$i + 1]" : '=404';

        push @buf, <<"TXT";
    location $location {
        add_header    Cache-Control "public, max-age=30672000";
        root          $locations->[$i];
        try_files     \$uri $next;
    }
TXT
    }

    return <<"TXT";
@{[join $LF, @buf]}
TXT
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 12                   | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 38                   | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::CDN::Bucket::local

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
