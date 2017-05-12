package Net::Evernote;

BEGIN {
    my $module_dir = $INC{'Net/Evernote.pm'};
    $module_dir =~ s/Evernote\.pm$//;
    unshift @INC,$module_dir;
}

use warnings;
use strict;
use Exception::Class (
    'Net::Evernote::EDAMTest::Exception::ExceptionWrapper',
    'Net::Evernote::EDAMTest::Exception::FileIOError',
);

use LWP::Protocol::https; # it is not needed to 'use' here, but it must be installed.
        # if it is not installed, an error (Thrift::TException object) is to be thrown.
use Thrift::HttpClient;
use Thrift::BinaryProtocol;
use Net::Evernote::EDAMTypes::Types;  # you must do `use' Net::Evernote::EDAMTypes::Types and Net::Evernote::EDAMErrors::Types
use Net::Evernote::EDAMErrors::Types; # before doing `use' Net::Evernote::EDAMUserStore::UserStore or Net::Evernote::EDAMNoteStore::NoteStore
use Net::Evernote::EDAMUserStore::UserStore;
use Net::Evernote::EDAMNoteStore::NoteStore;
use Net::Evernote::EDAMUserStore::Constants;
use Evernote::Note;
use Evernote::Tag;
use Evernote::Notebook;
our $VERSION = '0.081';

sub new {
    my ($class, $args) = @_;
    my $authentication_token = $$args{authentication_token};
    my $debug = $ENV{DEBUG};
    my $evernote_host;

    if ($$args{use_sandbox}) {
        $evernote_host = 'sandbox.evernote.com';
    } else {
        $evernote_host = 'www.evernote.com';
    }

    my $user_store_url = 'https://' . $evernote_host . '/edam/user';
    my $result;
    my $note_store;

    eval {

        local $SIG{__DIE__} = sub {
            my ( $err ) = @_;
            if ( not ( blessed $err && $err->isa('Exception::Class::Base') ) ) {
                Net::Evernote::EDAMTest::Exception::ExceptionWrapper->throw( error => $err );
            }
        };

        my $user_store_client = Thrift::HttpClient->new( $user_store_url );
        # default timeout value may be too short
        $user_store_client->setSendTimeout( 2000 );
        $user_store_client->setRecvTimeout( 10000 );
        my $user_store_prot = Thrift::BinaryProtocol->new( $user_store_client );
        my $user_store = Net::Evernote::EDAMUserStore::UserStoreClient->new( $user_store_prot, $user_store_prot );

        my $version_ok = $user_store->checkVersion( 'Evernote Net::Evernote::EDAMTest (Perl)',
            Net::Evernote::EDAMUserStore::Constants::EDAM_VERSION_MAJOR,
            Net::Evernote::EDAMUserStore::Constants::EDAM_VERSION_MINOR );

        if ( not $version_ok ) {
            printf "Evernote API version not up to date?\n";
            exit(1)
        }

        my $note_store_url = $user_store->getNoteStoreUrl( $authentication_token );

        warn "[INFO] note store url : $note_store_url \n" if $debug;
        my $note_store_client = Thrift::HttpClient->new( $note_store_url );
        # default timeout value may be too short
        $note_store_client->setSendTimeout( 2000 );
        $note_store_client->setRecvTimeout( 10000 );
        my $note_store_prot = Thrift::BinaryProtocol->new( $note_store_client );

        # search this class for API methods
        $note_store = Net::Evernote::EDAMNoteStore::NoteStoreClient->new( $note_store_prot, $note_store_prot );
    };

    if ($@) {
        my $err = $@;
        die "Code: " . $$err{'code'} . ', ' . $$err{'message'};
    }

    return bless { 
        debug             => $debug,
        _authentication_token  => $authentication_token,
        _notestore        => $note_store,
        _authenticated    => 1, # safe to assume if we've gotten this far?
    }, $class;
}

# TODO: make this is current
sub createNote {
    my ($self, $args) = @_;
    my $authentication_token = $self->{_authentication_token};
    my $client    = $self->{_notestore};

    my $title = $$args{title};
    my $content = $$args{content};
    my $created = $$args{created};

    # support notebook name?
    my $notebook_guid = $$args{notebook_guid};
    $content =~ s/\n/<br\/>/g;

     my $cont_encoded =<<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd">
<en-note>
    $content
</en-note>
EOF

    my $note_args = {
        title   => $title,
        content => $cont_encoded,
    };

    $$note_args{created} = $created if $created;
    $$note_args{notebookGuid} = $notebook_guid if $notebook_guid;

    my $tags;

    # if tag already exists, just uses it and doesn't overwrite it.
    # Not sure if the eval is the best way to handle it but it seems
    # to do the job
    if (my $tag_args = $$args{tag_names}) {
        # make sure this is an array ref
        $tags = ref($tag_args) eq 'ARRAY' ? $tag_args: [$tag_args];
        map {
            my $tag = Net::Evernote::EDAMTypes::Tag->new({ name => $_ });
            eval {
                $client->createTag($authentication_token, $tag);
            };

            if ($@) {
                # dump 'em in a ditch
             }
        } @$tags;

         $$note_args{tagNames} = $tags;
    }

    if (my $tag_guids = $$args{tag_guids}) {
        my $guids = ref($tag_guids) eq 'ARRAY' ? $tag_guids : [$tag_guids];
        $$note_args{tagGuids} = $guids;
    }

    my $note = Net::Evernote::EDAMTypes::Note->new($note_args);

    return Net::Evernote::Note->new({
        _obj        => $client->createNote($authentication_token, $note),
        _notestore => $self->{_notestore},
        _authentication_token       => $authentication_token,
    });
}

sub deleteNote {
    my ($self, $args) = @_;
    my $guid = $$args{guid};

    my $authToken = $self->{_authentication_token};
    my $client = $self->{_notestore};

    $client->deleteNote($authToken,$guid);
}

sub getNote {
    my ($self, $args) = @_;
    my $guid = $$args{guid};

    my $client = $self->{_notestore};
    my $authentication_token = $self->{_authentication_token};

    return Net::Evernote::Note->new({
        _obj        => $client->getNote($authentication_token, $guid, 1),
        _notestore => $self->{_notestore},
        _authentication_token       => $authentication_token,
    });
}

sub getNotebook {
    my ($self, $args) = @_;
    my $guid = $$args{guid};

    my $client = $self->{_notestore};
    my $authentication_token = $self->{_authentication_token};

    my $notebook;
    eval {
        $notebook = Net::Evernote::Notebook->new({
            _obj        => $client->getNotebook($authentication_token, $guid, 1),
            _notestore => $self->{_notestore},
            _authentication_token       => $authentication_token,
        });
    };

    if (my $error = $@) {
        # notebook not found
        if (ref($error) eq 'Net::Evernote::EDAMNotFoundException') {
            return;
        }
    }

    return $notebook;
}

sub findNotes {
    my ($self, $args) = @_;
    my $string = $$args{string};
    my $offset = $$args{offset} || 0;
    my $maxNotes = $$args{maxCount} || 1;

    my $authentication_token = $self->{_authentication_token};

    my $stru = Net::Evernote::EDAMNoteStore::NoteFilter->new({ words => $string });
    my $client = $self->{_notestore};

    return $client->findNotes($authentication_token,$stru,$offset,$maxNotes);
}

sub listNotebooks {
    my $self = shift;
    my $client = $self->{_notestore};
    return $client->listNotebooks($self->{_authentication_token});
}

sub createNotebook {
    my ($self, $args) = @_;
    my $client = $self->{_notestore};
    my $notebook = Net::Evernote::EDAMTypes::Notebook->new({
        name => $$args{name},
    });

    return Net::Evernote::Notebook->new({
        _obj => $client->createNotebook($self->{_authentication_token}, $notebook),
        _notestore => $self->{_notestore},
    });
}

sub deleteNotebook {
    my ($self, $args) = @_;
    my $guid = $$args{guid};

    my $authToken = $self->{_authentication_token};
    my $client = $self->{_notestore};

    return $client->expungeNotebook($authToken,$guid);
}

sub authenticated {
    my $self = shift;
    return $self->{_authenticated};
}

sub createTag {
    my ($self, $args) = @_;
    my $authentication_token = $self->{_authentication_token};
    my $client    = $self->{_notestore};

    my $name = $$args{name};

    die "Name required to create tag\n" if !$name;

    my $tag = Net::Evernote::EDAMTypes::Tag->new({ name => $name });

    return Net::Evernote::Tag->new({
        _obj        => $client->createTag($authentication_token, $tag),
        _notestore => $self->{_notestore},
        _authentication_token  => $authentication_token,
    }); 
}

sub getTag {
    my ($self, $args) = @_;
    my $guid = $$args{guid};

    my $client = $self->{_notestore};
    my $authentication_token = $self->{_authentication_token};

    my $tag;

    eval {
        $tag = Net::Evernote::Tag->new({
            _obj        => $client->getTag($authentication_token, $guid, 1),
            _notestore => $self->{_notestore},
            _authentication_token       => $authentication_token,
        });
    };

    if (my $error = $@) {
        # tag not found
        if (ref($error) eq 'Net::Evernote::EDAMNotFoundException') {
            return;
        }
    }

    return $tag;

}

sub deleteTag {
    my ($self, $args) = @_;
    my $ns = $self->{_notestore};

    # FIXME: IS THIS EVEN POSSIBLE?
    # I don't see any code for this yet in Net::Evernote::EDAMNoteStore::NoteStore.pm

}

1;

=head1 NAME

Net::Evernote - Perl API for Evernote

=head1 VERSION

Version 0.06


=head1 SYNOPSIS

    use Net::Evernote;

    my $evernote = Net::Evernote->new({
        authentication_token => $authentication_token
    });

    # write a note
    my $res = $evernote->createNote({
        title => $title,
        content => $content
    });

    my $guid = $res->guid;

    # get the note
    my $thisNote = $evernote->getNote({ guid => $guid });
    print $thisNote->title,"\n";
    print $thisNote->content,"\n";

    # delete the note
    $evernote->deleteNote({ guid => $guid });

    # find notes
    my $search = $evernote->findNotes({ keywords => $keywords, offset => $offset, max_notes => 5 });
    for my $thisNote ( @{$search->notes} ) {
        print $thisNote->guid,"\n";
        print $thisNote->title,"\n";
    }

=head1 METHODS

More docs coming for this. 

=head1 SEE ALSO

http://www.evernote.com/about/developer/api/


=head1 AUTHOR

David Collins <davidcollins4481@gmail.com>

=head1 BUGS/LIMITATIONS

If you have found bugs, please send email to <davidcollins4481@gmail.com>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Evernote


=head1 COPYRIGHT & LICENSE

Copyright 2013 David Collins, all rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.
