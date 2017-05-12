package Net::Hadoop::YARN::Roles::JMX;
$Net::Hadoop::YARN::Roles::JMX::VERSION = '0.202';
use 5.10.0;
use strict;
use warnings;

use Carp  qw( confess );
use Clone qw( clone   );
use Constant::FromGlobal DEBUG => { int => 1, default => 0, env => 1 };
use JSON::XS ();
use Moo::Role;
use Ref::Util qw(
    is_arrayref
    is_coderef
    is_hashref
    is_ref
);
use Scalar::Util qw( blessed );
use Time::HiRes  qw( time );

has 'target_host_port' => (
    is => 'rw',
    default => sub {
        my $self = shift;
        return join q{:}, $self->target_host, $self->target_port;
    }
);

has 'target_host' => (
    is      => 'rw',
    default => sub {
        confess "target_host is not defined";
    }
);

has 'target_port' => (
    is      => 'rw',
    default => sub {
        confess "target_port is not defined";
    }
);

has stats => (
    is      => 'rw',
    default => sub {
        shift->all_available_stats;
    },
    isa => sub {
        my $thing = shift;
        if ( ref $thing ne 'ARRAY' ) {
            confess "$thing must be an ARRAY";
        }
        # TODO: verify somehow
    },
    lazy => 1,
);

has flat => (
    is      => 'rw',
    default => sub { 0 },
    lazy    => 1,
);

has decode_json_substrings => (
    is      => 'rw',
    default => sub { 0 },
    lazy    => 1,
);

sub all_available_stats {
    my $self = shift;
    my $c = $self->clone;
    $c->stats( ['all'] );
    $c->decode_json_substrings( 0 );

    my @names;

    $c->_looper(
        $c->collect,
        sub {
            my($thing, $name_or_index, $is_hash) = @_;
            if ( $is_hash && $name_or_index eq 'ObjectName' ) {
                push @names, $thing->{$name_or_index};
            }
        },
    );

    if ( ! @names ) {
        confess "Failed to collect the avaialble stat names!";
    }

    return [ @names ];
}

sub collect {
    my $self               = shift;
    my $user_defined_stats = shift;
    my $host_port          = $self->target_host_port;

    my @stats = is_arrayref $user_defined_stats
                    ? @{ $user_defined_stats }
                    : @{ $self->stats        }
                ;

    my $has_all = grep { $_ eq 'all'} @stats;

    @stats = qw( all ) if $has_all; # ignore the rest, if any

    my $uri_tmpl = $has_all ? 'http://%s/jmx' : 'http://%s/jmx?qry=%s';
    my $is_flat  = $self->flat;
    my %rv;

    STATS: foreach my $stat ( @stats ) {
        my $uri = sprintf $uri_tmpl, $host_port, ( $has_all ? () : ( $stat ) );
        my $resp;
        eval {
            my $start = time;
            $resp = $self->agent_request( $uri ) || next STATS;
            DEBUG && sprintf "[ %s REST ] Took %.2f seconds\n", ref $self, time - $start;
            1;
        } or do {
            my $eval_error = $@ || 'Zombie error';
            my $msg = "Error from $host_port: $eval_error";
            die $msg;
        };

        next if ! keys %{ $resp };

        if ( $is_flat ) {
            if ( $has_all ) {
                foreach my $bean ( @{ $resp->{beans} } ) {
                    my $name = $bean->{ObjectName} || $bean->{name};
                    $rv{ $name } = $bean;
                }
            }
            else {
                $rv{ $stat } = $resp;
            }
            next STATS;
        }

        if ( $has_all ) {
            foreach my $bean ( @{ $resp->{beans} } ) {
                my $name = $bean->{ObjectName} || $bean->{name};
                $self->_expand( $name, $bean, \%rv );
            }
        }
        else {
            $self->_expand( $stat, $resp, \%rv );
        }
    }

    if ( $self->decode_json_substrings ) {
        $self->_expand_json_substrings_in_place( \%rv );
    }

    return \%rv;
}

sub _expand {
    my $self      = shift;
    my $stat_name = shift;
    my $response  = shift;
    my $rv        = shift;

    my @names = split m{ [.,=:] }xms, $stat_name;

    if ( @names > 1 ) {
        my $slot = $rv->{ shift @names } ||= {};

        while ( my $name = shift @names ) {
            if ( @names ) {
                $slot = $slot->{ $name } ||= {};
            }
            else {
                $slot->{$name} = $response;
            }
        }
    }
    else {
        $rv->{ $stat_name } = $response;
    }

    return;
}

sub _expand_json_substrings_in_place {
    my $self = shift;
    my $rv   = shift || die "No data set specified!";

    my $re_json = qr{ \A \{\" }xms;
    my $callback = sub {
        my($thing, $name_or_index, $is_hash) = @_;
        if ( $is_hash ) {
            my $item = $thing->{ $name_or_index };
            if ( $item =~ $re_json ) {
                $thing->{ $name_or_index } = JSON::XS::decode_json( $item ); # loop?
            }
        }
        else {
            my $item = $thing->[ $name_or_index ];
            # Array: We don't seem to have such a thing, but you can never know
            if ( $item =~ $re_json ) {
                $thing->[ $name_or_index ] = JSON::XS::decode_json( $item ); # loop?
            }
        }
        return;
    };

    $self->_looper( $rv, $callback );

    return;
}

sub _looper {
    my $self = shift;
    my $rv   = shift || die 'No data was specified!';
    my $callback = shift;

    if ( ! is_coderef $callback ) {
        die "callback needs to be a CODE ref";
    }

    my $looper;
    $looper = sub {
        my $thing = shift;
        my $cb    = shift;

        if ( is_hashref $thing ) {
            LOOPH: foreach my $name ( keys %{ $thing } ) {
                my $item = $thing->{ $name } || next;
                if ( is_ref $item ) {
                    $looper->( $item );
                    next LOOPH;
                }
                $callback->( $thing, $name, 1 );
            }
        }
        elsif ( is_arrayref $thing ) {
            LOOPA: foreach my $i ( 0.. $#{ $thing } ) {
                my $item = $thing->[ $i ];
                if ( ref $item ) {
                    $looper->( $item );
                    next LOOPA;
                }
                $callback->( $thing, $i );
            }
        }
        elsif ( is_ref $thing ) {
            if ( blessed $thing && $thing->isa('JSON::PP::Boolean') ) {
                return;
            }
            die "Unknown key: $thing";
        }
        else {
            die "$thing is not a reference!";
        }
    };

    $looper->( $rv, $callback );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Hadoop::YARN::Roles::JMX

=head1 VERSION

version 0.202

=head1 SYNOPSIS

    -

=head1 DESCRIPTION

JMX helpers for YARN endpoints.

=head1 METHODS

=head2 all_available_stats

=head2 collect

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Morel & Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
