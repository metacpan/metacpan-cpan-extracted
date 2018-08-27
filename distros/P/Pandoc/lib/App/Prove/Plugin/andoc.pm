package App::Prove::Plugin::andoc;
use 5.014;
use warnings;

our $VERSION = '0.8.8';

use Pandoc;
use File::Temp qw(tempdir);
use Cwd qw(realpath);

sub load {
    my ($class, $p) = @_;
    my ($bin) = @{$p->{args}};
    
    die "Usage: prove -Pandoc=EXECUTABLE ...\n" unless defined $bin;
    die "Pandoc executable not found: $bin\n" unless -x $bin;  

    # dies if executable is not pandoc
    my $pandoc = Pandoc->new($bin);

    my $tmp = tempdir(CLEANUP => 1);
	symlink (realpath($pandoc->bin), "$tmp/pandoc")
        or die "symlinking pandoc failed!\n";
    
 	$ENV{PATH} = "$tmp:".$ENV{PATH};

    if ($p->{app_prove}->{verbose}) {
       print "# pandoc executable set to $bin\n";
    }
}

1;

__END__

=head1 NAME

App::Prove::Plugin::andoc - Select pandoc executable for tests

=head1 SYNOPSIS

  # specify executable
  prove -Pandoc=bin/pandoc-2.1.2 ...

  # specify executable in ~/.pandoc/bin by version
  prove -Pandoc=2.1.2 ...

=head1 DESCRIPTION

This plugin to L<prove> modifies PATH to use a selected pandoc executable
before running tests. See L<Pandoc::Release> to download pandoc executables.

=head1 SEE ALSO

Pandoc executable with package L<Pandoc> can be specified by constructor or
with environment variable C<PANDOC_PATH>.

=cut
