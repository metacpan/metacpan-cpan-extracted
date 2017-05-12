package Prophet::CLI::Command::Info;
{
  $Prophet::CLI::Command::Info::VERSION = '0.751';
}
use Any::Moose;
extends 'Prophet::CLI::Command';

sub ARG_TRANSLATIONS { shift->SUPER::ARG_TRANSLATIONS(), l => 'local' }

sub usage_msg {
    my $self = shift;
    my $cmd  = $self->cli->get_script_name;

    return <<"END_USAGE";
usage: ${cmd}info
END_USAGE
}

sub run {
    my $self = shift;

    $self->print_usage if $self->has_arg('h');

    print "Records Database\n";
    print "----------------\n";

    print "Location:      "
      . $self->handle->url
      . " (@{[ref($self->handle)]})\n";
    print "Database UUID: " . $self->handle->db_uuid . "\n";
    print "Replica UUID:  " . $self->handle->uuid . "\n";
    print "Changesets:    " . $self->handle->latest_sequence_no . "\n";
    print "Known types:   "
      . join( ',', @{ $self->handle->list_types } ) . "\n\n";

    print "Resolutions Database\n";
    print "--------------------\n";

    print "Location:      "
      . $self->handle->resolution_db_handle->url
      . " (@{[ref($self->handle)]})\n";
    print "Database UUID: "
      . $self->handle->resolution_db_handle->db_uuid . "\n";
    print "Replica UUID:  " . $self->handle->resolution_db_handle->uuid . "\n";
    print "Changesets:    "
      . $self->handle->resolution_db_handle->latest_sequence_no . "\n";

    # known types get very unwieldy for resolutions
    # print "Known types:   "
    #     .join(',', @{$self->handle->resolution_db_handle->list_types} )."\n";
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::CLI::Command::Info

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
