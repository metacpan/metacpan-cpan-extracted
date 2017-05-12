#!/usr/bin/perl
use warnings;
use strict;
use Persevere::Client;
use JSON::XS;

my $json = JSON::XS->new;

my $persvr = Persevere::Client->new(
	host => "localhost",
	port => "8080",
	auth_type => "none",
#	auth_type => "basic",
#	username => "test",
#	password => "pass",
	debug => 1,
	defaultSourceClass => "org.persvr.datasource.InMemorySource",
#	base_uri => "activetalker"
);

# createObjects requires an array of hashes, so push your objects (hashes) onto an array

my $className = "Conference";
my $initialclass = $persvr->class($className)->uuid;

if (!($initialclass->exists)){
	my $outcome = $initialclass->create;
	if (!($outcome->{success})){
		warn "Error creating " . $initialclass->{name} . "\n";
	}
}else{
	my $datareq = $initialclass->query("");
	if ($datareq->{success}){
		my @data = @{$datareq->{data}};
                my @new_data;
                foreach my $item (@data){
			my $outcome = $initialclass->deleteById($item->{id});
			if (!($outcome->{success})){
         		       print "Unable to delete item.\n";
        		}
		}
	}
#	$initialclass->delete;
#	my $outcome = $initialclass->create;
#	if (!($outcome->{success})){
#		warn "Error creating " . $initialclass->{name} . "\n";
#	}
}

my @conf_list = qw(asdf dsac woeid asec 123jfi ascoin WMFDe);

# Create Conferences
foreach my $pos (1 .. 100){
	my $userid = "user$pos";
	my $confid = $conf_list[int(rand(5))];
	my $roomnum = "room" . int(rand(10));
	my %hash = (
		id => $userid,
		confId => $confid,
		fullname => "User $pos",
		room => $roomnum,
		talking => 0
	);
#	print time() . " ID: $userid\tCID: $confid\tRm: $roomnum\n";
	my @post_data;
	push @post_data, \%hash;
	my $postreq = $initialclass->updateObjects(\@post_data);
	if (!($postreq->{success})){
					warn "unable to post data";
	}
}
