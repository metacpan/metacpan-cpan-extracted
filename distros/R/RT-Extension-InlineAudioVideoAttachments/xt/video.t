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

$m->form_name('TicketCreate');
$m->field('Subject', 'Video attachment test');
$m->field('Content', 'Content with video');
$m->submit;
is($m->status, 200, "Request successful");

$m->content_contains('Video attachment test', 'We have subject on the page');
$m->content_contains('Content with video', 'And content');

# Reply with uploaded attachments
$m->follow_link_ok({text => 'Reply'}, "Reply to the ticket");
$m->content_lacks('AttachExisting');
$m->form_name('TicketUpdate');
$m->field('Attach', $video_file);
$m->field('UpdateContent', 'Message');
$m->click('SubmitTicket');
is($m->status, 200, "Request successful");

$m->content_contains("Download $video_name", 'Page has file name');
$m->content_like(qr{<video controls><source src="Attachment/\d+/\d+/$video_name" type="video/mp4">Your browser does not support the video tag.</video>}, 'Video can be watched in HTML5 player');
