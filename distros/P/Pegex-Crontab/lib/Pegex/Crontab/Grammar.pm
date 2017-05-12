package Pegex::Crontab::Grammar;
use Pegex::Base;
extends 'Pegex::Grammar';

use constant file => '../crontab-pgx/crontab.pgx';

sub make_tree {
  {
    '+toprule' => 'crontab',
    'EOL' => {
      '.rgx' => qr/\G\r?\n/
    },
    '__' => {
      '.rgx' => qr/\G\s+/
    },
    'blank_line' => {
      '.rgx' => qr/\G[\ \t]*\r?\n/
    },
    'command' => {
      '.rgx' => qr/\G(.*)/
    },
    'comment_line' => {
      '.rgx' => qr/\G[\ \t]*\#.*\r?\n/
    },
    'cron_line' => {
      '.all' => [
        {
          '.ref' => 'minute'
        },
        {
          '.ref' => '__'
        },
        {
          '.ref' => 'hour'
        },
        {
          '.ref' => '__'
        },
        {
          '.ref' => 'dom'
        },
        {
          '.ref' => '__'
        },
        {
          '.ref' => 'month'
        },
        {
          '.ref' => '__'
        },
        {
          '.ref' => 'dow'
        },
        {
          '.ref' => '__'
        },
        {
          '.ref' => 'command'
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'crontab' => {
      '+min' => 0,
      '.any' => [
        {
          '.ref' => 'comment_line'
        },
        {
          '.ref' => 'blank_line'
        },
        {
          '.ref' => 'env_line'
        },
        {
          '.ref' => 'cron_line'
        }
      ]
    },
    'dom' => {
      '.ref' => 'time'
    },
    'dow' => {
      '.ref' => 'time'
    },
    'env_line' => {
      '.all' => [
        {
          '.ref' => 'variable'
        },
        {
          '.rgx' => qr/\G=/
        },
        {
          '.ref' => 'value'
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'hour' => {
      '.ref' => 'time'
    },
    'minute' => {
      '.ref' => 'time'
    },
    'month' => {
      '.ref' => 'time'
    },
    'time' => {
      '.rgx' => qr/\G(\*|(?:(?:[0-9]{1,2})\-(?:[0-9]{1,2})(?:\/(?:[0-9]{1,2}))?|(?:[0-9]{1,2}))(?:,(?:(?:[0-9]{1,2})\-(?:[0-9]{1,2})(?:\/(?:[0-9]{1,2}))?|(?:[0-9]{1,2})))+,?|(?:[0-9]{1,2})\-(?:[0-9]{1,2})(?:\/(?:[0-9]{1,2}))?|(?:mon|tue|wed|thu|fri|sat|sun)|(?:[0-9]{1,2}))/
    },
    'value' => {
      '.rgx' => qr/\G(.*)/
    },
    'variable' => {
      '.rgx' => qr/\G(\w+)/
    }
  }
}

1;
