package Net::Hadoop::YARN::ResourceManager::Scheduler::UserApps;
$Net::Hadoop::YARN::ResourceManager::Scheduler::UserApps::VERSION = '0.202';
use 5.10.0;
use strict;
use warnings;

use Data::Dumper   ();
use Moo;
use POSIX          ();
use Ref::Util      ();
use Scalar::Util   ();
use Time::Duration ();
use Net::Hadoop::YARN::ResourceManager;

has rm_object => (
    is       => 'rw',
    isa      => sub {
        my $thing = shift;
        my $type  = 'Net::Hadoop::YARN::ResourceManager';
        if (   ! $thing
            || ! Scalar::Util::blessed $thing
            || ! $thing->isa( $type )
        ) {
            die "rm_object is not a $type";
        }
    },
    default => sub {
        Net::Hadoop::YARN::ResourceManager->new(
            ( $ENV{YARN_RESOURCE_MANAGER} ? (
                servers => [ split /,/, $ENV{YARN_RESOURCE_MANAGER} ]
            ) : () )
        );
    },
);

sub collect {
    my $self = shift;
    my $user = shift || die "No user name was specified";

    my $apps = $self->rm_object->apps( user => $user );

    if ( ! Ref::Util::is_arrayref $apps ) {
        if ( Ref::Util::is_hashref $apps ) {
            if ( my $check = $apps->{apps} ) {
                if ( ! keys %{ $check }) {
                    $apps = [];
                }
                else {
                    die sprintf "[TODO-1] Don't know what to do with %s",
                                Data::Dumper::Dumper [ $user => $apps ],
                    ;
                }
            }
        }
        else {
            die sprintf "[TODO-2] Don't know what to do with %s",
                            Data::Dumper::Dumper [ $user => $apps ],
            ;
        }
    }

    my $format_epoch = sub {
        my $epoch = shift || die "No epoch specified!";
        return POSIX::strftime  "%a %b %d %Y %H:%M:%S %Z", localtime $epoch;
    };

    my %apps_by_state;

    foreach my $app ( @{ $apps } ) {
        foreach my $resource ( qw(
                allocatedMB
                allocatedVCores
        ) ) {
            $app->{ $resource } = 0 if $app->{ $resource } eq '-1';
        }

        if ( $app->{allocatedMB} ) {
            $app->{allocatedMB_fmt} = $self->format_bytes( $app->{allocatedMB} * 1024**2 );
        }

        if ( $app->{allocatedVCores} ) {
            $app->{allocatedVCores_fmt} = sprintf '%s vCore%s',
                                                    $app->{allocatedVCores},
                                                    $app->{allocatedVCores} > 1 ? 's' : '',
            ;
        }

        # TODO
        # [STRING]"applicationTags"
        # the value is something like "oozie-59a27f107d250c9822fd45e87fd40db8"
        # which is not the job id.

        foreach my $hash_or_string ( qw(
            diagnostics
            applicationTags
        )) {
            next if ! exists $app->{ $hash_or_string };
            # This is a bug in the REST layer
            if (   Ref::Util::is_hashref $app->{ $hash_or_string }
                && ! keys %{ $app->{ $hash_or_string } }
            ) {
                $app->{ $hash_or_string } = '';
            }
        }

        # https://www.cloudera.com/documentation/enterprise/latest/topics/cm_dg_yarn_applications.html
        foreach my $duration_field ( qw(
            vcoreSeconds
            elapsedTime
            memorySeconds
        ) ) {
            next if ! exists $app->{ $duration_field };
            if ( $app->{ $duration_field } ) {
                $app->{ $duration_field . '_fmt' } = Time::Duration::duration(
                                                         $duration_field eq 'elapsedTime'
                                                            ? $app->{ $duration_field } / 1000
                                                            : $app->{ $duration_field }
                                                    );
            }
        }

        foreach my $time_field ( qw(
            finishedTime
            startedTime
        ) ) {
            next if ! exists $app->{ $time_field };
            if ( $app->{ $time_field } ) {
                $app->{ $time_field . '_fmt' } = $format_epoch->( $app->{ $time_field } / 1000);
            }
        }

        if ( $app->{name} =~ m{ \Q-oozie-oozi-W\E \z }xms ) {
            my %name = map  { @{ $_ } > 1 ? @{ $_ } : ( $_->[0] => 1 ) }
                        map { [ split m{ [=] }xms, $_, 2 ] }
                        split m{ [:] }xms, $app->{name};
            $name{workflow_name} = delete $name{W} if $name{W};
            $name{action_name}   = delete $name{A} if $name{A};
            $name{action_type}   = delete $name{T} if $name{T};
            $name{id}            = delete $name{ID} if $name{ID};
            $app->{oozie_meta} = \%name;
            $app->{oozie_id}   = $name{id} if $name{id};
        }

        push @{ $apps_by_state{ $app->{state} } ||= [] }, $app;
    }

    my %total_res;
    foreach my $app ( @{ $apps_by_state{RUNNING} }) {
        $total_res{allocatedMB}     += $app->{allocatedMB};
        $total_res{allocatedVCores} += $app->{allocatedVCores};
    }

    if ( $total_res{allocatedMB} ) {
        $total_res{allocatedMB_fmt} = $self->format_bytes( $total_res{allocatedMB} * 1024**2 );
    }

    if ( $total_res{allocatedVCores} ) {
        $total_res{allocatedVCores_fmt} = sprintf '%s vCore%s',
                                                $total_res{allocatedVCores},
                                                $total_res{allocatedVCores} > 1 ? 's' : '',
        ;
    }

    my @grouped;
    foreach my $ordered_state (qw(
        RUNNING
        ACCEPTED
        FINISHED
        KILLED
        FAILED
    )) {
        push @grouped, {
            state     => lc( $ordered_state ),
            state_fmt => ucfirst( lc $ordered_state ),
            apps      => delete( $apps_by_state{$ordered_state} )  || [],
        },
    }

    # TODO: possibly needs to be removed if we are sure that the code above
    # is handling all of the possible states. So, this is a "just in case" part
    #
    push @grouped, {
        state => 'rest',
        apps  => [ map { @{ $_ } } values %apps_by_state ],
    };

    # Spark jobs are returned like this for whatever reason.
    if ( my $apps = $grouped[-1]->{apps} ) {
        if ( Ref::Util::is_arrayref $apps && Ref::Util::is_arrayref $apps->[0] ) {
            $grouped[-1]->{apps} = [ @{ $apps->[0] } ];
        }
    }

    return {
        grouped_apps => [ grep { @{ $_->{apps} } > 0 } @grouped ],
        total_apps   => scalar @{ $apps },
        resources    => \%total_res,
        user         => $user,
    };
}

sub format_bytes {
    my $self  = shift;
    my $bytes = shift;
    return sprintf '%.2f GB', $bytes / 1024**3;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Hadoop::YARN::ResourceManager::Scheduler::UserApps

=head1 VERSION

version 0.202

=head1 SYNOPSIS

    use Net::Hadoop::YARN::ResourceManager::Scheduler::UserApps;
    my $uapps = Net::Hadoop::YARN::ResourceManager::Scheduler::UserApps->new(%opt);
    my $stats = $uapps->collect( $user_name );

=head1 DESCRIPTION

User application stats in the Resource Manager.

=head1 NAME

Net::Hadoop::YARN::ResourceManager::Scheduler::UserApps - User application stats in the Resource Manager

=head1 METHODS

=head2 new

Available options:

=over 4

=item rm_object

The default C<rm_object> (resouce manager) can be overridden with this option.
The object needs to be a subclass of C<Net::Hadoop::YARN::ResourceManager>.

=back

=head2 collect

This method only accepts a user name parameter and it will return back
the statistics for that user's applications.

=head2 format_bytes

This will return the byte-size as a string representation in gigabytes with a
simple division. You may want yo subclass to override if you need a more fine
grained output.

=head1 SEE ALSO

L<Net::Hadoop::YARN::ResourceManager>.

=head1 AUTHOR

Burak Gursoy C<<burakE<64>cpan.org>>

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Morel & Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
