package Net::Hiveminder;
use Moose;
extends 'Net::Jifty';

our $VERSION = '0.08';

use DateTime;
use Number::RecordLocator;
my $LOCATOR = Number::RecordLocator->new;

has '+site' => (
    default => 'http://hiveminder.com'
);

has '+cookie_name' => (
    default => 'JIFTY_SID_HIVEMINDER',
);

has '+appname' => (
    default => 'BTDT',
);

has '+config_file' => (
    default => "$ENV{HOME}/.hiveminder",
);

has '+filter_file' => (
    default => ".hm",
);

sub display_tasks {
    my $self = shift;
    my @out;

    my $now = DateTime->now;
    my %email_of;

    my %args;
    if (ref($_[0]) eq 'ARRAY') {
        %args = @{ shift(@_) };
    }

    for my $task (@_) {
        my $locator = $self->id2loc($task->{id});
        my $display;

        if ($task->{complete}) {
            $display .= '* ';
        }

        if ($args{linkify_locator}) {
            $display .= sprintf '<a href="%s/task/%s">#%s</a>: %s',
                $self->site,
                $locator,
                $locator,
                $task->{summary};
        }
        else {
            $display .= "#$locator: $task->{summary}";
        }

        # don't display start date if it's <= today
        delete $task->{starts}
            if $task->{starts}
            && $self->load_date($task->{starts}) < $now;

        $display .= " [$task->{tags}]" if $task->{tags};
        for my $field (qw/due starts group/) {
            $display .= " [$field: $task->{$field}]"
                if $task->{$field};
        }

        $display .= " [priority: " . $self->priority($task->{priority}) . "]"
            if $task->{priority} != 3;

        my $helper = sub {
            my ($field, $name) = @_;

            my $id = $task->{$field}
                or return;

            # this wants to be //=. oh well
            my $email = $email_of{$id} ||= $self->email_of($id)
                or return;

            $self->is_me($email)
                and return;

            $display .= " [$name: $email]";
        };

        $helper->('requestor_id', 'for');
        $helper->('owner_id', 'by');

        push @out, $display;
    }

    return wantarray ? @out : join "\n", @out;
}

sub get_tasks {
    my $self = shift;
    my @args = @_;
    unshift @args, "tokens" if @args == 1;

    return @{ $self->act('TaskSearch', @args)->{content}{tasks} };
}

sub todo_tasks {
    my $self = shift;
    my @args = @_;
    unshift @args, "tokens" if @args == 1;

    $self->get_tasks(
        complete_not     => 1,
        accepted         => 1,
        owner            => 'me',
        starts_before    => 'tomorrow',
        depends_on_count => 0,

        %{ $self->filter_config },

        # XXX: this is one place to improve the API

        @args
    );
}

sub todo {
    my $self = shift;
    my $opts = [];
    $opts = shift if ref($_[0]) eq 'ARRAY';

    $self->display_tasks( $opts, $self->todo_tasks(@_) );
}

sub create_task {
    my $self    = shift;
    my $summary = shift;
    my %args    = @_;

    $self->create(Task =>
        summary => $summary,
        %{ $self->filter_config },
        %args,
    );
}

sub read_task {
    my $self  = shift;
    my $loc   = shift;
    my $id    = $self->loc2id($loc);

    return $self->read(Task => id => $id);
}

sub update_task {
    my $self = shift;
    my $loc  = shift;
    my $id   = $self->loc2id($loc);

    return $self->update(Task => id => $id, @_);
}

sub delete_task {
    my $self = shift;
    my $loc  = shift;
    my $id   = $self->loc2id($loc);

    return $self->delete(Task => id => $id);
}

sub bulk_update {
    my $self = shift;
    my %args = @_;

    my @ids;
    my $ids = delete $args{ids} || '';
    my $tasks = delete $args{tasks} || '';

    if (ref($ids) eq 'ARRAY') {
        push @ids, @$ids;
    }
    else {
        push @ids, split ' ', $ids;
    }

    if (ref($tasks) eq 'ARRAY') {
        push @ids, $self->loc2id(@$tasks);
    }
    elsif (ref($tasks) eq 'HASH') {
        push @ids, $self->loc2id($tasks);
    }
    else {
        push @ids, $self->loc2id(split ' ', $tasks);
    }

    $self->act('BulkUpdateTasks',
        ids => join(' ', @ids),
        %args,
    );
}

sub complete_tasks {
    my $self = shift;
    $self->bulk_update(
        tasks    => \@_,
        complete => 1,
    );
}

sub braindump {
    my $self = shift;
    my $text = shift;

    if (@_ == 1) {
        Carp::carp("You must now pass in an explicit 'tokens => string|arrayref' to have default tokens in Net::Hiveminder->braindump");
        unshift @_, 'tokens';
    }

    my %args = (
        tokens  => '',
        returns => 'summary',
        @_,
    );

    my $tokens = $args{tokens};
    if (ref($tokens) eq 'ARRAY') {
        $tokens = join ' ', @$tokens;
    }

    $tokens .= ' ' . join ' ', %{ $self->filter_config };

    my $ret = $self->act('ParseTasksMagically', text => $text, tokens => $tokens);
    if ($args{returns} eq 'ids') {
        return @{ $ret->{content}->{ids} || [] };
    }
    elsif ($args{returns} eq 'tasks') {
        return @{ $ret->{content}->{created} || [] };
    }

    return $ret->{message};
}

sub upload_text {
    my $self = shift;
    my $text = shift;

    return $self->act(UploadTasks => content => $text, format => 'sync')
                ->{message};
}

sub upload_file {
    my $self = shift;
    my $file = shift;

    my $text = do { local (@ARGV, $/) = $file; <> };

    return $self->upload_text($text);
}

sub download_text {
    my $self = shift;
    my $query = shift;

    return $self->act('DownloadTasks' =>
        $query ? (query => $query) : (),
        format => 'sync',
    )->{content}{result};
}

sub download_file {
    my $self = shift;
    my $file = shift;

    my $text = $self->download_text(@_);
    open my $handle, '>', $file
        or confess "Unable to open $file for writing: $!";
    print $handle $text;
    close $handle;
}

my @priorities = (undef, qw/lowest low normal high highest/);
sub priority {
    my $self = shift;
    my $priority = shift;

    # if they pass in a task, DTRT :)
    $priority = $priority->{priority}
        if ref($priority) eq 'HASH';

    return $priorities[$priority];
}

sub done {
    my $self = shift;

    for (@_) {
        my $id = $self->loc2id($_);
        $self->update('Task', id => $id, complete => 1);
    }
}

sub loc2id {
    my $self = shift;

    my @ids = map {
        my $locator = $_;

        # they passed in a hashref, so almost certainly a real task
        ref($locator) eq 'HASH'
            ? $locator->{id}
            : do {
                $locator =~ s/^#+//; # remove leading #
                $LOCATOR->decode($locator);
            };
    } @_;

    return wantarray ? @ids : $ids[0];
}

sub tasks2ids {
    Carp::carp "Net::Hiveminder->tasks2ids is deprecated, use loc2id instead.";
    loc2id(@_);
}

sub id2loc {
    my $self = shift;

    my @locs = map { $LOCATOR->encode($_) } @_;

    return wantarray ? @locs : $locs[0];
}

sub comments_on {
    my $self = shift;
    my $task = $self->loc2id(shift);

    return grep { defined }
           map { $_->{message} }
           @{ $self->search('TaskEmail', task_id => $task) || [] };
}

sub comment_on {
    my $self = shift;
    my $task = $self->loc2id(shift);
    my $msg  = shift;

    require Email::Simple;
    require Email::Simple::Creator;

    my $email = Email::Simple->create(
        header => [
            From => $self->email,
        ],
        body => $msg,
    );

    $self->create('TaskEmail',
        task_id => $task,
        message => $email->as_string,
    );
}

sub send_feedback {
    my $self = shift;
    my $text = shift;

    $self->act('SendFeedback', content => $text);
}


sub get_task_history {
    my $self = shift;
    my $task_id = $self->loc2id(shift);

    # see http://hiveminder.com/=/model/BTDT.Model.TaskTransaction
    return $self->search( 'TaskTransaction', task_id => $task_id, );
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 NAME

Net::Hiveminder - Perl interface to hiveminder.com

=head1 SYNOPSIS

    use Net::Hiveminder;
    my $hm = Net::Hiveminder->new(use_config => 1);
    print $hm->todo;
    $hm->create_task("Boy these pretzels are making me thirsty [due tomorrow]");

=head1 DESCRIPTION

Hiveminder is a collaborate todo list organizer, built with L<Jifty>.

This module uses Hiveminder's REST API to let you manage your tasks any way you
want to.

This module is built on top of L<Net::Jifty>. Consult that module's
documentation for the lower-level interface.

=head2 display_tasks [ARGS], TASKS

This will take a list of hash references, C<TASKS>, and convert each to a
human-readable form.

In scalar context it will return the readable forms of these tasks joined by
newlines.

Passing options into this is somewhat tricky, because tasks are currently
regular hashes. You may pass arguments to this method as such:

    $hm->display_tasks([arg1 => 'val1', arg2 => 'val2'], @tasks)

The arguments currently respected are:

=over 4

=item linkify_locator

Make the record locator (C<#foo>) into an HTML link, pointing to the task on
C<site>.

=back

=head2 get_tasks ARGS

Runs a search with C<ARGS> for tasks. There are no defaults here, so this can
be used for anything.

Returns a list of hash references, each one being a task. Use C<display_tasks>
if necessary.

=head2 todo_tasks [ARGS]

Returns a list of hash references, each one a task. This uses the same query
that the home page of Hiveminder uses. The optional C<ARGS> will be passed as
well so you can narrow down your todo list.

=head2 todo [ARGS]

Returns a list of tasks in human-readable form. The optional C<ARGS> will be
passed as well so you can narrow down your todo list.

In scalar context it will return the concatenation of the tasks.

If the first argument is an array reference, it will be passed to
L</display_tasks> as options.

For example, to display tasks due today (with color):

    print scalar $hm->todo([color => 1], due => "today");

=head2 create_task SUMMARY, ARGS

Creates a new task with C<SUMMARY>. You may also specify arguments such as what
tags the task will have.

=head2 read_task LOCATOR

Load task C<LOCATOR>.

=head2 update_task LOCATOR, ARGS

Update task C<LOCATOR> with C<ARGS>.

=head2 delete_task LOCATOR

Delete task C<LOCATOR>.

=head2 bulk_update ARGS

Bulk-updates the given tasks. You can pass tasks in with one or more of the
following:

=over 4

=item tasks

An array reference of task hashes or locators, or a space-delimited string of
locators.

=item ids

An array reference or space-delimited string of task IDs.

=back

=head2 complete_tasks TASKS

Marks the list of tasks or locators as complete.

=head2 braindump TEXT[, ARGS]

Braindumps C<TEXT>.

Optional arguments:

=over 4

=item tokens => string | arrayref

tokens may be used to provide default attributes to all the braindumped tasks
(this is part of what the filter feature of Hiveminder's IM bot does).

=item returns => 'ids' | 'tasks'

Return the affected task IDs, or the tasks themselves, instead of a summary of
the changes made.

=back

=head2 upload_text TEXT

Uploads C<TEXT> to BTDT::Action::UploadTasks.

=head2 upload_file FILENAME

Uploads C<FILENAME> to BTDT::Action::UploadTasks.

=head2 download_text

Downloads your tasks. This also gets the metadata so that you can edit the text
and upload it, and it'll make the same changes to your task list.

This does not currently accept query arguments, because Hiveminder expects a
"/not/owner/me/group/personal" type argument string, when all we can produce is
"owner_not => 'me', group => 'personal'"

=head2 download_file FILENAME

Downloads your tasks and puts them into C<FILENAME>.

This does not currently accept query arguments, because Hiveminder expects a
"/not/owner/me/group/personal" type argument string, when all we can produce is
"owner_not => 'me', group => 'personal'"

=head2 priority (NUMBER | TASK) -> Maybe String

Returns the "word" of a priority. One of: lowest, low, normal, high, highest.
If the priority is out of range, C<undef> will be returned.

=head2 done LOCATORS

Marks the given tasks as complete.

=head2 loc2id (LOCATOR|TASK)s -> IDs

Transforms the given record locators (or tasks) to regular IDs.

=head2 id2loc IDs -> LOCATORs

Transform the given IDs into record locators.

=head2 tasks2ids

Deprecated

=head2 comments_on TASK -> (String)s

Returns a list of the comments on the given task.

=head2 comment_on TASK, MESSAGE

Add a comment to TASK.

This method requires L<Email::Simple::Creator>, which is an optional dependency
of Net::Hiveminder. If Creator is unavailable, then this will throw an error.

=head2 send_feedback TEXT

Sends the given TEXT as feedback to the Hiveminder team.

=head2 get_task_history LOCATOR

Load the transaction history for task LOCATOR.

Returns an array of transactions looking like:

$VAR1 = {
    'modified_at' => '2008-07-24 15:38:06',
    'type' => 'update',
    'id' => '1745040',
    'task_id' => '433397',
    'created_by' => '463'
};

=head1 SEE ALSO

L<App::Todo>, L<Jifty>, L<Net::Jifty>

=head1 AUTHOR

Shawn M Moore, C<< <sartak at bestpractical.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-hiveminder at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Hiveminder>.

=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

