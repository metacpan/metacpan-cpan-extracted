package Net::Comcast::Customer;
use strict;
use warnings;
use Carp;
use WWW::Mechanize;
use Date::Calc qw( Days_in_Month );

=head1 NAME

Net::Comcast::Customer - Comcast Customer Central web interface

=head1 VERSION

Version 1.2

=cut

our $VERSION = '1.2';

=head1 SYNOPSIS

Access Comcast's Customer website.


	use Net::Comcast::Customer;

	my $c = Net::Comcast::Customer->new();
	$c->login('username', 'pa$$word');
	
	# Get data usage in gigabytes.
	my $usage = $c->get_usage;
	my $budgeted = $c->get_budgeted_usage;
	...

=head1 DESCRIPTION

Comcast Customer Central is "The one place where you can view and pay your bill, and manage all your Comcast product features and settings." Since Comcast has a 250 GB/month data cap, this module will allow you to view your total bandwidth used and your current "budgeted" bandwidth. The data is suitable for exporting into monitoring tools like RRDtool and Cacti.

In other words, this module is a programmatic interface to what you can see at L<https://customer.comcast.com/Secure/UsageMeterDetail.aspx> .

This module could do much more (patches welcome). Also, Comcast apparently breaks this all the time, so good luck!

=cut

# Comcast constants
my $LOGIN_URL = 'https://customer.comcast.com/Secure/Home.aspx';
my $USAGE_URL = 'https://customer.comcast.com/Secure/UsageMeterDetail.aspx';
my $USER_AGENT = 'Mozilla/5.0 (X11; Linux i686; rv:12.0) Gecko/20100101 Firefox/12.0';

=head1 METHODS

=head2 new

No args, just create and go.

=cut

sub new {
	my $class = shift;
	my $self = {
		'mech' => WWW::Mechanize->new(
			agent => $USER_AGENT,
		),
		# Monthly GB limit
		# This was hard to scrape reliably from the HTML, so I'm
		# hardcoding here.
		'max_gb' => 250,
		'debug' => 0,
	};
	bless($self, $class);
	return $self;
}

=head2 debug

Get/Set the debug level. Takes one argument: an integer.

Use this if you're having problems. Set this to zero to silence all debugging (the default).

Returns an integer.

=cut

sub debug {
        my $self = shift;
        if (@_) { $self->{'debug'} = shift; }
	# Custom debugging for WWW::Mechanize
	if ($self->{'debug'} > 1) {
		$self->mech->add_handler("request_send",  sub { shift->dump; return });
	}
        return $self->{'debug'};
}


=head2 mech

WWW::Mech accessor. You probably won't need to use this in your own code.

Returns a WWW::Mechanize object.

=cut

sub mech {
        my $self = shift;
        if (@_) { $self->{'mech'} = shift; }
        return $self->{'mech'};
}


=head2 max_gb

Monthly Gigabyte limit accessor. Defaults to 250.

Comcast has plans to change this to 300 in the future. Read more on the L<"Comcast blog entry"|http://blog.comcast.com/2012/05/comcast-to-replace-usage-cap-with-improved-data-usage-management-approaches.html> and L<"Comcast FAQ page"|https://customer.comcast.com/help-and-support/internet/data-usage-what-are-the-different-plans-launching/> .

Returns an integer.

=cut

sub max_gb {
        my $self = shift;
        if (@_) { $self->{'max_gb'} = shift; }
        return $self->{'max_gb'};
}


=head2 login

Log in to Comcast's customer service portal. Takes two arguments: a username string and a password string.

=cut

sub login {
        my $self = shift;
	my $username = shift || croak("missing username arg");
	my $password = shift || croak("missing password arg");

	# Load the login page.
	$self->mech->get( $LOGIN_URL );
	# TODO: Error-check (network conn) here.

	$self->mech->submit_form(
		form_name => 'signin',
		fields      => {
			user => $username,
			passwd => $password,
		}
	);

	# After submitting the login form, we're taken to a page "Retrieving
	# your account information, one moment please..." with a Flash app.
	# The page has a "redir" form with a "cima.ticket" value. Javascript
	# submits this form when the page is loaded. We do it here manually.

	# Before we switched to $LOGIN_URL:
	# This will be a POST to $USAGE_URL, which will then 302 Redirect to
	# Preload.aspx. 
	$self->mech->submit_form(
		form_name => 'redir',
	);

	# We're now at some sort of ASP.net-related page ("Preload.aspx").
	# We have to append "preload=true" and load it a second time in order
	# to continue.
	# (Maybe there's a more elegant way to do this?)
	$self->mech->get( $self->mech->uri . '&preload=true' );

	# Now we can get whatever page we want.
}


=head2 get_usage

Get your data usage in GB. You must log in first with login().

Returns an integer, or undef if the data could not be found.

=cut

sub get_usage {
	my $self = shift;
	# TODO: check if we're actually logged in.
	# Load the Usage page.
	$self->mech->get( $USAGE_URL );
	# Pull the usage data from the HTML.
	return $self->_get_usage_from_content($self->mech->content)
}

# Extract the usage data from HTML.
sub _get_usage_from_content {
	my $self = shift;
	my $html = shift || croak("HTML content argument missing");

	# These GB values are integers, or "<1" for "less than one GB".
	my ($used) = $html =~ /<span id="[^"]*Used[^"]*">(<?\d+)GB<\/span>/s;
	my ($remaining) = $html =~ /<span id="ctl00_ctl00_ContentArea_PrimaryColumnContent_UsedWrapper"><?(<?\d+)GB<\/span>/s;
	
	# Get rid of that pesky less-than sign.
	if($used && $used eq '<1') {
		$used = 0;
	}
	if($remaining && $remaining eq '<1') {
		$remaining = 0;
	}

	# Sanity check
	if (!defined($used) && $self->debug > 0) {
		carp("could not find usage data in HTML.");
		# Try to find the chunk of HTML that generally has what we need.
		my ($dataused) = $html =~ /<div id="ctl00_ctl00_ContentArea_PrimaryColumnContent_ctl18_DataUsed"(.+?)<\/div>/s;
		if ($dataused) {
			carp($dataused);
		} else {
			# Just print the entire thing.
			carp($html);
		}
	}

	return $used;
}

=head2 get_budgeted_usage

Get your budgeted data usage in GB.  For planning purposes, you'll want to correlate this value with what you get from get_usage().

Each month Comcast resets their counters to zero. If your cap is 250 GB/month, then on the first day of the month, you should use about 8 GB. After the second day of the month, your usage should be up to 16 GB. After the third day, 24 GB. And so on...

This get_budgeted_usage() method does the math for you. Using localtime(), it will figure out how much bandwidth you should have used B<right now>. If you graph this value, it will give you a trend line that will help you know how well you're doing at staying under your limit.

This method returns a value with a resolution of one hour.  Remember that Comcast says their system is delayed up to three hours. If you suddenly download down 10GB of data, it may not show up on their site's meter until three hours later.

Pure math, no HTTP involved.

Returns a floating point value.

=cut

sub get_budgeted_usage {
	my $self = shift;

	# Get today's date info.
	my (undef, undef, $hour, $day, $month, $year) = localtime;
	$month++;
	$year += 1900;
	# Get the number of hours elapsed so far. 
	my $hours = $hour + ($day * 24);
	# Get the total number of hours in this month.
	my $days_in_month = Days_in_Month($year, $month);
	my $hours_in_month = $days_in_month * 24;
	# Divide "now" by the total number of hours.
	my $fraction = $hours / $hours_in_month;
	# Find out our budgeted GB value.
	my $budgeted_gb = $self->max_gb * $fraction;
	$budgeted_gb = sprintf("%.3f", $budgeted_gb);
	return $budgeted_gb;
}

1;
__END__

=head1 AUTHOR

Ken Dreyer, C<< <ktdreyer at ktdreyer.com> >>


=head1 ACKNOWLEDGEMENTS

All the brave souls on the internet who have tried to scrape this bandwidth information and failed.

=head1 SEE ALSO

Comcast's L<"Data Usage Meter Information"|http://networkmanagement.comcast.net/datausagemeter.htm> documentation. 

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Ken Dreyer.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
