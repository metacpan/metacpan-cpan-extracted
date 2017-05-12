#!perl -w
use strict;
use Net::Shared;

# demonstrates shared variables across forked child and parent

my $listen = new Net::Shared::Handler;
my $new_shared = new Net::Shared::Local (name=>"new_shared", port=>3252);
$listen->add(\$new_shared);

$SIG{CHLD} = 'IGNORE';

$listen->store($new_shared, "");

die "Can't fork: $!" unless defined (my $child = fork());
if ($child == 0)
{
    # this is the child
    my $var = "assigned at the child";
    $listen->store($new_shared, $var);
    exit 0;
}
else
{
    # this is the parent
    while ()
    {
        my $var = $listen->retrieve($new_shared);
        next unless $var;
        print "Parent says that \$var was \"", $var,"\".\n" if $var;
        last;
    }
}

$listen->destroy_all;