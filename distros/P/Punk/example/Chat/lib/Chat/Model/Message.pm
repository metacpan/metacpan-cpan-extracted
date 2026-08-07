package Chat::Model::Message;

use Punk::Model;

# Every message ever said, in every room. The web page, the WebSocket
# handler and the API operations all reach this one model through
# $c->model('Message') - the instance is built once per worker.

table 'messages';

field id      => { type => 'integer', primary => 1 };
field room    => { type => 'string', required => 1, minLength => 1,
                   maxLength => 32, pattern => '^[a-z0-9][a-z0-9-]*$' };
field nick    => { type => 'string', required => 1, minLength => 1,
                   maxLength => 32 };
field body    => { type => 'string', required => 1, minLength => 1,
                   maxLength => 1000 };
field created => { type => 'string' };

# ---- custom queries --------------------------------------------------------
#
# The six-method contract orders by the primary key ascending, which is the
# right shape for paging forward through history and the wrong one for "the
# last N". Both of these are what Punk::Model calls a custom method: an
# ordinary sub on the model class, using the backend's pooled handle.

# The newest $limit messages in a room, oldest first (chat reading order).
sub recent {
    my ($self, $room, $limit) = @_;
    $limit = 50 unless defined $limit && $limit > 0;
    $limit = 200 if $limit > 200;
    my $rows = $self->backend->dbh->selectall_arrayref(
        'SELECT id, room, nick, body, created FROM messages
          WHERE room = ? ORDER BY id DESC LIMIT ?',
        { Slice => {} }, $room, $limit);
    return [ reverse @$rows ];
}

# Every room that has ever been spoken in, with its message count and the
# timestamp of the last thing said.
sub rooms {
    my ($self) = @_;
    return $self->backend->dbh->selectall_arrayref(
        'SELECT room, COUNT(*) AS messages, MAX(created) AS last_at
           FROM messages GROUP BY room ORDER BY room',
        { Slice => {} });
}

# Empty one room; the number of messages removed.
sub purge {
    my ($self, $room) = @_;
    my $dbh = $self->backend->dbh;
    my $sth = $dbh->prepare_cached('DELETE FROM messages WHERE room = ?');
    $sth->execute($room);
    my $n = $sth->rows;
    $sth->finish;
    return $n < 0 ? 0 : $n;
}

1;
