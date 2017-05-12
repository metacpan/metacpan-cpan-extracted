package Prophet::Server::ViewHelpers::Function;
{
  $Prophet::Server::ViewHelpers::Function::VERSION = '0.751';
}

use Template::Declare::Tags;

BEGIN {
    delete ${ __PACKAGE__ . "::" }{meta};
    delete ${ __PACKAGE__ . "::" }{with};
}

use Any::Moose;
use Any::Moose 'Util::TypeConstraints';

has record => (
    isa => 'Prophet::Record',
    is  => 'ro'
);

has action => (
    isa => ( enum [qw(create update delete)] ),
    is => 'ro'
);

has order => ( isa => 'Int', is => 'ro' );

has validate => ( isa => 'Bool', is => 'rw', default => 1);
has canonicalize => ( isa => 'Bool', is => 'rw', default => 1);
has execute => ( isa => 'Bool', is => 'rw', default => 1);

has name => (
    isa => 'Str',
    is  => 'rw',

    #regex    => qr/^(?:|[\w\d]+)$/,
);

sub new {
    my $self = shift->SUPER::new(@_);
    $self->name( ( $self->record->loaded ? $self->record->uuid : 'new' ) . "-"
          . $self->action )
      unless ( $self->name );
    return $self;
}

sub render {
    my $self = shift;
    my %bits = (
        order        => $self->order,
        action       => $self->action,
        type         => $self->record->type,
        class        => ref( $self->record ),
        uuid         => $self->record->uuid,
        validate     => $self->validate,
        canonicalize => $self->canonicalize,
        execute      => $self->execute
    );

    my $string = "|"
      . join( "|", map { $bits{$_} ? $_ . "=" . $bits{$_} : '' } keys %bits )
      . "|";

    outs_raw(
        qq{<input type="hidden" name="prophet-function-@{[$self->name]}" value="$string" />}
    );
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
no Any::Moose;
1;

__END__

=pod

=head1 NAME

Prophet::Server::ViewHelpers::Function

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
