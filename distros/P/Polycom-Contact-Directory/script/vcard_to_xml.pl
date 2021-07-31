#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use Polycom::Contact::Directory;
use vCard;

# Read the command-line arguments
if (scalar @ARGV != 2)
{  
    die qq(Usage: vcard_to_xml.pl "vcard.vcf" "XXXXXXXXXXXX-directory.xml");
} 
my ($vcard_filename, $poly_dir_filename) = @ARGV;

die "Can't find vcard file '$vcard_filename'" if (!-e $vcard_filename);
die "Can't find directory.xml file '$poly_dir_filename'" if (!-e $poly_dir_filename);

# Read the vCard and extract the relevant information
my $vcard = vCard->new;
$vcard->load_file($vcard_filename);

my @given_names = @{$vcard->given_names()};
my $first_name = scalar(@given_names) ? $given_names[0] : $vcard->full_name();
my @family_names = @{$vcard->family_names()};
my $last_name = scalar(@family_names) ? $family_names[0] : '';

my @phones = @{$vcard->phones()};
my ($contact) = map { $_->{number} } grep { $_->{preferred} } @phones;

# Append this contact to the directory
my $poly_dir = (-e $poly_dir_filename) ?
    Polycom::Contact::Directory->new($poly_dir_filename) :
    Polycom::Contact::Directory->new();
$poly_dir->insert(
  {   first_name => $first_name,
      last_name  => $last_name,
      contact    => $contact,
  },
);
$poly_dir->save($poly_dir_filename);


__END__

=head1 NAME

vcard_to_xml.pl - Extracts contact data from a vCard file and appends it to a XXXXXXXXXXXX-directory.xml file.

=head1 SYNOPSIS

  perl vcard_to_xml.pl vcard.vcf XXXXXXXXXXXX-directory.xml

=head1 DESCRIPTION

Extracts contact data from a vCard (VCF) file and appends it to a XXXXXXXXXXXX-directory.xml file.

  $> perl vcard_to_xml.pl vcard.vcf XXXXXXXXXXXX-directory.xml
  
=head1 SEE ALSO

C<Polycom::Contact::Directory> - parses the XML-based local contact directory file used by Polycom SoundPoint IP, SoundStation IP, and VVX VoIP phones, and can be used to read, modify, or create contacts in the file. 

=head1 AUTHOR

Zachary Blair, E<lt>zblair@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
