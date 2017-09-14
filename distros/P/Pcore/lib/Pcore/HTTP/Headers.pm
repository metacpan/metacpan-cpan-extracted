package Pcore::HTTP::Headers;

use Pcore -class;
extends qw[Pcore::Util::Hash::Multivalue];

sub to_string ($self) {
    my $hash = $self->get_hash;

    my $headers = q[];

    for ( keys $hash->%* ) {
        my $header;

        if (/[^[:upper:]_]/sm) {
            $header = $_;
        }
        else {
            $header = ( ucfirst lc ) =~ s/_([[:alpha:]])/q[-] . uc $1/smger;
        }

        for ( grep {defined} $hash->{$_}->@* ) {
            $headers .= $header . q[:] . $_ . $CRLF;
        }
    }

    return $headers;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::HTTP::Headers

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
