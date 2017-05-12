#!perl -T
use strict;
use Test::More;
BEGIN { plan tests => 18 }
use File::Spec;
use Parse::Syslog::Mail;

my $file = File::Spec->catfile(qw(t logs sendmail-plain.log));

# check that the following functions are available
ok( defined &Parse::Syslog::Mail::new,     "new() exists" );
ok( defined &Parse::Syslog::Mail::next,    "next() exists" );


# create an object with new() as a class method
my $parser = undef;
is( $parser, undef,                        "Creating an object with CLASS->new()" );
eval { $parser = new Parse::Syslog::Mail $file };
is( $@, '',                                " - no error" );
ok( defined $parser,                       " - is defined" );
ok( $parser->isa('Parse::Syslog::Mail'),   " - is a Parse::Syslog::Mail object" );
is( ref $parser, 'Parse::Syslog::Mail',    " - is a Parse::Syslog::Mail ref" );
isa_ok( $parser, 'Parse::Syslog::Mail',    " -" );

# check that the following object methods are available
is( ref $parser->can('new'),     'CODE',   " - can new()" );
is( ref $parser->can('next'),    'CODE',   " - can next()" );


# create an object with new() as an object method
my $parser2 = undef;
is( $parser2, undef,                       "Creating an object with \$parser->new()" );
eval { $parser2 = $parser->new($file) };
is( $@, '',                                " - no error" );
ok( defined $parser2,                      " - is defined" );
ok( $parser2->isa('Parse::Syslog::Mail'),  " - is a Parse::Syslog::Mail object" );
is( ref $parser2, 'Parse::Syslog::Mail',   " - is a Parse::Syslog::Mail ref" );
isa_ok( $parser2, 'Parse::Syslog::Mail',   " -" );

# check that the following object methods are available
is( ref $parser2->can('new'),     'CODE',   " - can new()" );
is( ref $parser2->can('next'),    'CODE',   " - can next()" );

