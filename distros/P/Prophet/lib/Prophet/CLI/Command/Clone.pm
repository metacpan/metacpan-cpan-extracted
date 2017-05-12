package Prophet::CLI::Command::Clone;
{
  $Prophet::CLI::Command::Clone::VERSION = '0.751';
}
use Any::Moose;
extends 'Prophet::CLI::Command::Merge';

sub usage_msg {
    my $self = shift;
    my $cmd  = $self->cli->get_script_name;

    return <<"END_USAGE";
usage: ${cmd}clone --from <url> [--as <alias>] | --local
END_USAGE
}

sub run {
    my $self = shift;

    $self->print_usage if $self->has_arg('h');

    if ( $self->has_arg('local') ) {
        $self->list_bonjour_sources;
        return;
    }

    $self->validate_args();

    $self->set_arg( 'to' => $self->app_handle->handle->url() );

    $self->target(
        Prophet::Replica->get_handle(
            url        => $self->arg('to'),
            app_handle => $self->app_handle,
        )
    );

    if ( $self->target->replica_exists ) {
        die "The target replica already exists.\n";
    }

    if ( !$self->target->can_initialize ) {
        die "The target replica path you specified can't be created.\n";
    }

    $self->source(
        Prophet::Replica->get_handle(
            url        => $self->arg('from'),
            app_handle => $self->app_handle,
        )
    );

    my %init_args;
    if ( $self->source->isa('Prophet::ForeignReplica') ) {
        $self->target->after_initialize(
            sub { shift->app_handle->set_db_defaults } );
    } else {
        %init_args = (
            db_uuid    => $self->source->db_uuid,
            resdb_uuid => $self->source->resolution_db_handle->db_uuid,
        );
    }

    unless ( $self->source->replica_exists ) {
        die
          "The source replica '@{[$self->source->url]}' doesn't exist or is unreadable.\n";
    }

    $self->target->initialize(%init_args);

    # create new config section for this replica
    my $from     = $self->arg('from');
    my $alias    = $self->arg('as');
    my $base_key = $alias ? 'replica.' . $alias : 'replica.' . $from;

    $self->app_handle->config->group_set(
        $self->app_handle->config->replica_config_file,
        [
            {
                key   => $base_key . '.url',
                value => $self->arg('from'),
            },
            {
                key   => $base_key . '.uuid',
                value => $self->target->uuid,
            },
        ]
    );

    if ( $self->source->can('database_settings') ) {
        my $remote_db_settings = $self->source->database_settings;
        my $default_settings   = $self->app_handle->database_settings;
        for my $name ( keys %$remote_db_settings ) {
            my $uuid = $default_settings->{$name}[0];
            die $name unless $uuid;
            my $s = $self->app_handle->setting( uuid => $uuid );
            $s->set( $remote_db_settings->{$name} );
        }
    }

    $self->SUPER::run();
}

sub validate_args {
    my $self = shift;

    unless ( $self->has_arg('from') ) {
        warn "No --from specified!\n";
        die $self->print_usage;
    }
}

# When we clone from another replica, we ALWAYS want to take their way forward,
# even when there's an insane, impossible conflict
#
sub merge_resolver {'Prophet::Resolver::AlwaysTarget'}


sub list_bonjour_sources {
    my $self = shift;
    my @bonjour_sources;

    Prophet::App->try_to_require('Net::Bonjour');
    if ( Prophet::App->already_required('Net::Bonjour') ) {
        print "Probing for local sources with Bonjour\n\n";
        my $res = Net::Bonjour->new('prophet');
        $res->discover;
        my $count = 0;
        for my $entry ( $res->entries ) {
            require URI;
            my $uri = URI->new();
            $uri->scheme('http');
            $uri->host( $entry->hostname );
            $uri->port( $entry->port );
            $uri->path('replica/');
            print '  * ' . $uri->canonical . ' - ' . $entry->name . "\n";
            $count++;
        }

        if ($count) {
            print "\nFound $count source" . ( $count == 1 ? '' : 's' ) . "\n";
        } else {
            print "No local sources found.\n";
        }
    }

    return;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::CLI::Command::Clone

=head1 VERSION

version 0.751

=head1 METHODS

=head2 list_bonjour_sources

Probes the local network for bonjour replicas if the local arg is specified.

Prints a list of all sources found.

=head1 AUTHORS

=over 4

=item *

Jesse Vincent <jesse@bestpractical.com>

=item *

Chia-Liang Kao <clkao@bestpractical.com>

=item *

Christine Spang <christine@spang.cc>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Best Practical Solutions.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Prophet>.

=head1 CONTRIBUTORS

=over 4

=item *

Alex Vandiver <alexmv@bestpractical.com>

=item *

Casey West <casey@geeknest.com>

=item *

Cyril Brulebois <kibi@debian.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Jonas Smedegaard <dr@jones.dk>

=item *

Kevin Falcone <falcone@bestpractical.com>

=item *

Lance Wicks <lw@judocoach.com>

=item *

Nelson Elhage <nelhage@mit.edu>

=item *

Pedro Melo <melo@simplicidade.org>

=item *

Rob Hoelz <rob@hoelz.ro>

=item *

Ruslan Zakirov <ruz@bestpractical.com>

=item *

Shawn M Moore <sartak@bestpractical.com>

=item *

Simon Wistow <simon@thegestalt.org>

=item *

Stephane Alnet <stephane@shimaore.net>

=item *

Unknown user <nobody@localhost>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=item *

franck cuny <franck@lumberjaph.net>

=item *

robertkrimen <robertkrimen@gmail.com>

=item *

sunnavy <sunnavy@bestpractical.com>

=back

=cut
