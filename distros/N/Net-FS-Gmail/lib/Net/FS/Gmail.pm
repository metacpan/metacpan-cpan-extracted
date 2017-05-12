package Net::FS::Gmail;

use strict;
use Mail::Webmail::Gmail;
use File::Basename;
use Time::ParseDate;
use URI::Escape;
our $VERSION           = "0.2";
our $FILESTORE_VERSION = "0.1"; # this way we can track different revisions of filestore format

=head1 NAME

Net::FS::Gmail - store and retrieve files on Gmail

=head1 SYNOPSIS

    my $fs = Net::FS::Gmail->new( username => $user, password => $pass );

    $fs->store("file.txt");
    $fs->store("piccy.jpg", "renamed_piccy.jpg");

    open (FILE, ">output.jpg") || die "Couldn't write to file: $!\n";
    binmode (FILE);
    print FILE $fs->retrieve("renamed_piccy.jpg");
    close (FILE);


=head1 METHODS

=cut

=head2 new 

Takes the same options as Mail::Webmail::Gmail

=cut

sub new {
    my $class = shift;
    my %opts  = @_;
    my $gmail =  Mail::Webmail::Gmail->new( %opts );
    # TODO better error reporting
    $gmail->login() || die "Couldn't log into gmail : ".$gmail->error_msg();
    my $self = { _gmail => $gmail, _user => $opts{username} };
    return bless $self, $class;
}


=head2 store <filename> [as]

Store the file <filename> on Gmail. If a second filename is given then use that 
as the name on GMail

=cut

sub store {
    my $self = shift;
    my $file = shift;
    my $as   = shift;  $as = $file unless defined $as;
    die "No such file $file\n" unless -f $file;

    my $subject  = "GmailStore v$FILESTORE_VERSION $as";
    my $user     = $self->{_user}; $user .= '@googlemail.com' unless $user =~ m!\@googlemail\.com$!;

    $self->{_gmail}->send_message( to => $user, subject => $subject, msgbody => '', file0 => [ $file ] );
}



=head2 retrieve <filename> [version] 

Get <filename> from Gmail. 

If the file has multiple versions then you can pass in a version number to get version 
- 1 being the oldest. If you don't pass in a version then you get the latest.


=cut

sub retrieve  {
    my $self    = shift;
    my $file    = shift;
    my $version = shift;

    my @versions = $self->versions($file); 

    die "Couldn't find $file\n" unless @versions;

    my $mid;
    if (!defined $version) {
        $mid =  $versions[0]->{id};
    } elsif ($version > @versions || $version < 1) {
        die "No such version $version\n";
    } else {
        $mid = $versions[-$version]->{id};
    }

    my $message = $self->{_gmail}->get_indv_email( id => $mid, label => $Mail::Webmail::Gmail::FOLDERS{ 'INBOX' } )->{$mid};


    die "Error: couldn't get attachments\n" unless defined $message->{ 'attachments' };
    my $attachment = $self->{_gmail}->get_attachment( attachment => $message->{ 'attachments' }->[0] );
    if ( $self->{_gmail}->error() ) {
        die $self->{_gmail}-error_msg()."\n";
    }
    return $$attachment;
}

=head2 versions <filename>

Returns a list of all the versions of a file

Each item on the list is a hashref containing the date the file was saved 
and the id of that version using the keys I<timestamp> and I<id> respectively. 

The list is sorted, latest version first.

=cut

sub versions {
    my $self = shift;
    my $file = shift;
    my @versions;
    foreach my $message (@{$self->{_gmail}->get_messages()}) {
        my $email = $self->{_gmail}->get_indv_email( msg => $message );
        foreach my $id (keys %$email) {
            my $item = $email->{$id};
            # TODO the subject may be html encoded
            next unless uri_unescape($item->{'subject'}) =~ m!^GmailStore v[\d.]+ $file$!;
            # TODO the sent time may be html encoded and need to be de-unicoded (7&frac12; hours ago for example)
            my $epoch_date  = parsedate($item->{'sent'});
            push @versions, { id => $id, timestamp => $epoch_date };
        }
    }
    return sort { $b->{timestamp} <=> $a->{timestamp}  } @versions;
}


=head2 files

Get a list of all the files on the system

=cut

sub files {
    my $self = shift;

    my @files;
    foreach my $message (@{$self->{_gmail}->get_messages()}) {
        # we do this to force it to be read
        my $email = $self->{_gmail}->get_indv_email( msg => $message );
        my $subject = uri_unescape((values(%$email))[0]->{subject});        
        next unless $subject =~ m!^GmailStore v[\d.]+ !;
        push @files, $';
    }
    return @files;
}


=head2 delete <file> [version]

Delete a file. If you pass a version number than only delete that version.

=cut

sub delete {
    my $self    = shift;
    my $file    = shift;
    my $version = shift;
    
    $self->_delete($file, 1, $version);
}

=head2 remove <file> [version]

The same as remove except that the file is merely moved to the trash.

=cut

sub remove {
    my $self    = shift;
    my $file    = shift;
    my $version = shift;
    
    $self->_delete($file, 0, $version);
}


sub _delete {
    my $self    = shift;
    my $file    = shift;
    my $delete  = shift;
    my $version = shift;


    my @versions = $self->versions($file);

    die "Couldn't find $file\n" unless @versions;

    my @mids;
    if (!defined $version) {
        @mids = map { $_->{id} } @versions; 
    } elsif ($version > @versions || $version < 1) {
        die "No such version $version\n";
    } else {
        push @mids, $versions[-$version]->{id};
    }
    print STDERR "Deleting ".join(", ", @mids)."\n";
    
    $self->{_gmail}->delete_message( msgid => [ @mids ], del_message => $delete );


}


=head2 quota 

Get your current remaining quota, just like in Mail::Webmail::Gmail i.e
returns a scalar with the amount of MB remaining in you account.

If called in list context, returns an array as follows:

    [ Used, Total, Percent Used ] [ "0 MB", "1000 MB", "0%" ]

=cut

sub quota {
    my $self = shift;
    return $self->{_gmail}->size_usage();
}


=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2006, Simon Wistow

Released under the same terms as Perl itself

=cut




1;
