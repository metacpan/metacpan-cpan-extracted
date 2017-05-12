# vim: set filetype=perl :
use Test::More tests => 7;
# use Test::More qw/no_plan/;
use Log::Log4perl qw/:easy/;
Log::Log4perl->easy_init($FATAL);

BEGIN { use_ok('Nagios::Clientstatus'); }

# check optional arguments
my $nc;
my %default_args;
my %args;
my $fake_commandline;

# try out different arguments to new
%args = (
    dont_check_commandline_args => 0, # check them
    help_subref => sub { 'this is help' },
    mandatory_args => [ 'url' ],
    optional_args => [ 'carsize' ],
);

# no arguments in commandline
@ARGV = ();
eval { $nc = Nagios::Clientstatus->new(%args); };
# There is no mandatory arg: url
ok( $@, "Mandatory arg 'url' not given" );

# only mandatory argument
@ARGV = ();
push @ARGV, '--url=http://idontcare';

eval { $nc = Nagios::Clientstatus->new(%args); };
ok( ! $@, "Mandatory arg 'url' given, but no optional 'carsize' -> don't die" );

# now the optional argument too
@ARGV = ();
push @ARGV, '--carsize=medium';
push @ARGV, '--url=http://idontcare';
is(scalar @ARGV, 2, 'Commandline has 2 arguments');

eval { $nc = Nagios::Clientstatus->new(%args); };
ok( ! $@, "Mandatory arg 'url' given and optional 'carsize' -> don't die" );

is($nc->get_given_arg('carsize'), 'medium', 
    "Optional arg 'carsize' is 'medium'");

is($nc->get_given_arg('not_ever_given'), undef,
    "Query not-known optional arg 'not_ever_given'");

# overwrite the exitmethod of Nagios::Clientstatus
# which usually does an "exit", but it shall die in
# the tests
sub Nagios::Clientstatus::_exit {
    print STDERR "This is fake exit for testing\n";
    die 'fake exit';
}

