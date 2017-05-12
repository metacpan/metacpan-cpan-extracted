package Net::Evernote::Note;

use warnings;
use strict;
our $VERSION = '0.07';

sub new {
    my ($class, $args) = @_;
    my $debug = $ENV{DEBUG};
    
    return bless { 
        _obj        => $$args{_obj},
        _notestore => $$args{_notestore},
        _authentication_token       => $$args{_authentication_token},
        debug       => $debug,
    }, $class;
}

# return all of the note's Tag objects
sub tags {
    
}

sub delete {
    my ($self) = @_;

    my $authToken = $self->{_authentication_token};
    my $client = $self->{_notestore};
    my $guid = $self->guid;
    return $client->deleteNote($authToken,$guid);
}

sub tagNames {
    my $self = shift;

    my $obj  = $self->{_obj};
    my $ns   = $self->{_notestore};
    my $auth = $self->{_authentication_token};
    my $guids = $obj->tagGuids;

    return undef if !$guids;
    my @tag_names = map {
        $ns->getTag($auth, $_)->name;
    } @$guids;

    return wantarray ? @tag_names : \@tag_names;
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
        # FIXME: would be better to get feedback about a non-existing method
        return undef;
    }
}

1;

__END__

1;


=head1 NAME

Net::Evernote::Note

=head1 VERSION

Version 0.06


=head1 SYNOPSIS

    use Net::Evernote;
    use Net::Evernote::Note;

    my $evernote = Net::Evernote->new({
        authentication_token => $authentication_token
    });

my $note_title = 'test title';
my $note_tags  = [qw(evernote-perl-api-test-tag-1 evernote-perl-api-test-tag-2)];

# let's throw a date in there:
my $dt = DateTime->new(
    year   => 1981,
    month  => 4,
    day    => 4,
    hour   => 13,
    minute => 30,
    time_zone => 'EST'
);

my $epoch_time  = $dt->epoch;

my $note = $evernote->createNote({
    title     => $note_title,
    content   => 'here is some test content',
    tag_names => $note_tags,
    created   => $epoch_time*1000,
});

my $guid = $note->guid;

my $new_note = $evernote->getNote({
    guid => $guid,
});

# delete it
$new_note->delete;

=head1 SEE ALSO

http://www.evernote.com/about/developer/api/


=head1 AUTHOR

David Collins <davidcollins4481@gmail.com>

=head1 BUGS/LIMITATIONS

If you have found bugs, please send email to <davidcollins4481@gmail.com>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Evernote::Note


=head1 COPYRIGHT & LICENSE

Copyright 2013 David Collins, all rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.
