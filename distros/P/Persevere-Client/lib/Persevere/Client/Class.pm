package Persevere::Client::Class;

use strict;
use warnings;

=head1 NAME

Persevere::Client::Class - The Class interface to Persevere the JSON Database 

=cut

our $VERSION = '0.31';

use HTTP::Request::Common qw(GET HEAD POST PUT DELETE);
use Carp        qw(confess);

sub new{
	my $class = shift;
	my %opt = @_ == 1 ? %{$_[0]} : @_;
	my %self;

	$self{name} = $opt{name} || confess "Persevere Class requires a name.";
	$self{name} .= '/' unless $self{name} =~ m{/$};
	$self{client} = $opt{client} || confess "Persevere requires a client.";
	return bless \%self, $class;
}

sub fullname {
	my $self = shift;
	my $name = $self->{name};
	$name =~ s/\/$//g;
	return $name;
}

sub exists {
	my $self = shift;
	my $name = $self->fullname;
	if ($self->{client}->classExists($self->fullname)){
		return 1;
	}else{
		return 0;
	}
}

sub properties{
	my $self = shift;
	my %args = @_;
	# TODO This should do some error checking
	$self->{properties} = \%args;
	return $self;
}

sub sourceClass{
	my $self = shift;
	my $sourceClass = shift;
	$self->{sourceClass} = $sourceClass;
	return $self;
}

sub uuid{ 
	my $self = shift;
	$self->{uuid} = 1;
	return $self;
}

sub nouuid{
	my $self = shift;
	$self->{uuid} = 0;
	return $self;
}

sub create {
	my $self = shift;
	my $classpath = $self->{client}->{uri} . "Class/";
	if ($self->fullname !~ /\w|\d/){
		$self->{client}->alert("No Name defined for class, Can't create it");
		my $failed = {
			success => 0
		};
		return $failed;
	}
	if (!($self->{client}->classExists($self->fullname))){
		my (%newclass, %extends);
		$extends{'$ref'} = "Object";
		$newclass{id} = $self->fullname;
		$newclass{extends} = \%extends;
		if ($self->{uuid}){
			$newclass{useUUIDs} = $self->{client}->{json}->true;
		}
		if (defined $self->{properties}){
			$newclass{properties} = \%{$self->{properties}};
		}
		if ((defined $self->{client}->{defaultSourceClass}) && (!(defined $self->{sourceClass}))){
			# if a default sourceClass is defined, and we didn't explicitly define a source class
			$self->{sourceClass} = $self->{client}->{defaultSourceClass};
		}
		if (defined $self->{sourceClass}){
			$newclass{sourceClass} = $self->{sourceClass};
		}
		if ($self->{client}->{debug}){
			print "DEBUG (FUNCTION create): POST $classpath " . $self->{client}->{json}->encode(\%newclass) . "\n";
		}
		my $req = $self->{client}->req('POST', $classpath, undef, \%newclass);
		$req->{path} = $classpath;
		return $req;
	}else{
		if ($self->{exist_is_error}){
			$self->{client}->alert("Class " . $self->fullname . " Already Exists");
		}
		return $self;	
	}
}

sub createObjects{
	my $self = shift;
	my $data = shift;
	my $classpath = $self->{client}->{uri} . $self->{name};
	if ($self->{client}->{debug}){
		print "DEBUG (FUNCTION createObjects): POST $classpath " . $self->{client}->{json}->encode(\@{$data}) . "\n";
	}my $req = $self->{client}->req('POST', $classpath, undef, $data);	
	if (!($req->{success})){
		$self->{client}->alert($req->{content});
	}
	
	$req->{path} = $classpath;
	return $req; 
}

sub updateObjects{
	my $self = shift;
	my $data = shift;
	my $classpath = $self->{client}->{uri} . $self->{name};
	if ($self->{client}->{debug}){
		print "DEBUG (FUNCTION updateObjects): PUT $classpath " . $self->{client}->{json}->encode(\@{$data}) . "\n";
	}
	my $req = $self->{client}->req('PUT', $classpath, undef, $data);	
	if (!($req->{success})){
		$self->{client}->alert($req->{content});
	}
	
	$req->{path} = $classpath;
	return $req;
}

sub idGet(){
	my $self = shift;
	my $id = shift;
	my $path = $self->{client}->{uri} . $self->{name} . $id;
	if ($self->{client}->{debug}){
		print "DEBUG (FUNCTION idGet): GET $path \n";
	}
	my $idresponse = $self->{client}->req('GET', $path, undef, undef, 1);
	$idresponse->{path} = $path;
	return $idresponse;
}

sub propSet(){
	my $self = shift;
	my $id = shift;
	my $data = shift;
	my $path = $self->{client}->{uri} . $self->{name} . $id;
	if ($self->{client}->{debug}){
		print "DEBUG (FUNCTION propSet): PUT $path $data \n";
	}
	my $idresponse = $self->{client}->req('PUT', $path ,undef, $data, 0, 1);
	$idresponse->{path} = $path;
	return $idresponse;
}

sub idExists(){
	my $self = shift;
	my $id = shift;
	my $path = $self->{client}->{uri} . $self->{name} . $id;
	if ($self->{client}->{debug}){
		print "DEBUG (FUNCTION idExists): GET $path\n";
	}
	my $idresponse = $self->{client}->req('GET', $path, undef, undef, 1);
	if ($idresponse->{code} == "404"){
		return 0;
	}else{
		return 1;
	}
}

sub queryRange(){
	my $self = shift;
	my $query = shift;
	my $sub_range_start = shift;
	my $sub_range_end = shift;
	my $classpath = $self->{client}->{uri} . $self->{name};
	my @original_data;

	my $header = HTTP::Headers->new;
	$header->header('Range' => "items=$sub_range_start-$sub_range_end");
	my $path = "$classpath$query";
	if ($self->{client}->{debug}){
		print "DEBUG (FUNCTION queryRange): GET $path $header\n";
	}	
	my $testresponse = $self->{client}->req('GET', $path, $header);

	if ($testresponse->{code} != 200){
		$self->{client}->alert($testresponse->{status_line});
	}
	return $testresponse;
}

sub query(){
	my $self = shift;
	my $query = shift;
	if (!(defined $query)){
		$query = '';
	}
	my $classpath = $self->{client}->{uri} . $self->{name};
	my @original_data;
	my $path = "$classpath$query";
	if ($self->{client}->{debug}){
		print "DEBUG (FUNCTION query): GET $path\n";
	}
	my $testresponse = $self->{client}->req('GET', $path);
	if ($testresponse->{code} != 200){
		$self->{client}->alert($testresponse->{status_line});
	}
	return $testresponse;
}

sub delete{
	my $self = shift;
	my $dpath = $self->{client}->{uri} . "Class/" .  $self->fullname;
	# this should be converted to use the req wrapper
	if ($self->{client}->{debug}){
		print "DEBUG (FUNCTION delete): DELETE $dpath\n";
	}
	my $res = $self->{client}->{ua}->request(DELETE $dpath);
	$res->{path} = $dpath;
	my $auth_status = 1;
	if ($res->code == 401){
		$auth_status = 0;
	}
	my $ret = {
		code => $res->code,
		status_line => $res->status_line,
		success => 0,
		content => $res->content,
		auth => $auth_status
	};
	if ($res->is_success){
		$ret->{success} = 1;
	}
	return $ret;	
}

sub deleteById{
	my $self = shift;
	my $id = shift;
	my $dpath = $self->{client}->{uri} . $self->fullname . "/$id";
	# this should be converted to use the req wrapper
	if ($self->{client}->{debug}){
		print "DEBUG (FUNCTION delete): DELETE $dpath\n";
	}
	my $res = $self->{client}->{ua}->request(DELETE $dpath);
	$res->{path} = $dpath;
	my $auth_status = 1;
	if ($res->code == 401){
		$auth_status = 0;
	}
	my $ret = {
		code => $res->code,
		status_line => $res->status_line,
		success => 0,
		content => $res->content,
		auth => $auth_status
	};
	if ($res->is_success){
		$ret->{success} = 1;
	}
	return $ret;	
}
=pod

=head1 SYNOPSIS

This module provides an interface to the classes in persevere

  $persvr = Persevere::Client->new(
    host => "localhost",
    port => "8080",
    auth_type => "basic",
    username => "test",
    password => "pass"
  );
  %hash1 = ("name1" => "test1", "type" => "odd");
  %hash2 = ("name2" => "test2", "type" => "even");
  push @post_data, \%hash1;
  push @post_data, \%hash2;
  # createObjects and updateObjects require and array of hashes
  $postreq = $initialclass->createObjects(\@post_data);
  $datareq = $initialclass->query("[?type='even']");
  # query returns an array of hashes
  if ($datareq->{success}){
	# array of hashes
    @data = @{$datareq->{data}};
  }

=head1 METHODS

=over 8

=item new

	This is called from Persevere::Client->class.

=item fullname

	Returns a scalar of the name of the class the object refers to, removes trailing slash.

=item exists

	Returns true if the class the object refers to exists.

=item create

	Creates the class the object refers to. calling $persvr->class("classname"); does not create a class, it only creates an object that refers to the class, calling create on that object creates the actual class.

=item delete

	Deletes the class the object refers to.

=item createObjects

	Creates new objects, takes an array of hashes as input.

=item updateObjects

	Updates existing objects, takes an array of hashes as input. Hashes must have id's correcly set to update objects.

=item queryRange

	Queries a range of results from the objects class.

=item query

	Queries all results from the objects class. 

=back

=head1 AUTHOR

Nathanael Anderson, C<< <wirelessdreamer at gm]a[il d[0]t com> >>

=head1 BUGS 

Please report any bugs or feature requests to C<bug-persevere-client at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Persevere-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE 

Copyright 2009-2011 Nathanael Anderson.

s program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Persevere::Client::Class
