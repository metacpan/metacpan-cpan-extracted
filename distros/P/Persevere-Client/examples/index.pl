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
#	password => "pass" 
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

my %hash1 = ("name" => "test01", "type" => "odd", "value" => 19);
my %hash2 = ("name" => "test02", "type" => "even", "value" => 20);


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
push @post_data, \%hash1;
push @post_data, \%hash2;
push @post_data, createTestObjects(4);
my $className = "NewClass";
my $initialclass = $persvr->class($className);
print "Class: " . $initialclass->fullname . "\n";

show_classes();
# users can check if a class exists either by using a class object, or by asking the server

print "class: " . $initialclass->exists . " " . $persvr->classExists("$className") . "\n";
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
	print "Posted " . $json->encode(\@{$postreq->{data}}) . "\n";
}

if ($initialclass->exists){
	my @results;
	my $datareq = $initialclass->query("[?type='even']");
	if ($datareq->{success}){
		my @data = @{$datareq->{data}};
		my @new_data;
		foreach my $item (@data){
			if ($item->{type} eq "even"){
				$item->{value} += 100;
				push @new_data, \%{$item};
			}
		}
		my $update = $initialclass->updateObjects(\@new_data);
		if ($update->{success}){
			print "Successfully updated " . $initialclass->fullname . "to:\n";
			print "posted " . $json->encode(\@{$update->{data}}) . "\n";
		}
	}
	if ($datareq->{auth}){
		print "this user has rights to correctly preform the action they just executed\n";
	}
}

if ($initialclass->delete){
	print "Successfully deleted " .$initialclass->fullname . "\n";
}
