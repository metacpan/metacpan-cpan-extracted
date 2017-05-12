package Net::LeanKit;
BEGIN {
  $Net::LeanKit::AUTHORITY = 'cpan:ADAMJS';
}
$Net::LeanKit::VERSION = '2.001';
# ABSTRACT: A perl library for Leankit.com

use Carp qw(croak);
use Path::Tiny;
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::JSON qw(encode_json decode_json);
use Function::Parameters;
use Moose;
use namespace::clean;



has email    => (is => 'ro', required => 1, isa => 'Str');
has password => (is => 'ro', required => 1, isa => 'Str');
has account  => (is => 'ro', required => 1, isa => 'Str');

has defaultWipOverrideReason => (
    is      => 'ro',
    default => 'WIP Override performed by external system'
);

has ua => (is => 'ro', isa => 'Mojo::UserAgent', builder => '_build_http');

method _build_http {
    Mojo::UserAgent->new;
}

method get ($endpoint) {
    my $url = Mojo::URL->new;
    $url->scheme('https');
    $url->userinfo(sprintf("%s:%s", $self->email, $self->password));
    $url->host($self->account . '.leankit.com');
    $url->path('kanban/api/' . $endpoint);
    my $r = $self->ua->get($url->to_string);
    if (my $res = $r->success) {
        my $content = decode_json($res->body);
        return {
            code    => $content->{ReplyCode},
            content => $content->{ReplyData}->[0],
            status  => $content->{ReplyText}
        };
    }
    else {
        my $err = $r->error;
        croak "$err->{code} response: $err->{message}" if $err->{code};
        croak "$err->{message}";
    }
}

method post ($endpoint, $body) {
    my $url = Mojo::URL->new;
    $url->scheme('https');
    $url->userinfo(sprintf("%s:%s", $self->email, $self->password));
    $url->host($self->account . '.leankit.com');
    $url->path('kanban/api/' . $endpoint);
    my $r = $self->ua->post($url->to_string => form => $body);
    if (my $res = $r->success) {
        my $content = decode_json($res->body);
        return {
            code    => $content->{ReplyCode},
            content => $content->{ReplyData}->[0],
            status  => $content->{ReplyText}
        };
    }
    else {
        my $err = $r->error;
        croak "$err->{code} response: $err->{message}" if $err->{code};
        croak "$err->{message}";
    }
}



method getBoards {
    return $self->get('boards');
}



method getNewBoards {
    return $self->get('ListNewBoards');
}


method getBoard ($id) {
    my $boardId = sprintf('boards/%s', $id);
    return $self->get($boardId);
}



method getBoardByName ($boardName) {
    foreach my $board (@{$self->getBoards->{content}}) {
        next unless $board->{Title} =~ /$boardName/i;
        return $board;
    }
}


method getBoardIdentifiers ($boardId) {
    my $board = sprintf('board/%s/GetBoardIdentifiers', $boardId);
    return $self->get($board);
}


method getBoardBacklogLanes ($boardId) {
    my $board = sprintf("board/%s/backlog", $boardId);
    return $self->get($board);
}


method getBoardArchiveLanes ($boardId) {
    my $board = sprintf("board/%s/archive", $boardId);
    return $self->get($board);
}


method getBoardArchiveCards ($boardId) {
    my $board = sprintf("board/%s/archivecards", $boardId);
    return $self->get($board);
}


method getNewerIfExists ($boardId, $version) {
    my $board = sprintf("board/%s/boardversion/%s/getnewerifexists", $boardId,
        $version);
    return $self->get($board);
}


method getBoardHistorySince ($boardId, $version) {
    my $board = sprintf("board/%s/boardversion/%s/getboardhistorysince",
        $boardId, $version);
    return $self->get($board);
}


method getBoardUpdates ($boardId, $version) {
    my $board =
      sprintf("board/%s/boardversion/%s/checkforupdates", $boardId, $version);
    return $self->get($board);
}


method getCard ($boardId, $cardId) {
    my $board = sprintf("board/%s/getcard/%s", $boardId, $cardId);
    return $self->get($board);
}


method getCardByExternalId ($boardId, $externalCardId) {
    my $board = sprintf("board/%s/getcardbyexternalid/%s",
        $boardId, $externalCardId);
    return $self->get($board);
}



method addCard ($boardId, $laneId, $position, $card) {
    $card->{UserWipOverrideComment} = $self->defaultWipOverrideReason;
    my $newCard =
      sprintf('board/%s/AddCardWithWipOverride/Lane/%s/Position/%s',
        $boardId, $laneId, $position);
    return $self->post($newCard, $card);
}


method addCards ($boardId, ArrayRef $cards) {
    my $newCard = sprintf('board/%s/AddCards?wipOverrideComment="%s"',
        $boardId, $self->defaultWipOverrideReason);
    return $self->post($newCard, $cards);
}



method moveCard ($boardId, $cardId, $toLaneId, $position) {
    my $moveCard =
      sprintf('board/%s/movecardwithwipoverride/%s/lane/%s/position/%s',
        $boardId, $cardId, $toLaneId, $position);
    my $params = {comment => $self->defaultWipOverrideReason};
    return $self->post($moveCard, $params);
}



method moveCardByExternalId ($boardId, $externalCardId, $toLaneId, $position) {
    my $moveCard = sprintf(
        'board/%s/movecardbyexternalid/%s/lane/%s/position/%s',
        $boardId, uri_escape($externalCardId),
        $toLaneId, $position
    );
    my $params = {comment => $self->defaultWipOverrideReason};
    return $self->post($moveCard, $params);
}



method moveCardToBoard ($cardId, $destinationBoardId) {
    my $moveCard = sprintf('card/movecardtoanotherboard/%s/%s',
        $cardId, $destinationBoardId);
    my $params = {};
    return $self->post($moveCard, $params);
}



method updateCard ($boardId, $card) {
    $card->{UserWipOverrideComment} = $self->defaultWipOverrideReason;
    my $updateCard = sprintf('board/%s/UpdateCardWithWipOverride');
    return $self->post($updateCard, $card);
}


method updateCardFields ($updateFields) {
    return $self->post('card/update', $updateFields);
}


method getComments ($boardId, $cardId) {
    my $comment = sprintf('card/getcomments/%s/%s', $boardId, $cardId);
    return $self->get($comment);
}


method addComment ($boardId, $cardId, $userId, $comment) {
    my $params = {PostedById => $userId, Text => $comment};
    my $addComment = sprintf('card/savecomment/%s/%s', $boardId, $cardId);
    return $self->post($addComment, $params);
}


method addCommentByExternalId ($boardId, $externalCardId, $userId, $comment) {
    my $params = {PostedById => $userId, Text => $comment};
    my $addComment = sprintf('card/savecommentbyexternalid/%s/%s',
        $boardId, uri_escape($externalCardId));
    return $self->post($addComment, $params);
}


method getCardHistory ($boardId, $cardId) {
    my $history = sprintf('card/history/%s/%s', $boardId, $cardId);
    return $self->get($history);
}



method searchCards ($boardId, $options) {
    my $search = sprintf('board/%s/searchcards', $boardId);
    return $self->post($search, $options);
}


method getNewCards ($boardId) {
    my $newCards = sprintf('board/%s/listnewcards', $boardId);
    return $self->get($newCards);
}


method deleteCard ($boardId, $cardId) {
    my $delCard = sprintf('board/%s/deletecard/%s', $boardId, $cardId);
    return $self->post($delCard, {});
}


method deleteCards ($boardId, $cardIds) {
    my $delCard = sprintf('board/%s/deletecards', $boardId);
    return $self->post($delCard, $cardIds);
}


method getTaskBoard ($boardId, $cardId) {
    my $taskBoard =
      sprintf('v1/board/%s/card/%s/taskboard', $boardId, $cardId);
    return $self->get($taskBoard);
}


method addTask ($boardId, $cardId, $taskCard) {
    $taskCard->{UserWipOverrideComment} = $self->defaultWipOverrideReason;
    my $url = sprintf('v1/board/%s/card/%s/tasks/lane/%s/position/%s',
        $boardId, $cardId, $taskCard->{LaneId}, $taskCard->{Index});
    return $self->post($url, $taskCard);
}


method updateTask ($boardId, $cardId, $taskCard) {
    $taskCard->{UserWipOverrideComment} = $self->defaultWipOverrideReason;
    my $url = sprintf('v1/board/%s/update/card/%s/tasks/%s',
        $boardId, $cardId, $taskCard->{Id});
    return $self->post($url, $taskCard);
}


method deleteTask ($boardId, $cardId, $taskId) {
    my $url = sprintf('v1/board/%s/delete/card/%s/tasks/%s',
        $boardId, $cardId, $taskId);
    return $self->post($url, {});
}


method getTaskBoardUpdates ($boardId, $cardId, $version) {
    my $url = sprintf('v1/board/%s/card/%s/tasks/boardversion/%s',
        $boardId, $cardId, $version);
    return $self->get($url);
}


method moveTask ($boardId, $cardId, $taskId, $toLaneId, $position) {
    my $url = sprintf('v1/board/%s/move/card/%s/tasks/%s/lane/%s/position/%s',
        $boardId, $cardId, $taskId, $toLaneId, $position);
    return $self->post($url, {});
}


method getAttachmentCount ($boardId, $cardId) {
    my $url = sprintf('card/GetAttachmentsCount/%s/%s', $boardId, $cardId);
    return $self->get($url);
}


method getAttachments ($boardId, $cardId) {
    my $url = sprintf('card/GetAttachments/%s/%s', $boardId, $cardId);
    return $self->get($url);
}


method getAttachment ($boardId, $cardId, $attachmentId) {
    my $url = sprintf('card/GetAttachments/%s/%s/%s',
        $boardId, $cardId, $attachmentId);
    return $self->get($url);
}

method downloadAttachment ($boardId, $cardId, $attachmentId, $dst) {
    my $url = sprintf('card/DownloadAttachment/%s/%s/%s',
        $boardId, $cardId, $attachmentId);
    my $dl = $self->get($url);
    path($dst)->spew($dl);
}



method deleteAttachment ($boardId, $cardId, $attachmentId) {
    my $url = sprintf('card/DeleteAttachment/%s/%s/%s',
        $boardId, $cardId, $attachmentId);
    return $self->post($url, {});
}

# method addAttachment($boardId, $cardId, $description, $file) {
#   my $url = sprintf('card/SaveAttachment/%s/%s', $boardId, $cardId);
#   my $filename = path($file);
#   my $attachment_data = { Id => 0, Description => $description, FileName => $filename->basename};
#   return $self->post($url, $file, $attachment_data);
# }

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::LeanKit - A perl library for Leankit.com

=head1 VERSION

version 2.001

=head1 SYNOPSIS

  use Net::LeanKit;
  my $lk = Net::LeanKit->(email => 'user\@.mail.com',
                          password => 'pass',
                          account => 'my company');
  $lk->getBoards;

=head1 ATTRIBUTES

=head2 email

Login email

=head2 password

Password

=head2 account

Account name in which your account is under, usually a company name.

=head1 METHODS

=head2 getBoards

Returns list of boards

=head2 getNewBoards

Returns list of latest created boards

=head2 getBoard

Gets leankit board by id

=head2 getBoardByName

Finds a board by name

=head2 getBoardIdentifiers

Get board identifiers

=head2 getBoardBacklogLanes

Get board back log lanes

=head2 getBoardArchiveLanes

Get board archive lanes

=head2 getBoardArchiveCards

Get board archive cards

=head2 getNewerIfExists

Get newer board version if exists

=head2 getBoardHistorySince

Get newer board history

=head2 getBoardUpdates

Get board updates

=head2 getCard

Get specific card for board

=head2 getCardByExternalId

Get specific card for board by an external id

=head2 addCard

Add a card to the board/lane specified. The card hash usually contains

  { TypeId => 1,
    Title => 'my card title',
    ExternalCardId => DATETIME,
    Priority => 1
  }

=head2 addCards

Add multiple cards to the board/lane specified. The card hash usually contains

  { TypeId => 1,
    Title => 'my card title',
    ExternCardId => DATETIME,
    Priority => 1
  }

=head2 moveCard

Moves card to different lanes

=head2 moveCardByExternalId

Moves card to different lanes by externalId

=head2 moveCardToBoard

Moves card to another board

=head2 updateCard

Update a card

=head2 updateCardFields

Update fields in card

=head2 getComments

Get comments for card

=head2 addComment

Add comment for card

=head2 addCommentByExternalId

Add comment for card

=head2 getCardHistory

Get card history

=head2 searchCards

Search cards, options is a hashref of search options

Eg,

    searchOptions = {
        IncludeArchiveOnly: false,
        IncludeBacklogOnly: false,
        IncludeComments: false,
        IncludeDescription: false,
        IncludeExternalId: false,
        IncludeTags: false,
        AddedAfter: null,
        AddedBefore: null,
        CardTypeIds: [],
        ClassOfServiceIds: [],
        Page: 1,
        MaxResults: 20,
        OrderBy: "CreatedOn",
        SortOrder: 0
    };

=head2 getNewCards

Get latest added cards

=head2 deleteCard

Delete a single card

=head2 deleteCards

Delete batch of cards

=head2 getTaskBoard

Get task board

=head2 addTask

Adds task to card

=head2 updateTask

Updates task in card

=head2 deleteTask

Deletes task

=head2 getTaskBoardUpdates

Get latest task additions/changes

=head2 moveTask

Moves task to different lanes

=head2 getAttachmentCount

Get num of attachments for card

=head2 getAttachments

Get list of attachments

=head2 getAttachment

Get single attachment

=head2 deleteAttachment

Removes attachment from card

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
