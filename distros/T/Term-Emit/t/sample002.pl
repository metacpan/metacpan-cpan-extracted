#!perl -w
use strict;
use warnings;
use Term::Emit qw/:all/, {-step => 3};

emit "Updating Configuration";

  emit "System parameter updates";
    emit "CLOCK_UTC";
    emit_ok;
    emit "NTP Servers";
    emit_ok;
    emit "DNS Servers";
    emit_warn;
  emit_done;

  emit "Application parameter settings";
    emit "Administrative email contacts";
    emit_error;
    emit "Hop server settings";
    emit_ok;
  emit_done;

  emit "Web server primary page";
  emit_ok;

  emit "Updating crontab jobs";
  emit_ok;

  emit "Restarting web server";
  emit_done;

exit 0;
