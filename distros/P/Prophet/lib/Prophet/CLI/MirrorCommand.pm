package Prophet::CLI::MirrorCommand;
{
  $Prophet::CLI::MirrorCommand::VERSION = '0.751';
}
use Any::Moose 'Role';
with 'Prophet::CLI::ProgressBar';
use Params::Validate ':all';

sub get_cache_for_source {
    my $self = shift;
    my ($source) = validate_pos( @_, { isa => 'Prophet::Replica' } );
    my $target = Prophet::Replica->get_handle(
        url        => 'prophet_cache:' . $source->uuid,
        app_handle => $self->app_handle
    );

    if ( !$target->replica_exists && !$target->can_initialize ) {
        die "The target replica path you specified can't be created.\n";
    }

    $target->initialize_from_source($source);
    return $target;
}

sub sync_cache_from_source {
    my $self = shift;
    my %args = validate(
        @_,
        {
            target => { isa => 'Prophet::Replica::prophet_cache' },
            source => { isa => 'Prophet::Replica' }
        }
    );

    if ( $args{target}->latest_sequence_no ==
        $args{source}->latest_sequence_no )
    {
        print "Mirror of " . $args{source}->url . " is already up to date\n";
        return;
    }

    print "Mirroring resolutions from " . $args{source}->url . "\n";
    $args{target}->resolution_db_handle->mirror_from(
        source             => $args{source}->resolution_db_handle,
        reporting_callback => $self->progress_bar(
            max =>
              ( $args{source}->resolution_db_handle->latest_sequence_no || 0 )
        )
    );
    print "\nMirroring changesets from " . $args{source}->url . "\n";
    $args{target}->mirror_from(
        source             => $args{source},
        reporting_callback => $self->progress_bar(
            max => ( $args{source}->latest_sequence_no || 0 )
        )
    );
}

no Any::Moose 'Role';

1;

__END__

=pod

=head1 NAME

Prophet::CLI::MirrorCommand

=head1 VERSION

version 0.751

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
