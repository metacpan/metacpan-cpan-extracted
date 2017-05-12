package Spreadsheet::WriteExcel::Simple::Save;

use 5.006;
use strict;
use warnings;

use FileHandle;
use Spreadsheet::WriteExcel::Simple;


use Carp qw(croak);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Spreadsheet::WriteExcel::Simple::Save ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.05';


# Preloaded methods go here.

sub Spreadsheet::WriteExcel::Simple::save {

    my $self      = shift;
    my $save_name = shift or croak "must supply save file name";

    my $savef = new FileHandle ">$save_name" or die $!;

    binmode($savef);
    
    $savef->print($self->data);

    

}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Spreadsheet::WriteExcel::Simple::Save - convenience method for Spreadsheet::WriteExcel::Simple

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 #=====================================================================
 # DECLARATIONS
 #=====================================================================
 use strict;
 
 use Spreadsheet::WriteExcel::Simple::Save;
 
 
 #=====================================================================
 #  PROGRAM PROPER
 #=====================================================================
 
 my $ss  = Spreadsheet::WriteExcel::Simple->new;
 my @row = qw(000234 234234);
 
 warn "@row";
 
 $ss->sheet->keep_leading_zeros; # A Spreadsheet::WriteExcel method
                                # irrelevant to the SYNOPSIS
 $ss->write_row(\@row);

 $ss->save('test.xls');


1; 


=head1 DESCRIPTION

Spreadsheet::WriteExcel::Simple::Save adds a save() method to 
Spreadsheet::WriteExcel::Simple objects. Tony Bowden liked my patch
and made some suggestions, but clearly is overloaded with his
obligations as maintainer of Class::DBI, so he never integrated my
patch.

I have taken his suggestions and written the method as he suggested.

=head2 EXPORT

None by default.


=head1 AUTHOR

T. M. Brannon, E<lt>tbone@cpan.orgE<gt>

=head1 SEE ALSO

Spreadsheet::WriteExcel::Simple, Spreadsheet::WriteExcel

=cut
