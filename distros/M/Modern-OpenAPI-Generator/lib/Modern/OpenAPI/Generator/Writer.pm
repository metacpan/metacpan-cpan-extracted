package Modern::OpenAPI::Generator::Writer;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use File::Path qw(make_path);
use File::Spec ();
use Path::Tiny qw(path);

sub new {
    my ( $class, %arg ) = @_;
    bless {
        root  => path( $arg{root} )->stringify,
        force => $arg{force} // 0,
        merge => $arg{merge} // 0,
    }, $class;
}

sub write {
    my ( $self, $rel, $content ) = @_;
    croak "Writer: empty rel" unless defined $rel && length $rel;
    my $full = path( $self->{root} )->child($rel);
    $full->parent->mkpath( { mode => 0755 } );

    if ( -e $full && $self->{merge} && !$self->{force} ) {
        return;
    }
    if ( -e $full && !$self->{force} && !$self->{merge} ) {
        croak "Refusing to overwrite $full (use --force)";
    }

    $full->spew_utf8($content);
    return $full;
}

1;

__END__

=encoding utf8

=head1 NAME

Modern::OpenAPI::Generator::Writer - Write generated files under a root directory

=head1 DESCRIPTION

Respects C<force> (overwrite) and C<merge> (skip existing files unless C<force>).

=head2 new

Constructor. Keys: C<root> (output tree root), optional C<force>, C<merge>.

=head2 write

Writes C<$content> to C<$rel> relative to C<root>, creating parent directories.
Returns a L<Path::Tiny> object for the file, or nothing when C<merge> skips an
existing path.

=cut
