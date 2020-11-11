use Orbital::Transfer::Common::Setup;
package Orbital::CLI::Command::Launch::MSYS2DepFiles;
# ABSTRACT: List/copy MSYS2 files
$Orbital::CLI::Command::Launch::MSYS2DepFiles::VERSION = '0.001';
use Modern::Perl;
use Mu;
use CLI::Osprey;
use Path::Tiny;
use Capture::Tiny qw(capture_stdout);
use File::Copy;
use YAML::XS qw(Dump Load);
use Term::ProgressBar;

method build_msys2_file_list() {
	my $package_list_file = shift @ARGV
		or die "Need to pass path to package list\n";
	$package_list_file = path( $package_list_file );

	my @packages = $package_list_file->lines_utf8({ chomp => 1 });
	my $package_deps = {};
	my $package_deps_graphviz = {};
	my $package_set = {};

	for my $package (@packages) {
		my ($linear_stdout, $linear_exit) = capture_stdout {
			system( qw(pactree -l), $package );
		};
		my $dep_packages = [ split /\n/, $linear_stdout ];
		$package_deps->{ $package } = $dep_packages;
		for my $dep_package (@$dep_packages) {
			$package_set->{ $dep_package } = 1;
		}

		my ($graphviz_stdout, $graphviz_exit) = capture_stdout {
			system( qw(pactree -g), $package );
		};
		$package_deps_graphviz->{ $package } = $graphviz_stdout;
	}

	my $package_files = {};
	for my $package (keys %$package_set) {
		my ($stdout, $exit) = capture_stdout {
			system( qw(pacman -Ql), $package );
		};
		my @files = map { s/^[\w-]+\s+//r } split /\n/, $stdout;

		$package_files->{ $package } = \@files;
	}

	my $output = {
		linear => $package_deps,
		graphviz => $package_deps_graphviz,
		files => $package_files,
	};
	print Dump( $output );
}

method get_list_of_files() {
	my $data = shift @_;

	my @all_file_list;

	PACKAGE:
	while( my ($package, $file_list) = each %{ $data->{files} } ) {
		next PACKAGE if $package =~ /python2/;
		next PACKAGE if $package =~ /-(tcl|tk)$/;
		next PACKAGE if $package =~ /-(dmake)$/;
		FILE:
		for my $file (@$file_list) {
			next FILE if $file =~ m|/share/(gtk-)?doc/|;
			next FILE if $file =~ m|/share/man/|;
			next FILE if $file =~ /\.(c|h|html|pdf)$/;
			next FILE if $file =~ /\.(gir)$/;
			next FILE if $file =~ /\.(a)$/;

			push @all_file_list, $file;
		}
	}

	return \@all_file_list;
}

sub copy_files_to_prefix {
	my $prefix = shift @ARGV
		or die "Need to pass path to install prefix\n";

	my $yaml_data = join "", <STDIN>;

	my @all_file_list = @{ get_list_of_files(Load($yaml_data)) };

	my $max = scalar @all_file_list;
	my @term_set = exists $ENV{MSYSCON} || exists $ENV{APPVEYOR_BUILD_FOLDER}
		? ( term => 1, term_width => 80 )
		: ();
	my $progress = Term::ProgressBar->new ({
			name => "Copying package files",
			@term_set,
			ETA => 'linear',
			count => $max, });
	my $processed_files = 0;
	my $next_update = 0;

	chomp( my $msys2_base = `cygpath -w /` );
	for my $file (@all_file_list) {
		my $source_path = path( $msys2_base, $file );
		my $target_path = path( $prefix, $file );

		if( -f $source_path && ! -r $target_path ) {
			$target_path->parent->mkpath;
			#say "$target_path";
			$source_path->copy( $target_path );
		}
		++$processed_files;
		$next_update = $progress->update($processed_files)
			if $processed_files >= $next_update;
	}
	$progress->update($max) if $max > $next_update;

	# post run
	system( qw(glib-compile-schemas), path( $prefix, qw(mingw64 share glib-2.0 schemas) ) );
}

method run() {
	my $command = shift @ARGV
		or die "No command given: $0 [files|copy]\n";

	if( $command eq 'files' ) {
		$self->build_msys2_file_list;
	} elsif( $command eq 'copy' ) {
		$self->copy_files_to_prefix;
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Orbital::CLI::Command::Launch::MSYS2DepFiles - List/copy MSYS2 files

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
