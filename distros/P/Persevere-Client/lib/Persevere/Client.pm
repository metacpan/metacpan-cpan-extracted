package Persevere::Client;

use warnings;
use strict;
use JSON;
use LWP::UserAgent;
use HTTP::Request qw(GET HEAD POST PUT DELETE);
use HTTP::Status;
use HTTP::Headers;
use HTTP::Response;
use HTTP::Cookies;
use Persevere::Client::Class;
use Carp qw(confess carp);
use Encode qw(encode);

=head1 NAME

Persevere::Client - A Simple to use Interface to Persevere the JSON Database 

=head1 VERSION

Version 0.31

=cut

our $VERSION = '0.31';

sub new{
	my $class = shift;
	my %opt = @_ == 1 ? %{$_[0]} : @_;
	my %self;
	$self{module_version} = $VERSION;
	if ($opt{uri}){
		$self{uri} = $opt{uri};
		$self{uri} .= '/' unless $self{uri} =~ m{/$};
	}else{
		$self{uri} = ($opt{scheme} || 'http')      . '://' .
		($opt{host}   || 'localhost') . ':'   .
		($opt{port}   || '8080')      . '/';
	}
	$self{json} = ($opt{json} || JSON->new->utf8->allow_blessed);
	$self{ua}   = ($opt{ua}   || LWP::UserAgent->new(agent => ($self{agent} || "Persevere::Client/$VERSION")));
	if (defined $opt{query_timeout}){
		$self{query_timeout} = $opt{query_timeout};
	}else{
		$self{query_timeout} = 30;
	}
	# Throw this in an eval so other ua's don't croak here?
	$self{ua}->timeout($self{query_timeout});
	if (defined $opt{defaultSourceClass}){
		$self{defaultSourceClass} = $opt{defaultSourceClass};
	}

	$self{auth_type} = ($opt{auth_type} || "basic");
    if (!( ($self{auth_type} eq "json-rpc") || ($self{auth_type} eq "basic") || ($self{auth_type} eq "none") )){
        confess "Invalid auth type. Choices are json-rpc, basic, or none";
    }elsif (!($self{auth_type} eq "none")){
        $self{username} = $opt{username} || confess "A username must be provided if auth_type is not set to none";
        $self{password} = $opt{password} || confess "A password must be provided if auth_type is not set to none";
		if ($self{auth_type} eq "json-rpc"){
	# Not Implemented yet
#			$self{ua}->cookie_jar(HTTP::Cookies->new);
#			my $auth_string = '{"method":"authenticate", "params":[ "' . $self{username} . '":"' . $self{password} . '"], "id":"call0"}';
#			my $authin = $self{ua}->(HTTP::Request->new(POST, $self{uri} . "/Class/User", undef, $auth_string ));
#			my $authin = $self{req}->('POST', $self{uri} . "/Class/User", undef, $auth_string);
#			print $authin->{status_line} . "\n";
		}elsif ($self{auth_type} eq "basic"){
			$self{ua}->default_headers->authorization_basic($self{username}, $self{password});
		}
    }	

	$self{ua}->default_headers->push_header('Accept' => "application/json"); 

	if (defined $opt{debug}){
		$self{debug} = $opt{debug};
	}else{
		$self{debug} = 0;
	}
	
	if (defined $opt{showwarnings}){
		$self{showwarnings} = $opt{showwarnings};
	}else{
		$self{showwarnings} = 1;
	}

	if (defined $opt{exist_is_error}){
		$self{exist_is_error} = $opt{exist_is_error};
	}else{
		$self{exist_is_error} = 0;
	}

    return bless \%self, $class;
}

sub testConnection{
	my $self = shift;
	my $testpath =  $self->{uri} . "status";
	my $testresponse = $self->req('GET', $testpath, undef, undef, 1);
	if (!($testresponse->{success})){
		return 0;
	}else{
		return 1;
	}
}

sub serverInfo{
	my $self = shift;
	my $inforesponse = $self->req('GET', "$self->{uri}status", undef, undef, 1);
	if ($self->testConnection){
		return $inforesponse;
	}
}

sub classExists{
	my $self = shift;
	my $ClassName = shift;
	if (!(defined $ClassName)){
		$self->alert("No class passed to classExists, classExists requires a class name to properly function");
	}
	if ($self->{debug}){
                print "DEBUG (FUNCTION classExists): GET $self->{uri}Class/$ClassName\n";
        }
  	my $classresponse = $self->req('GET', "$self->{uri}Class/$ClassName", undef, undef, 1);
  	if ($classresponse->{success}){
		return 1;
	}else{
		return 0;
	}
}
# ***** Warning *****
# this does not represent how the user interface will behave once implemented
# These are just personal notes
# ***** Warning *****
#sub newUser{
#	my $self = shift;
#	my $user = shift;
#	my $pass = shift;
#	my $userresponse = $self->req('POST', "$self->{uri}Class/User", undef, 
#		'{"method":"createUser","id":"register","params":["' . $user . '","' . $pass . '"]}');
#	if ($userresponse->{code} == 204){
#		return 0;
#	}else{
#		if ($self->{debug}){
#			carp $userresponse->{status_line};
#		}
#		return 1;
#	}
#}

sub listClassNames{
	my $self = shift;
	my @classlist;
	my $classresponse = $self->req('GET', "$self->{uri}Class/");
	if ($self->{debug}){
                print "DEBUG (FUNCTION listClassNames): GET $self->{uri}Class/\n";
        }
	my @allclasses = $classresponse->{data};
	my @inside = @{$allclasses[0]};
	foreach my $item (@inside){
		if (defined $item->{core}){
			if ($item->{core} == 1){
				next;
			}else{
				push @classlist, $item->{id};
			}	
		}else{
			push @classlist, $item->{id};
		}
	}
	$classresponse->{data} = \@classlist;
	return $classresponse;
}

sub req{
	my $self = shift;
	my $meth = shift;
	my $path = shift;
	my $header = shift;
	my $cont = shift;
	my $nowarn = shift;
	my $noencode = shift;
	my $content;
	if (!(defined $nowarn)){
		$nowarn = 0;
	}
	if (!(defined $noencode)){
		$noencode = 0;
	}
	if ($noencode){
		$content = $cont;
	}elsif (ref $cont){
		$content = encode('utf-8', $self->{json}->encode($cont));
	}
	my $dheader; # debug header
	if (!(defined $header)){
		$dheader = "";
	}
	if (!(defined $content)){
		$content = "";
	}
#	if ($self->{debug}){
#		print "DEBUG (FUNCTION req): Method: $meth Path: $path Header: $dheader Content: $content NoWarn: $nowarn NoEncode: $noencode\n";
#	}
	
	my $res = $self->{ua}->request(HTTP::Request->new($meth, $path, $header, $content));
	my $query = "$meth, $path, $dheader, $content";
	my $auth_status;
	if ($res->code == 401){
		$auth_status = 0;
	}else{
		$auth_status = 1;
	}
	my $ret = {
		code => $res->code,
		status_line => $res->status_line,
		success => 0,
		content => $res->content,
		auth => $auth_status,
		query => $query
	};
	if ($res->is_success){
		$ret->{success} = 1;
		if (!($noencode)){
			$ret->{data} = $self->{json}->decode($res->content);
		}else{
			$ret->{data} = $res->content;
		}
		$ret->{range} = $res->header('Content-Range') if (defined $res->header('Content-Range'));
	}else{
		if (!($nowarn)){
			$self->alert($res->content);
		}
	}
	return $ret;
}

sub alert {
    my $self = shift;
    my @message = @_;
    if ($self->{showwarnings}){
        carp @message;
    }
}

sub class{
	my $self = shift;
	my $ClassName = shift;
	return Persevere::Client::Class->new(name => $ClassName, client => $self);
}

=head1 SYNOPSIS

This module Is a simple interface to Persevere, the JSON Database.

This module provides an interface similar to that of Couchdb::Client

View documentation on Persevere::Client::Class for information on how
to interact with Persevere Classes.

use Persevere::Client;

  my $persvr = Persevere::Client->new(
    host => "localhost",
    port => "8080",
    auth_type => "basic",
    username => "user", 
    password => "pass"  
  );

  die "Unable to connect to $persvr->{uri}\n" if !($persvr->testConnection);
  my $status;
  my $statusreq = $persvr->serverInfo;
  if ($statusreq->{success}){
      $status = $statusreq->{data};
  }
  print "VM: $status->{vm}\nVersion: $status->{version}\n";
  print "Class File Exists\n" if $persvr->classExists("File");
  print "Class Garbage Doesn't Exist\n" if (!($persvr->classExists("garbage")));
  my @class_list;
  my $classreq = $persvr->listClassNames;
  if ($classreq->{success}){
      @class_list = @{$classreq->{data}};
  }

=head1 MEATHODS 

=over 8

=item new

Constructor

uri - Takes a hash or hashref of options: uri which specifies the server's URI; scheme, host, port which are used if uri isn't provided and default to 'http', 'localhost', and '8080' respectively; 

json - which defaults to a JSON object with utf8 and allow_blessed turned on but can be replaced with anything with the same interface; 

ua - which is a LWP::UserAgent object and can also be replaced.

agent - Replace the name the defaut LWP::UserAgent reports to the db when it crud's 

debug - boolean, defaults to false, set to 1 to enable debug messages (show's crud sent to persevere). 

auth_type  - can be set to basic, json-rpc, or none, basic is default, and throws an error without a username and password. json-rpc auth is not yet implemented.

query_timeout - how long to wait until timing out on a request, defaults to 30. 

exist_is_error - return an error if a class we try and create already exists

showwarnings - carp warning messages 

=item testConnection

Returns true if a connection can be made to the server, false otherwise.

=item req

All requests made to the server that do not have a boolean response return a req hash. 
  All req hashes contain:
    code - http status code
    status_line - http status_line (this is what you use to debug why a request failed)
    success - false for failure, true for success
    content - content of the request
    auth - false if authentication failed for the query, true if authentication succeeded
  
  Successful requests contain:
    data - decoded json data, when assigning this to a variable its type must be declared. most data will be arrays, with the exception of status. 
    Example: 
    my $postreq = $initialclass->createObjects(\@post_data);
    if ($postreq->{success}){
        foreach (@{$postreq->{data}}){
	    print "$_\n";
	}
    }else{
        warn "unable to post data";
    }

    range - if applicable returns the range header information for the request.

	using req hashes provides a uniform approach to dealing with error handling for auth, and failed requests.

=item serverInfo

Returns a req hash, server metadata is contained in {data}, and is typically something that looks like { id => "status", version => "1.0 beta 2" ... }. It throws an warning if it can't connect.

=item classExists

Returns true if a class of that name exists, false otherwise.

=item listClassNames

Returns an req hash, with {data} containing all non core class names that the server knows of.

=item class

Returns a new Persevere::Client::Class object for a class of that name. Note that the Class does not need to exist yet, and will not be created if it doesn't. The create method will create the class, and is documented in Persevere::Client::Class

=back

=head1 AUTHOR

Nathanael Anderson, C<< <wirelessdreamer at gm]a[il d[0]t com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-persevere-client at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Persevere-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Persevere::Client


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Persevere-Client>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Persevere-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Persevere-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/Persevere-Client/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to mst in #perl-help on irc.perl.org for looking over the code, and providing feedback

=head1 COPYRIGHT & LICENSE

Copyright 2009-2011 Nathanael Anderson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Persevere::Client
