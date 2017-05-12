package Stlgen;

use warnings;
use strict;

use Template;
use Data::Dumper;

=head1 NAME

Stlgen - Create "Standard Template Library" (STL) C++ type containers but generate code in other languages.

=head1 VERSION

Version 0.012

=cut

our $VERSION = '0.012';


=head1 SYNOPSIS

Stlgen is based off the Standard Template Library (STL) for C++ here:

	http://www.cplusplus.com/reference/stl/

The difference is that Stlgen will generate instances of STL templates
in a different language. The default language is c.

This example below uses Stlgen to generate list_uint.(c/h) files which will implement
a linked list container coded in the c language.

	#!/usr/bin/perl -w

	use Stlgen;

	my $inst = Stlgen->New(
		Template=>'list', 
		Instancename => 'uint',
		payload => [
			{name=>'uint',   type=>'unsigned int', dumper=>'printf("\t\tuint = %u\n", currelement->uint);'},
		],
	);

	$inst->Instantiate();

You could use these files in a main.c program like this:

	#include <stdio.h>
	#include "list_uint.h"

	int main (void) {

		struct list_uint_list *mylist;

		mylist = list_uint_constructor();
	
		list_uint_push_back(mylist, 21);
		list_uint_push_back(mylist, 99);
		list_uint_push_back(mylist, 33);
		list_uint_push_back(mylist, 34);
		list_uint_push_back(mylist, 67);
		list_uint_push_back(mylist, 12);
		list_uint_push_back(mylist, 28);
		list_uint_push_back(mylist, 55);
		list_uint_push_back(mylist, 76);

		list_uint_sort(mylist);

		printf("\n\n\nThis is the sorted list\n");
		list_uint_list_dumper(mylist);

		return 0;
	}

The above c program currently works and produces the following output
when you compile and execute it:

	This is the sorted list
	// list at address 140644360{
	'beforefirst' marker:
		// element at address 8621018
			prev = 0
			next = 8621088
			uint = 0
	user elements:
		// element at address 8621088
			prev = 8621018
			next = 8621038
			uint = 12
		// element at address 8621038
			prev = 8621088
			next = 8621098
			uint = 21
		// element at address 8621098
			prev = 8621038
			next = 8621058
			uint = 28
		// element at address 8621058
			prev = 8621098
			next = 8621068
			uint = 33
		// element at address 8621068
			prev = 8621058
			next = 86210a8
			uint = 34
		// element at address 86210a8
			prev = 8621068
			next = 8621078
			uint = 55
		// element at address 8621078
			prev = 86210a8
			next = 86210b8
			uint = 67
		// element at address 86210b8
			prev = 8621078
			next = 8621048
			uint = 76
		// element at address 8621048
			prev = 86210b8
			next = 8621028
			uint = 99
	'afterlast' marker:
		// element at address 8621028
			prev = 8621048
			next = 0
			uint = 0


Note: this is a pre-alpha version. Currently the only STL container 
implemented is the linked list. And that hasn't been tested very well yet.
The "push", "pop", "size", "sort", and "dumper" functions are known to work.



=head1 SUBROUTINES/METHODS

=head2 New

Create a Stlgen object.

=cut

sub New {
	my $class = shift(@_);

	my $href={
		Separator => '/',
		Language => 'c',
		Extension => ['template'],	 # possible extensions that template file might have.
		TemplateSubdir => ['templates'],	 # subdirectory to look for containing the templates.
		Path => [], # ref to an array containing a list of paths to look for template in.
		Template => undef, # this would be "list" or "hash" or whatever STL container name you want
	};

	my %useroverrides = @_;

	while( my($key,$data)=each(%useroverrides) ){
		print "override key '$key' to data '$data'\n";
		$href->{$key}=$data;
	}

	my $obj = bless($href,$class);	

	return $obj;
}




=head2 FindTemplate

Given all the configuration info we know, find the template that the user wants to use.

=cut


sub FindTemplate{

	my($obj)=@_;

	#print Dumper \%INC;

	my $sep = $obj->{Separator};

	my $class = ref($obj);
	#print "class is '$class'\n";

	my $modulename = "$class.pm";

	unless(exists($INC{$modulename})) {
		die "ERROR: unable to find modulename in \%INC, '$modulename'";
	}

	my $modulepath = $INC{$modulename};

	$modulepath =~ s{\.pm\Z}{};

	my @paths = ($modulepath);

	# figure out the name of the template subdirs we're looking for
	my $templatename = $obj->{Template};
	my $language = $obj->{Language};

	# now go through the paths in order and look for the class that the object is blessed as.
	foreach my $path (@paths) {
		foreach my $templatesubdir (@{$obj->{TemplateSubdir}}) {
			my $lookingfor = 
				$path.$sep.$templatesubdir.$sep.
				$language.$sep.$templatename;

			warn "Stlgen is looking for template '$lookingfor'";

			if(-e $lookingfor and -d $lookingfor) {
				warn "Stlgen found template '$lookingfor'";
				return $lookingfor;
			}
		}
	}

	die "Error: unable to find template file";

}


=head2 Instantiate

Instantiate a template based on a particular type.

=cut

sub Instantiate {
	my($obj)=@_;

	#print Dumper $obj;

	my $templatepath = $obj->FindTemplate();
	
	print "templatepath is '$templatepath'\n";

	my $tt = Template->new({
		ABSOLUTE => 1,	# allow absolute filename paths
		RELATIVE => 1,	# allow relative filename paths
		INTERPOLATE  => 0,
	}) || die "$Template::ERROR\n";	

	$obj->{payloadsize}=scalar(@{$obj->{payload}});


	my @templates = `ls -1 $templatepath`;
	foreach my $template (@templates) {
		chomp($template);
	}
	#print Dumper \@templates;

	my $sep = $obj->{Separator};
	my $shortname = $obj->{Instancename};

	foreach my $template (@templates) {
		my $templatefile = $templatepath.$sep.$template;

		my $named_template = $template;
		$named_template =~ s{NAME}{$shortname};
		my $instname     = '.'.$sep.$named_template;

		print "Instantiating template file '$templatefile' as '$instname'\n";
		$tt->process($templatefile, $obj, $instname )
	        || die $tt->error(), "\n";
	}



}



=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Greg London, C<< <email at greglondon.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-stlgen at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Stlgen>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Stlgen


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Stlgen>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Stlgen>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Stlgen>

=item * Search CPAN

L<http://search.cpan.org/dist/Stlgen/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Greg London.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Stlgen


