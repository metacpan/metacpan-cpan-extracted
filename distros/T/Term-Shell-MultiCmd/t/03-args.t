#!perl

use Test::More;


# plan ( skip_all => "Can't create Term::ReadLine: $@\n")
#   unless eval { use Term::ReadLine ; Term::ReadLine->new() } ;

BEGIN { plan tests => 6}

use Term::Shell::MultiCmd ;
sub check_arg(@) {( Term::Shell::MultiCmd
                    -> new ( @_ )
                    -> populate ('return true' => { exec => sub { 1 }} )
                    -> cmd      ('return true' )
                    ,
                    "Check new arg:: @_")}

ok( check_arg prompt => 'My Prompt');
ok( check_arg prompt => sub { 'my Prompt' });
ok( check_arg help_cmd => 'foo', quit_cmd => 'bar', root_cmd => 'LiKolGal' );
ok( check_arg history_file => '/tmp/mcmd.tst', history_size => 200);
ok( check_arg record_cmd => sub { my $cmd = shift; print "user cmd: $cmd\n"});
ok( check_arg empty_cmd  => sub { print "you had only hit return" });
