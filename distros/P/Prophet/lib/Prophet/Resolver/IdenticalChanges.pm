package Prophet::Resolver::IdenticalChanges;
{
  $Prophet::Resolver::IdenticalChanges::VERSION = '0.751';
}
use Any::Moose;
use Params::Validate qw(:all);
use Prophet::Change;
extends 'Prophet::Resolver';

sub run {
    my $self = shift;
    my ( $conflicting_change, $conflict, $resdb ) = validate_pos(
        @_,
        { isa => 'Prophet::ConflictingChange' },
        { isa => 'Prophet::Conflict' }, 0
    );

    # for everything from the changeset that is the same as the old value of the target replica
    # we can skip applying
    return 0 if $conflicting_change->file_op_conflict;

    my $resolution = Prophet::Change->new_from_conflict($conflicting_change);

    for my $prop_change ( @{ $conflicting_change->prop_conflicts } ) {
        next
          if (
            (
                !defined $prop_change->target_value
                || $prop_change->target_value eq ''
            )

            && ( !defined $prop_change->source_new_value
                || $prop_change->source_new_value eq '' )
          );
        next
          if (  defined $prop_change->target_value
            and defined $prop_change->source_new_value
            and
            ( $prop_change->target_value eq $prop_change->source_new_value ) );
        return 0;
    }

    $conflict->autoresolved(1);

    return $resolution;

}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::Resolver::IdenticalChanges

=head1 VERSION

version 0.751

=head2 attempt_automatic_conflict_resolution

Given a L<Prophet::Conflict> which can not be cleanly applied to a replica, it
is sometimes possible to automatically determine a sane resolution to the
conflict.

=over

=item *

When the new-state of the conflicting change matches the previous head of the
replica.

=item *

When someone else has previously done the resolution and we have a copy of that
hanging around.

=back

In those cases, this routine will generate a L<Prophet::ChangeSet> which
resolves as many conflicts as possible.

It will then update the conclicting changes to mark which
L<Prophet::ConflictingChange>s and L<Prophet::ConflictingPropChanges> have been
automatically resolved.

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
