use strict;
use warnings;
package Net::Google::Drive::Simple::Mirror;
use Net::Google::Drive::Simple;
use DateTime::Format::RFC3339;
use DateTime;
use Carp;

our $VERSION = '0.53';

sub new{
    my ($class, %options) = @_;

    croak "Local folder '$options{local_root}' not found"
        unless -d $options{local_root};
    $options{local_root} .= '/'
        unless $options{local_root} =~ m{/$};

    my $gd = Net::Google::Drive::Simple->new();
    $options{remote_root} = '/'.$options{remote_root}
        unless $options{remote_root} =~ m{^/};
    # XXX To support slashes in folder names in remote_root, I would have
    # to implement a different remote_root lookup mechanism here:
    my (undef, $remote_root_ID) = $gd->children( $options{remote_root});

    my $self = {
        remote_root_ID          => $remote_root_ID,
        export_format           => ['opendocument', 'html'],
        download_condition      => \&_should_download,
        force                   => undef,       # XXX move this to mirror()
        net_google_drive_simple => $gd,

        %options
    };

    bless $self, $class;
}

sub mirror{
    my $self = shift;

    _process_folder(
        $self,
        $self->{remote_root_ID},
        $self->{local_root}
    );
}

sub _process_folder{
    my ($self, $folder_id, $path) = @_;
    my $gd = $self->{net_google_drive_simple};
    my $children = $gd->children_by_folder_id($folder_id);

    for my $child (@$children){
        my $file_name = $child->title();
        $file_name =~ s{/}{_};
        my $local_file = $path.$file_name;

        # a google document: export to preferred format
        if ($child->can( "exportLinks" )){
            next unless $self->{download_condition}
                    ->($self, $child, $local_file);
            print "$path$file_name ..exporting\n";

            my $type;
            FOUND:
            foreach my $preferred_type (@{$self->{export_format}}){
                foreach my $t (keys %{$child->exportLinks()}){
                    $type = $t;
                    last FOUND if $t =~ /$preferred_type/;
                }
            }

            my $url = $child->exportLinks()->{$type};
            $gd->download($url, $local_file);
            next;
        }

        # pdfs and the like get downloaded directly
        if ($child->can( "downloadUrl" )){
            next unless $self->{download_condition}
                    ->($self, $child, $local_file);
            print "$path$file_name ..downloading\n";
            $gd->download( $child, $local_file);
            next;
        }

        # if we reach this, we could not "fetch" the file. A dir, then..
        mkdir ($path.$file_name)
            unless -d $path.$file_name;

        _process_folder($self, $child->id(), $path.$file_name.'/');

    }
}


sub _should_download{
    my ($self, $remote_file, $local_file) = @_;

    return 1 if $self->{force};

    my $date_time_parser = DateTime::Format::RFC3339->new();

    my $local_epoch =  (stat($local_file))[9];
    my $remote_epoch = $date_time_parser
                            ->parse_datetime($remote_file->modifiedDate())
                            ->epoch();

    if (-f $local_file and $remote_epoch < $local_epoch ){
        return 0;
    }
    else {
        return 1;
    }
}

1;

__END__

=head1 NAME

Net::Google::Drive::Simple::Mirror - Locally mirror a Google Drive folder structure

=head1 SYNOPSIS

    use Net::Google::Drive::Simple::Mirror;

    # requires a ~/.google-drive.yml file containing an access token,
    # see documentation of Net::Google::Drive::Simple
    my $google_docs = Net::Google::Drive::Simple::Mirror->new(
        remote_root => '/folder/on/google/docs',
        local_root  => 'local/folder',
        export_format => ['opendocument', 'html'],
    );

    $google_docs->mirror();


=head1 DESCRIPTION

Net::Google::Drive::Simple::Mirror allows you to locally mirror a folder structure from Google Drive.

=head2 GETTING STARTED

For setting up your access token see the documentation of Net::Google::Drive::Simple.

=head1 METHODS

=over 4

=item C<new()>

Creates a helper object to mirror a remote folder to a local folder.

Parameters:

remote_root: folder on your Google Docs account. See "CAVEATS" below.

local_root: local folder to put the mirrored files in.

export_format: anonymous array containing your preferred export formats.
Google Doc files may be exported to several formats. To get an idea of available formats, check 'exportLinks()' on a Google Drive Document or Spreadsheet, e.g.

    my $gd = Net::Google::Drive::Simple->new(); # 'Simple' not 'Mirror'
    my $children = $gd->children( '/path/to/folder/on/google/drive' );
    for my $child ( @$children ) {
        if ($child->can( 'exportLinks' )){
            foreach my $type (keys %{$child->exportLinks()}){
                print "$type";
            }
        }
    }

Now, specify strings that your preferred types match against. The default is ['opendocument', 'html']

download_condition: reference to a sub that takes the remote file name and the local file name as parameters. Returns true or false. The standard implementation is:

    sub _should_download{
        my ($self, $remote_file, $local_file) = @_;

        return 1 if $self->{force};

        my $date_time_parser = DateTime::Format::RFC3339->new();

        my $local_epoch =  (stat($local_file))[9];
        my $remote_epoch = $date_time_parser
                                ->parse_datetime
                                    ($remote_file->modifiedDate())
                                ->epoch();

        if (-f $local_file and $remote_epoch < $local_epoch ){
            return 0;
        }
        else {
            return 1;
        }
    }

download_condition can be used to change the behaviour of mirror(). I.e. do not download but list al remote files and what they became locally:

    my $google_docs = Net::Google::Drive::Simple::Mirror->new(
        remote_root   => 'Mirror/Test/Folder',
        local_root    => 'test_data_mirror',
        export_format => ['opendocument','html'],
        # verbosely download nothing:
        download_condition => sub {
            my ($self, $remote_file, $local_file) = @_;
            say "Remote:     ", $remote_file->title();
            say "`--> Local: $local_file";
            return 0;
        }
    );

    $google_docs->mirror();


force: download all files and replace local copies.

=item C<mirror()>

Recursively mirrors Google Drive folder to local folder.

=back

=head1 CAVEATS

At the moment, remote_root must not contain slashes in the file names of its folders.

    remote_root => 'Folder/Containing/Letters A/B'

is not existing because folder "Letters A/B" contains a slash:

    Folder
         `--Containing
                     `--Letters A/B

This will be resolved to:

    Folder
         `--Containing
                     `--Letters A
                                `--B

The remote_root 'Example/root' may contain folders and files with slashes. These get replaced with underscores in the local file system.

    remote_root => 'Example/root';

    Example
          `--root
                `--Letters A/B

With local_root 'Google-Docs-Mirror' this locally becomes:

    local_root => 'Gooogle-Docs-Mirror';

    Google-Docs-Mirror
                    `--Letters A_B

(Net::Google::Drive::Simple::Mirror uses folder ID's as soon as it has found the remote_root and does not depend on folder file names.)

=head1 AUTHOR

Matthias Bloch, <lt>matthias at puffin ch<gt>

=head1 COPYRIGHT AND LICENSE

=Copyright (C) 2014 by :m)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
