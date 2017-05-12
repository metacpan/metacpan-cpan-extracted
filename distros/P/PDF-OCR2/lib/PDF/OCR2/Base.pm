package PDF::OCR2::Base;
use strict;
use vars qw($VERSION @EXPORT_OK @ISA @EXPORT $CHECK_PDF $REPAIR_XREF %EXPORT_TAGS);
use Exporter;
use Carp;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;
@ISA = qw/Exporter/;
@EXPORT_OK = qw(check_pdf get_abs_pdf repair_xref);
%EXPORT_TAGS = ( all => \@EXPORT_OK );
use LEOCHARRE::Debug;

*CHECK_PDF = \$PDF::OCR2::CHECK_PDF; 
$CHECK_PDF = 1; # turn this on by default

*REPAIR_XREF = \$PDF::OCR2::REPAIR_XREF;

sub check_pdf {
   $_[0] or confess('missing arg');
   require PDF::API2;
	eval { PDF::API2->open($_[0]) } ? 1 : 0;
}

sub get_abs_pdf {
   my $arg = shift;
   $arg or confess('missing arg to check_pdf');

   debug();

   require Cwd;
   my $abs = Cwd::abs_path($arg)
      or warn("Can't resolve with Cwd::abs_path() '$arg'")
      and return;

   -f $abs 
      or warn("Not file on disk: $abs") 
      and return;

   no warnings;
   if ( $CHECK_PDF ){
      warn("CHECK_PDF flag is on..");
      check_pdf($abs) 
         and return $abs;

      warn("PDF::API2 cannot open '$abs', maybe bad xref? $@");

      if ( $REPAIR_XREF ){
         warn("REPAIR_XREF flag is on..")
            and return repair_xref($abs);
      }      
      
      return;
   }

   return $abs;
}


sub repair_xref {
   my $abs = shift;
   my $abs_to = shift;

   unless ($abs_to ) {
      $abs_to = $abs;

      $abs_to=~s/(\.\w{1,5})$/_repaired_xref_table$1/ 
         or warn("Cannot match extension into '$abs'")
         and return;
   }

   debug();

   require File::Which;
   my $bin = File::Which::which('pdftk')
      or warn("repair_xref() Can't find path to pdftk.")
      and return;

   #sprintf "%s.repaired_xref_table_%s.%s.pdf", $abs , time(), ( int rand 100 );
   my @a = ('pdftk', $abs, 'output', $abs_to );

   ( system(@a) == 0 )
      or warn("pdftk fails on '@a'\n -error: $!,$@")
      and return;
   
   #check it again..
   check_pdf($abs_to) 
      ? ( warn("Repaired xref table.") and return $abs_to )
      : ( warn("Could not repair xref table.") and unlink $abs_to and return );


}







1;


__END__

=pod

=head1 NAME

PDF::OCR2::Base

=head1 DESCRIPTION

=head1 SUBS

None are exported by default.

=head2 check_pdf()

Argument is path to pdf file.
Checks with PDF::API2.
Returns true or false, warns of any errors.

This uses an eval. Because PDF::API2 would otherwise die out on loading a bad pdf.

=head2 get_abs_pdf()

Argument is abs path to pdf.

May attempt to check a pdf, and repair an xref table (not on the original file).
See L<PDF::OCR2>.


=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 COPYRIGHT

Copyright (c) 2009 Leo Charre. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut
