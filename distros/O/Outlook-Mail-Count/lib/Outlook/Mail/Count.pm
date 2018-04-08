package Outlook::Mail::Count;

use 5.006;
use strict;
use warnings;
use DateTime;
use Date::Calc qw(:all);
our @ISA    = qw( Exporter );
our @EXPORT = qw( run );

=head1 NAME

Outlook::Mail::Count - The module is work for windows platform for collection email number by folder and date.
output sample:
      Folder      Total      Today  Yesterday   ThisWeek   LastWeek  ThisMonth  LastMonth   ThisYear  LastsYear
       Inbox        480         19         15         42         90         42        391        451         29
       Cloud        243          0          0          0          2          0          9         85        158
        None         35          0          0          0          0          0          0         12         23
          IT        242          2          1          5          8          5         81        180         62
     Systems        732          2          6         15         49         15        177        378        354
      Devops        293          0          0          0          0          0          1        122        171
          DB         67          0          0          0          0          0          0          8         59
    Security        411          2          2          5          3          5         31        149        262
     Manager        104          0          0          0          2          0         11         34         70
          RM        146          0          0          0          0          0          3         38        108
 Application        348          0          0          0          0          0          8        139        209
          HR          0          0          0          0          0         10         61        130
          QA        628          0          0          0          0          0          5        164        464
        O-IT       1286          5          3         11         28         11         87        417        869
          ME          1          0          1          1          0          1          0          1          0

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';
use Win32::OLE qw(in with);
use Win32::OLE::Const 'Microsoft Outlook';
$Win32::OLE::Warn = 2;
my $dt = DateTime->now;
my $today = $dt->ymd('-');
my $week = $dt->week_number(); #day_of_week();
my $month = $dt->month();
my $year =  $dt->year();
my $yesterday = $dt->add( days => -1 )->ymd('-');

my @FIELDS = (
    [ qw( Email1Address Email1DisplayName) ],
    [ qw( Email2Address Email2DisplayName) ],
    [ qw( Email3Address Email3DisplayName) ],
);

my $outlook = get_outlook();


my $mapi = $outlook->GetNamespace('MAPI');
my $inbox = $mapi->GetDefaultFolder(olFolderInbox);

=head1 SYNOPSIS

Quick summary of what the module does.

    use Outlook::Mail::Count qw (run);
    run();
    

=head1 EXPORT

 run   - Invoke count subroutines passthrough folder parameter.
 
=head1 SUBROUTINES/METHODS

 run   - Invoke count subroutines passthrough folder parameter.
 count - count folder emails.
 
=cut

sub run {
	printf("%30s %10s %10s %10s %10s %10s %10s %10s %10s %10s\n","Folder","Total","Today","Yesterday","ThisWeek","LastWeek","ThisMonth","LastMonth", "ThisYear","LastsYear");
	my $count = $inbox->{Items}{Count};
	count($inbox);
	
	foreach ( in $inbox->Folders) {
		count($_);
	}
}


=head2 count

=cut

sub count {
	my $subfolder = shift;
	my $c = 0;
    my $y = 0;
    my $this_week = 0;
    my $last_week = 0;
    my $m = 0;
    my $lm = 0;
	my $ty = 0;
	my $ly = 0;
	foreach my $msg (reverse in($subfolder->{items})) {

	#print $msg->{Received};die;$msg->{EntryID}
    my $dt2 = DateTime->new(
                year      => $msg->{ReceivedTime}->Date("yyyy"),
                month     => $msg->{ReceivedTime}->Date("MM"),
                day       => $msg->{ReceivedTime}->Date("dd"),
                hour      => $msg->{ReceivedTime}->Time("HH"),
                minute    => $msg->{ReceivedTime}->Time("mm"),
                time_zone => "Asia/Chongqing",
    );

	my $dt2_day_of_week = $dt2->week_number();
	my $dt2_year = $dt2->year;
	my $dt2_day  = $msg->{ReceivedTime}->Date("yyyy-MM-dd");
	my $d_o_w = $week - $dt2_day_of_week;

		if( $dt2_year == $year ) { 
			$ty = $ty + 1; 
			if( $dt2_day =~ /$today/ ) { $c = $c + 1; }
			if( $dt2_day =~ /$yesterday/ ) { $y = $y + 1; }
			if( $d_o_w == 0 ) { 

				$this_week = $this_week + 1; 
			}
			if( $d_o_w == 1 ) { $last_week = $last_week + 1; }
			if( $dt2->month() == $month ) { $m = $m + 1; }
			if(( $month - $dt2->month()) == 1 ) { $lm = $lm + 1; }
		} else {
			$ly = $ly + 1;
		}
	}
    #printf("%30s %10s %10s %10s %10s %10s %10s %10s %10s %10s\n","Folder","Total","Today","Yesterday","ThisWeek","LastWeek","ThisMonth","LastMonth", "ThisYear","LastsYear");
 	printf("%30s %10s %10s %10s %10s %10s %10s %10s %10s %10s\n", $subfolder->{Name},$subfolder->{Items}{Count}, $c, $y, $this_week, $last_week, $m, $lm, $ty, $ly);

}
 
sub content {
		
	foreach my $msg (reverse in($inbox->{items})) {
		printf("%10s,%8s,%20s\n", $msg->{ReceivedTime}->Date("yyyy-MM-dd"), $msg->{ReceivedTime}->Time("HH:mm:ss"), $msg->{SenderEmailAddress});
	}

}

sub contact {
	my $contacts = $mapi->GetDefaultFolder(olFolderContacts);
	
	my $count = $contacts->{Items}{Count};
	
	print qq{"name","Email Address"\n};
	
	for my $k (1 .. $count) {
		my $contact = $contacts->{Items}->Item($k);
	
		for my $field ( @FIELDS ) {
			if ( (my $addr = $contact->{ $field->[0] })
					and (my $name = $contact->{ $field->[1]}) ) {
				$name =~ s{(\s+\(.+\))}{};
				printf qq{"%s", %s\n}, $name, $addr;
			}
		}
	}
}

sub get_outlook {
    my $outlook;
    eval {
        $outlook = Win32::OLE->GetActiveObject('Outlook.Application');
    };
    die "$@\n" if $@;
    return $outlook if defined $outlook;

    $outlook = Win32::OLE->new('Outlook.Application', sub { $_[0]->Quit })
        or die "Oops, cannot start Outlook: ",
               Win32::OLE->LastError, "\n";
}

sub emulate {
	my $wd = Win32::OLE::Const->Load($inbox->{Items}[1]);
		foreach my $key (keys %$wd) {
			printf "$key = %s\n", $wd->{$key};
		}
	exit;
}

=head1 AUTHOR

Linus Yuan, C<< <yuan_shijiang at 163.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-outlook-mail-count at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Outlook-Mail-Count>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Outlook::Mail::Count


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Outlook-Mail-Count>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Outlook-Mail-Count>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Outlook-Mail-Count>

=item * Search CPAN

L<http://search.cpan.org/dist/Outlook-Mail-Count/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Linus Yuan.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Outlook::Mail::Count
