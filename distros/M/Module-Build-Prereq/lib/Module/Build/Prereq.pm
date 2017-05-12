package Module::Build::Prereq;

use 5.010000;
use strict;
use warnings;
use Module::CoreList;
use File::Find;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(assert_modules);

our $VERSION = '0.04';

sub assert_modules {
    my %args = @_;

    my %modules = ();

    my $skips = $args{ignore_modules};
    my $finds = $args{module_paths} || ['lib'];
    my $ext   = $args{pm_extension} || qr(\.[Pp][Mm]$);

    find( sub { my $file = $_;
                return unless $file =~ $ext;

                open my $fh, "<", $file or do { warn "Unable to open $file: $!\n"; return; };
                while( my $module = <$fh> ) {
                    next unless $module =~ s/^use (\S+).*;.*/$1/;
                    chomp $module;
                    next if $module =~ /^\d/; # version pragma
                    next if exists $args{prereq_pm}->{$module};
                    next if defined $skips and $module =~ $skips;

                    $modules{$module} = $File::Find::name;
                }
                close $fh;
            }, @$finds );

    my $mod = join('|', sort keys %modules);
    my @core = Module::CoreList->find_modules(qr/^(?:$mod)$/);
    delete @modules{@core};

    if (scalar keys %modules) {
        my @missing = map { "  $_ (used by $modules{$_})" } sort keys %modules;
        die "Missing modules:\n" . join("\n", @missing) . "\n";
    }

    return 1;
}

1;
__END__

=encoding utf8

=head1 NAME

Module::Build::Prereq - Verify your Build.PL/Makefile.PL has all the modules you use()

=head1 SYNOPSIS

  use Module::Build::Prereq;

  assert_modules(\%prereq_pm);

  WriteMakefile(CONFIGURE_REQUIRES => {
                  'Module::Build::Prereq' => '0.01' },
                PREREQ_PM => \%prereq_pm);

  # or Module::Build->new(requires => \%prereq_pm)->create_build_script;

=head1 DESCRIPTION

B<Module::Build::Prereq> helps you as a developer make sure you've
captured all of your dependencies correctly in your F<Makefile.PL> or
F<Build.PL>. This module is meant to be used during development or for
non-public modules that need to guarantee modules are installed during
deployment.

B<Module::Build::Prereq> naïvely crawls through your source files
(F<*.pm> by default) looking for 'use ...' statements. It then
subtracts any module that is part of Perl's core module list (as
determined by B<Module::CoreList>), subtracts any modules you've told
it to ignore, skips any modules already in the I<PREREQ_PM> hashref,
then warns you about the rest.

What then? Ideally you'd include those modules in your
F<Makefile.PL>'s I<PREREQ_PM> list (or F<Build.PL>'s I<requires> list)
or add them to the I<ignore_modules> pattern in B<assert_modules> for
the next run.

For more thorough and careful dependency checks (including CPAN
lookups) see BDFOY's L<Module::Release::Prereq>, RJBS's
L<Perl::PrereqScanner>, and other related modules.

=head2 assert_modules

B<Module::Build::Prereq> has one exported function:
B<assert_modules>. It takes the following parameters:

=over 4

=item prereq_pm

Required. This is the same hashref you would supply to
B<WriteMakefile>'s I<PREREQ_PM> argument:

    my $prereq_pm = { 'Foo' => '1.22',
                      'Bar' => '0.27a' };

    assert_modules(prereq_pm => $prereq_pm);

    WriteMakefile(PREREQ_PM => $prereq_pm, ...);

=item ignore_modules

Optional. A regular expression of module names B<assert_modules>
should ignore when looking for missing modules.

    assert_modules(prereq_pm => \%modules,
                   ignore_modules => qr(^(?:Corp::|BigCorp::|InHouse::)));

=item module_paths

Optional. A listref of paths to crawl for your F<*.pm> (or see
I<pm_extension>) files; by default this is set to F<lib>.

    assert_modules(prereq_pm => \%modules,
                   module_paths => ['lib', 'examples']);

=item pm_extension

Optional. A regular expression of what your module names look like. By
default this is set to F</\.[Pp][Mm]$/>.

    assert_modules(prereq_pm => \%modules,
                   pm_extension => qr(\.p[ml]$));

=back

If B<assert_modules> finds one or more modules you are B<use()>ing but
not found in your F<Makefile.PL>, it will B<die()> saying which
modules were not found.

=head1 BACKSTORY

The author uses the following general pattern for deployment in one particular case:

    $ perl Makefile.PL
    $ make
    $ make test
    $ make dist
    (copy tarball to production and install it)

Every now and then someone will add a new dependency via a B<use()>
statement in a module but forget to update F<Makefile.PL> with that
dependency. When the module rolls out, sometimes the dynamic nature of
things allows things to run I<except> for the one module that's
missing its dependency.

B<Module::Build::Prereq> is one simple-minded effort to prevent that
from happening.

=head1 SEE ALSO

L<Test::Prereq> (BDFOY) for a more thorough way to do this in your
module tests rather than at F<Makefile.PL>. L<Module::Release::Prereq>
is also by BDFOY and far more throrough than this
module. L<Perl::PrereqScanner> (RJBS) is a mature scanner
implementation as well.

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@betterservers.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Scott Wiersdorf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
