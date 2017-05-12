package Prophet::DatabaseSetting;
{
  $Prophet::DatabaseSetting::VERSION = '0.751';
}
use Any::Moose;
extends 'Prophet::Record';

use Params::Validate;
use JSON;

has default => ( is => 'ro', );

has label => (
    isa => 'Str|Undef',
    is  => 'rw',
);

has '+type' => ( default => '__prophet_db_settings' );

sub BUILD {
    my $self = shift;

    $self->initialize
      unless (
        $self->handle->record_exists(
            uuid => $self->uuid,
            type => $self->type
        )
      );
}

sub initialize {
    my $self = shift;

    $self->set( $self->default );
}

sub set {
    my $self = shift;
    my $entry;

    if ( exists $_[1] || !ref( $_[0] ) ) {
        $entry = [@_];
    } else {
        $entry = shift @_;
    }

    my $content = to_json(
        $entry,
        {
            canonical    => 1,
            pretty       => 0,
            utf8         => 1,
            allow_nonref => 0,
        }
    );

    my %props = (
        content => $content,
        label   => $self->label,
    );

    if (
        $self->handle->record_exists(
            uuid => $self->uuid,
            type => $self->type
        )
      )
    {
        $self->set_props( props => \%props );
    } else {
        $self->_create_record(
            uuid  => $self->uuid,
            props => \%props,
        );
    }
}

sub get_raw {
    my $self    = shift;
    my $content = $self->prop('content');
    return $content;
}

sub get {
    my $self = shift;

    $self->initialize() unless $self->load( uuid => $self->uuid );
    my $content = $self->get_raw;

    my $entry = from_json( $content, { utf8 => 1 } );
    return $entry;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::DatabaseSetting

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
