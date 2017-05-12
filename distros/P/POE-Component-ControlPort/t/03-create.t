
use Test::More tests => 18;

sub LOCALHOST () { 127.0.0.1 }
sub HIGH_PORT () { 30337 }
sub HOSTNAME () { 'PIE' }
sub APPNAME () { 'APPLE' }

BEGIN {
    use_ok('POE::Component::ControlPort');
}

BEGIN {
    use POE;
    no warnings;
    sub POE::Session::create {
        eval {
            my $class = shift;
            my %args = @_;

            ok(defined $args{heap},'POE::Session create heap check');
            is($args{heap}{address}, LOCALHOST, 'heap "address" check');
            is($args{heap}{port}, HIGH_PORT, 'heap "port" check');
            is($args{heap}{hostname}, HOSTNAME, 'heap "hostname" check');
            is($args{heap}{appname}, APPNAME, 'heap "appname" check');
            
        };
        is($@,'',"POE::Session create call");
    }
}

use warnings;
use strict;

ok(POE::Component::ControlPort->can('create'),
    "'create' existence check");

eval {
    POE::Component::ControlPort->create();
};

ok(length $@, "create() with no parameters exception check");
like($@, qr/Mandatory parameters.*missing/, 'create() with no parameters exception content check');

my $s;
eval {
    $s = POE::Component::ControlPort->create(
            local_address => LOCALHOST,
            local_port => HIGH_PORT,
            hostname => HOSTNAME,
            appname => APPNAME,
        );
};
is($@,'', "create() exception check");
ok(defined $POE::Component::ControlPort::Command::TOPICS{general},
    '"general" topic existence check');

foreach my $cmd (@POE::Component::ControlPort::DefaultCommands::COMMANDS) {
    ok(defined $POE::Component::ControlPort::Command::REGISTERED_COMMANDS{ $cmd->{name} },
        "'$cmd->{name}' command existence check");

    
    is_deeply($POE::Component::ControlPort::Command::REGISTERED_COMMANDS{ $cmd->{name} },
            $cmd, "'$cmd->{name}' contents check");

    ok(grep(@{$POE::Component::ControlPort::Command::TOPICS{general}}, $cmd->{name}),
        "'$cmd->{name}' inclusion in 'general' topic check");

}

