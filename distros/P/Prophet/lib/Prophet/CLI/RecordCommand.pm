package Prophet::CLI::RecordCommand;
{
  $Prophet::CLI::RecordCommand::VERSION = '0.751';
}
use Any::Moose 'Role';
use Params::Validate;
use Prophet::Record;

has type => (
    is        => 'rw',
    isa       => 'Str',
    required  => 0,
    predicate => 'has_type',
);

has uuid => (
    is        => 'rw',
    isa       => 'Str',
    required  => 0,
    predicate => 'has_uuid',
);

has record_class => (
    is  => 'rw',
    isa => 'Prophet::Record',
);


sub _get_record_object {
    my $self = shift;
    my %args = validate( @_, { type => { default => $self->type }, } );

    my $constructor_args = {
        app_handle => $self->cli->app_handle,
        handle     => $self->cli->handle,
        type       => $args{type},
    };

    if ( $args{type} ) {
        my $class = $self->_type_to_record_class( $args{type} );
        return $class->new($constructor_args);
    } elsif ( my $class = $self->record_class ) {
        Prophet::App->require($class);
        return $class->new($constructor_args);
    } else {
        $self->fatal_error(
            "I couldn't find that record. (You didn't specify a record type.)"
        );
    }
}


sub _load_record {
    my $self   = shift;
    my $record = $self->_get_record_object;
    $record->load( uuid => $self->uuid );

    if ( !$record->exists ) {
        $self->fatal_error(
            "I couldn't find a " . $self->type . ' with that id.' );
    }
    return $record;
}


sub _type_to_record_class {
    my $self = shift;
    my $type = shift;
    my $try  = $self->cli->app_class . "::Model::" . ucfirst( lc($type) );
    Prophet::App->try_to_require($try);    # don't care about fails
    return $try if ( $try->isa('Prophet::Record') );

    $try = $self->cli->app_class . "::Record";
    Prophet::App->try_to_require($try);    # don't care about fails
    return $try if ( $try->isa('Prophet::Record') );
    return 'Prophet::Record';
}

no Any::Moose 'Role';

1;

__END__

=pod

=head1 NAME

Prophet::CLI::RecordCommand

=head1 VERSION

version 0.751

=head1 METHODS

=head2 _get_record_object [{ type => 'type' }]

Tries to determine a record class from either the given type argument or the
current object's C<$type> attribute.

Returns a new instance of the record class on success, or throws a fatal error
with a stack trace on failure.

=head2 _load_record

Attempts to load the record specified by the C<uuid> attribute.

Returns the loaded record on success, or throws a fatal error if no record can
be found.

=head2 _type_to_record_class $type

Takes a type and tries to figure out a record class name from it. Returns
C<'Prophet::Record'> if no better class name is found.

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
