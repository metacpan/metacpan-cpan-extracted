package Polycom::Contact::Directory;
use strict;
use warnings;

use Encode;
use IO::File;
use List::MoreUtils;

use Polycom::Contact;

our $VERSION = 0.05;

######################################
# Overloaded Operators
######################################
use overload (
    '==' => sub { $_[0]->equals($_[1]) },
    '!=' => sub { !$_[0]->equals($_[1]) },
);

###################
# Constructor
###################
sub new
{
    my ($class, $file) = @_;

    my @contacts;
    if ($file)
    {
        my $xml;

        if ($file =~ /<\/item>/)
        {
            $xml = $file;
        }
        elsif (ref $file)
        {
            binmode($file, ':utf8');
            $xml = do { local $/; <$file> };
        }
        elsif (-e $file)
        {
            my $fh = IO::File->new($file, '<');
            $fh->binmode(':utf8');
            $xml = do { local $/; <$fh> };
        }
        else
        {
            die "Cannot open '$file'";
        }

        if (!utf8::is_utf8($xml))
        {
            $xml = Encode::decode('utf8', $xml);
        }

        while ($xml =~ m/<item>(.*?)<\/item>/gs)
        {
            my $str = $1;
            my ($fn) = $str =~ /<fn>(.*?)<\/fn>/s;
            my ($ln) = $str =~ /<ln>(.*?)<\/ln>/s;
            my ($ct) = $str =~ /<ct>(.*?)<\/ct>/s;
            my ($sd) = $str =~ /<sd>(.*?)<\/sd>/s;
            my ($lb) = $str =~ /<lb>(.*?)<\/lb>/s;
            my ($rt) = $str =~ /<rt>(.*?)<\/rt>/s;
            my ($dc) = $str =~ /<dc>(.*?)<\/dc>/s;
            my ($ar) = $str =~ /<ar>(.*?)<\/ar>/s;
            my ($ad) = $str =~ /<ad>(.*?)<\/ad>/s;
            my ($bw) = $str =~ /<bw>(.*?)<\/bw>/s;
            my ($bb) = $str =~ /<bb>(.*?)<\/bb>/s;

            foreach ($fn, $ln, $ct, $sd, $lb, $rt, $dc, $ar, $ad, $bw, $bb)
            {
                next if !defined;
                s/&amp;/&/g;
                s/&quot;/"/g;
                s/&apos;/'/g;
                s/&lt;/</g;
                s/&gt;/>/g;
            }

            push @contacts,
                Polycom::Contact->new(
                first_name     => $fn,
                last_name      => $ln,
                contact        => $ct,
                speed_index    => $sd,
                label          => $lb,
                ring_type      => $rt,
                divert         => $dc || 0,
                auto_reject    => $ar || 0,
                auto_divert    => $ad || 0,
                buddy_watching => $bw || 0,
                buddy_block    => $bb || 0,
                in_storage     => 1,
                );
        }
    }

    return bless { contacts => \@contacts, }, $class;
}

###################
# Public methods
###################

sub insert
{
    my ($self, @contacts) = @_;

    foreach my $c (@contacts)
    {
        $c->{in_storage} = 1;
        push @{ $self->{contacts} },
            UNIVERSAL::isa($c, 'Polycom::Contact') ? $c : Polycom::Contact->new(%{$c});
    }

}

sub all
{
    return grep { $_->in_storage } @{ $_[0]->{contacts} };
}

sub search
{
    my ($self, $cond) = @_;
    return if !defined $cond || !ref $cond;

    my @results;
    foreach my $c ($self->all)
    {
        if (List::MoreUtils::all { defined $cond->{$_} && $c->{$_} eq $cond->{$_} }
            keys %{$cond}
            )
        {
            push @results, $c;
        }
    }

    return @results;
}

sub count
{
    my ($self) = @_;
    return scalar(grep { $_->in_storage } @{ $self->{contacts} });
}

sub to_xml
{
    my ($self) = @_;

    my $xml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
    $xml .= "\n<directory>\n <item_list>\n";
    foreach my $c ($self->all)
    {
        my %f = %{$c};
        foreach my $key (keys %f)
        {
            next if !defined $f{$key};
            $f{$key} =~ s/&/&amp;/g;
            $f{$key} =~ s/"/&quot;/g;
            $f{$key} =~ s/'/&apos;/g;
            $f{$key} =~ s/</&lt;/g;
            $f{$key} =~ s/>/&gt;/g;
        }

        $xml .= "  <item>\n";
        $xml .= "   <fn>$f{first_name}</fn>\n" if defined $f{first_name};
        $xml .= "   <ln>$f{last_name}</ln>\n" if defined $f{last_name};
        $xml .= "   <ct>$f{contact}</ct>\n" if defined $f{contact};
        $xml .= "   <sd>$f{speed_index}</sd>\n" if defined $f{speed_index};
        $xml .= "   <lb>$f{label}</lb>\n" if defined $f{label};
        $xml .= "   <rt>$f{ring_type}</rt>\n" if defined $f{ring_type};
        $xml .= "   <dc>$f{divert}</dc>\n" if defined $f{divert};
        $xml .= "   <ar>$f{auto_reject}</ar>\n" if defined $f{auto_reject};
        $xml .= "   <ad>$f{auto_divert}</ad>\n" if defined $f{auto_divert};
        $xml .= "   <bw>$f{buddy_watching}</bw>\n" if defined $f{buddy_watching};
        $xml .= "   <bb>$f{buddy_block}</bb>\n" if defined $f{buddy_block};
        $xml .= "  </item>\n";
    }
    $xml .= " </item_list>\n</directory>";

    return $xml;
}

sub save
{
    my ($self, $filename) = @_;
    if (!defined $filename || $filename eq '')
    {
        $filename = '000000000000-directory.xml';
    }

    my $fh = IO::File->new($filename, '>');
    $fh->binmode(':utf8');

    print $fh $self->to_xml;
}

sub is_valid
{
    my ($self) = @_;

    my %contact_num;
    my %speed_index;
    foreach my $c ($self->all)
    {
        # Verify that all of the constituent contacts are valid
        if (!$c->is_valid)
        {
            return;
        }

        # Verify that there are no duplicate contact values
        if (exists $contact_num{ $c->{contact} })
        {
            return;
        }
        $contact_num{ $c->{contact} } = 1;

        # Verify that there are no duplicate speed dial values
        if (exists $speed_index{ $c->{speed_index} })
        {
            return;
        }
        $speed_index{ $c->{speed_index} } = 1;
    }

    return 1;
}

sub equals
{
    my ($self, $other) = @_;

    # The are unequal if they contain different numbers of contacts
    return if $self->count != $other->count;

    my @myAll    = $self->all;
    my @otherAll = $other->all;
    for my $i (0 .. @myAll - 1)
    {
        if ($myAll[$i] != $otherAll[$i])
        {
            return;
        }
    }

    return 1;
}

'Together. Great things happen.';

=head1 NAME

Polycom::Contact::Directory - Parser for Polycom VoIP phone local contact directory files.

=head1 SYNOPSIS

  use Polycom::Contact::Directory;

  # Load an existing contact directory file
  my $dir = Polycom::Contact::Directory->new('0004f21ac123-directory.xml');  

  # Add a contact
  $dir->insert(
    {   first_name => 'Jenny',
        last_name  => 'Xu',
        contact    => '2',
    },
  );
  
  # Find some contacts
  my @all    = $dir->all;
  my @smiths = $dir->search({ last_name => 'Smith' });
  
  # Modify a contact in the directory
  $smiths[0]->last_name('Johnson');
  
  # Remove a contact
  $smiths[1]->delete;

  # Save the directory to an XML file suitable for being read by the phone
  $dir->save('0004f21ac123-directory.xml');

=head1 DESCRIPTION

Polycom SoundPoint IP, SoundStation IP, and VVX VoIP phones maintain a local contact directory that is stored on their configured boot server. Upon boot-up, each phone looks for a file named I<<Ethernet address>>-directory.xml on their boot server, and if found, downloads and parses the file to build up its local contact directory. In addition to basic contact information such first/last name and phone number, each contact in the local contact directory can also include information about speed-dialing, distinctive ring tones, presence, and instant messaging.

Each I<<Ethernet address>>-directory.xml contains fairly straightforward XML:

  <?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
  <directory>
   <item_list>
    <item>
     <ln>Doe</ln>
     <fn>John</fn>
     <ct>1001</ct>
     <sd>1</sd>
     <rt>1</rt>
     <dc/>
     <ad>0</ad>
     <ar>0</ar>
     <bw>0</bw>
     <bb>0</bb>
    </item>
      ...
   </item_list>
  </directory>

This module parses Polycom VoIP phone local contact directory files, and can be used to read, modify, or create local contact directory files. It also provides a C<is_valid> method that can be used to perform some basic integrity checks on contact directory files.

For more information about administering the Local Contact Directory on Polycom SoundPoint IP phones, see the "I<SoundPoint IP, SoundStation IP and Polycom VVX Administrator's Guide>" at L<http://www.polycom.com/support/voice/soundpoint_ip/soundpoint_ip670.html>.

=head1 CONSTRUCTOR

=head2 new ( $filename | $file_handle | $xml_contents )

  # Create a new empty directory
  my $dir = Polycom::Contact::Directory->new();

  # Load a directory from a filename or file handle
  my $dir2 = Polycom::Contact::Directory->new('directory.xml');
  my $dir3 = Polycom::Contact::Directory->new($fh);

If you have already slurped the contents of a contact directory file into a scalar, you can also pass that scalar to C<new> to parse those XML contents.

=head1 METHODS

=head2 insert ( @contacts )

  $dir->insert(
    {   first_name => 'Jenny',
        last_name  => 'Xu',
        contact    => '2',
        speed_index => 1,
        ring_type   => 5,
    },
    {   first_name => 'Jacky',
        last_name  => 'Cheng',
        contact    => '3',
        speed_index => 2,
        ring_type   => 10,
    },
  );

Adds the specified I<@contacts> contacts, if any, to the directory. I<@contacts> may be an array of hash references containing keys like "first_name", "last_name", and "contact", or it can be an array of C<Polycom::Contact> objects.

=head2 all

  my @contacts = $dir->all;
  foreach my $contact (@contacts)
  {
    # ...
  }

Returns an array of all of the C<Polycom::Contact> objects in the contact directory.

=head2 count

  my $num_contacts = $dir->count;

Returns the number of contacts in the directory.

=head2 equals ( $directory2 )

  if ($dir1->equals($dir2))
  {
    print "The contact directories are equal\n";
  }

Returns true if both contact directories are equal (i.e. they contain the same contacts).

Because the I<==> and I<!=> operators have also been overloaded for both C<Polycom::Contact> and C<Polycom::Contact::Directory> objects, it is equivalent to compare two contact directories using:

  if ($dir1 == $dir2)
  {
    print "The contact directories are equal\n";
  }

=head2 is_valid

  if (!$dir->is_valid)
  {
    print "$dir is invalid.\n";
  }

Returns true if each contact is valid (e.g. has a contact number, name is < 40 bytes long, etc), there are no duplicate contact numbers, and there are no duplicate speed index numbers. Otherwise, it returns false.

=head2 save ( $filename )

  $dir->save('0004f21acabf-directory.xml');
  # or
  $dir->save()

Writes the contents of the contact directory object to the specified file such that a phone should be able to read those contacts from the file if the file is placed on the phone's boot server.

If I<$filename> is not specified, the default filename used is "000000000000-directory.xml", which is the filename the phones look for if a directory file whose name contains their MAC address is not found.

=head2 search ( $condition )

  my @smiths = $dir->search({ last_name => 'Smith' });

Returns an array of the contacts that match the specified condition. I<$condition> must be a hash reference whose keys are field names of C<Polycom::Contact> fields (e.g. first_name, last_name, contact, ring_type, etc). All of the specified conditions must hold in order for a contact to be present in the array returned.

=head2 to_xml

  my $xml = $directory->to_xml;

Returns the XML representation of the contact directory. It is exactly this XML representation that the C<save> method writes to the local contact directory file.

=head1 SEE ALSO

=over

=item C<Polycom::Contact> - A contact in the local contact directory. Each C<Polycom::Contact::Directory> object contains zero or more C<Polycom::Contact> objects.

=item I<SoundPoint IP Admin Guide> - L<http://www.polycom.com/global/documents/support/setup_maintenance/products/voice/spip_ssip_vvx_Admin_Guide_SIP_3_2_2_eng.pdf>

=back

=head1 AUTHOR

Zachary Blair, E<lt>zblair@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Polycom Canada 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

