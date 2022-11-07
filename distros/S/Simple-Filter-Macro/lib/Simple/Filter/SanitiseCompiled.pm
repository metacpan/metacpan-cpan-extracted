package Simple::Filter::SanitiseCompiled;

# Load the basic Perl pragmas.
use 5.010000;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Base class of this module.
our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export names
# by default without a very good reason. Use EXPORT_OK instead. Do not simply
# export all your public functions/methods/constants.

# This allows declaration use Simple::Filter::Macro ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

# our %EXPORT_TAGS = ( 'all' => [ qw( to be filled in ) ] );

# our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# Export the implemented subroutines and the global variable.
our @EXPORT = qw(
    SanitiseCompiled	
);

# Set ter VERSION of this module.
our $VERSION = '0.03';

# Load the required Perl module.
use File::Basename;

# ---------------------------------------------------------------------------- #
# Subroutine SanitiseCompiled()                                                # 
# ---------------------------------------------------------------------------- #
sub SanitiseCompiled {
    # Assigne the subroutine argument to the local variable.
    my $file = $_[0];     
    # Check the filename extension.
    my (undef, undef, $ext) = fileparse($file, '\..*');
    if ($ext ne ".plc") {
        exit 1;
    };   
    # Set the temporary file.
    my $tmpfile = "${file}.tmp";
    # Set the inblock variable to 0.
    my $inblock = 0;
    # Open the original file
    if (open IN, "<", $file) {
        ;
        # print "Successfully opened ${file}.\n";
    } else {
        # print "Failed to open ${file}.\n";
        exit 2;
    };
    # Create a tmp file
    if (open OUT, ">", "${tmpfile}") {
        ;
        # print "Successfully opened ${tmpfile}.\n";
    } else {
        # print "Failed to open ${tmpfile}.\n";
        exit 2;
    };
    # Write Shebang to file.
    print OUT "#!/usr/bin/perl\n";
    # Loop through each line in the original file.
    while (my $line = <IN>) {
        # Check on empty lines and comments.
        if ($line =~ /^\s*$/ || $line =~ /^#/) {
            # Cheeck if key word is found.
            if ($line =~ /^#line 1\s*$/) {
                # Swap switch on given value.                 
                $inblock = ($inblock == 0 ? 1 : 0);
            };
        } else {
            # If it is not in the block print the line.
            if ($inblock == 0) {
                print OUT $line;
            };
        };
    };
    # Close both file handlers.
    close IN;
    close OUT;
    # Delete the original file.
    unlink($file);
    # Rename the tmp file to get back the original file.
    rename($tmpfile, $file);
};

1;

__END__

=head1 NAME

Simple::Filter::SanitiseCompiled - Perl extension for sanitising a compiled file.

=head1 SYNOPSIS

  use Simple::Filter::SanitiseCompiled;

  # Set filename.
  my $filename = "compiled_script.plc";

  # Sanitise compiled file.
  SanitiseCompiled($filename);

=head1 DESCRIPTION

The module is santising a compiled file. Empty lines as well as comment lines
are removed. The block enclosed in C<#line 1> to C<#line 1> is also removed.

=head1 METHOD

  SanitiseCompiled()

=head1 EXPORT

  SanitiseCompiled()

=head1 METHOD RETURN

Returns a sanitised compiled file of same name as input file.  

=head1 ERROR CODE

  1 => Error reading or writing a file. 

=head1 BUGS

Not known yet.

=head1 SEE ALSO

C<Simple::Filter::Macro>

C<Simple::Filter::MacroLight>

L<Filter::Macro|https://metacpan.org/pod/Filter::Macro/>

L<Filter::Simple::Compile|https://metacpan.org/pod/Filter::Simple::Compile/>

L<File::Basename|https://metacpan.org/pod/File::Basename/>

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify it under
the same terms of The MIT License. For more details, see the full text of the
license in the attached file LICENSE in the main package folder. This library
is distributed in the hope that it will be useful, but without any warranty;
without even the implied warranty of merchantability or fitness for a
particular purpose.

=cut
