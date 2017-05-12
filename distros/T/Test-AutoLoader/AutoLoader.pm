# (c) Copyright 2005 Neurogen Corporation, all rights reserved.
package Test::AutoLoader;

use 5.006; # for 'warnings'
use strict;
use warnings;
use Exporter;
BEGIN{*import = \&Exporter::import};
use File::Spec;
use Test::Builder;

our @EXPORT = ('autoload_ok');
our $VERSION = 0.03;

# Lifted fairly directly from AutoLoader.pm
my ($is_dosish, $is_epoc,$is_vms, $is_macos);
BEGIN {
    $is_dosish = $^O eq 'dos' || $^O eq 'os2' || $^O eq 'MSWin32';
    $is_epoc = $^O eq 'epoc';
    $is_vms = $^O eq 'VMS';
    $is_macos = $^O eq 'MacOS';
}

sub autoload_ok {
    my ($package,@subnames) = @_;
    my $Test = Test::Builder->new;
    # initialize the special vars here?  (if we make this part of Test::More)
    unless ($package) {
        return $Test->ok(0,"Can't test autoload of empty package")
    }
    my $test_label = "Autoload of $package" .
      (@subnames ? " (listed subroutines)" : " (all files)");
    (my $pkg = $package) =~ s#::#/#g;
    my $dirname;
    my (@ok,@nok);

    if (defined($dirname = $INC{"$pkg.pm"})) {
        if ($is_macos) {
            $pkg =~ tr#/#:#;
            $dirname =~ s#^(.*)$pkg\.pm\z#$1auto:$pkg#s;
        } else {
            $dirname =~ s#^(.*)$pkg\.pm\z#$1auto/$pkg#s;
        }
    }
    unless (defined $dirname and -d $dirname && -r _ ) {
        $Test->ok(0,$test_label);
        my $diag = "Unable to find valid autoload directory for $package";
        $diag .= " (perhaps you forgot to load '$package'?)"
          if !defined $dirname;
        $Test->diag($diag);
        return;
    }
    my @filenames = map "$_.al", @subnames;
    if (!@filenames ) {
        unless (opendir AUTOLOAD, $dirname) {
            $Test->ok(0,$test_label); 
            $Test->diag("Can't open $dirname: $!");
            return;
        }
        @filenames = grep /.+\.al\z/, readdir AUTOLOAD;
        closedir AUTOLOAD or $Test->diag("Unable to close $dirname: $!");
    }

    foreach my $filename (@filenames) {
        my $full_path = File::Spec->catfile($dirname,$filename);
        # also lifted directly from AutoLoader.pm, then tweaked
        unless ($full_path =~ m|^/|s) {
            if ($is_dosish && $full_path !~ m{^([a-z]:)?[\\/]}is) {
                $full_path = "./$full_path";
            } elsif ($is_epoc && $full_path !~ m{^([a-z?]:)?[\\/]}is) {
                $full_path = "./$full_path";
            } elsif ($is_vms) {
                # XXX todo by VMSmiths
                $full_path = "./$full_path";
            } elsif (!$is_macos) {
                $full_path = "./$full_path";
            }
        }
        local ($@,$!,$?);
        if (my $ret = do $full_path) {
            push @ok, $filename;
        } else {
            my $err = $!
              || $@ && "Compile error"
              || "false return value";
            push @nok, [$filename,$err];
        }
    }
    if (@nok) {
        $Test->ok(0,$test_label);
        $Test->diag(map "    couldn't load $_->[0]: $_->[1]\n", @nok);
        return 0;
    } elsif(@ok) {
        return $Test->ok(1,$test_label);
    } else {
        $Test->ok(0,$test_label);
        $Test->diag("No autoloaded files found");
        return 0;
    }
}
no warnings 'void';
"I pass the test.  I will diminish, and go into the West, and remain Galadriel"
__END__


=head1 NAME

Test::AutoLoader - a testing utility for autosplit/autoloaded modules.

=head1 SYNOPSIS

  use Test::AutoLoader;
  use Test::More tests => 3;
  
  use_ok("My::Module"); # from Test::More
  autoload_ok("My::Module","mysub","sub_two); # test only the listed subs
  autoload_ok("My::Module"); # tests all '.al' files found for the module

=head1 DESCRIPTION

This single-purpose module attempts to eliminate uncaught syntax
errors or other obvious goofs in subroutines that are autosplit, and
hence not looked at by C<perl -c Module.pm>.  Ideally, this module
will become unnecessary as you reach full coverage of those
subroutines in your unit tests.  Until that happy day, however, this
should provide a quick and dirty backstop for embarrassing typos.

Test::AutoLoader is built on Test::Builder, and should interoperate
smoothly with other such modules (e.g. Test::Simple, Test::More).

=head1 EXPORT

=head2 autoload_ok

Very much like the 'use_ok' subroutine (see L<Test::More>).  If passed
only a module name, it will find all subroutine definitions in the
"auto" directory and attempt to compile them.  If passed a list of
subroutine names, it will look for and attempt to compile those (and only
those).  Any files that cannot be found (if specified directly), read, and
compiled will be listed in the diagnostic output for the failed test.

=head1 AUTHOR

Ben Warfield (ben_warfield@nrgn.com)

=head1 COPYRIGHT AND LICENSE

This module is copyright (c) 2005 Neurogen Corporation, Branford,
Connecticut, USA.  It may be distributed under the terms of the GNU
General Public License.

=head1 SEE ALSO

L<perl>, L<Test::More>, L<AutoLoader>.

=cut
