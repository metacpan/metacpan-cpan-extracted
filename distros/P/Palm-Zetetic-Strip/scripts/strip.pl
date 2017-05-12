#!/usr/bin/perl -w

use strict;
use Palm::Zetetic::Strip;


my $dir;
my $strip;
my $password;
my @accounts;
my $account;
my @systems;
my $system;
my $version;

$dir = $ARGV[0];

system "stty -echo";
print STDERR "Strip password: ";
chomp($password = <STDIN>);
print STDERR "\n";
system "stty echo";

$strip = new Palm::Zetetic::Strip();
$strip->set_directory($dir);
$version = $strip->get_strip_version();

if ($version->is_0_5i())
{
    print "Strip version 0.5i database\n";
}
elsif ($version->is_1_0())
{
    print "Strip version 1.0 database\n";
}
else
{
    print "Unknown Strip database\n";
}

if (! $strip->set_password($password))
{
    print "Password does not match\n";
    exit(1);
}
$strip->load();

@systems = $strip->get_systems();
foreach $system (@systems)
{
    print "Category: ", $system->get_name(), "\n";
    printf("%-20s %-20s %-20s %-15s\n", "System", "Username", "Password",
           "Comment");
    print '='x20, " ", '='x20, " ", '='x20, " ", '='x15, "\n";

    @accounts = $strip->get_accounts($system);
    foreach $account (@accounts)
    {
        printf("%-20s %-20s %-20s %-15s\n", $account->get_system(),
               $account->get_username(),
               '"'. $account->get_password() .'"',
              $account->get_comment());
    }
    print "\n";
}

