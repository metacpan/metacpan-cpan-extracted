#!perl -w

use strict;

use Test2::V0;

use Path::List::Rule;

# with thanks to Module::Loader for the test module naming scheme!

my @paths = qw(
  Monkey/Plugin/Bonobo.pm
  Monkey/Plugin/Mandrill.pm
  Monkey/Plugin/Bonobo/Utilities.pm
  Monkey/See/Monkey/Do/
);


my @files = qw(
  Monkey/Plugin/Bonobo.pm
  Monkey/Plugin/Mandrill.pm
  Monkey/Plugin/Bonobo/Utilities.pm
);

my @dirs = qw(
  Monkey
  Monkey/See
  Monkey/See/Monkey
  Monkey/See/Monkey/Do
  Monkey/Plugin
  Monkey/Plugin/Bonobo
);

my $rule = Path::List::Rule->new( \@paths );
is(
    [ map "$_", $rule->all( 'Monkey' ) ],
    bag {
        item $_ for @files, @dirs;
        end;
    },
    'all',
);

is(
    [ map "$_", $rule->clone->dir->all( 'Monkey' ) ],
    bag {
        item $_ for @dirs;
        end;
    },
    'dirs',
);

is(
    [ map "$_", $rule->clone->file->all( 'Monkey' ) ],
    bag {
        item $_ for @files;
        end;
    },
    'files',
);

is(
    [ map "$_", $rule->clone->perl_module->all( 'Monkey' ) ],
    bag {
        item $_ for @files;
        end;
    },
    'perl modules',
);

# check if trailing / works
is(
    [ map "$_", $rule->clone->perl_module->all( 'Monkey/' ) ],
    bag {
        item $_ for @files;
        end;
    },
    'trailing slash',
);

done_testing;
