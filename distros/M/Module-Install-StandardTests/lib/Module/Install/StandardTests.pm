package Module::Install::StandardTests;

use warnings;
use strict;
use File::Spec;

use base 'Module::Install::Base';


our $VERSION = '0.05';


sub use_standard_tests {
    my ($self, %specs) = @_;
    
    my %with = map { $_ => 1 } qw/compile pod pod_coverage perl_critic/;
    if (exists $specs{without}) {
        $specs{without} = [ $specs{without} ] unless ref $specs{without};
        delete $with{$_} for @{ $specs{without} };
    }

    $self->build_requires('Test::More');
    $self->build_requires('UNIVERSAL::require');

    # Unlike other tests, this is mandatory.
    $self->build_requires('Test::Compile');

    $self->write_standard_test_compile;    # no if; this is mandatory
    $self->write_standard_test_pod          if $with{pod};
    $self->write_standard_test_pod_coverage if $with{pod_coverage};
    $self->write_standard_test_perl_critic  if $with{perl_critic};
}


sub write_test_file {
    my ($self, $filename, $code) = @_;
    $filename = File::Spec->catfile('t', $filename);

    # Outdent the code somewhat. Remove first empty line, if any. Then
    # determine the indent of the first line. Throw that amount of indenting
    # away from any line. This allows you to indent the code so it's visually
    # clearer (see methods below) while creating output that's indented more
    # or less correctly. Smoke result HTML pages link to the .t files, so it
    # looks neater.

    $code =~ s/^ *\n//;
    (my $indent = $code) =~ s/^( *).*/$1/s;
    $code =~ s/^$indent//gm;

    print "Creating $filename\n";
    open(my $fh, ">$filename") or die "can't create $filename $!";

    my $perl = $^X;
    print $fh <<TEST;
#!$perl -w

use strict;
use warnings;

$code
TEST

    close $fh or die "can't close $filename $!\n";
    $self->realclean_files($filename);
}


sub write_standard_test_compile {
    my $self = shift;
    $self->write_test_file('000_standard__compile.t', q/
        BEGIN {
            use Test::More;
            eval "use Test::Compile";
            Test::More->builder->BAIL_OUT(
                "Test::Compile required for testing compilation") if $@;
            all_pm_files_ok();
        }
    /);
}


sub write_standard_test_pod {
    my $self = shift;
    $self->write_test_file('000_standard__pod.t', q/
        use Test::More;
        eval "use Test::Pod";
        plan skip_all => "Test::Pod required for testing POD" if $@;
        all_pod_files_ok();
    /);
}


sub write_standard_test_pod_coverage {
    my $self = shift;
    $self->write_test_file('000_standard__pod_coverage.t', q/
        use Test::More;
        eval "use Test::Pod::Coverage";
        plan skip_all =>
            "Test::Pod::Coverage required for testing POD coverage" if $@;
        all_pod_coverage_ok();
    /);
}


sub write_standard_test_perl_critic {
    my $self = shift;
    $self->write_test_file('000_standard__perl_critic.t', q/
        use FindBin '$Bin';
        use File::Spec;
        use UNIVERSAL::require;
        use Test::More;

        plan skip_all =>
            'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.'
            unless $ENV{TEST_AUTHOR};

        my %opt;
        my $rc_file = File::Spec->catfile($Bin, 'perlcriticrc');
        $opt{'-profile'} = $rc_file if -r $rc_file;

        if (Perl::Critic->require('1.078') &&
            Test::Perl::Critic->require &&
            Test::Perl::Critic->import(%opt)) {

            all_critic_ok("lib");
        } else {
            plan skip_all => $@;
        }
    /);
}


1;

__END__

=head1 NAME

Module::Install::StandardTests - generate standard tests for installation

=head1 SYNOPSIS

  use inc::Module::Install;
  name 'Class-Null';
  all_from 'lib/Class/Null.pm';
  
  use_test_base;
  use_standard_tests;
  auto_include;
  WriteAll;

=head1 DESCRIPTION

Writes a few standard test files to the test directory C<t/>.

=head1 FUNCTIONS

=over 4

=item use_standard_tests

  use_standard_tests;
  use_standard_tests(without => 'pod_coverage');
  use_standard_tests(without => [ qw/pod_coverage perl_critic/ ]);

Adds a few requirements to the build process, then simply calls the
C<write_standard_test_*> methods one after the other.

If you pass a named argument called C<without>, the the tests corresponding to
the value (as a string) or values (as an array reference) are omitted. Possible values are:

=over 4

=item compile

=item pod

=item pod_coverage

=item perl_critic

=back

=item write_standard_test_compile

Writes the C<t/000_standard__compile.t> file, which uses L<Test::Compile> to
check that all perl module files compile. If L<Test::Compile> is not
available, the tests are skipped.

=item write_standard_test_perl_critic

Writes the C<t/000_standard__perl_critic.t> file, which uses
L<Test::Perl::Critic> to criticise Perl source code for best practices. If
L<Test::Perl::Critic> is not available, the tests are skipped.

If there is a C<t/perlcriticrc> file, it is used as the Perl::Critic
configuration.

=item write_standard_test_pod

Writes the C<t/000_standard__pod.t> file, which uses L<Test::Pod> to check for
POD errors in files. If L<Test::Pod> is not available, the tests are skipped.

=item write_standard_test_pod_coverage

Writes the C<t/000_standard__pod_coverage.t> file, which uses
L<Test::Pod::Coverage> to check for POD coverage in the distribution. If
L<Test::Pod::Coverage> is not available, the tests are skipped.

=item write_test_file($filename, $code)

  $self->write_test_file('000_standard__perl_critic.t', q/.../);

Writes the code into the specified file inside the C<t/> directory. The
shebang line, together with C<use warnings;> and C<use strict;> are prepended
to the code.

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-module-install-standardtests@rt.cpan.org>, or through the web interface
at L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHOR

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

