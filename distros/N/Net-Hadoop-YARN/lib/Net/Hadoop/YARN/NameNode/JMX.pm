package Net::Hadoop::YARN::NameNode::JMX;
$Net::Hadoop::YARN::NameNode::JMX::VERSION = '0.203';
use 5.10.0;
use strict;
use warnings;
use Ref::Util qw( is_arrayref );

use Moo;

my $RE_TIMEOUT = qr{ \Q500 read timeout\E }xms;
my $RE_DEAD    = qr{ \Q500 Can't connect to\E .+? \QConnection refused\E }xms;

has namenodes => (
    is      => 'rw',
    default => sub {
        die "namenodes not specified";
    },
    isa => sub {
        if ( ! is_arrayref $_[0] ) {
            die "namenodes needs to be an ARRAY";
        }
        if ( ! @{ $_[0] } ) {
            die "namenodes needs at least one element";
        }
    },
);

sub active_namenode {
    my $self = shift;
    my $opt  = ref $_[0] eq 'HASH' ? shift @_ : {};
    my($rv, $try);
    NN_TRY: {
        NN_PROBE: foreach my $nn ( @{ $self->namenodes } ) {
            my $uri = sprintf 'http://%s/jmx?qry=Hadoop:service=NameNode,name=FSNamesystem', $nn;
            my $jmx;
            eval {
                $jmx = $self->agent_request( $uri );
                1;
            } or do {
                my $eval_error = $@ || 'Zombie error';
                if (
                       $eval_error =~ $RE_TIMEOUT
                    || $eval_error =~ $RE_DEAD
                ) {
                    next NN_PROBE;
                }
                die sprintf 'Error while probing the name node `%s`: %s',
                                ( split m{ [:] }xms, $nn, 2 )[0],
                                $eval_error,
                ;
            };
            next NN_PROBE if ref $jmx ne 'HASH';
            my $status = $jmx->{beans}[0]{'tag.HAState'};
            next NN_PROBE if ! $status || $status ne 'active';

            if ( $opt->{real_hostname} ) {
                $rv = $jmx->{beans}[0]{'tag.Hostname'} || die "Unable to locate tag.Hostname from JMX";
                if ( ! $opt->{hostname_only} ) {
                    $rv .= ':' . (split m{ [:] }xms, $nn )[1]
                }
            }
            else {
                $rv = $nn;
            }

            last NN_PROBE;
        }
        if ( ! $rv ) {
            if ( ++$try <= 1 ) {
                sleep 1;
                redo NN_TRY;
            }
            die sprintf 'Failed to locate the active namenode (tried %s times)', $try;
        }
    }

    return $opt->{hostname_only} ? (split m{ [:] }xms, $rv )[0] : $rv;
}

sub startupProgress {
    my $self = shift;
    my @nn   = @{ $self->namenodes };
    my $uri_tmpl = 'http://%s/%s';

    NAME_NODE: while ( my $nn = shift @nn ) {
        my $uri  = sprintf $uri_tmpl, $nn, 'startupProgress';
        my $resp;
        eval {
            $resp = $self->agent_request( $uri );
            1;
        } or do {
            my $eval_error = $@ || 'Zombie error';
            my $msg = "Error from $nn: $eval_error";

            # TODO:
            # if ( $eval_error =~ $failover_or_passive_or_whatever ) {
            #     warn $msg; @rv = (); next NAME_NODE;
            # }
            #

            die $msg;
        };

        return $resp;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Hadoop::YARN::NameNode::JMX

=head1 VERSION

version 0.203

=head1 SYNOPSIS

    my $nn = Net::Hadoop::YARN::NameNode::JMX->new( %opt );

=head1 DESCRIPTION

YARN NameNode JMX methods.

=head1 METHODS

=head2 active_namenode

    my $active_host_port = $nn->active_namenode;
    my $active_host      = $nn->active_namenode({ hostname_only => 1 });

=head2 startupProgress

    my $sup = $nn->startupProgress;

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Morel & Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
