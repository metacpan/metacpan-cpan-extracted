#!/usr/bin/perl 
use strict;
use warnings;
use utf8;
use Encode qw/:all/;
use Encode::Locale;
use Getopt::Long qw(:config no_ignore_case);
#use Smart::Comments;

$| = 1;

#binmode( STDIN,  ":encoding(console_out)" );
#binmode( STDOUT, ":encoding(console_out)" );
#binmode( STDERR, ":encoding(console_out)" );

my %opt;
GetOptions(
    \%opt,
    'mail_attach|f=s',

    # remote ansible host
    #'remote|R=s',  

    # mail
    'mail_msg|m=s', 
    'mail_server|M=s', 
    'mail_port|p=s', 
    'mail_usr|U=s', 
    'mail_pwd|P=s', 
    'mail_from|F=s', 'mail_to|T=s', 
);

send_novel(%opt);

sub send_novel {
my ( %o ) = @_;

print "send_novel : $o{mail_msg}, $o{mail_attach}, $o{mail_to}\n";
my $cmd=qq[calibre-smtp -a "$o{mail_attach}" -s "$o{mail_msg}" --relay $o{mail_server} --port $o{mail_port} -u "$o{mail_usr}" -p "$o{mail_pwd}" "$o{mail_from}" "$o{mail_to}" "$o{mail_msg}"];

system($cmd);

}
