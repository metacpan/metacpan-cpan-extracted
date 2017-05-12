package Net::DNS::ToolKit::Question;

#use 5.006;
use strict;
#use diagnostics;
#use warnings;

use Net::DNS::ToolKit qw(
	get16
	put16
	dn_comp
	dn_expand
);
use Net::DNS::Codes qw(TypeTxt ClassTxt);

use vars qw($VERSION);

$VERSION = do { my @r = (q$Revision: 0.03 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

sub DESTROY {}

=head1 NAME

Net::DNS::ToolKit::Question - Resource Handler

=head1 SYNOPSIS

  DO NOT use Net::DNS::ToolKit::Question
  DO NOT require Net::DNS::ToolKit::Question

  Net::DNS::ToolKit::Question is autoloaded by
  class Net::DNS::ToolKit::RR and its methods
  are instantiated in a 'special' manner.

=head1 DESCRIPTION

=over 4

=item * ($newoff,$name,$type,$class) = 
	$get->Question(\$buffer,$offset);

Get question from $buffer. Returns the expanded name, type and class.

  input:	pointer to buffer,
		offset into buffer
  returns:	new offset,
		expanded name,
		type,
		class

=cut

sub get {
  my($self,$bp,$off) = @_;
  ($off, my $name) = dn_expand($bp,$off);
  (my $type,$off) = get16($bp,$off);
  (my $class,$off) = get16($bp,$off);
  return ($off,$name,$type,$class);
}

=item * ($newoff,@dnptrs) =
	$put->Question(\$buffer,$offset,
	$name,$type,$class,\@dnptrs);

Append a question to the $buffer. Returns a new pointer array for compressed
names and the offset to the next RR. 

NOTE: it is up to the user to update the question count. See: L<put_qdcount>

Since the B<question> usually is the first record to be appended to the
buffer, @dnptrs may be ommitted. See the details at L<dn_comp>.

Usage: ($newoff,@dnptrs)=$put->Question(\$buffer,$offset,
	$name,$type,$class);

  input:	pointer to buffer,
		offset into buffer,
		domain name,
		question type,
		question class,
		pointer to array of
		  previously compressed names,
  returns:	offset to next record,
		updated array of offsets to
		  previous compressed names

=cut

sub put {
  my($self,$bp,$off,$name,$type,$class,$dp) = @_;
  ($off, my @dnptrs)=dn_comp($bp,$off,\$name,$dp);
  $off = put16($bp,$off,$type);
  if (! $class && exists $self->{class}) {
    $class = $self->{class};
  }
  $off = put16($bp,$off,$class);
  return $off unless wantarray;
  return($off,@dnptrs);
}

=item * ($name,$typeTXT,$classTXT) =
	$parse->Question($name,$type,$class);

Convert non-printable and numeric data
into ascii text.

  input:	domain name,
		question type (numeric)
		question class (numeric)
  returns:	domain name,
		type TEXT,
		class TEXT

=back

=cut

sub parse {
  my($self,$name,$type,$class) = @_;
  return ($name.'.',TypeTxt->{$type},ClassTxt->{$class});
}

=head1 DEPENDENCIES

	Net::DNS::ToolKit

=head1 EXPORT

	none

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 COPYRIGHT

    Copyright 2003 - 2011, Michael Robinton <michael@bizsystems.com>
   
Michael Robinton <michael@bizsystems.com>

All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

  a) the GNU General Public License as published by the Free
  Software Foundation; either version 2, or (at your option) any
  later version, or

  b) the "Artistic License" which comes with this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either    
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
distribution, in the file named "Artistic".  If not, I'll be glad to provide
one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the

        Free Software Foundation, Inc.                        
        59 Temple Place, Suite 330
        Boston, MA  02111-1307, USA                                     

or visit their web page on the internet at:                      

        http://www.gnu.org/copyleft/gpl.html.

=head1 See also:

Net::DNS::ToolKit(3)

=cut

1;

