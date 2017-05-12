package DBMedit;


my $end = sub {
	#warn('--END--');
	for my $name(keys %{$DBM}){
		dbmclose(%{$DBM->{$name}}) if %{$DBM->{$name}}; 
	}
	die @_ if @_; 
};
$SIG{INT} = $end;
END {$end->();}

my $DBM     = {};
my $db_path = {}; # name=>path
my $name;


sub dbmopen {
	
	@_ == 2 or return 'parameter error .. dbmopen($name, $dbm_file_fullpath) ';
	
	$name = shift ;
	$db_path->{$name} = shift;
	
	return dbmopen(%{$DBM->{$name}}, $db_path->{$name}, 0666) || join "\t"=>( $! ,$name, $db_path->{$name} , __LINE__);
	#return scalar keys %{$DBM->{$name}};
}

sub dbmclose {
	$name = shift if @_;
#	if (%{$DBM->{$name}}) {
		delete $db_path->{$name};
		dbmclose(%{$DBM->{$name}}) ; 
		undef $name;
#	}
}

sub path { return $db_path }
sub name { $name = shift || return $name}

sub keys {
	#@_ or return 'parameter error .. keys($offset, $length) count=>'. &count();
	my ($offset, $length ) = @_;
	$offset ||= 0; 
	$length ||= 9;
	return (keys %{$DBM->{$name}})[$offset .. $length];
}


sub del {
	my $key = shift;
	return delete $DBM->{$name}->{$key};
}

sub get {
	my $key = shift;
	return $DBM->{$name}->{$key};
}

sub like {
	my $key = shift;
	$key = qr/$key/;
	my @list;
	for (keys %{$DBM->{$name}}) {
		/$key/ and push @list, $_;
	}
	return @list
}

sub gets {
	#my ($offset, $length ) = @_;
	my %h;
	%h = map {$_=>$DBM->{$_[2] || $name}->{$_}} &keys(@_);
	return \%h;
}

sub count {return scalar keys %{$DBM->{$name}};}
sub counts {
	my $h;
	for my $name(keys %{$DBM}){
		$h->{$name} = scalar keys %{$DBM->{$name}};
	}
	return $h;
}

sub copy {
	my ($name1, $name2, $key) = @_;
	$DBM->{$name2}->{$key} = $DBM->{$name1}->{$key};
}

sub copys {
	my ($name1, $name2, $offset, $length ) = @_;
	for my $key( (keys %{$DBM->{$name1}})[$offset .. $length]) {
		$DBM->{$name2}->{$key} = $DBM->{$name1}->{$key};
	}
}

1;

