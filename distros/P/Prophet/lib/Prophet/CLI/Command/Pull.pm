package Prophet::CLI::Command::Pull;
{
  $Prophet::CLI::Command::Pull::VERSION = '0.751';
}
use Any::Moose;
extends 'Prophet::CLI::Command::Merge';

sub ARG_TRANSLATIONS { shift->SUPER::ARG_TRANSLATIONS(), l => 'local' }

sub usage_msg {
    my $self = shift;
    my $cmd  = $self->cli->get_script_name;

    return <<"END_USAGE";
usage: ${cmd}pull --from <url|name>
       ${cmd}pull --all
       ${cmd}pull --local
END_USAGE
}

sub run {
    my $self = shift;
    my @from;

    $self->print_usage if $self->has_arg('h');

    Prophet::CLI->end_pager();

    # prefer replica.name.pull-url if it exists, otherwise use
    # replica.name.url
    my %previous_sources_by_name_pull_url =
      $self->app_handle->config->sources( variable => 'pull-url' );
    my %previous_sources_by_name_url = $self->app_handle->config->sources;

    my $explicit_from = '';

    if ( $self->has_arg('from') ) {

        # substitute friendly name -> replica url if we can
        my $url_from_name =
          exists $previous_sources_by_name_pull_url{ $self->arg('from') }
          ? $previous_sources_by_name_pull_url{ $self->arg('from') }
          : exists $previous_sources_by_name_url{ $self->arg('from') }
          ? $previous_sources_by_name_url{ $self->arg('from') }
          : $self->arg('from');

        $explicit_from = $url_from_name;
        push @from, $explicit_from;
    } elsif ( $self->has_arg('all') ) {

        # if a source exists in both hashes, the pull-url version will
        # override the url version
        my %sources =
          ( %previous_sources_by_name_url,
            %previous_sources_by_name_pull_url );
        for my $url ( values %sources ) {
            push @from, $url;
        }
    }

    $self->validate_args;
    $self->set_arg( to => $self->handle->url );

    for my $from ( grep {defined} ( @from, $self->find_bonjour_sources ) ) {
        print "Pulling from $from\n";

        #if ( $self->has_arg('all') || $self->has_arg('local') );
        $self->set_arg( from => $from );
        $self->SUPER::run();
        if ( $self->source->uuid and ( $from eq $explicit_from ) ) {
            $self->record_replica_in_config( $explicit_from,
                $self->source->uuid );
        }
        print "\n";
    }
}

sub validate_args {
    my $self = shift;

    unless ( $self->has_arg('from')
        || $self->has_arg('local')
        || $self->has_arg('all') )
    {
        warn "No --from, --local, or --all specified!\n";
        $self->print_usage;
    }
}


sub find_bonjour_sources {
    my $self = shift;
    my @bonjour_sources;

    # We can't pull from bonjour sources if we don't have a db yet
    return unless $self->app_handle->handle->replica_exists;

    my $db_uuid = $self->arg('db_uuid') || $self->app_handle->handle->db_uuid;

    if ( $self->has_arg('local') ) {
        Prophet::App->try_to_require('Net::Bonjour');
        if ( Prophet::App->already_required('Net::Bonjour') ) {
            print "Probing for local database replicas with Bonjour\n";
            my $res = Net::Bonjour->new('prophet');
            $res->discover;
            for my $entry ( $res->entries ) {
                my $name = $entry->name;
                if ( $name eq $db_uuid || $name =~ m/[(]$db_uuid[)]$/ ) {
                    print "Found a database replica on "
                      . $entry->hostname . "\n";
                    require URI;
                    my $uri = URI->new();
                    $uri->scheme('http');
                    $uri->host( $entry->hostname );
                    $uri->port( $entry->port );
                    $uri->path('replica/');
                    push @bonjour_sources, $uri->canonical . "";    #scalarize
                }
            }
        }

    }
    return @bonjour_sources;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::CLI::Command::Pull

=head1 VERSION

version 0.751

=head1 METHODS

=head2 find_bonjour_sources

Probes the local network for bonjour replicas if the local arg is specified.

Returns a list of found replica URIs.

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
