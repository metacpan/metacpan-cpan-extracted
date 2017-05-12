package Symbol::Table;

use 5.008;

use strict;
use warnings;
use Data::Dumper;
use Carp;

our $VERSION = '1.01';

#########################################################################
sub _callers_package_name
#########################################################################
{
	# @_ contains 0 or 1 item
	# item is a string containing the name of the package
	# whose symbol table we want to create.
	# note: package name looks like a regular perl package name,
	#       it does NOT look like a perl symbol table name
	#	i.e. use 'main::mypackage', dont use 'main::mypackage::'
	# if item is missing, use package name of caller.

	my $pkg_name;
	if(scalar(@_)==1) 
		{
		# if caller passes in a package
		$pkg_name=shift(@_) ;
		}
	else
		{
		# by default, create a symbol table for callers package
		$pkg_name='main::'. ((caller(1))[0]); 
		}

	unless($pkg_name=~m{^[\w:]+$})
		{
		croak "bad package name '$pkg_name'";
		}

	return $pkg_name;
}


my %warehouse;

# no GLOB and no NAME
my @element_types_array = qw(SCALAR ARRAY HASH CODE );
sub ElementTypes
{
	return (@element_types_array);
}

my @hierarchy_types_array = qw(PACKAGE);
sub HierarchyTypes
{
	return (@hierarchy_types_array);
}

sub AllTypes
{
	return (@element_types_array, @hierarchy_types_array);
}


my %valid_type_hash;
map{$valid_type_hash{$_}=1;} AllTypes;

#########################################################################
# Create a tied hash that access things of a particular type in symbol table
# (type is scalar, array, hash, code, glob, filehandle, name, package)
#########################################################################
sub New
{
	my $class=shift(@_);

	my $type = 'PACKAGE';
	$type = shift(@_) if (scalar(@_));

	unless(exists($valid_type_hash{$type}))
		{
		print "I can handle the following types "
			.join(" ", AllTypes)."\n";
		croak "Error: bad type '$type'";
		}	


	my $pkg_name = _callers_package_name(@_);

	my %hash;
	tie %hash, 'Symbol::Table::Tie', $pkg_name.'::', $type;

	my $ref = \%hash;

	bless $ref, $class;

	$warehouse{$ref}=
		{
		PackageName => $pkg_name,
		Type	=> $type,
		};

	return $ref;
	
}


sub Package
{
	return $warehouse{$_[0]}->{PackageName}; 
}

sub Type
{
	return $warehouse{$_[0]}->{Type}; 
}

sub InvoiceWarehouse
{
	print Dumper \%warehouse;
}

sub DESTROY
{
	my $obj=$_[0];
	delete($warehouse{$_[0]});
}

#########################################################################
#########################################################################
package Symbol::Table::Tie;
#########################################################################
#########################################################################
use Data::Dumper;
use Carp;

sub SYMBOL_TABLE_NAME    {0;}	# main::mypackage::subpackage::
sub SYMBOL_TABLE_TYPE    {1;}	# CODE or ARRAY etc


sub debugging
{
	return unless($::DEBUG);

	my ($pkg, $filename, $linenum) = caller(0);

	my $suffix = " at $filename line $linenum\n";

	my $msg = shift(@_);

	$msg .= $suffix;

	warn $msg;
}


sub TIEHASH
{
	debugging( "TIEHASH" );
	debugging Dumper \@_;	

	my ($class, $st_name, $type)=@_;

	my $st_package = $st_name;
	$st_package =~ s{::$}{};

	my $obj=[];
	$obj->[SYMBOL_TABLE_NAME]=$st_name;
	$obj->[SYMBOL_TABLE_TYPE]=$type;

	return bless $obj, $class;
}



sub DESTROY
{
	debugging "DESTROY";
	my ($obj)=@_;

}

sub FETCH
{ 
	no strict; no warnings;

	my ($obj, $key)=@_;
	debugging "FETCH: looking for key '$key' in ". $obj;

	if($obj->[SYMBOL_TABLE_TYPE] eq 'PACKAGE')
		{
		my $new_package_name = $obj->[SYMBOL_TABLE_NAME] . $key;
		debugging "new_package_name is $new_package_name";
		my $new_obj = 
			Symbol::Table->New('PACKAGE', $new_package_name );
		return $new_obj;
		}
	else
		{
		local *local_val;
		my $eval=
			  '*local_val = $' 
			. $obj->[SYMBOL_TABLE_NAME] 
			. "{$key};";
	
		debugging "eval is >>>$eval<<<\n";
		eval($eval); 
	
		my $st_type = $obj->[SYMBOL_TABLE_TYPE];
	
		my $ret = *local_val{$st_type};
		return $ret;
		}


}

sub STORE
{
	debugging "STORE";
	my ($obj, $key, $value)=@_;

	my $st_type = $obj->[SYMBOL_TABLE_TYPE];

	my $val_type = ref($value);
	croak "Must store a reference, not value '$value'"
		unless($val_type);

	croak "Type mismatch, $st_type ne $val_type" 
		if ($st_type ne $val_type);

	my $eval='*' . $obj->[SYMBOL_TABLE_NAME] . $key."=\$value;";

	debugging "eval is >>>$eval<<<\n";
	eval($eval); 


}

sub FIRSTKEY
{
	debugging "FIRSTKEY";
	my ($obj)=@_;

	my $eval='@keys = keys( %'.$obj->[SYMBOL_TABLE_TYPE].');';
	debugging "eval is >>>$eval<<<";
	eval($eval); 

	return $obj->NEXTKEY(); #prevkey doesnt matter

}


my %pass_condition_for_type =
	(
	SCALAR => '$boolean=1 if(defined($sym));' ,
	ARRAY  => '$boolean=1 if(defined(@sym));' ,
	HASH   => '$boolean=1 if(defined(%sym));' ,
	CODE   => '$boolean=1 if(defined(&sym));' ,
	PACKAGE=> '$boolean=1 if($key=~m{::$});' ,
	);

sub NEXTKEY
{
	debugging "NEXTKEY";
	my ($obj, $prevkey)=@_; # prev key is ignored

	my $st_type = $obj->[SYMBOL_TABLE_TYPE];
	my $st_name = $obj->[SYMBOL_TABLE_NAME];

	die "Error: no pass condition defined for type '$st_type'" 
		unless(exists($pass_condition_for_type{$st_type}));

	my ($eval, @keys, $key, $val, $bool);

	local *sym;

	while(1)
		{
		$eval ='($key, $val) = 
			each( %'.  $obj->[SYMBOL_TABLE_NAME] .');';
		debugging "eval is >>>$eval<<<";
		eval($eval); 

		return undef unless(defined($key));
		next if($key =~ m{^(_|[^\w])});

		# main:: symbol table contains a reference to itself.
		# which means you get infinitely recursive symbol tables.
		# main::main::main::main:: etc
		# which isn't very useful. 
		# if the key is 'main::' just ignore it and 
		# look for the next one
		next if($key eq 'main::');	

		my $boolean=0;

		$eval  = 'no warnings; no strict;';
		$eval .= ' *sym = $'.$st_name.'{'.$key.'}; ' ;
		$eval .= $pass_condition_for_type{$st_type};

		debugging "eval is >>>$eval<<<";
		eval($eval); 

		debugging "boolean is $boolean";

		$key =~ s{::$}{};

		return $key if ($boolean); 

		}

}


1;




1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Symbol::Table - An easy interface to symbol tables (no eval(), no *typeglobs )

=head1 SYNOPSIS

  use Symbol::Table;

  # constructor takes two arguments, 
  # which TYPE of symbols (PACKAGE,CODE,SCALAR,ARRAY,HASH)
  # and what package namespace do you wish to examine
  # the return value is a symbol table object.
  my $st_pkg = Symbol::Table->New('PACKAGE', 'main');

  # the keys to a PACKAGE type symbol table are all the 
  # sub packages under the objects namespace.
  # For all other types, the keys are the names of the
  # symbols (of that TYPE) in the objects namespace.
  foreach my $subpkg (keys(%$st_pkg))
	{
	print "package main contains package '$subpkg'\n";
	}

=head1 ABSTRACT

Symbol::Table allows the user to manipulate Perl's symbol table
while hiding all those nasty eval's and *typeglobs from the user.
Symbol::Table gives the user an object oriented interface to perl's
actual symbol table. The constructor returns a reference to a tied
hash as a Symbol::Table object. The object acts like a reference
to a hash: the keys are the name of the symbols in the symbol table,
and the values are references to the symbol itself. The tied bit of
magic allows changes in the actual symbol table to be reflected
as changes in the tied hash. Tieing also allows assignments to the
hash to translate into assignments into perl's actual symbol table.

=head1 DESCRIPTION

=head2 Disclaimer

This code is an "acedemic exercise" in manipulating perl's symbol table.
It wasn't coded to be fast or efficient. It was simply coded to provide
the functionality I wanted it to provide.  If you look at the code,
you'll notice numerous calls to a subroutine called "debugging",
which prints out a string if $main::DEBUG is set. If your script uses
the -s perl option, then you can turn on debugging by calling your
script with a -DEBUG command line option. This is grossly inefficient
from a speed perspective, however.


=head2 Constuctor

The Symbol::Table constructor is a method called New. It takes up to two
parameters and returns a Symbol::Table object. 

	my $symbol_table = Symbol::Table->New( TYPE, PACKAGENAME );

You can create symbol tables of 5 different TYPES:

	PACKAGE
	SCALAR
	ARRAY
	HASH
	CODE

The symbol table created will only contain the symbols of the TYPE specified
to the constructor. If no TYPE is specified, the default TYPE is PACKAGE.

The PACKAGENAME specifies the name of the package whose symbol table for 
which you wish to construct a Symbol::Table object. The PACKAGENAME format
is a standard perl package name. It is NOT the format used for perl
symbol table entries. In other words, use 'main::MyPackage' and do NOT use
'main::MyPackage::'.

If no PACKAGENAME is specified, the constructor defaults to the name of
the package from which the constructor was called. If you wish to override
the default PACKAGENAME, then you must also specify the TYPE when calling
the constructor.

	package SomePackage

	# TYPE = PACKAGE,  PACKAGENAME = 'main::SomePackage'
	my $my_pkg_st = Symbol::Table->New;


	# TYPE = SCALAR, PACKAGENAME = 'main::SomePackage'
	my $my_scalar_st = Symbol::Table->New('SCALAR');

	# TYPE = HASH, PACKAGENAME = 'main'
	my $main_hash_st = Symbol::Table->New('HASH', 'main');


=head2 Hash Keys

The constructor returns a reference to a hash. The keys of the hash are
the names of the symbols of the TYPE in the symbol table of the PACKAGENAME
specified to the constructor.

=head2 Hash Keys when TYPE is PACKAGE

A Symbol::Table of TYPE PACKAGE, PACKAGENAME 'main::MyPackage' will contain 
keys that are all the packages under package 'main::MyPackage'. If there is
a package called MyPackage::SubPackage, then one of the keys in the hash
will be 'SubPackage'.

	# print all the packages contained "under" a package namespace
	package MyPackage::SubPackageOne;
	package MyPackage::SubPackageTwo;
	package MyPackage;
	use Symbol::Table;

	my $st = Symbol::Table->New;
	foreach my $subpkg (keys(%$st))
		{
		print "MyPackage contains package '$subpkg'\n";
		}

=head2 Hash Keys when TYPE is not PACKAGE

A Symbol::Table of any other TYPE (SCALAR ARRAY HASH CODE) will contain 
keys that name all the symbols of that TYPE in PACKAGENAME.

	# print the names of all scalars in the current package
	package MyPackage;
	use Symbol::Table;

	our $our_scalar=0; $our_scalar++;

	my $st = Symbol::Table->New('SCALAR');
	foreach my $scalar (keys(%$st))
		{
		print "MyPackage contains scalar '$scalar'\n";
		}

=head2 Hash Values when TYPE is PACKGAGE

A Symbol::Table of TYPE PACKAGE contains values that are Symbol::Table objects
for the package specified by the key. The key is a package name contained
under the current namespace. The value is a Symbol::Table object of TYPE
PACKAGE for that package.

This bit of code prints out all the package names spaces from 'main' down:

	# print a representation of all package names current used.
  	use Symbol::Table;

  	my $st = Symbol::Table->New('PACKAGE', 'main');

	sub ShowPackages
	{
		my ($symbol_table, $indent)=@_;
	
		while( my($subpkgname, $subpkgsymtab)= each(%$symbol_table))
			{
			print $indent.$subpkgname."\n";
			ShowPackages($subpkgsymtab, $indent."\t");
			}
	}

	ShowPackages($st, "\t");

When I ran the above example, it printed out the text below. Note that
package Data::Dumper translates into a package 'Data' containing a package 
'Dumper'. Here's my output:

	attributes
	DB
	Data
		Dumper
	overload
	UNIVERSAL
	DynaLoader
	Exporter
		Heavy
	warnings
	IO
		Handle
	strict
	Carp
		Heavy
	XSLoader
	mypackage
		subpackage
			belowpackage
	Symbol
		Table
			Tie



=head2 Hash Values when TYPE is not PACKGAGE


A Symbol::Table of any other TYPE (SCALAR ARRAY HASH CODE) will contain values
that are references to the actual symbol in the symbol table.

You can print out the value of a scalar named $our_scalar contained 
in package 'main::OtherPackage' like this:

	package OtherPackage;
	our $our_scalar=13;

	package MyPackage;

	my $st = Symbol::Table->New('SCALAR', 'main::OtherPackage');
	my $val = $st->{our_scalar};
	print "val is $val\n";

Continuing this example, you could then change the value of the scalar:

	my $override=42;
	$st->{our_scalar}=\$override;


Remember, the hash VALUE is a REFERENCE to the data, not the data itself.
That's why there's a '\' in front of $override in the above example.

If you want to convert someone's package variable into a package constant,
you could do this:


	package OtherPackage;
	our $our_scalar=13;

	package MyPackage;
	use Symbol::Table;

	my $st = Symbol::Table->New('SCALAR', 'main::OtherPackage');

	# using a reference to a CONSTANT.
	$st->{our_scalar}=\42;

	# can still be read
	print "OtherPackage::our_scalar is ";
	print $OtherPackage::our_scalar ."\n";

	# assignment causes error:
	# "Modification of a read-only value attempted"
	$OtherPackage::our_scalar = 3;

Note: this is an example. I'm not recommending you do this in production code.

=head2 Using Symbol::Table to export subroutines

By creating a TYPE CODE Symbol::Table and assigning a code reference to
a subroutine name, you can install and even override any currently 
existing subroutine in your own or someone else's package namespace.

Note: I'm not recommending you do it this way, I'm only showing
how Symbol::Table would allow you to do it.



	package DumpTheDumper;

	sub import
		{
		use Symbol::Table;

		my $caller=caller;

		my $st=Symbol::Table->New('CODE', $caller);

		$st->{Dumper}= sub 
			{return "Dumper cant come to the phone now.\n";};

		}
	1;


If you then use DumpTheDumper in another file that also happened to 
use Data::Dumper then you might see some interesting behaviour.

	#!/usr/local/bin/perl

	use Data::Dumper;

	use DumpTheDumper;

	my $test_var = [ qw ( alpha bravo charlie delta ) ];

	print Dumper $test_var;


If you run this script, the output will look like this:

	Dumper cant come to the phone now.


The above example shows how to export to other packages, but it would be
just as easy to change a subroutine in your own package. 


=head2 EXPORT

None by default.

=head1 SEE ALSO

=head1 AUTHOR

Greg London, http://www.greglondon.com

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Greg London, All Rights Reserved

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
