# vim: set filetype=perl :
use Test::More tests => 23;
# use Test::More qw/no_plan/;
use Log::Log4perl qw/:easy/;
Log::Log4perl->easy_init($FATAL);

BEGIN { use_ok('Nagios::Clientstatus'); }

# wrong call to new, there are some mandatory arguments
my $nc;

eval { $nc = Nagios::Clientstatus->new(); };
ok( $@, "Die on calling new without args" );

my %args;

# try out different arguments to new
%args = ( help_subref => "wrong", );
eval { $nc = Nagios::Clientstatus->new(%args); };
ok( $@, "Die on calling new with wrong help_subref" );

# anonymous help_subref is ok
%args = ( help_subref => sub { print "This is help"; }, );
eval { $nc = Nagios::Clientstatus->new(%args); };
ok( !$@, "Anonymous help_subref is ok" );

# Subref to a help-sub in my prg is ok
%args = ( help_subref => \&help, );
eval { $nc = Nagios::Clientstatus->new(%args); };
ok( !$@, "Ref to subroutine help is ok" );

# Try arg is always use from now on
my %ok_args = (
    help_subref => \&help,
    version     => "9.999",
);
%args = %ok_args;
eval { $nc = Nagios::Clientstatus->new(%args); };
ok( !$@, "ok_args ok" );

%args = ( %ok_args, mandatory_args => ["warning"], );
eval { $nc = Nagios::Clientstatus->new(%args); };
ok( $@ =~ m{^ fake \s exit}xms,
    "Mandatory prg-argument 'warning' not given, help && exit" );

ok( 1,
"I am alive after not getting mandatory 'warning', so overwriting exit worked"
);

# Now fake warning on commandline
# This is not enough:
foreach my $not_enough ( "warning", "-warning", "--warning", "--warning 60" ) {
    @ARGV = ($not_enough);
    eval { $nc = Nagios::Clientstatus->new(%args); };
    ok( $@ =~ m{^ fake \s exit}xms,
        "Mandatory prg-argument '$not_enough' is not enough" );
}

# but this should be ok
my $enough = "--warning=60";
@ARGV = ($enough);
eval { $nc = Nagios::Clientstatus->new(%args); };
ok( !$@, "Mandatory prg-argument '$enough' is enough" );

is( $nc->get_given_arg('warning'), "60", "get_given_arg" );

my $exit_try = "DOES_NOT_EXIST";
eval { $exit_value = $nc->exitvalue($exit_try); };
ok( $@, "get exit-value '$exit_try' from function exitvalue -> die" );

my %nagios_returnvalue = (
    'OK'       => 0,
    'WARNING'  => 1,
    'CRITICAL' => 2,
    'UNKNOWN'  => 3,
);
foreach my $cleartext ( sort keys %nagios_returnvalue ) {
    is(
        $nagios_returnvalue{$cleartext},
        $nc->exitvalue($cleartext),
        "exitvalue '$cleartext' as object-method"
    );

    is(
        $nagios_returnvalue{$cleartext},
        Nagios::Clientstatus::exitvalue($cleartext),
        "exitvalue '$cleartext' as class-method"
    );
}

sub help {
    print STDERR "This is fake help for testing\n";
}

sub Nagios::Clientstatus::_exit {
    print STDERR "This is fake exit for testing\n";
    die 'fake exit';
}
