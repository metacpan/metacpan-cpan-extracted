#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use Polycom::Contact::Directory; 

# Parse the command-line arguments
my ($file, $contact) = @ARGV;
if (!defined $file || !defined $contact)
{
    die qq(Usage: delete_contact.pl "XXXXXXXXXXXX-directory.xml" "Number");
}

if (!-e $file)
{
    die "Can't find file '$file'";
}

my $dir = Polycom::Contact::Directory->new($file);

# See if the directory already contains a conflicting contact
my @existing_contacts = $dir->search({contact => $contact});
if (!@existing_contacts)
{
    warn "Cannot find contact '$contact'. No changes made.";
}
else
{
    # Delete the contact(s). Note that if there are multiple
    # contacts with the same contact number, the dir file was
    # technically invalid. However, we still ought to remove all
    # of the matching contacts
    foreach my $c (@existing_contacts)
    {
        $c->delete;
    }
    $dir->save($file);
}

__END__

=head1 NAME

delete_contact.pl - Deletes the specified contact from a contact directory file.

=head1 SYNOPSIS

  perl delete_contact.pl dir.xml "1236"

=head1 DESCRIPTION

Deletes a contact with the specified contact number from a contact directory file.

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
