package # hide from PAUSE
	FakeCollectd;

=head1 NAME

FakeCollectd - Provides in-place replacement for testing L<Collectd> plugins.

=head1 SYNOPSIS

Used internally by Test::Collectd::Plugins.

=cut

use Carp qw/croak/;
require Exporter;
push @ISA, qw/Exporter/;
our %EXPORT_TAGS = (
	all => [qw(
		TYPE_CONFIG
		TYPE_INIT
		TYPE_READ
		TYPE_WRITE
		TYPE_SHUTDOWN
		TYPE_LOG
		TYPE_NOTIF
		TYPE_FLUSH
		TYPE_DATASET
		LOG_DEBUG
		LOG_INFO
		LOG_NOTICE
		LOG_WARNING
		LOG_ERR
		NOTIF_FAILURE
		NOTIF_WARNING
		NOTIF_OKAY
		$hostname_g
		$interval_g
		plugin_register
		plugin_dispatch_values
		plugin_log
		WARN
		%FakeCollectd
	)],
);
push @EXPORT, @{$EXPORT_TAGS{all}};

our $VERSION = "0.1000";

our $interval_g = 10;
our $hostname_g = "localhost";
our %FakeCollectd;

use constant TYPE_CONFIG => "config";
use constant TYPE_INIT => "init";
use constant TYPE_READ => "read";
use constant TYPE_WRITE => "write";
use constant TYPE_SHUTDOWN => "shutdown";
use constant TYPE_LOG => "log";
use constant TYPE_NOTIF => "notify";
use constant TYPE_FLUSH => "flush";
use constant TYPE_DATASET => "init";

use constant LOG_DEBUG => 7;
use constant LOG_INFO => 6;
use constant LOG_NOTICE => 5;
use constant LOG_WARNING => 4;
use constant LOG_ERR => 3;

use constant NOTIF_FAILURE => 1;
use constant NOTIF_WARNING => 2;
use constant NOTIF_OKAY => 4;

=head2 plugin_register (CALLBACK_TYPE, PLUGIN_NAME, CALLBACK_NAME)

Will Populate %FakeCollectd using provided arguments.

=cut

sub plugin_register {
	my ($type,$name,$data) = @_;
	my $caller = scalar caller 0;
	$FakeCollectd{$caller}->{Name} = $name;
	if ($type eq TYPE_CONFIG) {
		$FakeCollectd{$name}->{Callback}->{Config} = $caller."::".$data;
	} elsif ($type eq TYPE_INIT) {
		$FakeCollectd{$name}->{Callback}->{Init} = $caller."::".$data;
	} elsif ($type eq TYPE_READ) {
		$FakeCollectd{$name}->{Callback}->{Read} = $caller."::".$data;
	} else {
		die "$type not supported (yet)";
	}
	1;
}

=head2 plugin_dispatch_values ( value_type )

Populates %FakeCollectd with the data.

=cut

sub plugin_dispatch_values {
	my $caller = scalar caller 0;
	unless (ref $_[0] eq "HASH") {
		croak "plugin_dispatch_values $caller: dispatch can only be called using HASHREF arg";
		return undef;
	}
	my $plugin = $_[0] -> {plugin};
	unless (defined $plugin) {
		croak "plugin_dispatch_values $caller: no 'plugin' key in dispatch";
		return undef;
	}
	# confused here as to which PK to use
	# use both!
	push @{$FakeCollectd{$plugin}->{Values}}, \@_;
	push @{$FakeCollectd{$caller}->{Values}}, \@_;
	1;
}

=head2 WARN

Replaces Warning function

=cut

sub WARN {
	plugin_log (LOG_WARNING, @_);
}

=head2 plugin_log

Replaces log function

=cut

sub plugin_log {
	eval {croak join " ", @_}
}

1;

