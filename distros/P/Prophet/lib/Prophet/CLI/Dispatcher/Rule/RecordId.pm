package Prophet::CLI::Dispatcher::Rule::RecordId;
{
  $Prophet::CLI::Dispatcher::Rule::RecordId::VERSION = '0.751';
}
use Any::Moose;
extends 'Path::Dispatcher::Rule::Regex';
with 'Prophet::CLI::Dispatcher::Rule';

use Prophet::CLIContext;

has '+regex' => ( default => sub {qr/^$Prophet::CLIContext::ID_REGEX$/i} );

has type => (
    is  => 'ro',
    isa => 'Str',
);

sub complete {
    my $self = shift;
    my $path = shift->path;

    my $handle = $self->cli->app_handle->handle;

    my @types = $self->type || @{ $handle->list_types };

    my @ids;
    for my $type (@types) {
        push @ids, grep { substr( $_, 0, length($path) ) eq $path }
          map { ( $_->uuid, $_->luid ) } @{
            $handle->list_records(
                type         => $type,
                record_class => $self->cli->record_class,
            )
          };
    }
    return @ids;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::CLI::Dispatcher::Rule::RecordId

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
