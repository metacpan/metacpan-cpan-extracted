package Parley::ResultSet::ThreadView;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use base 'DBIx::Class::ResultSet';

sub watching_thread {
    my ($self, $thread, $person) = @_;

    if (not defined $thread) {
        warn 'undefined value passed as $thread in watching_thread()';
        return;
    }
    if (not defined $person) {
        warn 'undefined value passed as $person in watching_thread()';
        return;
    }

    my $thread_view = $self->find(
        {
            person_id => $person->id(),
            thread_id => $thread->id(),
        }
    );

    return $thread_view->watched();
}

sub notification_list {
    my ($self, $post) = @_;
    my ($schema);

    if (not defined $post) {
        warn 'undefined value passed as $post in notification_list()';
        return;
    }

    # make sure we have full object details
    # [we don't seem to get all the default column data for a new create()]
    $schema = $self->result_source()->schema();
    $post = $schema->resultset('Post')->find(
        id => $post->id()
    );
    if (not defined $post) {
        warn 'failed to re-fetch post in notification_list()';
        return;
    }

    # find the list of people to notify about this update
    my $notification_list = $self->search(
        {
            # the thread the post belongs to
            thread_id       => $post->thread()->id(),
            # only interested in records where a person is watching
            watched         => 1,
            # and they last viewed the thread before the last post
            timestamp       => {
                '<',
                DateTime::Format::Pg->format_datetime(
                    $post->created()
                )
            },
            # and they've not been notified
            last_notified   => [
                {   '=',    undef   },
                   \'< timestamp'    ,
            ],
            # and they aren't the person that created the post itself
            person_id => {
                '!=',
                $post->creator()->id(),
            },
        }
    );

    return $notification_list;
}

1;
