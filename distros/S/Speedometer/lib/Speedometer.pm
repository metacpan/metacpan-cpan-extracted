package Speedometer;
$VERSION = 1.07;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(speedometer);
use 5.006;

use warnings;
use strict;
use Benchmark qw/cmpthese timethese/;



=head1 NAME

Speedometer - An easy interface to the Benchmark moudule to compare the performance of two Perl files.
 
=head1 VERSION

Version 1.07

=head1 SYNOPSIS

Speedometer compares the performance of two Perl files.

one can use it like this;

use Speedometer;

speedometer("file1","file2"); #by default it will run for 3 CPU seconds.

or one can give third optional argument which is the time/number of iterations one want perform. i.e (-10 or 1_000_000);

speedometer("file1","file2",-10); 

=head1 EXPORT

Speedometer exports one function called speedometer.

=head1 SUBROUTINES/METHODS

=head2 speedometer($script1, $script2, $count) 

return $result

=cut

sub speedometer{ 

my ($script1, $script2, $count) = @_;


unless ($#ARGV <= 3) {
    
	die "usage: Script1, Script2 and optional paramter is Time/Iterations,  $!\n";

}



$count = 0 if !$count;


#print "SCRIPT1 : $script1\n";
#print "SCRIPT2 : $script2\n";
 
my $data1 = read_file($script1);
my $data2 = read_file($script2);

my $code1 = eval $data1; print $@, die if $@;
my $code2 = eval $data2; print $@, die if $@;


#print "CODE1 : $code1\n";
#print "CODE2 : $code2\n"; 
 

  my $result = timethese(
      $count,
      {
          $script1 => sub{
          
          $code1->();
          
          
          },
 
         $script2 => sub{
           
          $code2->();
            
          },
      }
  );
  
print "\n";
 
cmpthese($result);

print "......................................Speedometer\n";

}

=head2 read_file($filename)

returns $data.

=cut

sub read_file{

my $filename = shift;

my $data;

open my $fh, "$filename" or die "file couldn't open $!\n";
   
while(my $line = <$fh>){
    
next if $line=~/^\#/;

$data .= $line;   
    
}

close $fh;
   
$data = "sub{".$data."}";

#print "$data\n";    

return $data;
    
}


=head1 AUTHOR

Kiran Rajendrasa Pawar, C<< <pawark86 at gmail.com> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-speedometer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Speedometer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Speedometer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Speedometer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Speedometer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Speedometer>

=item * Search CPAN

L<http://search.cpan.org/dist/Speedometer/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Kiran Rajendrasa Pawar.

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

1; # End of Speedometer

