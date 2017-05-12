package Prophet::CLI::Command::Update;
{
  $Prophet::CLI::Command::Update::VERSION = '0.751';
}
use Any::Moose;
extends 'Prophet::CLI::Command';
with 'Prophet::CLI::RecordCommand';

sub ARG_TRANSLATIONS { shift->SUPER::ARG_TRANSLATIONS(), e => 'edit' }

sub usage_msg {
    my $self = shift;
    my ( $cmd, $type_and_subcmd ) = $self->get_cmd_and_subcmd_names;

    return <<"END_USAGE";
usage: ${cmd}${type_and_subcmd} <record-id> --edit
       ${cmd}${type_and_subcmd} <record-id> -- prop1="new value"
END_USAGE
}

sub edit_record {
    my $self   = shift;
    my $record = shift;

    my $props = $record->get_props;

    # don't feed in existing values if we're not interactively editing
    my $defaults = $self->has_arg('edit') ? $props : undef;

    my @ordering = ();

    # we want props in $record->props_to_show to show up in the editor if --edit
    # is supplied too
    if ( $record->can('props_to_show') && $self->has_arg('edit') ) {
        @ordering = $record->props_to_show;
        map { $props->{$_} = '' if !exists( $props->{$_} ) } @ordering;
    }

    return $self->edit_props(
        arg      => 'edit',
        defaults => $defaults,
        ordering => \@ordering
    );
}

sub run {
    my $self = shift;

    $self->print_usage if $self->has_arg('h');

    $self->require_uuid;
    my $record = $self->_load_record;

    my $new_props = $self->edit_record($record);

    # filter out props that haven't changed
    for my $prop ( keys %$new_props ) {
        my $old_prop =
          defined $record->prop($prop) ? $record->prop($prop) : '';
        delete $new_props->{$prop} if ( $old_prop eq $new_props->{$prop} );
    }

    if ( keys %$new_props ) {
        my $result = $record->set_props( props => $new_props );

        if ($result) {
            print ucfirst( $record->type ) . " "
              . $record->luid . " ("
              . $record->uuid . ")"
              . " updated.\n";

        } else {
            print "SOMETHING BAD HAPPENED "
              . $record->type . " "
              . $record->luid . " ("
              . $record->uuid
              . ") not updated.\n";
        }
    } else {
        print "No properties changed.\n";
    }
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::CLI::Command::Update

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
