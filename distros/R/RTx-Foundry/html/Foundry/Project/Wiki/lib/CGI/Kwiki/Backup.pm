package CGI::Kwiki::Backup;
$VERSION = '0.18';
use strict;

use base 'CGI::Kwiki';

sub commit {
    1;
}

sub has_history {
    0;
}

sub version_mark {
    my ($self) = @_;
    $self->database->update_time;
}

sub conflict {
    my ($self) = @_;
    return unless $self->database->update_time > $self->cgi->version_mark;
    return {
        error_msg => $self->error_msg,
    };
}

sub error_msg {
    <<MSG;
While you were editing this page somebody else saved changes to it. 
You need to start over and apply your changes to the latest copy of the page.
MSG
}

1;
