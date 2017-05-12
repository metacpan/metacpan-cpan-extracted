package Prophet::ConflictingPropChange;
{
  $Prophet::ConflictingPropChange::VERSION = '0.751';
}

# ABSTRACT: Conflicting property changes

use Any::Moose;


has name => (
    is  => 'rw',
    isa => 'Str',
);


has source_old_value => (
    is  => 'rw',
    isa => 'Str|Undef',
);


has target_value => (
    is  => 'rw',
    isa => 'Str|Undef',
);


has source_new_value => (
    is  => 'rw',
    isa => 'Str|Undef',
);

sub as_hash {
    my $self    = shift;
    my $hashref = {};

    for (qw(name source_old_value target_value source_new_value)) {
        $hashref->{$_} = $self->$_;
    }
    return $hashref;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::ConflictingPropChange - Conflicting property changes

=head1 VERSION

version 0.751

=head1 DESCRIPTION

Objects of this class describe a case when a property change can not be
cleanly applied to a replica because the old value for the property locally did
not match the "begin state" of the change being applied.

=head1 ATTRIBUTES

=head2 name

The property name for the conflict in question

=head2 source_old_value

The inital (old) state from the change being merged in

=head2 target_value

The current target-replica value of the property being merged.

=head2 source_new_value

The final (new) state of the property from the change being merged in.

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
