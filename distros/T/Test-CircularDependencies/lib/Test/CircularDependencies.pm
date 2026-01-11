package Test::CircularDependencies;
use strict;
use warnings;

our $VERSION = '0.03';

=head1 NAME

Test::CircularDependencies - make sure non of the modules depend on themselves

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Test::More tests => 1;
  use Test::CircularDependencies qw(test_loops);

  test_loops(['script/my_exe.pl'], ['lib'], 'loops');


The command line client can be used like this:

  find-circular-dependencies.pl t/circular_dependency/my_exe.pl --dir t/circular_dependency/

Multiple places to look for modules

  find-circular-dependencies.pl t/deep/my_exe.pl --dir t/deep/ --dir t/deep/My/

=head1 DESCRIPTION


Given one or more scripts, modules, or directories containing those, create a data structure that represents the dependencies.
Allow the user to restrict the recursion to files found in specific directories.

So let's say we have several application in our company and I'd like to make sure there are no circular dependencies.

  projectA/
    lib/A.pm
    bin/exe.pl
  projectB/
    lib/
      B.pm
      Module/
        C.pm
        D.pm

but for histoical reasons while C.pm holds 'package Module::C;' D.pm holds 'package D;' so
when we use this we need to

  use lib 'projectA/lib';
  use lib 'projectB/lib';
  use lib 'projectB/lib/Module';

=head1 SEE ALSO

L<circular::require>

L<App::PrereqGrapher>

=head1 AUTHOR

L<Gabor Szabo|http://szabgab.com/>

=head1 COPYRIGHT

Copyright 2015 Gabor Szabo, All Rights Reserved.

You may use, modify, and distribute this package under the
same terms as Perl itself.

=cut

use Carp             qw(croak);
use Data::Dumper     qw(Dumper);
use Exporter         qw(import);
use Module::CoreList ();

#use Module::Path qw(module_path);
use Perl::PrereqScanner;
use Path::Iterator::Rule;

our @EXPORT_OK = qw(find_dependencies test_loops);

my %depends;
my @loops;

### From here copy of functions from patched version of Module::Path
### https://github.com/neilbowers/Module-Path/issues/17
### remove these if that patch gets applied.
use Cwd qw/ abs_path /;
my $SEPARATOR;

BEGIN {
	if ( $^O =~ /^(dos|os2)/i ) {
		$SEPARATOR = '\\';
	}
	elsif ( $^O =~ /^MacOS/i ) {
		$SEPARATOR = ':';
	}
	else {
		$SEPARATOR = '/';
	}
}

sub module_path {
	my ( $module, $args ) = @_;
	my $relpath;
	my $fullpath;

	( $relpath = $module ) =~ s/::/$SEPARATOR/g;
	$relpath .= '.pm' unless $relpath =~ m!\.pm$!;

	my @inc = $args->{dirs} ? @{ $args->{dirs} } : @INC;

DIRECTORY:
	foreach my $dir (@inc) {
		next DIRECTORY if not defined($dir);

		# see 'perldoc -f require' on why you might find
		# a reference in @INC
		next DIRECTORY if ref($dir);

		next unless -d $dir && -x $dir;

		# The directory path might have a symlink somewhere in it,
		# so we get an absolute path (ie resolve any symlinks).
		# The previous attempt at this only dealt with the case
		# where the final directory in the path was a symlink,
		# now we're trying to deal with symlinks anywhere in the path.
		my $abs_dir = $dir;
		eval { $abs_dir = abs_path($abs_dir); };
		next DIRECTORY if $@ || !defined($abs_dir);

		$fullpath = $abs_dir . $SEPARATOR . $relpath;
		return $fullpath if -f $fullpath;
	}

	return undef;
}
### end of Module::Path code.

sub test_loops {
	my ( $input, $dirs, $text ) = @_;
	my @loops = find_dependencies( $input, $dirs );

	require Test::Builder;

	# TODO check if there is a plan already and croak if there is none? or plan if there is none? $Test->plan(@_);
	my $Test = Test::Builder->new;
	$Test->ok( !scalar(@loops), $text );
	if (@loops) {
		foreach my $loop (@loops) {
			$Test->diag("Loop found: @$loop");
		}
	}
	return not scalar @loops;
}

{
	my @tree;
	my %in_tree;

	sub find_loop {
		my ($elem) = @_;

		if ( $in_tree{$elem} ) {
			push @loops, [ @tree, $elem ];
			return;
		}
		else {
			push @tree, $elem;
			$in_tree{$elem} = 1;
			foreach my $dep ( sort keys %{ $depends{$elem} } ) {
				find_loop($dep);
			}
			pop @tree;
			delete $in_tree{$elem};
		}
	}
}

sub find_dependencies {
	my ( $inputs, $dirs, $verbose, $inc ) = @_;

	@loops   = ();
	%depends = ();

	my @dirs = @$dirs;
	if ($inc) {
		push @dirs, @INC;
	}

	my @queue;

	croak "Requires at least one input.\n" if not @$inputs;
	foreach my $inp (@$inputs) {
		if ( -f $inp ) {
			push @queue, $inp;
			next;
		}
		if ( -d $inp ) {

			# find all the scripts in the directory tree
			# find all the modules in the directory tree
			my $rule = Path::Iterator::Rule->new;
			for my $file ( $rule->all($inp) ) {
				if ( $file =~ /\.pl$/ ) {
					push @queue, $file;
				}
				if ( $file =~ /\.pm$/ ) {
					push @queue, $file;
				}
			}
		}
		croak "Invalid argument '$inp' (not file and not directory).\n";
	}
	my $scanner = Perl::PrereqScanner->new;
	while (@queue) {
		my $module = shift @queue;
		next if $depends{$module};
		$depends{$module} = {};
		my $path = -f $module ? $module : module_path( $module, { dirs => $dirs } );
		if ( not $path ) {
			croak __PACKAGE__ . " can't find '$module'\n";
			next;
		}

		# Huge files (eg currently Perl::Tidy) will cause PPI to barf
		# So we need to catch those, keep calm, and carry on
		my $prereqs = eval { $scanner->scan_file($path); };
		if ($@) {
			warn $@;
			next;
		}
		my $depsref = $prereqs->as_string_hash();
		foreach my $dep ( keys %{$depsref} ) {
			next                                 if is_core($dep);
			next                                 if $dep eq 'perl';
			say $dep                             if $verbose;
			die "Self dependency for '$module'?" if $module eq $dep;
			$depends{$module}{$dep} = 1;
			push( @queue, $dep );
		}
	}

	#print Dumper \%depends;
	foreach my $root ( sort keys %depends ) {
		find_loop($root);
		delete $depends{$root};    # so we won't find the same loop multiple times.
	}
	return @loops;
}

sub is_core {
	my $module  = shift;
	my $version = @_ > 0 ? shift : $^V;

	return 0 unless defined( my $first_release = Module::CoreList::first_release($module) );
	return 0 unless $version >= $first_release;
	return 1 if !defined( my $final_release = Module::CoreList::removed_from($module) );
	return $version <= $final_release;
}

1;

