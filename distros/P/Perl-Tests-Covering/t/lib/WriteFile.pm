package WriteFile;

use 5.014;

use strict;
use warnings FATAL => 'all';

use File::Basename qw{dirname};
use File::Path     qw{make_path};
use File::Spec     ();

use parent qw{Exporter};
our @EXPORT_OK = qw{write_file};

=head1 NAME

WriteFile - write a file of a fake distribution, for the tests

=head1 FUNCTIONS

=head2 write_file

    my $path = write_file( $root, 'lib/Foo.pm', "package Foo; 1;\n" );

Writes $content to $rel under $root, making the directories on the way, and
returns the path.  It dies when it cannot.

=cut

sub write_file {
    my ( $root, $rel, $content ) = @_;
    my $path = File::Spec->catfile( $root, $rel );
    make_path( dirname($path) );
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print {$fh} $content;
    close $fh or die "Cannot close $path: $!";
    return $path;
}

1;
