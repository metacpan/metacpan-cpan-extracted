#!perl -T
use strict;
use File::Spec;
use Test::More;
use lib "t";
use Utils;
use Parse::Syslog::Mail;

plan 'no_plan';

my $more_tests = 0;
my @logs = ();

if (@ARGV) {
    @logs = @ARGV 
}
else {
    @logs = my_glob(File::Spec->catfile(qw(t logs *.log)));

    push @logs, map { File::Spec->catfile(File::Spec->rootdir, @$_) } 
        [qw(var log syslog)], 
        [qw(var log maillog)], 
        [qw(var log mail.log)], 
        [qw(var log mail info)], 
    ;
}

if ($more_tests) {
    my $local_logs_dir = File::Spec->catdir('workshop', 'logs');
    if (-d $local_logs_dir) {
        push @logs, my_glob(File::Spec->catfile($local_logs_dir, '*'))
    }
}

for my $file (@logs) {
    my $maillog = undef;
    is( $maillog, undef                      , "Creating a new object" );
    eval { $maillog = new Parse::Syslog::Mail $file, year => 2005 };
    next if $@;
    diag(" -> reading $file") if $more_tests;
    ok( defined $maillog                     , " - object is defined" );
    is( ref $maillog, 'Parse::Syslog::Mail'  , " - object is of expected ref type" );
    ok( $maillog->isa('Parse::Syslog::Mail') , " - object is a Parse::Syslog::Mail object" );
    isa_ok( $maillog, 'Parse::Syslog::Mail'  , " - object" );

    while (my $log = $maillog->next) {
        next if $. > 2000;     # to prevent too long test times
        ok( defined $log,     " -- line $. => new \$log" );
        is( ref $log, 'HASH', " -- \$log is a hashref" );

        for my $field (keys %$log) {
            like( $field, '/^[\w-]+$/', " ---- is field '$field' a word?" )
        }

        like( $log->{host},      '/^[\w.-]+$/', " --- 'host' field must be present" );
        like( $log->{program},   '/^[\w/-]+$/', " --- 'program' field must be present" );
        like( $log->{timestamp}, '/^\d+$/',     " --- 'timestamp' field must be present" );
        like( $log->{text},      '/^.+$/',      " --- 'text' field must be present" );
        like( $log->{id},        '/^\w+$/',     " --- 'id' field must be present" );

        $log->{from} and like( $log->{from}, '/^(?:\w+|.*\@.*|<.*>)$/', " --- checking 'from'" );

        if ($log->{program} =~ /^(?:sendmail|postfix)/) {
            ok( exists($log->{from}) or exists($log->{to}), 
                " --- one of 'from' and 'to' should be defined (Sendmail, Postfix)" )
        }
    }
}

