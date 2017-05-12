
package SyslogScan::Daemon::SpamDetector::Filter;

use strict;
use warnings;
use SyslogScan::Daemon::SpamDetector::Plugin;
use Plugins::SimpleConfig;
use Tie::Cache::LRU;
our $msgcachesize = 3_000;
our(@ISA) = qw(SyslogScan::Daemon::SpamDetector::Plugin);

my %defaults = (
	status		=> 'spam',
	match		=> '',
	field		=> '',
	accept		=> undef,
	deny		=> undef,
	debug		=> 0,
	acceptfirst	=> 1,
	logname		=> 'FILTER',
);

sub config_prefix { 'sdfilter_' }

sub parse_config_line { simple_config_line(\%defaults, @_); }

sub new 
{
	my $self = simple_new(\%defaults, @_); 
	return $self;
}

sub preconfig
{
	my $self = shift;
	$self->{rx_match} = qr/$self->{match}/;
	$self->{rx_accept} = $self->{accept} 
		? qr/$self->{accept}/
		: undef;
	$self->{rx_deny} = $self->{deny}
		? qr/$self->{deny}/
		: undef;
	$self->{rx_status} = qr/$self->{status}/;
}

sub filter
{
	my ($self, %info) = @_;
	if ($self->{debug} >= 5) {
		print "$self->{logname}:\n";
		for my $k (sort keys %info) {
			printf "%15s= %s\n", $k, $info{$k};
		}
	}
	unless ($info{status} =~ /$self->{rx_status}/) {
		print "$self->{logname}: Status $info{status} not $self->{status}\n" if $self->{debug} >= 4;
		return undef;
	}
	unless ($info{match} =~ /$self->{rx_match}/) {
		print "$self->{logname}: Match $info{match} not $self->{match}\n" if $self->{debug} >= 3;
		return undef;
	}
	unless (defined $info{$self->{field}}) {
		print "$self->{logname}: field '$self->{field}' undefined\n" if $self->{debug};
		if ($self->{debug} && $self->{debug} < 5 && $info{ip}) {
			print "$self->{logname}:\n";
			for my $k (sort keys %info) {
				printf "%15s= %s\n", $k, $info{$k};
			}
		}
		return undef;
	}
	if ($self->{acceptfirst} && defined($self->{accept}) && $info{$self->{field}} =~ /$self->{rx_accept}/) {
		print "$self->{logname}: accept $self->{field} = $info{$self->{field}}\n" if $self->{debug} >= 2;
		return 1;
	}
	if (defined($self->{deny}) and $info{$self->{field}} =~ /$self->{rx_deny}/) {
		print "$self->{logname}: deny $self->{field} = $info{$self->{field}}\n" if $self->{debug};
		return 0;
	}
	if (! $self->{acceptfirst} and defined($self->{accept}) and $info{$self->{field}} =~ /$self->{rx_accept}/) {
		print "$self->{logname}: accept $self->{field} = $info{$self->{field}}\n" if $self->{debug} >= 2;
		return 1;
	}
	return undef;
}

1;

=head1 NAME

 SyslogScan::Daemon::SpamDetector::Filter - filter reports

=head1 SYNOPSIS

 plugin SyslogScan::Daemon::SpamDetector as sd_

sd_plugin SyslogScan::Daemon::SpamDetector::Filter
	status		spam
	match		SpamAssassin
	field		relayname
	acceptfirst	1
	accept		'(?:\bdynamic\b|\badsl\d*\b|\bcable\b|\.dhcp\.|\.dyn\.)'
	deny		'.'
	debug		0

=head1 DESCRIPTION

SyslogScan::Daemon::SpamDetector::Filter looks at spam reported via
L<SyslogScan::Daemon::SpamDetector>'s C<process_spam_match()> function.
It acts as a filter and can block reports.

This module can be used with the L<SyslogScan::Daemon::SpamDetector::SpamAssassin>
module and the L<SyslogScan::Daemon::SpamDetector::BlockList>
module to prevent too many sites from being blocked.  The configuration
in the L</SYNOPSIS> is an example of how to do this.

=head1 CONFIGURATION PARAMETERS

The following configuration parameters are supported:

=over 4

=item debug

Debugging on (1) or off (0).

=item logname

A string to prepend to debug and log output.  (Default: C<FILTER>)

=item status

What kind of report are we looking at?  Choices are: C<ham>, C<spam>, or C<idmap>.
(Default: C<spam>).   When called from L<SyslogScan::Daemon::SpamDetector::BadAddr>,
the status will be C<badaddr>.

=item match

What kind of match are we looking at?  Each module that makes reports 
sets this parameter.  Current choices are: C<SpamAssassin>, C<Postfix>,
C<Sendmail>, C<SpamSink>, and various C<BadAddr::*>.  A regualar
expression match is done on this field.  No default.

=item field

Which field from C<%info> will we examine with the accept and deny
regular expressions?   No default.

=item accept

What is the regular expression for passing this filter?

=item deny

What is the regular expression for being rejected by this filter?

=item acceptfirst

Check the accept expression first?  (Default: 1).

=back

=head1 SEE ALSO

L<SyslogScan::Daemon::SpamDetector>
L<SyslogScan::Daemon::SpamDetector::SpamAssassin>
L<SyslogScan::Daemon::SpamDetector::BlockList>

=head1 THANK THE AUTHOR

If you need high-speed internet services (T1, T3, OC3 etc), please 
send me your request-for-quote.  I have access to very good pricing:
you'll save money and get a great service.

=head1 LICENSE

Copyright(C) 2007 David Muir Sharnoff <muir@idiom.com>. 
This module may be used and distributed on the same terms
as Perl itself.

