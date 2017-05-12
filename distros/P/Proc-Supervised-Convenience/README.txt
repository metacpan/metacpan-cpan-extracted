NAME
    Proc::Supervised::Convenience - Supervise concurrent worker processes

SYNOPSIS
    driver script:

      #!/usr/bin/perl

      use Proc::Supervised::Convenience;

      Proc::Supervised::Convenience
        ->new_with_options( program => \&work )
        ->supervise;

      sub work {
        my @args = @_;
        # code to run forever
      }

    invocation:

      ./work -d -j 10 foo bar

FEATURES
    *   auto-restarts worker processes

    *   kill -HUP to restart all workers

    *   kill -INT to stop

    *   kill -USR1 to relaunch

Command-line options
    *   --detach | -d # detach from terminal

    *   --processes | -j N # run N copies of &work

    Any remaining command line arguments are passed on as is to your work
    subroutine.

SEE ALSO
    POE::Component::Supervisor.

COPYRIGHT & LICENSE
    Copyright 2011 Rhesa Rozendaal, all rights reserved.

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

