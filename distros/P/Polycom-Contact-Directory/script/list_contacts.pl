#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use Polycom::Contact::Directory; 

# Parse the command-line arguments
my ($file) = @ARGV;
if (!defined $file)
{
    die qq(Usage: list_contacts.pl "XXXXXXXXXXXX-directory.xml");
}

if (!-e $file)
{
    die "Can't find file '$file'";
}

# List the contacts, one per line
my $dir = Polycom::Contact::Directory->new($file);
foreach my $c ($dir->all)
{
    print "$c\n";
}

__END__

=head1 NAME

list_contacts.pl - Lists all of the contacts in the specified contact directory file.

=head1 SYNOPSIS

  perl list_contacts.pl dir.xml

=head1 DESCRIPTION

Lists all of the contacts in the specified contact directory file. Each contact is listed on its own line in the format "Firstname Lastname at Number".

  $> perl list_contacts.pl 000000000000-directory.xml
  Luke Skywalker at 1001
  Bart Simpson at 1002
  James Kirk at 1701

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
