package Prophet::Collection;
{
  $Prophet::Collection::VERSION = '0.751';
}

# ABSTRACT: Collections of L<Prophet::Record> objects

use Any::Moose;
use Params::Validate;
use Prophet::Record;

use overload '@{}' => sub { shift->items }, fallback => 1;
use constant record_class => 'Prophet::Record';

has app_handle => (
    is       => 'rw',
    isa      => 'Prophet::App|Undef',
    required => 0,
    trigger  => sub {
        my ( $self, $app ) = @_;
        $self->handle( $app->handle );
    },
);

has handle => (
    is  => 'rw',
    isa => 'Prophet::Replica',
);

has type => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->record_class->new( app_handle => $self->app_handle )
          ->record_type;
    },
);


has items => (
    is         => 'rw',
    isa        => 'ArrayRef',
    default    => sub { [] },
    auto_deref => 1,
);

sub count { scalar @{ $_[0]->items } }

sub add_item {
    my $self = shift;
    push @{ $self->items }, @_;
}


sub matching {
    my $self    = shift;
    my $coderef = shift;

    # return undef unless $self->handle->type_exists( type => $self->type );
    # find all items,
    Carp::cluck unless defined $self->type;

    my $records = $self->handle->list_records(
        record_class => $self->record_class,
        type         => $self->type
    );

    # run coderef against each item;
    # if it matches, add it to items
    for my $record (@$records) {
        $self->add_item($record) if ( $coderef->($record) );
    }

    # XXX TODO return a count of items found

}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::Collection - Collections of L<Prophet::Record> objects

=head1 VERSION

version 0.751

=head1 DESCRIPTION

This class allows the programmer to search for L<Prophet::Record> objects
matching certain criteria and to operate on those records as a collection.

=head1 ATTRIBUTES

=head2 items

Returns a reference to an array of all the items found

=head1 METHODS

=head2 matching $CODEREF

Find all L<Prophet::Record>s of this collection's C<type> where $CODEREF
returns true.

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
