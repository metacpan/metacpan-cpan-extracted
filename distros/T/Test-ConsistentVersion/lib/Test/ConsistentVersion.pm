package Test::ConsistentVersion;

use warnings;
use autodie;
use strict;
use Carp;
use Test::Builder;

use version; our $VERSION = qv('0.3.0');

my $TEST = Test::Builder->new;
my %ARGS;

sub check_consistent_versions {
    %ARGS = @_;
    
    my @modules = _find_modules();
    
    my $file_count = @modules;
    unless(@modules) {
        $TEST->diag('No files to get version from.');
    }
    my $test_count = $file_count;
    unless($ARGS{no_pod}) {
        eval { require Test::Pod::Content; };
        
        if ($@) {
            $TEST->diag('Test::Pod::Content required to test POD version consistency');
            $ARGS{no_pod} = 1;
        }
        else {
            $test_count+=$file_count
        }
    }
    $test_count++ unless $ARGS{no_changelog};
    $test_count++ unless $ARGS{no_readme};
    $TEST->plan(tests => $test_count) unless $TEST->has_plan;
    
    ## no critic (eval)
    #Find the version number
    eval "require $modules[0]";
    my $distro_version = $modules[0]->VERSION;
    $TEST->diag("Distribution version: $distro_version");
    
    _check_module_versions($distro_version, @modules);
    _check_pod_versions(@modules) unless $ARGS{no_pod};
    _check_changelog($distro_version) unless $ARGS{no_changelog};
    _check_readme($distro_version) unless $ARGS{no_readme};
}

sub _find_modules {
    my @modules;
    
    if($ARGS{files}) {
        @modules = @{$ARGS{modules}};
    }
    if(-e 'MANIFEST') {
        open(my $fh, '<', 'MANIFEST');
        @modules = map {
            my $str = $_;
            $str =~ s{^lib/(.*)\.pm}{$1};
            $str =~ s(/)(::)g;
            chomp $str;
            $str;
        } grep {
            /^lib.*\.pm$/
        } <$fh>;
        close $fh;
    }
    return @modules;
}

sub _check_pod_versions {
    my @modules = @_;
    unless(@modules) {
        $TEST->diag('No files to check POD of.');
    }
    
    ## no critic (eval)
    foreach my $module (@modules) {
        eval "require $module" or $TEST->diag($@);
        my $module_version = $module->VERSION;
        Test::Pod::Content::pod_section_like( $module, 'VERSION', qr{(^|\s)v?\Q$module_version\E(\s|$)}i, "$module POD version is the same as module version")
    }
}

sub _check_module_versions {
    my $version = shift;
    my @modules = @_;
    
    ## no critic (eval)
    foreach my $module (@modules) {
        eval "require $module" or $TEST->diag($@);
        $TEST->is_eq($module->VERSION, $version, "$module is the same as the distribution version");
    }
}

sub _check_changelog {
    my $version = shift;
    if(-e 'Changes') {
        open(my $fh, '<', 'Changes');
        my $version_check = quotemeta($version);
        
        my $changelog = join "\n", <$fh>;
        $TEST->like($changelog, qr{\bv?$version_check\b}i, 'Changelog includes reference to the distribution version: ' . $version);
        close $fh;
    }
    else {
        $TEST->ok(0, 'Unable to find Changes file');
    }
}

sub _check_readme {
    my $version = shift;
    if(-e 'README') {
        open(my $fh, '<', 'README');
        my $version_check = quotemeta($version);
        
        my $readme = join "\n", <$fh>;
        $TEST->like($readme, qr{\bv?$version_check\b}i, 'README file includes reference to the distribution version: ' . $version);
        close $fh;
    }
    else {
        $TEST->ok(0, 'Unable to find README file');
    }
}

1; # Magic true value required at end of module

__END__

=head1 NAME

Test::ConsistentVersion - Ensures a CPAN distribution has consistent versioning.


=head1 VERSION

This document describes Test::ConsistentVersion version 0.3.0


=head1 SYNOPSIS

[In a test file]

    use Test::More;
    
    if ( not $ENV{TEST_AUTHOR} ) {
        my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
        plan( skip_all => $msg );
    }
    
    eval "use Test::ConsistentVersion";
    plan skip_all => "Test::ConsistentVersion required for checking versions" if $@;
    Test::ConsistentVersion::check_consistent_versions();


=head1 DESCRIPTION

The purpose of this module is to make it easy for other distribution
authors to have consistent version numbers within the modules (as well
as readme file and changelog) of the distribution.


=head1 INTERFACE

=over

=item check_consistent_versions

    check_consistent_versions()

Checks the various versions throughout the distribution to ensure they
are all consistent.

=back


=head1 DIAGNOSTICS

Nothing so far.

=head1 CONFIGURATION AND ENVIRONMENT

Test::ConsistentVersion requires no configuration files or environment variables.


=head1 DEPENDENCIES

=over

=item L<Test::Builder>

=item L<autodie>

=back


B<Optional>

=over

=item L<Test::Pod::Content>

For ensuring the module version matches that referenced in the POD.

=back

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-consistentversion@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Glenn Fowler  C<< <cebjyre@cpan.org> >>

Thanks to L<http://www.affinitylive.com>.


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, Glenn Fowler C<< <cebjyre@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
