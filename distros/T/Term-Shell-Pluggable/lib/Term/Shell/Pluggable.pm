package Term::Shell::Pluggable;

use warnings;
use strict;

use Getopt::Long; Getopt::Long::Configure('pass_through');
use Sys::Hostname;
use File::Basename;

=head1 NAME

Term::Shell::Pluggable - Pluggable command-line framework

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

There is Term::Shell module in the first place. This is hybrid of that
one with Module::Pluggable. So you could add command line hooks to your
big and scary multi-module perl application.

  #!/usr/bin/env perl
  package Example;
  
  use warnings;
  use strict;
  
  use Getopt::Long qw(GetOptionsFromArray);
  
  sub smry_bubble { 'bubblesort numbers' }
  sub run_bubble {
      my $class = shift;
      Getopt::Long::GetOptionsFromArray(\@_,
          'verbose' => \my $verbose,
      ) and @_ or die "wrong options or numbers are missing\n" . $class->help_bubble;
      my @numbers = @_;
      ...
  }
  sub help_bubble { <<HELP
  usage: bubble [-v] <number1> <number2> ...
  HELP
  }
  
  package main;
  
  use Term::Shell::Pluggable;
  Term::Shell::Pluggable->run(packages => [
      'Example',
      'Some::Other::Example' # another package i.e. defined in separate .pm file 
  ]);
  
=head1 SEE ALSO

L<Term::Shell>

=head1 COPYRIGHT

Copyright 2013 Dmitri Popov.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub run {
	my $class = shift;
	my $args = {@_};
	
	GetOptions(
		'namespace=s' => \my @namespaces,
		'file=s' => \my @files,
		'package=s' => \my @packages,
		'help' => \my $help_wanted,
		'compgen' => \my $compgen_wanted,
	);
	
	if ($help_wanted) {
		print $class->help_message;
		exit 73;
	}

	my $arg_namespaces = $args->{namespaces} || [];

	basename($0) =~ /^(.*)\./;
	my $name = $1 || basename($0);
	my $prompt = $name . '@' . hostname() . '> ';
	my $arg_prompt = $args->{prompt} || sub { $prompt };
	
	my $ctx = Term::Shell::Pluggable::Context->new(
		namespaces => [@namespaces, @$arg_namespaces],
		prompt => $arg_prompt
	);
	
	my $a_packages = $args->{packages};
	foreach my $name (@packages, @$a_packages) {
		$ctx->load_package($name);
	}
	
	my $a_files = $args->{files};
	foreach my $path (@files, @$a_files) {
		$ctx->load_file($path);
	}
	
	if ($compgen_wanted) {
		$ctx->compgen(@ARGV);
		exit 0;
	}
	
	if (scalar @ARGV > 0) {
		# preserving quotes for complex commands
		my $cmd = '';
		for my $arg (@ARGV) {
			$cmd .= ' ' if $cmd;
			if ($arg =~ /\s/) {
				$cmd .= "'$arg'";
			}
			else {
				$cmd .= $arg;
			}
		}
		$ctx->cmd($cmd);
		exit 13 if $ctx->{last_cmd_error};
	}
	else {
		$ctx->cmdloop;
	}
}

sub help_message { <<EOF;
usage: $0 [--file=/home/joe/test.pm] [--namespace=Some::Namespace] [--package=Some::Shell] [command] [options...]

try $0 help for list of commands 
EOF
}

package Term::Shell::Pluggable::Context;

use Module::Pluggable search_path => [], require => 1, inner => 0;
use base 'Term::Shell';
use Sys::Hostname;

sub compgen {
	my $self = shift;
	my ($word, $line, $point) = @_;
	if ($line =~ /^(\w+\s+)/) { # remove program name
		my $l = length $1;
		$line = substr $line, $l;
		$point -= $l;
	}
	my $start = $point;
	if ($word) { # set to start of the current word
		$start = $start - length $word;
	}
	else {
		$word = '';
	}
	my $reply = join "\n", $self->rl_complete($word, $line, $start);
	print $reply . "\n";
}

sub new {
	my $class = shift;
	my $args = {@_};
	if (my $namespaces = $args->{namespaces}) {
		foreach my $search_path (@$namespaces) {
			$class->search_path(add => $search_path);
		}
	}
	my $self = $class->SUPER::new();
	$self->{prompt} = $args->{prompt};
	return $self;
}

sub prompt_str {
	shift->{prompt}->();
}

sub preloop {
	my $self = shift;
	my $modules = join ', ', @{$self->{modules}};
	if ($modules) {
		#print "CLT [$modules]\n";
	}
	else {
		die "no modules\n";
	}
	my (undef, undef, $f) = File::Spec->splitpath($0);
	$f =~ s/\.pl$//; # remove .pl
	$f =~ s/\W/_/g; # cleanup
	$self->{history_path} = File::Spec->catfile($ENV{HOME}, '.' . $f . '_history') if $f;
	if ($self->{term}->Features->{setHistory} and $self->{history_path} and -r $self->{history_path}) {
		open my $fh, '<', $self->{history_path} or die "can't read $self->{history_path}: $!";
		my @history = <$fh>;
		chomp @history;
		$self->{term}->SetHistory(@history);
		close $fh;
    }
}

sub postloop {
	my $self = shift;
	print "\n";
	if ($self->{term}->Features->{getHistory} and $self->{history_path}) {
		open my $fh, '>', $self->{history_path} or die "can't write $self->{history_path}: $!";
		my $prev_line;
		foreach my $line ($self->{term}->GetHistory()) {
			next unless length $line; # skip empty lines
			next if $prev_line and $line eq $prev_line; # skip repeated commands
			print $fh "$line\n";
			$prev_line = $line;
		}
		close $fh;
	}
}

sub run { # overrides Term::Shell::run() to recover on commands errors
	my $self = shift;
	eval {
		$self->SUPER::run(@_);
	};
	my $error = $@;
	if ($error) {
		print STDERR "command failed: $error";
		$self->{last_cmd_error} = $error;
	}
	else {
		$self->{last_cmd_error} = undef;
	}
}

our @ISA;

sub init { # loading pluggable modules
	my $self = shift;
	$self->{modules} = [];
	$self->{r} = {};
	for my $module ($self->plugins) {
		$self->attach_package($module);
	}
}

sub load_package {
	my $self = shift;
	my ($package_name) = @_;
	{
		no strict 'refs';
		unless (grep {$_ !~ /::$/} %{$package_name . '::'}) { # skip requiring packages that may be loaded from start .pl script or loaded .pm files
			no warnings;
			eval "require $package_name" or die "can't load $package_name: $@";
		}
	}
	$self->attach_package($package_name);
}

sub load_file {
	my $self = shift;
	my ($path) = @_;
	die "file not found: $path" unless -f $path;
	open my $fh, $path or die "can't read $path: $!";
	my $in_pod = 0;
	{
		my $result = do $path;
		if (my $errror = $@) {
			warn;
		}
		elsif (not defined $result) {
			warn "can't do $path: $!";
		}
		elsif (not $result) {
			warn "$path returns false";
		}
	}
	while (my $line = <$fh>) {
		$in_pod = 1 if $line =~ m/^=\w/;
		$in_pod = 0 if $line =~ /^=cut/;
		next if ($in_pod || $line =~ /^=cut/); # skip pod text
		next if $line =~ /^\s*#/; # and comments
		if ($line =~ m/^\s*package\s+(.*::)?(.*)\s*;/i) {
			my @up = split /::/, $1 if defined $1;
			$self->attach_package(join "::", @up, $2);
		}
	}
	close $fh;
}

sub attach_package {
	my $self = shift;
	my ($package_name, $sub_package_name) = @_;
	die 'missing package name' unless $package_name;
	my @t = split '::', $package_name;
	my $modules = $self->{modules};
	push @$modules, pop @t unless $sub_package_name;
	{
		no strict 'refs';
		foreach my $sub_name (keys %{$package_name . '::'}) {
			next unless $sub_name =~ /^(run|help|smry|comp|catch|alias)_/o;
			$self->{r}->{$sub_name} = $sub_package_name || $package_name;
			$self->add_handlers($sub_name);
		}
	}
	{
		no strict 'refs';
		foreach my $super_package_name (@{$package_name . '::ISA'}) {
			$self->attach_package($super_package_name, $sub_package_name || $package_name);
		}
	}
}

our $AUTOLOAD;
sub AUTOLOAD {
	my $self = shift;
	my @t = split /::/, $AUTOLOAD;
	my $sub_name = pop @t;
	my $class = join '::', @t;
	return unless ref $self eq $class;
	if (my $package_name = $self->{r}->{$sub_name}) {
		$package_name->$sub_name(@_);
	}
	else {
		return undef;
	}
}

1;
