package Module::Build::Tiny;
$Module::Build::Tiny::VERSION = '0.052';
use strict;
use warnings;
use Exporter 5.57 'import';
our @EXPORT = qw/Build Build_PL/;

use CPAN::Meta;
use ExtUtils::Config 0.003;
use ExtUtils::Helpers 0.020 qw/make_executable split_like_shell man1_pagename man3_pagename detildefy/;
use ExtUtils::Install qw/pm_to_blib install/;
use ExtUtils::InstallPaths 0.002;
use File::Basename qw/basename dirname/;
use File::Find ();
use File::Path qw/mkpath rmtree/;
use File::Spec::Functions qw/catfile catdir rel2abs abs2rel splitdir curdir/;
use Getopt::Long 2.36 qw/GetOptionsFromArray/;
use JSON::PP 2 qw/encode_json decode_json/;

sub write_file {
	my ($filename, $content) = @_;
	open my $fh, '>', $filename or die "Could not open $filename: $!\n";
	print $fh $content;
}
sub read_file {
	my ($filename) = @_;
	open my $fh, '<', $filename or die "Could not open $filename: $!\n";
	return do { local $/; <$fh> };
}

sub get_meta {
	my ($metafile) = grep { -e $_ } qw/META.json META.yml/ or die "No META information provided\n";
	return CPAN::Meta->load_file($metafile);
}

sub manify {
	my ($input_file, $output_file, $section, $opts) = @_;
	return if -e $output_file && -M $input_file <= -M $output_file;
	my $dirname = dirname($output_file);
	mkpath($dirname, $opts->{verbose}) if not -d $dirname;
	require Pod::Man;
	Pod::Man->new(section => $section)->parse_from_file($input_file, $output_file);
	print "Manifying $output_file\n" if $opts->{verbose} && $opts->{verbose} > 0;
	return;
}

sub process_xs {
	my ($source, $options, $c_files) = @_;

	die "Can't build xs files under --pureperl-only\n" if $options->{'pureperl-only'};
	my (undef, @parts) = splitdir(dirname($source));
	push @parts, my $file_base = basename($source, '.xs');
	my $archdir = catdir(qw/blib arch auto/, @parts);
	my $tempdir = 'temp';

	my $c_file = catfile($tempdir, "$file_base.c");
	require ExtUtils::ParseXS;
	mkpath($tempdir, $options->{verbose}, oct '755');
	ExtUtils::ParseXS::process_file(filename => $source, prototypes => 0, output => $c_file);

	my $version = $options->{meta}->version;
	require ExtUtils::CBuilder;
	my $builder = ExtUtils::CBuilder->new(config => $options->{config}->values_set);
	my @objects = $builder->compile(source => $c_file, defines => { VERSION => qq/"$version"/, XS_VERSION => qq/"$version"/ }, include_dirs => [ curdir, 'include', 'src', dirname($source) ], extra_compiler_flags => $options->{extra_compiler_flags});

	my $o = $options->{config}->get('_o');
	for my $c_source (@{ $c_files }) {
		my $o_file = catfile($tempdir, basename($c_source, '.c') . $o);
		push @objects, $builder->compile(source => $c_source, include_dirs => [ curdir, 'include', 'src', dirname($c_source) ], extra_compiler_flags => $options->{extra_compiler_flags});
	}

	require DynaLoader;
	my $mod2fname = defined &DynaLoader::mod2fname ? \&DynaLoader::mod2fname : sub { return $_[0][-1] };

	mkpath($archdir, $options->{verbose}, oct '755') unless -d $archdir;
	my $lib_file = catfile($archdir, $mod2fname->(\@parts) . '.' . $options->{config}->get('dlext'));
	return $builder->link(objects => \@objects, lib_file => $lib_file, extra_linker_flags => $options->{extra_linker_flags}, module_name => join '::', @parts);
}

sub find {
	my ($pattern, $dir) = @_;
	my @ret;
	File::Find::find(sub { push @ret, $File::Find::name if /$pattern/ && -f }, $dir) if -d $dir;
	return @ret;
}

sub contains_pod {
	my ($file) = @_;
	return unless -T $file;
	return read_file($file) =~ /^\=(?:head|pod|item)/m;
}

my %actions = (
	build => sub {
		my %opt = @_;
		for my $pl_file (find(qr/\.PL$/, 'lib')) {
			(my $pm = $pl_file) =~ s/\.PL$//;
			system $^X, $pl_file, $pm and die "$pl_file returned $?\n";
		}
		my %modules = map { $_ => catfile('blib', $_) } find(qr/\.pm$/, 'lib');
		my %docs    = map { $_ => catfile('blib', $_) } find(qr/\.pod$/, 'lib');
		my %scripts = map { $_ => catfile('blib', $_) } find(qr/(?:)/, 'script');
		my %sdocs   = map { $_ => delete $scripts{$_} } grep { /.pod$/ } keys %scripts;
		my %dist_shared    = map { $_ => catfile(qw/blib lib auto share dist/, $opt{meta}->name, abs2rel($_, 'share')) } find(qr/(?:)/, 'share');
		my %module_shared  = map { $_ => catfile(qw/blib lib auto share module/, abs2rel($_, 'module-share')) } find(qr/(?:)/, 'module-share');
		pm_to_blib({ %modules, %docs, %scripts, %dist_shared, %module_shared }, catdir(qw/blib lib auto/));
		make_executable($_) for values %scripts;
		mkpath(catdir(qw/blib arch/), $opt{verbose});
		my $main_xs = join('/', 'lib', split /-/, $opt{meta}->name) . '.xs';
		for my $xs (find(qr/.xs$/, 'lib')) {
			my @c_files = $xs eq $main_xs ? find(qr/\.c$/, 'src') : ();
			process_xs($xs, \%opt, \@c_files);
		}

		if ($opt{install_paths}->install_destination('bindoc') && $opt{install_paths}->is_default_installable('bindoc')) {
			my $section = $opt{config}->get('man1ext');
			for my $input (keys %scripts, keys %sdocs) {
				next unless contains_pod($input);
				my $output = catfile('blib', 'bindoc', man1_pagename($input));
				manify($input, $output, $section, \%opt);
			}
		}
		if ($opt{install_paths}->install_destination('libdoc') && $opt{install_paths}->is_default_installable('libdoc')) {
			my $section = $opt{config}->get('man3ext');
			for my $input (keys %modules, keys %docs) {
				next unless contains_pod($input);
				my $output = catfile('blib', 'libdoc', man3_pagename($input));
				manify($input, $output, $section, \%opt);
			}
		}
		return 0;
	},
	test => sub {
		my %opt = @_;
		die "Must run `./Build build` first\n" if not -d 'blib';
		require TAP::Harness::Env;
		my %test_args = (
			(verbosity => $opt{verbose}) x!! exists $opt{verbose},
			(jobs => $opt{jobs}) x!! exists $opt{jobs},
			(color => 1) x !!-t STDOUT,
			lib => [ map { rel2abs(catdir(qw/blib/, $_)) } qw/arch lib/ ],
		);
		my $tester = TAP::Harness::Env->create(\%test_args);
		return $tester->runtests(sort +find(qr/\.t$/, 't'))->has_errors;
	},
	install => sub {
		my %opt = @_;
		die "Must run `./Build build` first\n" if not -d 'blib';
		install($opt{install_paths}->install_map, @opt{qw/verbose dry_run uninst/});
		return 0;
	},
	clean => sub {
		my %opt = @_;
		rmtree($_, $opt{verbose}) for qw/blib temp/;
		return 0;
	},
	realclean => sub {
		my %opt = @_;
		rmtree($_, $opt{verbose}) for qw/blib temp Build _build_params MYMETA.yml MYMETA.json/;
		return 0;
	},
);

my @options = qw/install_base=s install_path=s% installdirs=s destdir=s prefix=s config=s% uninst:1 verbose:1 dry_run:1 pureperl-only:1 create_packlist=i jobs=i extra_compiler_flags=s extra_linker_flags=s/;

sub get_arguments {
	my @sources = @_;
	my %opt;
	GetOptionsFromArray($_, \%opt, @options) for @sources;
	$_ = detildefy($_) for grep { defined } @opt{qw/install_base destdir prefix/}, values %{ $opt{install_path} };
	$_ = [ split_like_shell($_) ] for grep { defined } @opt{qw/extra_compiler_flags extra_linker_flags/};
	$opt{config} = ExtUtils::Config->new($opt{config});
	$opt{meta} = get_meta();
	$opt{install_paths} = ExtUtils::InstallPaths->new(%opt, dist_name => $opt{meta}->name);
	return %opt;
}

sub Build {
	my $action = @ARGV && $ARGV[0] =~ /\A\w+\z/ ? shift @ARGV : 'build';
	die "No such action '$action'\n" if not $actions{$action};
	my($env, $bargv) = @{ decode_json(read_file('_build_params')) };
	my %opt = get_arguments($env, $bargv, \@ARGV);
	exit $actions{$action}->(%opt);
}

sub Build_PL {
	my $meta = get_meta();
	printf "Creating new 'Build' script for '%s' version '%s'\n", $meta->name, $meta->version;
	my $dir = $meta->name eq 'Module-Build-Tiny' ? "use lib 'lib';" : '';
	write_file('Build', "#!perl\n$dir\nuse Module::Build::Tiny;\nBuild();\n");
	make_executable('Build');
	my @env = defined $ENV{PERL_MB_OPT} ? split_like_shell($ENV{PERL_MB_OPT}) : ();
	write_file('_build_params', encode_json([ \@env, \@ARGV ]));
	if (my $dynamic = $meta->custom('x_dynamic_prereqs')) {
		my %meta = (%{ $meta->as_struct }, dynamic_config => 0);
		my %opt = get_arguments(\@env, \@ARGV);
		require CPAN::Requirements::Dynamic;
		my $dynamic_parser = CPAN::Requirements::Dynamic->new(%opt);
		my $prereq = $dynamic_parser->evaluate($dynamic);
		$meta{prereqs} = $meta->effective_prereqs->with_merged_prereqs($prereq)->as_string_hash;
		$meta = CPAN::Meta->new(\%meta);
	}
	$meta->save(@$_) for ['MYMETA.json'], [ 'MYMETA.yml' => { version => 1.4 } ];
}

1;

#ABSTRACT: A tiny replacement for Module::Build


# vi:noet:sts=4:sw=4:ts=4

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Build::Tiny - A tiny replacement for Module::Build

=head1 VERSION

version 0.052

=head1 SYNOPSIS

 use Module::Build::Tiny;
 Build_PL();

=head1 DESCRIPTION

Many Perl distributions use a Build.PL file instead of a Makefile.PL file
to drive distribution configuration, build, test and installation.
Traditionally, Build.PL uses Module::Build as the underlying build system.
This module provides a simple, lightweight, drop-in replacement.

Whereas Module::Build has over 6,700 lines of code; this module has less
than 200, yet supports the features needed by most distributions.

=head2 Supported

=over 4

=item * Pure Perl distributions

=item * Building XS or C

=item * Recursive test files

=item * MYMETA

=item * Man page generation

=item * Generated code from PL files

=item * Module sharedirs

=item * Dynamic prerequisites

=back

=head2 Not Supported

=over 4

=item * HTML documentation generation

=item * Extending Module::Build::Tiny

=back

=head2 Directory structure

Your .pm, .xs and .pod files must be in F<lib/>.  Any executables must be in
F<script/>.  Test files must be in F<t/>. Dist sharedirs must be in F<share/>,
module sharedirs are under F<module-share> (e.g. F<module-share/Foo-Bar> for
module C<Foo::Bar>).

C<.c> files in the F<src/> are compiled together with the .xs file matching the
distribution name.

=head1 USAGE

These all work pretty much like their Module::Build equivalents.

=head2 perl Build.PL

=head2 Build [ build ] 

=head2 Build test

=head2 Build install

This supports the following options:

=over

=item * verbose

=item * install_base

=item * installdirs

=item * prefix

=item * install_path

=item * destdir

=item * uninst

=item * config

=item * pure-perl

=item * create_packlist

=back

=head1 AUTHORING

This module doesn't support authoring. To develop modules using Module::Build::Tiny, usage of L<Dist::Zilla::Plugin::ModuleBuildTiny> or L<App::ModuleBuildTiny> is recommended.

=head1 CONFIG FILE AND ENVIRONMENT

Options can be provided in the C<PERL_MB_OPT> environment variable the same way they can with Module::Build. This should be done during the configuration stage.

=head2 Incompatibilities

=over 4

=item * Argument parsing

Module::Build has an extremely permissive way of argument handling, Module::Build::Tiny only supports a (sane) subset of that. In particular, C<./Build destdir=/foo> does not work, you will need to pass it as C<./Build --destdir=/foo>.

=item * .modulebuildrc

Module::Build::Tiny does not support .modulebuildrc files. In particular, this means that versions of local::lib older than 1.006008 may break with C<ERROR: Can't create /usr/local/somepath>. If the output of C<perl -Mlocal::lib> contains C<MODULEBUILDRC> but not C<PERL_MB_OPT >, you will need to upgrade it to resolve this issue.

=back

=head1 SEE ALSO

L<Module::Build>

=head1 AUTHORS

=over 4

=item *

Leon Timmermans <leont@cpan.org>

=item *

David Golden <dagolden@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans, David Golden.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
