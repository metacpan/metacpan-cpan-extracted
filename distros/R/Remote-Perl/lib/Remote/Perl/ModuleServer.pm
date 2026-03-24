use v5.36;
package Remote::Perl::ModuleServer;
our $VERSION = '0.005';

use autodie qw(open close);
use File::Spec;

# Searches a list of directories for a module file and returns its source.
#
# new(inc => \@dirs, serve_filter => sub($path){...})
#   inc           -- dirs to search; defaults to \@INC if omitted
#   serve_filter  -- optional callback: receives the resolved file path,
#                    returns true to allow serving, false to deny
# find($filename) -- returns source string, or undef if not found/denied

sub new($class, %args) {
    return bless {
        inc          => $args{inc} // \@INC,
        serve_filter => $args{serve_filter},
    }, $class;
}

# Search for $filename (e.g. 'Foo/Bar.pm') in the configured directories.
# Returns the file's raw bytes, or undef if not found.
# Rejects filenames containing path traversal sequences.
sub find($self, $filename) {
    # Reject any filename with directory traversal components.
    my @parts = File::Spec->splitdir($filename);
    return if grep { $_ eq '..' } @parts;

    for my $dir (@{ $self->{inc} }) {
        # @INC entries can be code refs or objects (handled by Perl itself);
        # we only search plain directory strings.
        next unless defined $dir && !ref($dir) && -d $dir;
        my $path = File::Spec->catfile($dir, @parts);
        if (-f $path) {
            next if $self->{serve_filter} && !$self->{serve_filter}->($path);
            open(my $fh, '<', $path);
            local $/;
            return scalar <$fh>;
        }
    }
    return;
}

1;

__END__

=head1 NAME

Remote::Perl::ModuleServer - serve local modules to the remote executor (internal part of Remote::Perl)

=head1 DESCRIPTION

Handles module-serving requests: locates C<.pm> files in the local C<@INC> and
returns their source, rejecting path-traversal filenames.

=head1 INTERNAL

Not public API.  This is an internal module used by L<Remote::Perl>; its interface
may change without notice.

=cut
