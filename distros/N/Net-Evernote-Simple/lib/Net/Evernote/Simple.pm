###########################################
package Net::Evernote::Simple;
###########################################

use strict;
use warnings;

use Net::Evernote::Simple::EDAMUserStore::Constants;
use Net::Evernote::Simple::EDAMUserStore::Types;
use Net::Evernote::Simple::EDAMUserStore::UserStore;
use Net::Evernote::Simple::EDAMNoteStore::NoteStore;
use Net::Evernote::Simple::EDAMNoteStore::Types;
use Net::Evernote::Simple::EDAMErrors::Types;
use Net::Evernote::Simple::EDAMTypes::Types;
use Log::Log4perl qw(:easy);
use YAML qw( LoadFile );
use File::Basename;
use File::Temp qw( tempfile );
use Thrift;
use Thrift::HttpClient;
use Thrift::BinaryProtocol;
use Data::Dumper;

our $VERSION = "0.07";

our $EN_DEV_TOKEN_PAGE = 
    "http://dev.evernote.com/documentation/cloud/chapters/" .
    "Authentication.php#devtoken";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        evernote_host => "www.evernote.com",
        dev_token           => undef,
        config_file         => undef,
        consumer_key        => undef,
        thrift_send_timeout => 10000,
        thrift_recv_timeout => 75000,
        %options,
    };

    bless $self, $class;

    if( !defined $self->{ consumer_key } ) {
        ( my $dashed_pkg = __PACKAGE__ ) =~ s/::/-/g;
        $self->{ consumer_key } = lc $dashed_pkg;
    }

    if( ! defined $self->{ config_file } ) {
        my( $home ) = glob "~";
        $self->{ config_file } = "$home/.evernote.yml";
    }

    if( !defined $self->{ dev_token } ) {
        if( -f $self->{ config_file } ) {
            my $data = LoadFile $self->{ config_file };
            if( exists $data->{ dev_token } ) {
                $self->{ dev_token } = $data->{ dev_token };
            }
        }
    }

    my $user_store_uri =
        "https://$self->{ evernote_host }/edam/user";

    my $http_client = $self->thrift_http_client( $user_store_uri );
    my $protocol =
        Thrift::BinaryProtocol->new( $http_client );

    $self->{ client } =
        Net::Evernote::Simple::EDAMUserStore::UserStoreClient->new( $protocol );

    return $self;
}

###########################################
sub init {
###########################################
    my( $self ) = @_;

    if( $self->{ init_done } ) {
        return 1;
    }

    if( !defined $self->{ dev_token } ) {
        LOGDIE "Developer token argument 'dev_token' missing. ", 
            "Check $EN_DEV_TOKEN_PAGE on how to obtain one.";
    }
    
    if( ! $self->version_check() ) {
        LOGDIE "Version check failed";
    }

    $self->{ init_done } = 1;
}

###########################################
sub dev_token {
###########################################
    my( $self ) = @_;

    return $self->{ dev_token };
}

###########################################
sub thrift_http_client {
###########################################
    my( $self, $uri ) = @_;

    my $client = Thrift::HttpClient->new( $uri );

      # Timeouts can't be passed into Thrift::HttpClient's constructor,
      # so we set them manually here. Thrift's default values
      # are in the millisecond range and therefore completely out 
      # of whack unless you have the Evernote server on your LAN.
    $client->setSendTimeout( $self->{ thrift_send_timeout } );
    $client->setRecvTimeout( $self->{ thrift_recv_timeout } );

    return $client;
}

###########################################
sub note_store {
###########################################
    my( $self ) = @_;

    $self->init();

    my $note_store_uri;

    eval {
        $note_store_uri = 
          $self->{ client }->getNoteStoreUrl( $self->{ dev_token } );
    };

    if( $@ ) {
        ERROR Dumper( $@ );
        return undef;
    }

    my $note_store_client = $self->thrift_http_client( $note_store_uri );

    my $note_store_protocol = Thrift::BinaryProtocol->new(
       $note_store_client );

    my $note_store = 
      Net::Evernote::Simple::EDAMNoteStore::NoteStoreClient->new(
        $note_store_protocol );

    return $note_store;
}

###########################################
sub version_check {
###########################################
    my( $self ) = @_;

    eval {
      my $version_ok =
        $self->{ client }->checkVersion( $self->{ consumer_key },
          Net::Evernote::Simple::EDAMUserStore::Constants::EDAM_VERSION_MAJOR,
          Net::Evernote::Simple::EDAMUserStore::Constants::EDAM_VERSION_MINOR,
        );
  
      INFO "Version check returned: $version_ok";
    };

    if( $@ ) {
        LOGWARN Dumper( $@ );
        $self->horrid_thrift_client_error_diagnostics( $self->{client} );
        return 0;
    }

    return 1;
}

###########################################
sub horrid_thrift_client_error_diagnostics {
###########################################
    my( $self, $client ) = @_;

    # Apparently, there's no way to figure out what went wrong at the
    # http level once a thrift call fails, except poking around in thrift's
    # internal structures. Oh, the humanity!

    eval {
        my $in = $client->{input}->{trans}->{in};
        $in->setpos(0);
        LOGWARN join '', <$in>;
    };

    if( $@ ) {
        LOGWARN "Unable to diagnose underlying error";
    }
}

###########################################
sub sdk {
###########################################
    my( $self, $name ) = @_;

    return __PACKAGE__ . "::" . $name;
}

1;

__END__

=head1 NAME

Net::Evernote::Simple - Simple interface to the Evernote API

=head1 SYNOPSIS

    use Net::Evernote::Simple;

    my $evernote = Net::Evernote::Simple->new(
          # Obtain a developer token from Evernote and put it here
        dev_token => "XXX",
    );

      # check if our client API version still works
    if( ! $evernote->version_check() ) {
        print "Evernote API version out of date!\n";
    }

    my $note_store = $evernote->note_store();

    if( !$note_store ) {
        die "getting notestore failed: $@";
    }

      # retrieve all of our notebooks
    my $notebooks =
      $note_store->listNotebooks( $evernote->dev_token() );

    for my $notebook ( @$notebooks ) {
       print $notebook->name(), "\n";
    }

=head1 DESCRIPTION

Net::Evernote::Simple enables easy access to the Evernote API with developer
tokens.

Developer tokens allow read/write access to a user's Evernote data.
If you don't have a developer token yet, you can obtain one here:

    http://dev.evernote.com/documentation/cloud/chapters/Authentication.php#devtoken

Net::Evernote::Simple then lets you obtain a note_store object which can
then be used with a variety of functions of the Evernote API described
here:

    http://dev.evernote.com/documentation/cloud/chapters/

=head1 METHODS

=over 4

=item C<new()>

Constructor, creates a helper object to retrieve a note store object
later. To access Evernote data, you need a developer token and specify it
either with the C<dev_token> parameter in the constructor call:

    my $evernote = Net::Evernote::Simple->new(
        dev_token => "XXX",
    );

You can omit the C<dev_token> parameter and let Net::Evernote::Simple search
for a configuration file named C<~/.evernote.yml> containing the developer
token like

    dev_token: XXX

within the YAML data. To specify an alternative YAML file, use

    my $evernote = Net::Evernote::Simple->new(
        config_file => "/path/to/evernote.yml",
    );

The object points to the Evernote production server by default. If you
want to use the sandbox instead, use 

    my $evernote = Net::Evernote::Simple->new(
        evernote_host => "sandbox.evernote.com",
    );

=item C<version_check()>

Contact the Evernote API server and verify if the client API version 
we're using is still supported. If this fails, please contact the author
of this module and ask to update the distribution on CPAN.

To make things easier for users of this module, the Evernote 

=item C<dev_token()>

Return the value of the developer token. Many Evernote API functions need
the value of the token (like C<listNotebooks()> or C<createNote()>).

=item C<note_store()>

Obtain a note_store object from Evernote SDK, which allows you call
all sorts of Evernote data manipulation functions, like 
C<listNotebooks()> or C<createNote()>.

=back

One thing to keep in mind when using this library is that the original
C<EDAMxxx> namespace of the Evernote API has been converted to 
C<Net::Evernote::Simple::EDAMxxx> to avoid collisions. 

To obtain the fully qualified module names, you can use the special 
C<sdk()> method, so instead of saying

    my $filter =
      Net::Evernote::Simple::EDAMNoteStore::NoteFilter->new();

you can just as well say

    my $filter = $en->sdk( "EDAMNoteStore::NoteFilter" )->new();

See the example
below to get an idea on how to use this API. Consult the official Evernote
API documentation at the link listed above for details on data structures
used and parameters needed.

=head1 EXAMPLE: Finding and printing notes

    use Net::Evernote::Simple;
    my $en = Net::Evernote::Simple->new();
    
    if( ! $en->version_check() ) {
      die "Evernote API version out of date!";
    }
    
    my $note_store = $en->note_store() or
       die "getting notestore failed: $@";
    
    my $filter = $en->sdk(
      "EDAMNoteStore::NoteFilter" )->new(
        { words => "foo bar baz" } );
    
    my $offset    = 0;
    my $max_notes = 100;
    
    my $result = $note_store->findNotes(
        $en->{ dev_token },
        $filter,
        $offset,
        $max_notes
    );
    
    for my $hit ( @{ $result->{ notes } } ) {
      my $note = $note_store->getNote( 
       $en->{ dev_token }, $hit->{ guid }, 1 );
      print $note->{ content };
    }

=head1 EXAMPLE: Add a note with a JPG image to notebook "Recipes"

    use Net::Evernote::Simple;
    use Sysadm::Install qw( slurp );
    use Digest::MD5 qw( md5_hex );
    
    my( $jpg_file ) = @ARGV;
    
    if( !defined $jpg_file ) {
        die "usage: $0 jpg_file";
    }
    
    my $evernote = Net::Evernote::Simple->new(
      # Obtain a developer token from Evernote and put it here
      # or use a ~/.evernote.yml file with a "dev_token" entry
        # dev_token => "XXX",
    );
    
      # check if our client API version still works
    if( ! $evernote->version_check() ) {
        die "Evernote API version out of date!";
    }
    
    my $note_store = $evernote->note_store();
    
    if( !$note_store ) {
       die "getting notestore failed: $@";
    }
    
      # retrieve all of our notebooks
    my $notebooks =
       $note_store->listNotebooks( $evernote->dev_token() );
    
    my $notebook_guid;
    
      # see if we can find one named "Recipes"
    for my $notebook ( @$notebooks ) {
        if( $notebook->name() eq "Recipes" ) {
            $notebook_guid = $notebook->guid();
            last;
        }
    }
    
    if( !defined $notebook_guid ) {
        die "Notebook 'Recipes' not found";
    }
    
    my $data = Net::Evernote::Simple::EDAMTypes::Data->new();
    
    my $content = slurp $jpg_file;
    $data->body( $content );
    my $hash = md5_hex( $content );
    $data->bodyHash( $hash );
    $data->size( length $content );
    
    my $r = Net::Evernote::Simple::EDAMTypes::Resource->new();
    $r->data( $data );
    $r->mime( "image/jpeg" );
    $r->noteGuid( "" );
    
    my $note = Net::Evernote::Simple::EDAMTypes::Note->new();
    $note->title( "Our note title" );
    $note->resources( [$r] );
    $note->notebookGuid( $notebook_guid );
    
    my $enml = <<EOT;
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd">
    <en-note>
       <en-media type="image/jpeg" hash="$hash"/>
    </en-note>
    EOT
    
    $note->content( $enml );
    
    $note_store->createNote(
       $evernote->dev_token(), $note );

=head1 LEGALESE

Copyright 2012 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2012, Mike Schilli <cpan@perlmeister.com>
