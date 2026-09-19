package FakeDiff;

use 5.014;

use strict;
use warnings FATAL => 'all';

use re '/aa';

use Digest::SHA         ();
use File::Slurper       ();
use File::Slurper::Temp ();
use File::Spec          ();

use parent qw{Exporter};
our @EXPORT_OK = qw{change_lines git_blob};

=head1 NAME

FakeDiff - change lines of a file, and get the diff git would print for it

=head1 FUNCTIONS

=head2 change_lines

    my $diff = change_lines( $root, 'lib/Foo.pm', $line, $count, @new );

Replaces C<$count> lines of the file from line C<$line> with C<@new>, which
have no line ends, and returns the change as C<git diff -U0 --full-index>
would print it.  A C<$count> of 0 puts C<@new> in before line C<$line>, and no
C<@new> deletes.

=cut

sub change_lines {
    my ( $root, $rel, $line, $count, @new ) = @_;

    my $path  = File::Spec->catfile( $root, $rel );
    my $old   = File::Slurper::read_binary($path);
    my @lines = split m/^/, $old;
    my @gone  = splice @lines, $line - 1, $count, map { "$_\n" } @new;
    my $new   = join q{}, @lines;
    File::Slurper::Temp::write_binary( $path, $new );

    # An empty side is numbered by the line before it.
    my $old_range = $count ? "$line,$count"  : ( $line - 1 ) . ',0';
    my $new_range = @new   ? "$line," . @new : ( $line - 1 ) . ',0';
    return join q{}, "diff --git a/$rel b/$rel\n", 'index ', git_blob($old), q{..}, git_blob($new), " 100644\n", "--- a/$rel\n", "+++ b/$rel\n",
      "\@\@ -$old_range +$new_range \@\@\n", ( map { "-$_" } @gone ), ( map { "+$_\n" } @new );
}

=head2 git_blob

The id git gives a file with the content you pass.

=cut

sub git_blob {
    my ($content) = @_;
    return Digest::SHA::sha1_hex( 'blob ' . length($content) . "\0" . $content );
}

1;
