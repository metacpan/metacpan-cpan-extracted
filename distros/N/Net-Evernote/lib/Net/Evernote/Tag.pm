package Net::Evernote::Tag;

use strict;
use warnings;
our $VERSION = '0.07';

sub new {
    my ($class, $args) = @_;
    my $debug = $ENV{DEBUG};

    if (!$$args{_obj} && !$$args{name} && !$$args{guid}) {
        die "Name or Guid required to create/retrieve a tag\n";
    }

    my $obj = $$args{_obj};

    return bless { 
        _obj        => $obj,
        _authentication_token  => $$args{_authentication_token},
        debug       => $debug,
        _notestore  => $$args{_notestore},
    }, $class;
}

sub delete {
    my ($self, $args) = @_;
    my $guid = $self->guid;

    my $authToken = $self->{_authentication_token};
    my $client = $self->{_notestore};

    return $client->expungeTag($authToken,$guid);
}

# the magic
sub AUTOLOAD {
    my ($self,@args) = @_;
    our ($AUTOLOAD);
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    if ($self->{_obj}->can($method)) {
        return $self->{_obj}->$method;
    } else {
        return undef;
    }
}
1;



=head1 NAME

Net::Evernote::Tag

=head1 VERSION

Version 0.06


=head1 SYNOPSIS

    use Net::Evernote;
    use Net::Evernote::Tag;

    my $evernote = Net::Evernote->new({
        authentication_token => $authentication_token
    });

    my $tag = $evernote->createTag({'name' => $tag_name });
    $tag_guid = $tag->guid;

    my $tag = $evernote->getTag({
        guid => $tag_guid, 
    });

    my $note = $evernote->getNote({
        guid => $note_guid,
    });

    my $tagGuids = $note->tagGuids;

=head1 SEE ALSO

http://www.evernote.com/about/developer/api/


=head1 AUTHOR

David Collins <davidcollins4481@gmail.com>

=head1 BUGS/LIMITATIONS

If you have found bugs, please send email to <davidcollins4481@gmail.com>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Evernote::Tag


=head1 COPYRIGHT & LICENSE

Copyright 2013 David Collins, all rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.
