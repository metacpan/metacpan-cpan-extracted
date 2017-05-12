#the dumb terminal webmysql module
#mt 21/09/2003 2.3	updated readkey sub
#mt 28/09/2003 2.3	updated readkey sub
package Plack::App::WebMySQL::Key;
BEGIN {
   use Exporter();
	use Plack::App::WebMySQL;
	@ISA = qw(Exporter);
   @EXPORT = qw(expireKeys createKey readKey updateKey deleteKey);
}
###############################################################################################################
sub expireKeys{	#deletes old keys from the server
	if(opendir(KEYS, "keys")){
		foreach(readdir(KEYS)){
			if($_ =~ m/^\d+$/ && (time - $_) > 86400){unlink("keys/$_");}	#valid key older than a day found
		}
		closedir(KEYS);
	}
	else{$error = "Could not check for expired keys: $!\n";}
}
###############################################################################################################
sub createKey{	#creates a new server side cookie
	my $key = time;
	if(!-e "keys/$key"){	#key does not exist already
		if(open(COOKIE, ">keys/$key")){close(COOKIE);}
		else{$error = "Could not create session file: $!";}
		return $key;
	}
	else{$error = "New session already exists";}
	return undef;	#must of got an error somewhere in this sub
}
###############################################################################################################
sub readKey{	#read the contents of a server side cookie back into the form hash
	if($_[0]){	#got a key to try and open
		if(open(COOKIE, "<keys/$_[0]")){
			while(<COOKIE>){
				chomp $_;
				if(m/^([A-Z0-9]+) = (.+)$/){
					#print STDERR "$0: cookie line: $1 = $2\n";
					$form{lc($1)} = $2;
				}	#store the valid lines
				#else{print STDERR "$0: Ignoring invalid session file line: $_\n";}	#log warning, not really a problem
			}
			close(COOKIE);
			return 1;	#everything ok
		}
		else{$error = "Your session has expired, please re-login";}
	}
	else{$error = "No session givin, please re-login";}
	return 0;
}
###############################################################################################################
sub updateKey{	#saves last form's data, overwriting the existing key file
	$_[0] =~ m/^(\d+)$/;	#untaint
	my @wanted = ("database", "password", "host", "user", "type", "fields", "criteria", "tables", "creationfnames", "creationftypes", "creationfsizes", "creationfnulls", "db", "insertdata\\d+");
	if(open(COOKIE, ">keys/$1")){
		foreach my $name (keys %form){
			my $found = 0;
			foreach(@wanted){	#dont save unwanted elements
				if($name =~ m/^$_/){
					$found = 1;
					last;
				}
			}
			if($found){print COOKIE uc($name) . " = " . $form{$name} . "\n";}	#save this hash element
		}
		close(COOKIE);
		return 1;	#everything ok
	}
	else{$error = "Cant write session file: $!";}
	return 0;
}
##############################################################################################################
sub deleteKey{
	$_[0] =~ m/^(\d+)$/;	#untaint
	unlink("keys/$1");
}
###############################################################################
return 1;
END {}
