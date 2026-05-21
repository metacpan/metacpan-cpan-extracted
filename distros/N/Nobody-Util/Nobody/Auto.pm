package Nobody::Auto;
use strict;
use warnings;

our $VERSION = '0.01';

# Nobody::Auto - auto-install missing CPAN modules at runtime.
#
# Usage:
#   use lib '/path/to/lib';
#   use Nobody::Auto qw( JSON::PP HTTP::Tiny Some::Module );
#
# For each module listed, Nobody::Auto will:
#   1. Try to load it with require().
#   2. If that fails, shell out to cpanm --notest to install it.
#   3. Try to load it again; die if it still fails.
#
# After the first successful run everything is already installed, so
# subsequent starts are fast: require() succeeds immediately and cpanm
# is never called.

sub import {
    my ($class, @modules) = @_;

    for my $mod (@modules) {
        # Convert module name to file path (Foo::Bar -> Foo/Bar.pm)
        (my $file = $mod) =~ s{::}{/}g;
        $file .= '.pm';

        # Already loaded?
        next if $INC{$file};

        # Try loading it
        eval { require $file };
        next unless $@;  # loaded fine

        # Not found - install via cpanm
        warn "Nobody::Auto: $mod not found, installing via cpanm...\n";
        my $rc = system('cpanm', '--notest', '--quiet', $mod);
        if ($rc != 0) {
            die "Nobody::Auto: cpanm failed to install $mod (exit $rc)\n";
        }

        # Try again after install
        eval { require $file };
        if ($@) {
            die "Nobody::Auto: installed $mod but still cannot load it: $@\n";
        }

        warn "Nobody::Auto: $mod installed and loaded.\n";
    }
}

1;

__END__

=head1 NAME

Nobody::Auto - auto-install missing CPAN modules at runtime

=head1 SYNOPSIS

  use lib 'lib';
  use Nobody::Auto qw( JSON::PP HTTP::Tiny IO::Socket::UNIX );

=head1 DESCRIPTION

Lists modules as arguments to C<use Nobody::Auto>.  Each one is checked
with C<require>; any that are missing are installed via C<cpanm --notest>
and then loaded.  On subsequent runs the C<require> succeeds immediately
and C<cpanm> is never invoked.

Requires C<cpanm> (App::cpanminus) to be available in C<$PATH>.

=head1 AUTHOR

Nobody Does AI

=cut
