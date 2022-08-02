package My::Module::Meta;

use 5.006001;

use strict;
use warnings;

use Carp;

our $VERSION = '0.002';

sub new {
    my ( $class ) = @_;
    ref $class and $class = ref $class;
    my $self = {
	distribution => $ENV{MAKING_MODULE_DISTRIBUTION},
    };
    bless $self, $class;
    return $self;
}

sub abstract {
    return q<Don't use numeric variable names with leading zeroes.>;
}

sub add_to_cleanup {
    return [ qw{ cover_db } ];
}

sub author {
    return 'Thomas R. Wyant, III (wyant at cpan dot org)';
}

sub build_requires {
    return +{
        'Carp'      => 0,
	'Perl::Critic::TestUtils'	=> 0,
	'PPI::Document'			=> 0,
	'Test::More'	=> 0.88,	# for done_testing();
        'Test::Perl::Critic::Policy'    => 0,
        lib         => 0,
    };
}

sub configure_requires {
    return +{
	'lib'	=> 0,
	'strict'	=> 0,
	'warnings'	=> 0,
    };
}

sub dist_name {
    return 'Perl-Critic-Policy-Variables-ProhibitNumericNamesWithLeadingZero';
}


sub license {
    return 'perl';
}

sub meta_merge {
    my ( undef, @extra ) = @_;
    return {
	'meta-spec'	=> {
	    version	=> 2,
	},
	dynamic_config	=> 1,
	resources	=> {
	    bugtracker	=> {
		web	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Critic-Policy-Variables-ProhibitNumericNamesWithLeadingZero',
		# web	=> 'https://github.com/trwyant/perl-Perl-Critic-Policy-Variables-ProhibitNumericNamesWithLeadingZero/issues',
		mailto  => 'wyant@cpan.org',
	    },
	    license	=> 'http://dev.perl.org/licenses/',
	    repository	=> {
		type	=> 'git',
		url	=> 'git://github.com/trwyant/perl-Perl-Critic-Policy-Variables-ProhibitNumericNamesWithLeadingZero.git',
		web	=> 'https://github.com/trwyant/perl-Perl-Critic-Policy-Variables-ProhibitNumericNamesWithLeadingZero',
	    },
	},
	@extra,
    };
}


sub module_name {
    return 'Perl::Critic::Policy::Variables::ProhibitNumericNamesWithLeadingZero';
}

sub no_index {
    return +{
	directory => [ qw{ doc examples inc tools xt } ],
	file	=> [ qw{ TODO.pod } ],
    };
}

sub provides {
    my $provides;
    local $@ = undef;

    eval {
	require CPAN::Meta;
	require ExtUtils::Manifest;
	require Module::Metadata;

	my $manifest;
	{
	    local $SIG{__WARN__} = sub {};
	    $manifest = ExtUtils::Manifest::maniread();
	}
	keys %{ $manifest || {} }
	    or return;

	# Skeleton so we can use should_index_file() and
	# should_index_package().
	my $meta = CPAN::Meta->new( {
		name	=> 'Euler',
		version	=> 2.71828,
		no_index	=> no_index(),
	    },
	);

	# The Module::Metadata docs say not to use
	# package_versions_from_directory() directly, but the 'files =>'
	# version of provides() is broken, and has been known to be so
	# since 2014, so it's not getting fixed any time soon. So:

	foreach my $fn ( sort keys %{ $manifest } ) {
	    $fn =~ m/ [.] pm \z /smx
		or next;
	    my $pvd = Module::Metadata->package_versions_from_directory(
		undef, [ $fn ] );
	    foreach my $pkg ( keys %{ $pvd } ) {
		$meta->should_index_package( $pkg )
		    and $meta->should_index_file( $pvd->{$pkg}{file} )
		    and $provides->{$pkg} = $pvd->{$pkg};
	    }
	}

	1;
    } or return;

    return ( provides => $provides );
}

sub requires {
    my ( undef, @args ) = @_;
    return {
	'English'		    => 0,
	# 'Perl::Critic::Document'    => 1.119,   # need 1.119 here
        'Perl::Critic::Policy'      => 1.119,
        'Perl::Critic::Utils'       => 1.119,
	'PPI::Document'		    => 0,
	# 'PPI::Token::Symbol'        => 0,
        'PPIx::QuoteLike'           => 0.011,   # For full scope inside ""
	'PPIx::QuoteLike::Constant' => 0.011,
        'PPIx::Regexp'              => 0.071,   # For full scope inside //
        'Readonly'                  => 0,
        base                        => 0,
        strict                      => 0,
        warnings                    => 0,
        @args,
    };
}

sub recommended_module_versions {
    return (
	# 'File::Which'   => 0,
    );
}

sub requires_perl {
    return '5.006001';
}

sub script_files {
    return [
    ];
}

sub version_from {
    return 'lib/Perl/Critic/Policy/Variables/ProhibitNumericNamesWithLeadingZero.pm';
}

1;

__END__

=head1 NAME

My::Module::Meta - Metadata for the current module

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Meta qw{ recommended_module_versions };

=head1 DESCRIPTION

This Perl module holds metadata for the current module. It is private to
the current module.

=head1 METHODS

This class supports the following public methods:

=head2 new

 my $meta = My::Module::Meta->new();

This method instantiates the class.

=head2 build_requires

 use YAML;
 print Dump( $meta->build_requires() );

This method computes and returns a reference to a hash describing the
modules required to build the C<App::Retab> package, suitable for
use in a F<Build.PL> C<build_requires> key, or a F<Makefile.PL>
C<< {META_MERGE}->{build_requires} >> or C<BUILD_REQUIRES> key.

=head2 meta_merge

 use YAML;
 print Dump( $meta->meta_merge() );

This method returns a reference to a hash describing the meta-data which
has to be provided by making use of the builder's C<meta_merge>
functionality. This includes the C<dynamic_config>, C<no_index> and
C<resources> data.

=head2 recommended_module_versions

This subroutine returns an array of the names and versions of
recommended modules.

=head2 requires

 use YAML;
 print Dump( $meta->requires() );

This method computes and returns a reference to a hash describing
the modules required to run the C<App::Retab>
package, suitable for use in a F<Build.PL> C<requires> key, or a
F<Makefile.PL> C<PREREQ_PM> key. Any additional arguments will be
appended to the generated hash. In addition, unless
L<distribution()|/distribution> is true, configuration-specific modules
may be added.

=head2 requires_perl

This subroutine returns the version of Perl required by the module.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Critic-Policy-Variables-ProhibitNumericNamesWithLeadingZero>,
L<https://github.com/trwyant/perl-Perl-Critic-Policy-Variables-ProhibitNumericNamesWithLeadingZero/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2022 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 72
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=72 ft=perl expandtab shiftround :

=head2 abstract

This method returns the distribution's abstract.

=head2 add_to_cleanup

This method returns a reference to an array of files to be added to the
cleanup.

=head2 author

This method returns the name of the distribution author

=head2 configure_requires

 use YAML;
 print Dump( $meta->configure_requires() );

This method returns a reference to a hash describing the modules
required to configure the package, suitable for use in a F<Build.PL>
C<configure_requires> key, or a F<Makefile.PL>
C<< {META_MERGE}->{configure_requires} >> or C<CONFIGURE_REQUIRES> key.

=head2 dist_name

This method returns the distribution name.

=head2 license

This method returns the distribution's license.

=head2 meta_merge

 use YAML;
 print Dump( $meta->meta_merge() );

This method returns a reference to a hash describing the meta-data which
has to be provided by making use of the builder's C<meta_merge>
functionality. This includes the C<dynamic_config> and C<resources>
data.

Any arguments will be appended to the generated array.

=head2 module_name

This method returns the name of the module the distribution is based
on.

=head2 no_index

This method returns the names of things which are not to be indexed
by CPAN.

=head2 provides

 use YAML;
 print Dump( [ $meta->provides() ] );

This method attempts to load L<Module::Metadata|Module::Metadata>. If
this succeeds, it returns a C<provides> entry suitable for inclusion in
L<meta_merge()|/meta_merge> data (i.e. C<'provides'> followed by a hash
reference). If it can not load the required module, it returns nothing.

=head2 script_files

This method returns a reference to an array containing the names of
script files provided by this distribution. This array may be empty.

=head2 version_from

This method returns the name of the distribution file from which the
distribution's version is to be derived.

