#!perl
use strict;
use warnings;
use Test::More tests => 10;
use FindBin;
use File::Temp qw(tempfile);

use lib "$FindBin::Bin/../lib";
use_ok ('Speak', qw(speak last_message %PERSONA_MAP));

# 1. Non-existent file
{
  my $res = last_message ('/tmp/non_existent_speak_log_test.log');
  ok (!defined $res, 'last_message on non-existent file returns undef');
}

# 2. Parse sample log file
{
  my ($fh, $filename) = tempfile (UNLINK => 1);
  print $fh "2026-10-28 10:00:00: [speak] First message\n";
  print $fh "2026-10-28 10:05:00: [announceEmail Gmail] Incoming message Andrew\n";
  print $fh "2026-10-28 10:06:00: [Agent Smith] Muted notice [silent shh]\n";
  print $fh "\n\n";
  close $fh;

  # Scalar context returns message, skipping [silent shh]
  my $msg = last_message ($filename);
  is ($msg, 'Incoming message Andrew', 'last_message returns correct text skipping silent lines');

  # List context returns ($msg, $tag)
  my ($l_msg, $tag) = last_message ($filename);
  is ($l_msg, 'Incoming message Andrew', 'List context returns correct message');
  is ($tag, 'announceEmail Gmail', 'List context returns correct tag');
}

# 3. Log without brackets
{
  my ($fh, $filename) = tempfile (UNLINK => 1);
  print $fh "2026-10-28 09:00:00: Simple message without tag\n";
  close $fh;

  my ($msg, $tag) = last_message ($filename);
  is ($msg, 'Simple message without tag', 'Handles lines without brackets');
  ok (!defined $tag, 'Tag is undef when line has no brackets');
}

# 4. PERSONA_MAP display mapping
{
  is ($Speak::PERSONA_MAP{'Smith'}, 'Agent Smith', 'Maps Smith to Agent Smith');
  is ($Speak::PERSONA_MAP{'Picard'}, 'Captain Picard', 'Maps Picard to Captain Picard');
  is ($Speak::PERSONA_MAP{'Lennon'}, 'John Lennon', 'Maps Lennon to John Lennon');
}
