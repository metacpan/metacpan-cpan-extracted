package My::Module::Meta;

use 5.006001;

use strict;
use warnings;

use Carp;
use Exporter;

our $VERSION = '0.004';

our @ISA = qw{ Exporter };

our @EXPORT_OK = qw{
    recommended_module_versions
};

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
    return 'Beware empty alternatives, because they always match.';
}

sub add_to_cleanup {
    return [ qw{ cover_db } ];
}

sub author {
    return 'Thomas R. Wyant, III F<wyant at cpan dot org>';
}

sub build_requires {
    return +{
	'Perl::Critic::TestUtils'	=> 0,
	'PPI::Document'	=> 0,
	'Test::More'	=> 0.88,	# Because of done_testing().
	'Test::Perl::Critic::Policy'	=> 0,
	charnames	=> 0,
	open		=> 0,
    };
}

sub configure_requires {
    return +{
	lib		=> 0,
	strict		=> 0,
	warnings	=> 0,
    };
}

sub dist_name {
    return 'Perl-Critic-Policy-RegularExpressions-ProhibitEmptyAlternatives';
}

sub distribution {
    my ( $self ) = @_;
    return $self->{distribution};
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
		web	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Critic-Policy-RegularExpressions-ProhibitEmptyAlternatives',
		# web	=> 'https://github.com/trwyant/perl-Perl-Critic-Policy-RegularExpressions-ProhibitEmptyAlternatives/issues',
		mailto  => 'wyant@cpan.org',
	    },
	    license	=> 'http://dev.perl.org/licenses/',
	    repository	=> {
		type	=> 'git',
		url	=> 'git://github.com/trwyant/perl-Perl-Critic-Policy-RegularExpressions-ProhibitEmptyAlternatives.git',
		web	=> 'https://github.com/trwyant/perl-Perl-Critic-Policy-RegularExpressions-ProhibitEmptyAlternatives',
	    },
	},
	@extra,
    };
}


sub module_name {
    return 'Perl::Critic::Policy::RegularExpressions::ProhibitEmptyAlternatives';
}

sub no_index {
    return +{
      directory => [
                     'inc',
                     't',
                     'xt',
                   ],
    };
}

sub provides {
    -d 'lib'
	or return;
    local $@ = undef;
    my $provides = eval {
	require Module::Metadata;
	Module::Metadata->provides( version => 2, dir => 'lib' );
    } or return;
    return ( provides => $provides );
}

sub recommended_module_versions {
    return (
    );
}

sub requires {
    my ( $self, @extra ) = @_;
##  if ( ! $self->distribution() ) {
##  }
    return +{
	'Carp'			=> 0,
	'English'		=> 0,
	'Perl::Critic::Exception::Configuration::Option::Policy::ParameterValue'	=> 0,
	'Perl::Critic::Policy'	=> 0,
	'Perl::Critic::Utils'	=> 0,
	'PPIx::Regexp'		=> 0.070,	# For is_quantifier().
	'Readonly'		=> 0,
	base			=> 0,
	strict			=> 0,
	warnings		=> 0,
	@extra,
    };
}

sub requires_perl {
    return 5.006001;
}

sub script_files {
    return [
    ];
}

sub version_from {
    return 'lib/Perl/Critic/Policy/RegularExpressions/ProhibitEmptyAlternatives.pm';
}

1;

__END__

=head1 NAME

My::Module::Meta - Information needed to build Perl::Critic::Policy::RegularExpressions::Alternative

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Meta;
 my $meta = My::Module::Meta->new();
 use YAML;
 print "Required modules:\n", Dump(
     $meta->requires() );

=head1 DETAILS

This module centralizes information needed to build C<Perl::Critic::Policy::RegularExpressions::Alternative>. It
is private to the C<Perl::Critic::Policy::RegularExpressions::Alternative> package, and may be changed or
retracted without notice.

=head1 METHODS

This class supports the following public methods:

=head2 new

 my $meta = My::Module::Meta->new();

This method instantiates the class.

=head2 abstract

This method returns the distribution's abstract.

=head2 add_to_cleanup

This method returns a reference to an array of files to be added to the
cleanup.

=head2 author

This method returns the name of the distribution author

=head2 build_requires

 use YAML;
 print Dump( $meta->build_requires() );

This method computes and returns a reference to a hash describing the
modules required to build the C<Perl::Critic::Policy::RegularExpressions::Alternative> package, suitable for
use in a F<Build.PL> C<build_requires> key, or a F<Makefile.PL>
C<< {META_MERGE}->{build_requires} >> or C<BUILD_REQUIRES> key.

=head2 configure_requires

 use YAML;
 print Dump( $meta->configure_requires() );

This method returns a reference to a hash describing the modules
required to configure the package, suitable for use in a F<Build.PL>
C<configure_requires> key, or a F<Makefile.PL>
C<< {META_MERGE}->{configure_requires} >> or C<CONFIGURE_REQUIRES> key.

=head2 dist_name

This method returns the distribution name.

=head2 distribution

 if ( $meta->distribution() ) {
     print "Making distribution\n";
 } else {
     print "Not making distribution\n";
 }

This method returns the value of the environment variable
C<MAKING_MODULE_DISTRIBUTION> at the time the object was instantiated.

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

=head2 recommended_module_versions

This subroutine returns an array of the names and versions of
recommended modules.

=head2 required_module_versions

This subroutine returns an array of the names and versions of required
modules. Any arguments will be appended to the returned list.

=head2 requires

 use YAML;
 print Dump( $meta->requires() );

This method computes and returns a reference to a hash describing
the modules required to run the C<Perl::Critic::Policy::RegularExpressions::Alternative>
package, suitable for use in a F<Build.PL> C<requires> key, or a
F<Makefile.PL> C<PREREQ_PM> key. Any additional arguments will be
appended to the generated hash. In addition, unless
L<distribution()|/distribution> is true, configuration-specific modules
may be added.

=head2 requires_perl

 print 'This package requires Perl ', $meta->requires_perl(), "\n";

This method returns the version of Perl required by the package.

=head2 script_files

This method returns a reference to an array containing the names of
script files provided by this distribution. This array may be empty.

=head2 version_from

This method returns the name of the distribution file from which the
distribution's version is to be derived.

=head1 ATTRIBUTES

This class has no public attributes.

=head1 ENVIRONMENT

=head2 MAKING_MODULE_DISTRIBUTION

This environment variable should be set to a true value if you are
making a distribution. This ensures that no configuration-specific
information makes it into F<META.yml>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Critic-Policy-RegularExpressions-ProhibitEmptyAlternatives>,
L<https://github.com/trwyant/perl-Perl-Critic-Policy-RegularExpressions-ProhibitEmptyAlternatives/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
