#!/usr/bin/perl
use strict;
use warnings;
use Encode;

use lib '../lib';
use Polycom::Contact::Directory; 

# Parse the command-line arguments
my ($file) = @ARGV;
if (!defined $file)
{
    die qq(Usage: xml_to_csv.pl "XXXXXXXXXXXX-directory.xml");
}

if (!-e $file)
{
    die "Can't find file '$file'";
}

# Convert the XML contact directory to a CSV file
my $dir = Polycom::Contact::Directory->new($file);

binmode STDOUT, ":utf8";
print '"First Name", "Last Name", "Phone", "Display Name"';
print "\n";
foreach my $c ($dir->all)
{
    my $fn = decode_utf8($c->first_name || '');
    my $ln = decode_utf8($c->last_name || '');
    my $ct = decode_utf8($c->contact || '');
    my $lb = decode_utf8($c->label);
    
    if (!$lb)
    {
        $lb = "$fn $ln";
    }

    print qq("$fn", "$ln", "$ct", "$lb"\n);
}

__END__

=head1 NAME

xml_to_csv.pl - Converts the XML file to a CSV file suitable for being imported into Microsoft Outlook or another mail client.

=head1 SYNOPSIS

  perl xml_to_csv.pl dir.xml > dir.csv

=head1 DESCRIPTION

Converts the XML file to a CSV file suitable for being imported into Microsoft Outlook or another mail client.

  $> perl xml_to_csv.pl 000000000000-directory.xml > directory.csv
  
The generated comma-separated file contains the column headings on the first line.

  "First Name", "Last Name", "Phone", "Display Name"

The contents of the "First Name" column are taken from the I<fn> element in the 000000000000-directory.xml file. Similarly, the contents of the "Last Name" column are taken from the I<<ln>> element and the contents of the "Phone" column are taken from the I<<ct>> element. The contents of the "Display Name" column are taken from the I<<lb>> element, if present and not blank; otherwise, the "Display Name" entries consist of the first and last name of the contact.

=head1 SEE ALSO

C<Polycom::Contact::Directory> - parses the XML-based local contact directory file used by Polycom SoundPoint IP, SoundStation IP, and VVX VoIP phones, and can be used to read, modify, or create contacts in the file. 

=head1 AUTHOR

Zachary Blair, E<lt>zblair@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Polycom Canada 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

