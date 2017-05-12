package Net::Airbrake::Error;

use strict;
use warnings;

use Class::Tiny qw(type message backtrace);

sub BUILDARGS {
    my $class = shift;
    my ($param) = @_;

    if (ref $param eq 'HASH') {
        return $param;
    }
    elsif (ref $param) {
        require Data::Dumper;
        return { type => ref $param, message => Data::Dumper::Dumper($param) };
    }
    elsif ($param =~ /^(.+) at (.+) line (\d+)\.$/) {
        return {
            type      => 'CORE::die',
            message   => $1,
            backtrace => [ { file => $2, line => $3, function => 'N/A' } ],
        };
    }
    else {
        return { type => 'error', message => "$param" };
    }
}

sub to_hash {
    my $self = shift;

    {
        type      => $self->type,
        message   => $self->message,
        backtrace => [
            map {
                +{
                    file     => '' . $_->{file},
                    line     => 0  + $_->{line},
                    function => '' . $_->{function},
                }
            } @{$self->backtrace || []}
        ],
    };
}

1;
__END__

=pod

=head1 NAME

Net::Airbrake::Error - Error

=cut
