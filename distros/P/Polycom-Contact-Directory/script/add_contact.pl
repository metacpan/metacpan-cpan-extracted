#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use Polycom::Contact::Directory; 

# Parse the command-line arguments
my ($file, $first_name, $last_name, $contact) = @ARGV;
if (!defined $file || !defined $first_name || !defined $last_name || !defined $contact)
{
    die qq(Usage: add_contact.pl "XXXXXXXXXXXX-directory.xml" "First" "Last" "Number");
}

if (!-e $file)
{
    print "Creating new file: '$file'\n";
    open(my $fh, ">", $file) or die "Can't create $file: $!";
    close $fh or die "Can't close $file : $!";
}


my $dir = Polycom::Contact::Directory->new($file);

# See if the directory already contains a conflicting contact
my ($existing_contact) = $dir->search({contact => $contact});
if (defined $existing_contact)
{
    warn "Directory contains conflicting contact '$existing_contact'."
        . ' Contact NOT added.';
}
else
{

    # Add the contact
    $dir->insert({
            first_name => $first_name,
        last_name  => $last_name,
        contact    => $contact,
    });
    $dir->save($file);
}

__END__

=head1 NAME

add_contact.pl - Adds a simple contact to the specified contact directory file.

=head1 SYNOPSIS

  perl add_contact.pl dir.xml "Bob" "Smith" "1236"

=head1 DESCRIPTION

Adds a contact with the specified first name, last name, and contact number to a contact directory file. If the file does not already exist, a new directory file will automatically be created.

=head1 CAVEATS

This simple script only supports the first name, last name, and contact number fields for the added contact. However, it would be very simple to allow additional fields to be specified from the command line. See C<Polycom::Contact::Directory> for details.

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
