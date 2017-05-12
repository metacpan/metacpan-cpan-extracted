package XML::OBEXFTP::FolderListing;

use warnings;
use strict;

our $VERSION = '1.001001'; # VERSION

use Carp;
use XML::Simple;
use base 'Class::Accessor::Grouped';
__PACKAGE__->mk_group_accessors(
    simple => qw(folders files parent_folder  tree)
);

sub new {
    return bless {}, shift;
}

sub parse {
    my ( $self, $data ) = @_;
    return undef
        unless defined $data;
    my $parse_ref = XMLin($data,ForceArray => [ 'folder', 'file' ] );
    $parse_ref->{parent_folder} = delete $parse_ref->{'parent-folder'};
    $self->parent_folder( $parse_ref->{parent_folder}  );

    $self->folders( [ keys %{ $parse_ref->{folder} } ] );
    $self->files( [ keys %{ $parse_ref->{file} } ] );
    return $self->tree( $parse_ref );
}

sub is_folder {
    my ( $self, $name ) = @_;

    my $tree = $self->tree;
    return exists $tree->{folder}{ $name } ? 1 : 0;
}

sub is_file {
    my ( $self, $name ) = @_;

    my $tree = $self->tree;
    return exists $tree->{file}{ $name } ? 1 : 0;
}

sub info {
    my ( $self, $name, $type ) = @_;
    $type = 'file'
        unless defined $type;

    my $info = $self->tree->{ $type }{ $name };
    $info->{perms} = delete $info->{'user-perm'};
    $info->{modified_sane} = $self->modified_sane( $name, $type );
    return $info;
}

sub perms {
    my ( $self, $name, $type ) = @_;
    $type = 'file'
        unless defined $type;

    return $self->tree->{ $type }{ $name }{'user-perm'};
}

sub size {
    my ( $self, $name ) = @_;
    return $self->tree->{file}{ $name }{size};
}

sub type {
    my ( $self, $name ) = @_;
    return $self->tree->{file}{ $name }{type};
}

sub modified {
    my ( $self, $name, $type ) = @_;
    $type = 'file'
        unless defined $type;

    return $self->tree->{ $type }{ $name }{modified};
}

sub modified_sane {
    my $self = shift;
    my $time = $self->modified( @_ );
    return undef
        unless defined $time;
    my %time;
    @time{ qw(year month day hour minute second) }
        = $time =~ /(\d{4})(\d{2})(\d{2})\w(\d{2})(\d{2})(\d{2})/;
    return \%time;
}

1;

__END__

=encoding utf8

=for stopwords AnnoCPAN RT

=head1 NAME

XML::OBEXFTP::FolderListing - parse OBEX FTP x-obex/folder-listing XML

=head1 SYNOPSIS

    use strict;
    use warnings;
    use lib '../lib';
    use XML::OBEXFTP::FolderListing;

    my $data =<<'END_DATA';
    <?xml version="1.0" ?>
    <!DOCTYPE folder-listing SYSTEM "obex-folder-listing.dtd">
    <folder-listing>
    <parent-folder />
    <folder name="audio" size="0" type="folder" modified="19700101T000000Z" user-perm="RW" />
    <folder name="video" size="0" type="folder" modified="19700101T000000Z" user-perm="RW" />
    <folder name="picture" size="0" type="folder" modified="19700101T000000Z" user-perm="RW" />
    <file name="31-01-08_2213.jpg" size="27665" type="image/jpeg" modified="20080131T221123Z" user-perm="RW" />
    <file name="26-01-08_1228.jpg" size="40196" type="image/jpeg" modified="20080126T122836Z" user-perm="RW" />
    <file name="05-02-08_2043.jpg" size="33210" type="image/jpeg" modified="20080205T204310Z" user-perm="RW" />
    <file name="26-01-08_0343.jpg" size="40802" type="image/jpeg" modified="20080126T034339Z" user-perm="RW" />
    <file name="05-02-08_2312.jpg" size="33399" type="image/jpeg" modified="20080205T230946Z" user-perm="RW" />
    <file name="05-02-08_2047.jpg" size="21318" type="image/jpeg" modified="20080205T204358Z" user-perm="RW" />
    </folder-listing>
    END_DATA

    my $p = XML::OBEXFTP::FolderListing->new;

    $p->parse($data);

    for ( @{ $p->folders } ) {
        printf "Folder: %s\n\tPermissions: %s\n\tLast-Modified: %s\n\n",
                $_, $p->perms( $_, 'folder' ), $p->modified( $_, 'folder' );
    }

    for my $file ( @{ $p->files } ) {
        printf "File: %s\n\tPermissions: %s\n\tSize: %s\n\tType: %s\n\t"
                . "Last-Modified: %s\n\n",
                $file, map { $p->$_( $file ) } qw( perms size type modified );
    }

=head1 DESCRIPTION

The module provides means to parse information from OBEX File Transfer
Profile XML.

=head1 CONSTRUCTOR

=head2 new

    my $p = XML::OBEXFTP::FolderListing->new;

Takes no arguments, returns a freshly made XML::OBEXFTP::FolderListing
object that still has that "new object" smell on it!.

=head1 METHODS

=head2 parse

    my $tree = $p->parse( $your_XML_data );

Takes one mandatory argument which is the OBEX FTP x-obex/folder-listing
XML data. Returns a hashref which is a full parsed tree of your data,
e.g:

    $VAR1 = {
          'parent_folder' => {},
          'file' => {
                      '26-01-08_1228.jpg' => {
                                             'type' => 'image/jpeg',
                                             'size' => '40196',
                                             'modified' => '20080126T122836Z',
                                             'user-perm' => 'RW'
                                           },
                      '05-02-08_2312.jpg' => {
                                             'type' => 'image/jpeg',
                                             'size' => '33399',
                                             'modified' => '20080205T230946Z',
                                             'user-perm' => 'RW'
                                           },
                      '26-01-08_0343.jpg' => {
                                             'type' => 'image/jpeg',
                                             'size' => '40802',
                                             'modified' => '20080126T034339Z',
                                             'user-perm' => 'RW'
                                           },
                      '05-02-08_2043.jpg' => {
                                             'type' => 'image/jpeg',
                                             'size' => '33210',
                                             'modified' => '20080205T204310Z',
                                             'user-perm' => 'RW'
                                           },
                      '31-01-08_2213.jpg' => {
                                             'type' => 'image/jpeg',
                                             'size' => '27665',
                                             'modified' => '20080131T221123Z',
                                             'user-perm' => 'RW'
                                           },
                      '05-02-08_2047.jpg' => {
                                             'type' => 'image/jpeg',
                                             'size' => '21318',
                                             'modified' => '20080205T204358Z',
                                             'user-perm' => 'RW'
                                           }
                    },
          'folder' => {
                        'audio' => {
                                   'type' => 'folder',
                                   'size' => '0',
                                   'modified' => '19700101T000000Z',
                                   'user-perm' => 'RW'
                                 },
                        'video' => {
                                   'type' => 'folder',
                                   'size' => '0',
                                   'modified' => '19700101T000000Z',
                                   'user-perm' => 'RW'
                                 },
                        'picture' => {
                                     'type' => 'folder',
                                     'size' => '0',
                                     'modified' => '19700101T000000Z',
                                     'user-perm' => 'RW'
                                   }
                      }
        };

=head2 folders

    my $folders_ref = $p->folders;

Must be called after a call to C<parse()>. Takes no arguments.
Returns a possibly empty
arrayref, elements of which are the names of folders your XML contains.

=head2 files

    my $files_ref = $p->files;

Must be called after a call to C<parse()>. Takes no arguments.
Returns a possibly empty
arrayref, elements of which are the names of files your XML contains.

=head2 parent_folder

    my $parent_folder = $p->parent_folder;

Must be called after a call to C<parse()>. Takes no arguments. Supposedly
should return the parent folder of your OBEX FTP listing, I am yet
to see XML contain that info, maybe it's just my device (I got only one).
Please tell me if this actually works for someone.

=head2 tree

    my $tree = $p->tree;

Must be called after a call to C<parse()>. Takes no arguments. Returns
the same hashref as the return of last C<parse()>. See C<parse()> method
above for more information.

=head2 is_folder

    if ( $p->is_folder('audio') ) {
        # it's a folder, maybe we should setpath to it
    }

Must be called after a call to C<parse()>. Takes one mandatory argument
which is the name of the folder. Returns a true value if the name you
provided is a name of a folder. Returns a false value if the name you've
specified does not exist in the "folder" listing of your XML.

=head2 is_file

    if ( $p->is_file('05-02-08_2043.jpg') ) {
        # it's a file, maybe we should download it
    }

Must be called after a call to C<parse()>. Takes one mandatory argument
which is the name of the file. Returns a true value if the name you
provided is a name of a file. Returns a false value if the name you've
specified does not exist in the "file" listing of your XML.

=head2 perms

    my $permissions = $p->perms('05-02-08_2043.jpg');

    my $permissions2 = $p->perms('audio', 'folder' );

Must be called after a call to C<parse()>.
Takes one mandatory and one optional arguments. The first argument is
the name of either a file or a folder, the second argument can contain
either C<file> or C<folder> to specify whether your name is a name of
a file or a folder respectively; if not specified it will default to C<file>.

Returns a string containing the permissions of the folder or file you've
specified, e.g. C<RW> for read-write access. Will return C<undef> if
specified file/folder was not found in your XML.

=head2 size

    my $size = $p->size('05-02-08_2043.jpg');

Must be called after a call to C<parse()>.
Takes one mandatory argument which is a name of a file. Returns file's size
in bytes. All folders have size of zero. Will return C<undef> if
specified file was not found in your XML.

=head2 type

    my $type = $p->type('05-02-08_2043.jpg');

Must be called after a call to C<parse()>. Takes one mandatory argument
which is the name of the file. Returns a string containing file's type
(MIME), e.g. C<image/jpeg>. All folders have a type of C<folder>.
Will return C<undef> if specified file was not found in your XML.

=head2 modified

    my $modified = $p->modified('05-02-08_2043.jpg');

    my $modified = $p->modified('audio', 'folder' );

Must be called after a call to C<parse()>. Takes one mandatory
and one optional arguments. The first argument is the name of either the
file or a folder. The second optional argument can be set to either
C<file> or C<folder> to indicate whether your name represents a file
or a folder; it will default to C<file>.

Returns a scalar containing the modification date of the folder or file
you've specified, e.g. C<20080205T204358Z>. Will return C<undef> if
specified file/folder was not found in your XML.

=head2 modified_sane

    my $modified = $p->modified_sane('05-02-08_2043.jpg');

    my $modified = $p->modified_sane('audio', 'folder' );

Must be called after a call to C<parse()>. Takes one mandatory
and one optional arguments. The first argument is the name of either the
file or a folder. The second optional argument can be set to either
C<file> or C<folder> to indicate whether your name represents a file
or a folder; it will default to C<file>.

The method is similar to C<modified()> except it returns a hashref with
the following keys/values representing the last modification time of
your folder/file:

    $VAR1 = {
        'hour' => '12',
        'minute' => '28',
        'second' => '36',
        'month' => '01',
        'day' => '26',
        'year' => '2008'
    };

Will return C<undef> if
specified file/folder was not found in your XML.

=head2 info

    my $info_ref = $p->info('05-02-08_2043.jpg');

    my $info2_ref = $p->info('audio', 'folder' );

Must be called after a call to C<parse()>. Takes one mandatory
and one optional arguments. The first argument is the name of either the
file or a folder. The second optional argument can be set to either
C<file> or C<folder> to indicate whether your name represents a file
or a folder; it will default to C<file>.

This method combines info from C<modified()>, C<type()>, C<perms()>,
C<size()> and C<modified_sane()> methods. Will return C<undef> if
specified file/folder was not found in your XML. Otherwise returns a hashref
with the following keys/values:

    $VAR1 = {
        'type' => 'image/jpeg',
        'modified_sane' => {
            'hour' => '12',
            'minute' => '28',
            'second' => '36',
            'month' => '01',
            'day' => '26',
            'year' => '2008'
        },
        'perms' => 'RW',
        'size' => '40196',
        'modified' => '20080126T122836Z'
    };

=over 10

=item type

See C<type()> method.

=item modified_sane

See C<modified_sane()> method.

=item perms

See C<perms()> method.

=item size

See C<size()> method.

=item modified

See C<modified()> method.

=back

I<Note:> the C<info()> method does B<NOT> call each of the method listed
above, it just takes a piece of C<tree()> and appends C<modified_sane()>
and changes the name of C<user-perm> key. Therefore, it's possible that it
might contain some extra keys. Let me know if you come across such case.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-obexftp-folderlisting at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-OBEXFTP-FolderListing>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::OBEXFTP::FolderListing

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-OBEXFTP-FolderListing>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-OBEXFTP-FolderListing>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-OBEXFTP-FolderListing>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-OBEXFTP-FolderListing>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
