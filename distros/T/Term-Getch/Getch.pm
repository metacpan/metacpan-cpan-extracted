#!/usr/bin/perl	

# Copyright (c) 2000  Josiah Bryan  USA
#
# See AUTHOR section in pod text below for usage and distribution rights.   
#

BEGIN {
	 $Term::Getch::VERSION = "0.20";
	 $Term::Getch::ID = 
'$Id: Term::Getch.pm, v'.$Term::Getch::VERSION.' 2000/15/09 21:58:25 josiah Exp $';
}

		
package Term::Getch;

    require Exporter;

    @ISA = qw(Exporter);
    @EXPORT = qw(getch);
    @EXPORT_OK = qw(ascii);

    use strict;

	my %__ascii__lookup__table;
	for my $code (0..255){$__ascii__lookup__table{chr($code)}=$code}
	sub ascii {my $c=shift;$__ascii__lookup__table{$c}}
	
 	my ($STOUT,$STDERR,$STDIN);
	
	if($^O eq "MSWin32") {		
            use Win32::Console;    
	    $STDIN  = new Win32::Console(STD_INPUT_HANDLE);
	} else {
            eval('use Term::ReadKey');
	}
		
	
	sub getch {  
 	 	if($^O eq "MSWin32") {		
		    my $e = $STDIN->GetEvents();
		   	if($e) {
		   		my @in = $STDIN->Input();
		   		return chr($in[5]) if($in[0]==1 && !$in[1]);
		   	}
		   	return undef;
		} else {
			return ReadKey();
		}
	}

	  
		

1;
__END__

=head1 NAME

Term::Getch - A simple alternate ReadKey()-like interface for MSWin32 

=head1 SYNOPSIS

	use Term::Getch;
    
	while(1) {
		my $c = getch(); 
	 	print "Input: $c\r";
	}
	
=head1 DESCRIPTION

This module is for all those Win32 users who can't get Term::ReadKey to work
with ActiveState's Perl. I don't know if anybody else can, or can't get it to
work, but I know I had a heck of a time today trying to get Term::ReadKey to
work. So, finally, out of desperation, I hacked out this small attempt at 
a portable solution to the delima. Behold, Term::Getch;

This exports a single function, getch(). Optional export is ascii(), which
returns the ASCII character code of any character passed. (getch() returns
the ASCII character as given by chr()). 

getch() requires Win32::Console to be installed B<_IF_> you are a MSWin32 user.
If you are not a MSWin32 user, then it will default to Term::ReadKey in an 
eval() statement. 

getch() is a non-blocking read call. If there are no characters waiting, it returns
undef. Otherwise, it returns the ASCII character (on key up.) 

=head2 EXPORT

getch()
ascii()

=head2 NOTE

Note: This has only been tested on by the author with ActiveState on Windows 98. I'm not sure
how well this preforms on other systems. If this doesn't work on your system and you 
aren't a MS Windows user, go download Term::ReadKey and compile it for your system. Chances
are, it will work MUCH better than this ever will. Thankyou very much. Good day!

=head1 AUTHOR

Josiah Bryan F<E<lt>jdb@wcoil.comE<gt>>

Copyright (c) 2000 Josiah Bryan. All rights reserved. This program is free software; 
you can redistribute it and/or modify it under the same terms as Perl itself.

The C<Term::Getch> and related modules are free software. THEY COME WITHOUT WARRANTY OF ANY KIND.

=head1 DOWNLOAD

You can always download the latest copy of Term::Getch
from http://www.josiah.countystart.com/modules/get.pl?getch:pod


=head1 SEE ALSO

perl(1), Win32::Console, Term::ReadKey

=cut
