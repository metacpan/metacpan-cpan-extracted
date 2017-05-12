package Test::CPAN::README;

use strict;
use warnings;

use Test::Builder;
use Module::Want qw(have_mod ns2distname distname2ns);
$Test::CPAN::README::VERSION = '0.2';

my $Test = Test::Builder->new;

sub import {
    my $self = shift;

    my $caller = caller;
    no strict 'refs';    ## no critic
    *{ $caller . '::readme_ok' } = \&readme_ok;

    $Test->exported_to($caller);
    $Test->plan(@_);
}

sub readme_ok {
    my ($ns) = @_;

    if ( !$ns ) {
        if ( -e "META.json" ) {
            require JSON::Syck;
            $ns = JSON::Syck::LoadFile("META.json")->{'name'};
        }
        elsif ( -e "META.yml" ) {
            require YAML::Syck;
            $ns = YAML::Syck::LoadFile("META.yml")->{'name'};
        }
        elsif ( -e "META.yaml" ) {
            require YAML::Syck;
            $ns = YAML::Syck::LoadFile("META.yaml")->{'name'};
        }
        else {
            $Test->ok( 0, 'readme_ok() could not find META' );
            return;
        }

        $ns = distname2ns($ns);
    }

    if ( !have_mod($ns) ) {
        $Test->ok( 0, 'readme_ok() could not load NS' );
        return;
    }

    my $pkg = ns2distname($ns);
    my $cur = $ns->VERSION;

    $Test->plan( tests => 1 );
    if ( !-f 'README' && -s _ ) {
        $Test->ok( 0, 'no README file' );
    }
    else {
        open my $fh, '<', 'README' or die "Could not read README: $!";
        my ($first_line) = <$fh>;
        close $fh;
        $Test->is_eq( $first_line, "$pkg version $cur\n", 'First line is "<DIST> version <VERSION>\n"' );
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Test::CPAN::README -  Validation of the README file in a CPAN distribution

=head1 VERSION

This document describes Test::CPAN::README version 0.2

=head1 SYNOPSIS

    #!perl

    use Test::More;
    plan skip_all => 'pkg/README tests are only run in RELEASE_TESTING mode.' unless $ENV{'RELEASE_TESTING'};

    eval 'use Test::CPAN::README';
    plan skip_all => 'Test::CPAN::README required for testing the pkg/README file' if $@;

    readme_ok();    # this does the plan
    
or specify the NS instead of getting it from META info:

    readme_ok('Foo::Bar::Baz');    # this does the plan

=head1 DESCRIPTION

Validate that README file has the right heading/version line.

=head1 INTERFACE 

has one exported function: readme_ok

=head2 readme_ok([NS])

Tests that the README file contains the correct heading, namely: '<DIST> version <VERSION>\n'

The DIST is determined from META info. You can pass in an alternate name space to use instead.

=head1 DIAGNOSTICS

Any issues are turned into a failed tests expect when a README file can not be opened, which dies.

=head1 CONFIGURATION AND ENVIRONMENT

Test::CPAN::README requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Test::Builder>

L<Module::Want>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-cpan-readme@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

more types of tests?

any given README file?

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

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
