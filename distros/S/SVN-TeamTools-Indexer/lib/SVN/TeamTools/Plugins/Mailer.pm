use 5.008_000;
use strict;
use warnings;

package SVN::TeamTools::Plugins::Mailer;
{
        $SVN::TeamTools::Plugins::Mailer::VERSION = '0.002';
}
# ABSTRACT: Module to allow TeamTools to send email
#

use Carp;
use Error qw(:try);

use SVN::TeamTools::Store::Config;

use HTML::Template;
use CGI;
use URI::Escape;
use Data::Dumper;
use Net::SMTP;

my $conf;
my $logger;
BEGIN { $conf = SVN::TeamTools::Store::Config->new(); $logger = $conf->{logger}; }

sub hasAction {
	shift;
	my %args	= @_;
	my $action	= $args{action};
	return ("|dsp.config|" =~ /\|\Q$action\E\|/);
}

sub getTemplate {
	shift;
	my %args	= @_;
	my $action	= $args{action};
	my $cgi		= $args{cgi};
	my $template;
	if ($action eq "dsp.config") {
		$template = HTML::Template->new( filename => 'SVN/TeamTools/Plugins/tmpl/mailer-config.tmpl', path => @INC );
	}

	return $template;
}

# Send a mail message ($subject, @recipients, $message)
sub sendMail {
	shift;
	my %args	= @_;
	my $mailer	= $conf->{config}->{mailer};
	my $smtp;

	my $message = HTML::Template->new ( filename => 'SVN/TeamTools/Plugins/tmpl/mailer-message.tmpl', path => \@INC );
	$message->param(p_subject	=> $args{subject});
	$message->param(p_message	=> $args{message});
#	if ( defined $mailer->{mailauth} and $mailer->{mailauth} eq 1 ) {
#		$smtp = Net::SMTP::TLS->new($mailer->{mailrelayhost}, 
#				Hello 		=> $mailer->{maildomain}, 
#				User		=>$mailer->{mailusername},
#				Password	=>$mailer->{mailpassword}
#		) or die "Could not contact SMTP mail server";
#	} else {
		$smtp = Net::SMTP->new($mailer->{mailrelayhost}, Hello => $mailer->{maildomain}) or die "Could not contact SMTP mail server";
#	}
	if (! $smtp->mail ($mailer->{mailsender})) {
		die "Could not set mail sender";
	}
	if (! $smtp->recipient ( @{$args{recipients}} , { SkipBad => 1})) {
		die "Could not set recipients";
	}
	if (! $smtp->data ($message->output())) {
		die "Could not set mail content";
	}
	$smtp->quit();
}
1;

=pod 
=head1 NAME

SVN::TeamTools::Plugins::Mailer

=head1 DESCRIPTION

For internal use only, just to send emails

=head1 AUTHOR
Mark Leeuw (markleeuw@gmail.com)

=head1 COPYRIGHT AND LICENSE

This software is copyrighted by Mark Leeuw

This is free software; you can redistribute it and/or modify it under the restrictions of GPL v2

=cut

