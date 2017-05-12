
package slurp_fetchmail;

use strict;
use warnings;
use Carp;
use File::Slurp qw(slurp);
use Net::IMAP::Simple;
use File::Basename;

sub login {
    my $class = shift;
    my $fetchmailrc = slurp("$ENV{HOME}/.fetchmailrc");
    my ($server)    = $fetchmailrc =~ m/server\s+(.+)/m;
    my ($user)      = $fetchmailrc =~ m/user\s+(.+)/m;
    my ($pass)      = $fetchmailrc =~ m/pass\s+(.+)/m;

    croak "server, user and pass must be in the $ENV{HOME}/.fetchmailrc for this to work"
        unless $server and $user and $pass;

    if( exists $ENV{DEBUG} ) {
        if( $ENV{DEBUG} eq "1" ) {
            $ENV{DEBUG} = basename($0);
            $ENV{DEBUG} .= ".log";
        }
    }

    my $imap = Net::IMAP::Simple->new($server,
        ($ENV{DEBUG} ? (debug=>do { open my $x, ">>", $ENV{DEBUG} or die $!; $x}) : ()),
        @_) or croak "connect failed: $Net::IMAP::Simple::errstr";

    $imap->login($user=>$pass) or croak "login failed: " . $imap->errstr;

    return $imap;
}

"True";
