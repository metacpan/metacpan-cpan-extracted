#!/usr/bin/perl -w

=head1 NAME

Quizzer::FrontEnd::Web - web FrontEnd

=cut

=head1 DESCRIPTION

This is a FrontEnd that acts as a small, stupid web server. It is worth noting
that this doesn't worry about security at all, so it really isn't ready for
use. It's a proof-of-concept only. In fact, it's probably the crappiest web
server ever. It only accpets one client at a time!

=cut

=head1 METHODS

=cut

package Quizzer::FrontEnd::Web;
use Quizzer::FrontEnd;
use Quizzer::Level;
use IO::Socket;
use IO::Select;
use CGI;
use strict;
use vars qw(@ISA);
@ISA=qw(Quizzer::FrontEnd);

my $VERSION='0.01';

=head2 new

Creates and returns an object of this class. The object binds to port 8001, or
any port number passed as a parameter to this function.

=cut

# Pass in the port to bind to, 8001 is default.
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;
	$self->{port}=shift || 8001;
	$self->{formid}=0;
	$self->{interactive}=1;
	$self->{capb} = 'backup';

	# Bind to the port.
	$self->{server}=IO::Socket::INET->new(
		LocalPort => $self->{port},
		Proto => 'tcp',
		Listen => 1,
		Reuse => 1,
		LocalAddr => '127.0.0.1',
	) || die "Can't bind to ".$self->{port}.": $!";

	print STDERR "Note: Debconf is running in web mode. Go to http://localhost:".$self->{port}."/\n";

	return $self;
}

=head2 client

This method ensures that a client is connected to the web server and waiting for
input. If there is no client, it blocks until one connects. As a side affect, when
a client connects, this also reads in any HTTP commands it has for us and puts them
in the commands property.

=cut

sub client {
	my $this=shift;
	
	$this->{'client'}=shift if @_;
	return $this->{'client'} if $this->{'client'};

	my $select=IO::Select->new($this->server);
	1 while ! $select->can_read(1);
	my $client=$this->server->accept;
	my $commands='';
	while (<$client>) {
		last if $_ eq "\r\n";
		$commands.=$_;
	}
	$this->commands($commands);
	$this->{'client'}=$client;
}

=head2 closeclient

Forcibly close the current client's connection to the web server.

=cut

sub closeclient {
	my $this=shift;
	
	close $this->client;
	$this->client('');
}

=head2 showclient

Displays the passed text to the client. Can be called multiple times to build up
a page.

=cut

sub showclient {
	my $this=shift;
	my $page=shift;

	my $client=$this->client;
	print $client $page;
}

=head2 go

This overrides to go method in the Base FrontEnd. It goes through each
pending Element and asks it to return the html that corresponds to that
Element. It bundles all the html together into a web page and displays the
web page to the client. Then it waits for the client to fill out the form,
parses the client's response and uses that to set values in the database.

=cut

sub go {
	my $this=shift;

	my $httpheader="HTTP/1.0 200 Ok\nContent-type: text/html\n\n";
	my $form='';
	my $id=0;
	my %idtoelt;
	foreach my $elt (@{$this->{elements}}) {
		# Each element has a unique id that it'll use on the form.
		$idtoelt{$id}=$elt;
		$elt->id($id++);
		my $html=$elt->show;
		if ($html ne '') {
			$form.=$html."<hr>\n";
		}
	}
	# If the elements generated no html, return now so we
	# don't display empty pages.
	return 1 if $form eq '';

	$this->{elements}=[];

	# Each form sent out has a unique id.
	my $formid=$this->formid(1 + $this->formid);

	# Add the standard header to the html we already have.
	$form="<html>\n<title>".$this->title."</title>\n<body>\n".
	       "<form><input type=hidden name=formid value=$formid>\n".
	       $form."<p>\n";

	# Should the back button be displayed?
	if ($this->capb_backup) {
		$form.="<input type=submit value=Back name=back>\n";
	}
	$form.="<input type=submit value=Next>\n";
	$form.="</form>\n</body>\n</html>\n";

	my $query;
	# We'll loop here until we get a valid response from a client.
	do {
		$this->showclient($httpheader . $form);
	
		# Now get the next connection to us, which causes any http
		# commands to be read.
		$this->closeclient;
		$this->client;
		
		# Now parse the http commands and get the query string out
		# of it.
		my @get=grep { /^GET / } split(/\r\n/, $this->commands);
		my $get=shift @get;
		my ($qs)=$get=~m/^GET\s+.*?\?(.*?)(?:\s+.*)?$/;
	
		# Now parse the query string.
		$query=CGI->new($qs);
	} until ($query->param('formid') eq $formid);

	# Did they hit the back button? If so, ignore their input and inform
	# the ConfModule of this.
	if ($this->capb_backup && $query->param('back') ne '') {
		return '';
	}

	# Now it's just a matter of matching up the element id's with values
	# from the form, and passing the values from the form into the
	# elements, for them to process, and then storing the processed data.
	foreach my $id ($query->param) {
		next unless $idtoelt{$id};
		
		$idtoelt{$id}->question->value($idtoelt{$id}->process($query->param($id)));
		$idtoelt{$id}->question->flag_isdefault('false')
			if $idtoelt{$id}->visible;
		delete $idtoelt{$id};
	}
	# If there are any elements that did not get a result back, that in
	# itself is significant. For example, an unchecked checkbox will not
	# get anything back.
	foreach my $elt (values %idtoelt) {
		$elt->question->value($elt->process(''));
		$elt->question->flag_isdefault('false')
			if $elt->visible;
	}
	
	return 1;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
