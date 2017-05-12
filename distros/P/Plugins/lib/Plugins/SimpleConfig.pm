
package Plugins::SimpleConfig;

use warnings;
use strict;
use Carp;
use Scalar::Util qw(reftype);

our @ISA = qw(Exporter);
our @EXPORT = qw(simple_config_line simple_new);

our %history;

sub simple_config_line
{
	my ($defaults, $plugin, $prefix, $configfile, $line, $lineno, $seqno) = @_;
	my $callpkg = caller();
	my $pkg = ref($plugin) ? ref($plugin) : $plugin;
	my $debug = \0;
	{
		no strict qw(refs);
		$debug = \${"${pkg}::debug"};
	}
	$prefix eq '' or $line =~ s/^$prefix// or croak "unknown config line at $configfile:$lineno '$line'";
	$line =~ /^(\S+)\s+(?:"(.*?)"|'(.*?)'|(\S+))\s*$/
		or croak "Unknown config directive for $callpkg at $configfile:$lineno '$line'\n";
	my $key = $1;
	my $value = first_defined($2, $3, $4, '');


	confess unless defined $key;
	if (ref($defaults->{$key})) {
		refassign($defaults, $key, $value, $plugin, $$debug);
	} elsif (exists $defaults->{$key}) {
		if (ref($plugin)) {
			$plugin->{$key} = $value;
		} else {
			# these need to be saved for new()
			$history{$plugin}{$configfile}{$seqno}{$key} = $value;
			delete $history{$plugin}{$configfile}{$seqno - 1};
		}
	} else {
		croak "Unknown config directive ($key) $callpkg at $configfile:$lineno '$line'\n";
	}
}

sub simple_new
{
	my ($defaults, $pkg, $pconfig, %args) = @_;
	my $context = $pconfig->{context};
	my $self = bless { context => $context, api => $pconfig->{api} }, $pkg;
	my $debug = $defaults->{debug};
	$debug = $args{debug} if defined $args{debug};
	print "new $pkg called\n" if $debug;

	for my $key (keys %$defaults) {
		if (ref($defaults->{$key})) {
			refassign($defaults, $key, $args{$key}, $self, $debug)
				if exists $args{$key};
		} elsif (exists $args{$key}) {
			$self->{$key} = $args{$key};
		} elsif (exists $history{$pkg}{$context->{configfile}}{$context->{seqno}}) {
			$self->{$key} = $history{$pkg}{$context->{configfile}}{$context->{seqno}};
		} else {
			$self->{$key} = $defaults->{$key};
		}
		delete $args{$key};
	}

	for my $key (keys %args) {
		croak "unsupported argument to $pkg->new: $key ($context->{configfile}:$context->{lineno})";
	}
	return $self;
}

sub refassign
{
	my ($defaults, $key, $value, $pkgself, $debug) = @_;
	my $ref = $defaults->{$key};
	if (reftype($ref) eq 'SCALAR') {
		$$ref = $value;
	} elsif (reftype($ref) eq 'ARRAY') {
		push(@$ref, $value);
	} elsif (reftype($ref) eq 'CODE') {
		&$ref($pkgself, $key, $value);
	} else {
		die;
	}
}

sub first_defined
{
	for my $i (@_) {
		return $i if defined $i;
	}
	return undef;
}

1;

=head1 NAME

 Plugins::SimpleConfig

=head1 SYNOPSIS

 use Plugins::SimpleConfig;

 {
	simple_config_line(\%config_items, @_);
 }

 sub new
 {
	simple_new(\%config_items, @_);
 }

=head1 DESCRIPTION

Plugins::SimpleConfig handles the configuration needs of 
L<Plugins> plugins
that do not have complex configuration requirements.

It understands a couple of different kinds of items things
(as deteremined by the C<reftype()> of the value in the
C<%config_items> hash):

=over 10

=item SCALAR

What you would expect.

=item ARRAY

It pushes the new value onto the end of the array.

=item CODE

It calls the function with the following arguments:

=over 10

=item $pkgself

Either the class name or an instance object depending on when
it was called.  It will usually be an instance object.

=item $key

The configuration item being set.

=item $value

The new value.

=back

=back

=head1 HOW TO USE IT

First, create a hash (C<%config_items>) that maps configuration names 
to references to configuration variables.

Second, include the code from the L</SYNOPSIS> in your plugin:

 use Plugins::SimpleConfig;

 my $config_var1 = 'value1';
 my $config_var2 = 'value2';

 my %config_items = (
	var1	=> \$config_var1;
	var2	=> \$config_var2;
 );

 sub config_prefix { return 'myname_' };

 sub parse_config_line
 {
	simple_config_line(\%config_items, @_);
 }

 sub new
 {
	simple_new(\%config_items, @_);
 }

