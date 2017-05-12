# Copyright (C) 2006, David Muir Sharnoff <muir@idiom.com>

package Plugins::Style1;

use strict;
use warnings;
use Plugins;
use Hash::Util qw(lock_keys);
use Carp;

our @ISA = qw(Plugins);

my $prefix_generator = "PREFIX_000000";
our $debug = 0;
our %sequence;
our $VERSION = $Plugins::VERSION;

sub new
{
	my ($pkg, %args) = @_;
	my $self = $pkg->SUPER::new(%args);
	my $context = $self->{context} || {};
	$self->{prefixes_done}		= $context->{prefixes_done} || {};
	$self->{parse_config_line}	= $args{parse_config_line};
	$self->{config_prefix}		= $context->{config_prefix};
	$self->{plugin_directories}	= $context->{plugin_directories} || [ '.' ];
	lock_keys(%$self) 
		if $pkg eq __PACKAGE__;
	return $self;
}

sub parseconfig
{
	my ($self, $configfile, %args) = @_;

	my $caller = $args{self};

	$configfile ||= $args{configfile} || $args{context}{configfile} || $self->{configfile} || die "no config file";

	my $package = ref($caller) || scalar(caller());
	my $rdebug = $debug;
	{
		no strict qw(refs);
		$rdebug = ${"${package}::debug"};
	}

	printf STDERR "Reading %s for %s\n", $configfile, scalar(caller()) if $rdebug;

	my $combined_prefix = '';

	my $prefix = first_defined(
		$args{config_prefix},
		$self->{config_prefix},
		($caller && $caller->can('config_prefix') && $caller->config_prefix()),
		($self->{context}{requestor} && $prefix_generator++),
		'');

	my %prefixes_done = %{$self->{prefixes_done}};
	$prefixes_done{$configfile}{$prefix} = ref($caller) ? ref($caller) : $caller;

	my $unknown = $args{parse_config_line} 
		|| $self->{parse_config_line} 
		|| ($caller && $caller->can('parse_config_line'))
		|| sub { die "unknown line in $configfile: '$_' (currently: shortname='$prefix', combined_prefix='$combined_prefix'" };

	my $plugin_directories = $args{plugin_directories} || $self->{plugin_directories};
	$plugin_directories = [ @$plugin_directories ];

	my %active_prefixes;
	my %known_prefixes;

	my $seqno = ++$sequence{$configfile};

	open(CONFIG, "<$configfile") or croak "Could not open config file $configfile: $!";
	while(<CONFIG>) {
		next if /^$/;
		next if /^#/;
		next if /^\s/;
		chomp;
		if (/^(.+_)?plugin\s+(\S+)(?:\s+as\s+(\w+)$)?/) {
			my $pre = $1;
			my $pkg = $2;
			my $config_prefix = $3;
			my @args;
			my $redo = 0;
			while (<CONFIG>) { 
				$redo = 1;  # we haven't seen EOF
				chomp;
				last unless s/^\s+//;
				next if /^#/;
				while (s/(?:"(.*?)"|'(.*?)'|([^\s'"#][^\s#]*))\s*//) {
					my $word = defined($1) ? $1 : (defined $2 ? $2 : (defined $3 ? $3 : last));
					push(@args, $word);
					last if /^#/;
				}
			}
			if ($pkg =~ m{/} || $pkg =~ /^\w+$/) {
				$pkg = $self->file_plugin($pkg, 
					search_path	=> $plugin_directories,
					referenced	=> "(referenced at $configfile line $.)",
				);
				$config_prefix ||= '';
			} elsif ($config_prefix) {
				$self->pkg_invoke($pkg);
			} else {
				$config_prefix = $self->pkg_invoke($pkg, 'config_prefix') || '';
			}
			if (! defined($pre) && $prefix eq '' or $pre && $prefix && $pre eq $prefix) {
				my $context = $self->registerplugin(
					pkg		=> $pkg,
					new_args	=> \@args,
					config_prefix	=> $config_prefix,
					configfile	=> $configfile,
					lineno		=> $.,
					seqno		=> $seqno,
					prefixes_done	=> \%prefixes_done,
					(ref($self) eq __PACKAGE__ ? () : (pkg_override => ref($self))),
					config_lines	=> [],
				);
				$prefixes_done{$configfile}{$config_prefix} = $prefixes_done{$configfile}{$prefix};
				$active_prefixes{$config_prefix} = $context;
				print STDERR "Plugin $pkg registered\n" if $rdebug;
			} else {
				# this isn't our plugin so we'll ignore it for now
				print STDERR "Plugin $pkg ignored\n" if $rdebug;
			}
			if ($config_prefix) {
				croak "config_prefix '$config_prefix' is used twice: first for at $configfile line $. and again at $known_prefixes{$config_prefix}"
					if $known_prefixes{$config_prefix};
				$known_prefixes{$config_prefix} = "$pkg at line $.";
				if ($combined_prefix) {
					$combined_prefix = qr/(?:$combined_prefix|\Q$config_prefix\E)/;
				} else {
					$combined_prefix = qr/\Q$config_prefix\E/;
				}
			}
			redo if $redo && $_;
		} elsif (/^plugin_directory\s+(\S.*)/) {
			push(@$plugin_directories, grep($_ && -d $_, split(' ', $1)));
		} elsif ($combined_prefix && /^($combined_prefix)/) {
			push(@{$active_prefixes{$1}{config_lines}}, {
				config_prefix	=> $1,
				configfile	=> $configfile,
				seqno		=> $seqno,
				lineno		=> $.,
				line		=> $_,
			}) if $active_prefixes{$1};
		} elsif ($prefix && $self->{prefixes_done} && $self->{prefixes_done}{$configfile}{''}) {
			if (/^$prefix/ && ! $self->{prefixes_done}{$configfile}{$prefix}) {
				s/((?:[^'"]|".*?"|'.*?')*#.*)/$1/;
				&$unknown($caller, $prefix, $configfile, $_, $., $seqno);
			}
		} else {
			s/((?:[^'"]|".*?"|'.*?')*#.*)/$1/;
			&$unknown($caller, $prefix, $configfile, $_, $.);
		}
	}
	return ();
}

sub genkey
{
	my ($self, $context) = @_;
	my $key = "$context->{pkg}/$context->{config_prefix}/$context->{configfile}";
	return $key;
}

sub post_initialize
{
	my ($self, $context, $plugin) = @_;
	for my $l (@{$context->{config_lines}}) {
		$plugin->invoke('parse_config_line', $l->{config_prefix}, $l->{configfile}, $l->{line}, $l->{lineno}, $l->{seqno});
	}
}

sub first_defined
{
	for my $i (@_) {
		return $i if defined $i;
	}
	return undef;
}

sub file_plugin
{
	my $self = shift;
	my $pkg = $self->SUPER::file_plugin(@_, isa => 'Plugins::Style1::Plugin');
	unless ($pkg->can('config_prefix')) {
		no strict 'refs';
		*{"${pkg}::config_prefix"} = sub { print STDERR "USING CONFIG_PREFIX\n"; ''; };
	}
	return $pkg;
}

package Plugins::Style1::Plugin;

our @ISA = qw(Plugins::Plugin);

1;
