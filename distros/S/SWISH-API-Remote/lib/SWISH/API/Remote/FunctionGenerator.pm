package SWISH::API::Remote::FunctionGenerator;

############################################
# makeaccessors( 'packagename', 'fieldname', ['fieldname'...])
#  makes functions called fieldname() and fieldname2() in the package 'packagename'
#  which will create functions to get/set, ie, 
#  $self->fieldname() and $self->fieldname( "value" )
# returns nothing useful
sub makeaccessors {
	my ($package, @list) = @_;
	for my $f (@list) {
		die "not a valid function name: $f" unless $f =~ /^[a-zA-Z][a-zA-Z0-9]*$/;
		(my $fu = $f) =~ s/^([a-z])/uc($1)/e;
		my $acc = "package $package; sub $fu { ";
		$acc .= "my \$self = shift; return \$self->{$f} unless (\@_); \$self->{$f} = shift; }; ";
		#warn "\n$acc\n";
        
		eval $acc;

		die "Failed to create function $package::$f: $@" if $@;
	} 
}

1;
