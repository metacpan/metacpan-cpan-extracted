package Prophet::Server::ViewHelpers::ParamFromFunction;
{
  $Prophet::Server::ViewHelpers::ParamFromFunction::VERSION = '0.751';
}

use Template::Declare::Tags;

BEGIN {
    delete ${ __PACKAGE__ . "::" }{meta};
    delete ${ __PACKAGE__ . "::" }{with};
}

use Any::Moose;
use Any::Moose 'Util::TypeConstraints';

has function => (
    isa => 'Prophet::Server::ViewHelpers::Function',
    is  => 'ro'
);

has name          => ( isa => 'Str',                 is => 'rw' );
has prop          => ( isa => 'Str',                 is => 'ro' );
has from_function => ( isa => 'Prophet::Server::ViewHelpers::Function',                 is => 'rw' );
has from_result   => ( isa => 'Str',                 is => 'rw' );
has field         => ( isa => 'Prophet::Web::Field', is => 'rw' );

sub render {
    my $self = shift;

    my $unique_name = $self->_generate_name();

    my $record = $self->function->record;

    my $value =
        "function-"
      . $self->from_function->name
      . "|result-"
      . $self->from_result;

    $self->field(
        Prophet::Web::Field->new(
            name   => $unique_name,
            type   => 'hidden',
            record => $record,
            value  => $value

        )
    );

    outs_raw( $self->field->render_input );
}

sub _generate_name {
    my $self = shift;
    return
        "prophet-fill-function-"
      . $self->function->name
      . "-prop-"
      . $self->prop;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::Server::ViewHelpers::ParamFromFunction

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
