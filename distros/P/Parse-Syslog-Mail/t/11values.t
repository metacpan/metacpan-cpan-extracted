#!perl -T
use strict;
use File::Spec;
use Test::More;
use lib "t";
use Utils;
use Parse::Syslog::Mail;

plan 'no_plan';
my @logs = my_glob(File::Spec->catfile(qw(t logs *.log)));

my %mail = (
    j061bW9V000809 => {
        from => 'maddingue',  to => 'cpan-testers@perl.org',  
        msgid => '<200501060137.j061bW9V000809@jupiter.maddingue.net>', 
        size => 2039,  mailer => 'relay'
    }, 

    j061bXn5000812 => {
        from => '<maddingue@jupiter.maddingue.net>',  to => '<cpan-testers@perl.org>',  
        msgid => '<200501060137.j061bW9V000809@jupiter.maddingue.net>', 
        size => 2262,  mailer => 'esmtp'
    }, 

    j78ASk4e013165 => {
        status => 'done'
    }, 

    j2OFquVD026245 => {
        ruleset => 'check_rcpt',  arg1 => '<fwipada@dakkitydak.fap>', 
        relay => 'mx2.laboris.fr [123.456.789.1]', 
        to => '<fwipada@dakkitydak.fap>', 
        reject => '553 5.1.8 <fwipada@dakkitydak.fap>... Domain of sender address antoine@infirmiers.co does not exist', 
        status => 'reject: 553 5.1.8 <fwipada@dakkitydak.fap>... Domain of sender address antoine@infirmiers.co does not exist'
    }, 
);

for my $file (@logs) {
    my $maillog = undef;
    is( $maillog, undef                      , "Creating a new object" );
    $maillog = new Parse::Syslog::Mail $file, year => 2005;
    ok( defined $maillog                     , " - object is defined" );
    is( ref $maillog, 'Parse::Syslog::Mail'  , " - object is of expected ref type" );
    ok( $maillog->isa('Parse::Syslog::Mail') , " - object is a Parse::Syslog::Mail object" );
    isa_ok( $maillog, 'Parse::Syslog::Mail'  , " - object" );

    while(my $log = $maillog->next) {
        my $id = $log->{id};
        if(exists $mail{$id}) {
            ok( exists $mail{$id} , "id $id" );
            map { exists $mail{$id}{$_} and is( $log->{$_}, $mail{$id}{$_}, "  field '$_'" ) } keys %$log;
        }
    }

}
