use strict;
use warnings;
use Test::More tests => 2;
use Postfix::Parse::Mailq;

my $mailq = <<'END_MAILQ';
-Queue ID- --Size-- ----Arrival Time---- -Sender/Recipient-------
061A5B062E*    1300 Fri Oct 17 12:39:22  xavier@example.es
                                         example@example.com
                                         example@example.org
                                         example@example.net

0A238B065E* 8087383 Fri Oct 17 12:29:22  example@example.com
                                         xavier@example.es

10B11AF9A1!  221654 Fri Oct 17 12:38:55  devnull@example.me
                                         senor+bonbon@example.su

20B11AF9A1   221654 Fri Oct 17 12:38:55  devnull@example.me
                                         senor+bonbon@example.su

2CD706394A     2912 Wed Jul 15 20:29:29  shredder@example.party
                (connect to mx.example.ninja[1.2.3.4]:25: Connection timed out)
                                         jago@example.ninja

-- 8534903 Kbytes in 5 Requests.
END_MAILQ

my $entries = Postfix::Parse::Mailq->read_string($mailq);
my $want = [
 {
   'date' => 'Fri Oct 17 12:39:22',
   'error_string' => undef,
   'queue_id' => '061A5B062E',
   'spool' => undef,
   'remaining_rcpts' => [
     'example@example.com',
     'example@example.org',
     'example@example.net'
   ],
   'sender' => 'xavier@example.es',
   'size' => '1300',
   'status' => 'active'
 },
 {
   'date' => 'Fri Oct 17 12:29:22',
   'error_string' => undef,
   'queue_id' => '0A238B065E',
   'spool' => undef,
   'remaining_rcpts' => [
     'xavier@example.es'
   ],
   'sender' => 'example@example.com',
   'size' => '8087383',
   'status' => 'active'
 },
 {
   'date' => 'Fri Oct 17 12:38:55',
   'error_string' => undef,
   'queue_id' => '10B11AF9A1',
   'spool' => undef,
   'remaining_rcpts' => [
     'senor+bonbon@example.su'
   ],
   'sender' => 'devnull@example.me',
   'size' => '221654',
   'status' => 'held'
 },
 {
   'date' => 'Fri Oct 17 12:38:55',
   'error_string' => undef,
   'queue_id' => '20B11AF9A1',
   'spool' => undef,
   'remaining_rcpts' => [
     'senor+bonbon@example.su',
   ],
   'sender' => 'devnull@example.me',
   'size' => '221654',
   'status' => 'queued'
 },
 {
   'date' => 'Wed Jul 15 20:29:29',
   'error_string' => '(connect to mx.example.ninja[1.2.3.4]:25: Connection timed out)',
   'queue_id' => '2CD706394A',
   'spool' => undef,
   'remaining_rcpts' => [
     'jago@example.ninja',
   ],
   'sender' => 'shredder@example.party',
   'size' => '2912',
   'status' => 'queued'
 },
];

is_deeply($entries, $want, 'we parsed correctly');

{
  my $entries = Postfix::Parse::Mailq->read_string(
    $mailq,
    {
      spool => { '20B11AF9A1' => 'incoming' },
    },
  );

  $want->[-2]->{spool} = 'incoming';

  is_deeply($entries, $want, 'also works with some spool contents');
}

