#!/usr/bin/perl
use warnings;
use strict;
use Persevere::Client;
use JSON::XS;
use Data::Dumper;

my $json = JSON::XS->new;

my $persvr = Persevere::Client->new(
	host => "localhost",
	port => "8080",
	auth_type => "none",
#	auth_type => "basic",
#	username => "test",
#	password => "pass",
	debug => 1,
	defaultSourceClass => "org.persvr.datasource.InMemorySource"
);


sub createTestObjects {
    my $total = shift;
    my @data;
    my $type;
    for (my $loop = 1; $loop <= $total; $loop++){
        if (($loop % 2) == 0) {
            $type = "even";
        }else{
            $type = "odd";
        }
        chomp $type;
        my %hash = ("name$loop" => "test$loop", "type" => $type, "value" => $loop);
        push @data, \%hash;
    }
    return @data;
}


sub show_classes {
	my @class_list;
	my $classreq = $persvr->listClassNames;
		if ($classreq->{success}){
	    @class_list = @{$classreq->{data}};
	}
	print "Classes:\n";
	print $json->encode(\@class_list) . "\n";
}

my @post_data;
# createObjects requires an array of hashes, so push your objects (hashes) onto an array
push @post_data, createTestObjects(10);
my $className = "updateClass";
my $initialclass = $persvr->class($className);
my $deleteclass = $persvr->class("deleteClass");
print "Class: " . $initialclass->fullname . "\n";

if (!($initialclass->exists)){
	my $outcome = $initialclass->create;
	if ($outcome->{success}){
		print "Created " . $initialclass->{name} . "\n";
	}else{
		die "Error creating " . $initialclass->{name} . "\n";
	}
}else{
	print "class $className already exists\n";
}

show_classes();

my $postreq = $initialclass->createObjects(\@post_data);
if (!($postreq->{success})){
	warn "unable to post data";
}else{
#	print "Posted " . $json->encode(\@{$postreq->{data}}) . "\n";
}



while (1){

	if (!($deleteclass->exists)){
		my $outcome = $deleteclass->create;
		if ($outcome->{success}){
			print "Created " . $deleteclass->{name} . "\n";
		}else{
			die "Error creating " . $deleteclass->{name} . "\n";
		}
	}else{
		print "class $className already exists\n";
	}
	my $postreq1 = $deleteclass->createObjects(\@post_data);
		if (!($postreq1->{success})){
		warn "unable to post data";
	}else{
#		print "Posted " . $json->encode(\@{$postreq1->{data}}) . "\n";
	}
	if ($initialclass->exists){
		my @results;
		my $datareq = $initialclass->query("[?type='even']");
		if ($datareq->{success}){
			my @data = @{$datareq->{data}};
			my @new_data;
			foreach my $item (@data){
				if ($item->{type} eq "even"){
					$item->{value} += 1;
					push @new_data, \%{$item};
				}
			}
			my $update = $initialclass->updateObjects(\@new_data);
			if ($update->{success}){
				print "Successfully updated " . $initialclass->fullname . "to:\n";
	#			print "posted " . $json->encode(\@{$update->{data}}) . "\n";
			}else{
				print "Failed update\n";
			}
		}else{
			print "Query unsuccessful\n";
		}
		if ($datareq->{auth}){
			print "this user has rights to correctly preform the action they just executed\n";
		}
		# Use this to debug problems
		# print $json->pretty->encode(\%{$datareq}) ."\n";
	}

	if ($deleteclass->delete){
		print "Successfully deleted " .$initialclass->fullname . "\n";
	}
}
