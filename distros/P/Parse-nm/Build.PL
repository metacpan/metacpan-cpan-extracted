#!/usr/bin/env perl
use utf8;  # vim:set ts=4 sw=4 sts=4:

use strict;
use warnings;

use Module::Build;

my $class = 'Module::Build';

if (-d '.git') {
	$class = $class->subclass(
		class => 'My::Builder',
		code => q{
			sub ACTION_tag {
                my ($self) = @_;
				my $v = $self->dist_version;
				system(qw(git tag -a -m), "CPAN release $v", "release-$v")
					or die "Git tagging failed.";
			}
		},
	);
}


# Conditional build_requires
my @build_requires;
# Workaround test problems when a broken version of Locale::Maketext is installed
# => we force an upgrade to 1.16+
# https://rt.cpan.org/Ticket/Display.html?id=66040
eval {
	use Locale::Maketext;
	push @build_requires, 'Locale::Maketext' => '1.17' if Locale::Maketext->VERSION < '1.17';
};



my $builder = $class->new(
	module_name => 'Parse::nm',
	dist_author => 'Olivier Mengué <dolmen@cpan.org>',
	license     => 'perl',
	meta_add    => {
		resources => {
			homepage => 'http://github.com/dolmen/parse-nm',
			repository => 'http://github.com/dolmen/parse-nm.git',
			bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-nm',
		},
	},
	requires    => {
		'perl' => '5.006',
		'Regexp::Assemble' => '0.34',
		'String::ShellQuote' => '1.04',
	},
	configure_requires => {
		'Module::Build' => '0.38',
	},
	build_requires => {
		'Module::Build' => '0.38',
		'Test::More' => '0.94',
		'File::Spec' => 0,
		'Test::NoWarnings' => '1.00',
		@build_requires,
	},
    build_recommends => {
        'ExtUtils::CBuilder' => '0.27',
    },
);
$builder->add_to_cleanup('MANIFEST.bak');
$builder->create_build_script();
