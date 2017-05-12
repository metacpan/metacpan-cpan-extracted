package Pg::CLI::pg_config;
{
  $Pg::CLI::pg_config::VERSION = '0.11';
}

use Moose;

use namespace::autoclean;

use MooseX::SemiAffordanceAccessor;
use MooseX::Types::Moose qw( HashRef Maybe Str );

with 'Pg::CLI::Role::Executable';

has _config_info => (
    is       => 'ro',
    isa      => HashRef [ Maybe [Str] ],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_config_info',
);

my @attrs = qw(
    bindir
    cc
    cflags
    cflags_sl
    configure
    cppflags
    docdir
    htmldir
    includedir
    includedir_server
    ldflags
    ldflags_sl
    libdir
    libs
    localedir
    mandir
    pgxs
    pkgincludedir
    pkglibdir
    sharedir
    sysconfdir
    version
);

for my $attr (@attrs) {
    has $attr => (
        is       => 'ro',
        isa      => Maybe[Str],
        init_arg => undef,
        lazy     => 1,
        default  => sub { $_[0]->_config_info()->{$attr} },
    );
}

sub _build_config_info {
    my $self = shift;

    my %info;
    for my $line ( $self->_pg_config_output() ) {
        chomp $line;
        my ( $key, $val ) = split / = /, $line, 2;

        $key =~ s/-/_/;

        $info{ lc $key } = $val =~ /\S/ ? $val : undef;
    }

    return \%info;
}

# Separate method so it can be overridden for tests
sub _pg_config_output {
    my $self = shift;

    my $command = $self->executable();

    return `$command`;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Wrapper for the F<psql> utility

__END__

=pod

=head1 NAME

Pg::CLI::pg_config - Wrapper for the F<psql> utility

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  my $pg_config = Pg::CLI::pg_config->new();

  print $pg_config()->sharedir();
  print $pg_config()->version();

=head1 DESCRIPTION

This class provides a wrapper for the F<pg_config> utility.

=head1 METHODS

This class provides the following methods:

=head2 Pg::CLI::pg_config->new()

The constructor accepts one parameter:

=over 4

=item * executable

The path to F<pg_config>. By default, this will look for F<pg_config> in your
path and throw an error if it cannot be found.

=back

=head2 Config Info Methods

This class provides the following methods, each of which returns the relevant
configuration info. If there was no value for the item, the method returns
C<undef>.

=over 4

=item * $pg_config->bindir()

=item * $pg_config->cc()

=item * $pg_config->cflags()

=item * $pg_config->cflags_sl()

=item * $pg_config->configure()

=item * $pg_config->cppflags()

=item * $pg_config->docdir()

=item * $pg_config->htmldir()

=item * $pg_config->includedir()

=item * $pg_config->includedir_server()

=item * $pg_config->ldflags()

=item * $pg_config->ldflags_sl()

=item * $pg_config->libdir()

=item * $pg_config->libs()

=item * $pg_config->localedir()

=item * $pg_config->mandir()

=item * $pg_config->pgxs()

=item * $pg_config->pkgincludedir()

=item * $pg_config->pkglibdir()

=item * $pg_config->sharedir()

=item * $pg_config->sysconfdir()

=item * $pg_config->version()

=back

=head1 BUGS

See L<Pg::CLI> for bug reporting details.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
