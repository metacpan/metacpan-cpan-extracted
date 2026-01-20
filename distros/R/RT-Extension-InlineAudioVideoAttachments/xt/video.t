use strict;
use warnings;

use RT::Extension::InlineAudioVideoAttachments::Test tests => 18;

my $video_name   = 'ete_2016.mp4';
my $video_file   = RT::Test::get_relocatable_file($video_name, 'data');

my ($baseurl, $m) = RT::Test->started_ok;
ok $m->login, 'logged in';

my $queue = RT::Queue->new(RT->Nobody);
my $qid = $queue->Load('General');
ok( $qid, "Loaded General queue" );

# Create ticket
$m->form_name('CreateTicketInQueue');
$m->field('Queue', $qid);
$m->submit;
is($m->status, 200, "request successful");
$m->content_contains("Create a new ticket", 'Ticket create page');

$m->submit_form(
    form_name => "TicketCreate",
    fields    => {
        Subject => 'Video attachment test',
        Content => 'Content with video',
    },
    button => 'SubmitTicket',
);
is($m->status, 200, "Request successful");

$m->content_contains('Video attachment test', 'We have subject on the page');
$m->content_contains('Content with video', 'And content');

# Reply with uploaded attachments
$m->follow_link_ok({text => 'Reply'}, "Reply to the ticket");
$m->content_lacks('AttachExisting');
$m->submit_form(
    form_name => 'TicketUpdate',
    fields    => {
        Attach => $video_file,
        UpdateContent => 'Message',
    },
    button => 'SubmitTicket',
);
is($m->status, 200, "Request successful");

$m->content_contains('<span class="downloadfilename">' . $video_name . '</span>', 'Page has file name');
$m->content_like(qr{<video controls[^>]*><source src="Attachment/\d+/\d+/$video_name" type="video/mp4">Your browser does not support the video tag.</video>}, 'Video can be watched in HTML5 player');
