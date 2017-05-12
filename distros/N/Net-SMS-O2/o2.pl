#!/usr/bin/perl

#------------------------------------------------------------------------------
#
# Standard pragmas
#
#------------------------------------------------------------------------------

use strict;

use Getopt::Long;
use App::Config;
use Net::SMS::O2;

my @options = qw(
    username=s
    password=s
    recipient=s
    subject=s
    verbose
    quota
    audit_trail=s
    message=s
    file=s
);

my $cfg_file = "$ENV{HOME}/.o2cfg";
my %args;
if ( -e $cfg_file )
{
    my $ac = App::Config->new;
    for ( qw( password username subject recipient ) )
    {
        $ac->define( $_ );
    }
    $ac->cfg_file( $cfg_file );
    %args = map { $_ => $ac->get( $_ ) } qw( password username subject recipient );
}
die <<USAGE unless GetOptions( \%args, @options );
$0 
    -username <username> 
    -password <password>
    -recipient <mobile no.>
    [ -subject <subject> ]
    [ -audit_trail <audit trail dir> ]
    [ -verbose ]
    [ -quota ]
    [ -message message ]
    [ -file message_file ]

USAGE

if ( $args{file} )
{
    open( FH, $args{file} ) or die "Can't open message file $args{file}\n";
    $args{message} = join( '', <FH> );
    close( FH );
}

my $sms = Net::SMS::O2->new( %args );

if ( $args{quota} )
{
    for my $type ( qw( free paid ) )
    {
        print $sms->quota( $type ), " $type txts remaining\n";
    }
}
if ( $args{message} )
{
    $sms->send_sms();
}
