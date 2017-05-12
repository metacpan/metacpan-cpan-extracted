use 5.008_000;
use strict;
use warnings;

package SVN::TeamTools::Store::Config;
{
	$SVN::TeamTools::Store::Config::VERSION = '0.002';
}
# ABSTRACT: COmmon accessor for configuration file used by SVN::TeamTools modules

use Carp;
use Error qw(:try);

use XML::Simple;

use Exporter;
use Log::Log4perl qw(get_logger :levels);

use Data::Dumper;

my $config = undef;

sub hasAction {
        shift;
        my %args        = @_;
        my $action      = $args{action};
        return ("|dsp.config|" =~ /\|\Q$action\E\|/);
}
sub getTemplate {
	return HTML::Template->new( filename => 'SVN/TeamTools/Store/tmpl/config.tmpl', path => @INC );
}

sub new {
	my $class       = shift;

	if (! defined $config) {
		my %args        = @_;
	
		### Parse config file(s)
		my $xml = new XML::Simple;
	
		my $stc;
		try {
			$stc = $xml->XMLin("/etc/svnteamtools/system.conf", ForceArray => [qw(extention rules lang exclude regex treeregex context db)]);
		} otherwise {
			my $EXC = shift;
			croak "Could not open system.conf, error : $EXC";
		};
		if ( ! defined $stc ) {
			croak "Could not read system.conf";
		}
	
		my %src_types;
		foreach my $lang (@{$stc->{source}->{lang}}) {
			foreach my $regex (@{$lang->{extention}}) {
				$src_types{$regex}=$lang;
			}
		}
		my $indextypes = "txt";
		while (my ($regex, $lang) = each (%src_types)) {
		        if ('1' == $lang->{index}) {
		                $indextypes="$indextypes|$regex";
		        }
		}

	        my $logger      = get_logger();
	        $logger->level($INFO);

	        my $appender    = Log::Log4perl::Appender->new(
                                "Log::Dispatch::File",
                                filename => "/var/log/svnteamtools/messages.log",
                                mode     => "append",
	        );
		my $layout 	= Log::Log4perl::Layout::PatternLayout->new(
                                                   "%d{dd/MM/yyyy hh:mm:ss} %p %C > %m{chomp}%n");
		$appender->layout ($layout);
	        $logger->add_appender ($appender);

		my $self = {
			logger		=> $logger,
			repo		=> $stc->{svn}->{repo},
			svnindex	=> $stc->{svnindex}->{path},
			depindex	=> $stc->{depindex}->{path},
			svnstats	=> $stc->{svnstats}->{path},
			reviewdb	=> $stc->{reviewrules}->{path},
			src_types	=> \%src_types,
			config		=> $stc,
			indextypes	=> $indextypes,
		};
		bless $self, $class;
		$config = $self;
		return $self;
	} else {
		return $config;
	}
}

sub getData {
	$config 	= undef;
	my $self	= shift;

	$self		= ref($self)->new();

	return $self->{config};
}
sub store {
	my $self	= shift;
	my %args        = @_;

	my $data	= $args{data};
	my $xml		= XMLout($data, SuppressEmpty=>1, NoAttr=>1, RootName=>'ToolConfig');
	my %result = (
		status => "OK"
	);
	open (my $conffile, ">", "/etc/svnteamtools/system.conf") or die "Can't open configuration file for update";
	print $conffile $xml;
	close $conffile;
	$self->{logger}->info("Saved new configuration: $xml");
	$self->{logger}->info("Saved new configuration: " . Dumper($data));
	$config = undef;

	return \%result;
}
1;

=pod

=head1 NAME

SVN::TeamTools::Store::Config

=head1 SYNOPSIS

use SVN::TeamTools::Store::Config;

BEGIN { $conf = SVN::TeamTools::Store::Config->new(); $logger = $conf->{logger}; }

=head1 DESCRIPTION

Common accessor for configuration file used by SVN::TeamTools modules.
A basic configuration file will be configured by the installer as /etc/svnteamtools/system.conf
A basic log will be created as /var/log/svnteamtools/messages.log

The initial configuration file contains information about the SVN repository, the location of the search index and an initial list of filetype information (Java, Java Server Pages, Plain text, XML, XSD and SQL). Other modules will add additional configration items. Please see individual modules for configuration specifics.

=head2 Methods

=over 12

=item new

Creates a new configuration object. No parameters needed.

=item hasAction

Only for internal use by the web interface

=item getTemplate

Only for internal use by the web interface

=item getData

Only for internal use by the web interface

=item store

Only for internal use by the web interface

=back

=head1 AUTHOR

Mark Leeuw (markleeuw@gmail.com)

=head1 COPYRIGHT AND LICENSE

This software is copyrighted by Mark Leeuw

This is free software; you can redistribute it and/or modify it under the restrictions of GPL v2

=cut

