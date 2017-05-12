use v5.10;
use warnings;


my %ACTION = (

     start       => sub{ say "starting @_"; },
     stop        => sub{ say "stopping @_"; },
     restart     => sub{ say "restarting @_"; },
     connect     => sub{ say "connecting @_"; },
     disconnect  => sub{ say "disconnecting @_"; },
     reconnect   => sub{ say "reconnecting @_"; },
     login       => sub{ say "login to @_"; },
     logout      => sub{ say "logout from @_"; },
     logoutall   => sub{ say "logoutall on @_"; },
     ping        => sub{ say "pinging @_"; },
     stat        => sub{ say "stat'ing @_"; },
     status      => sub{ say "status of @_"; },

);

my %MACHINE = qw<

    leibnitz         ssh://vax011.example.com
    descartes        ssh://filesys.example.com
    newton           afp://macserver.example.org
    heidegger        ssh://nexus.example.com
    pascal           afp://macpro88.example.org:8088
    them             ssh://remote.example.com
    us               ssh://local.example.com

>;

my $machine_command = do{
    use Regexp::Grammars;
    qr{
        <Command>

        <rule: Command>
             <Action> <Machine_name>

        <rule: Action>
            <%ACTION>

        <rule: Machine_name>
            <%MACHINE>

    }xms
};


use IO::Prompter;

while (my $input = prompt) {

    if ($input =~ $machine_command) {
        my $handler = $ACTION{ $/{Command}{Action} };
        my $device  = $MACHINE{ $/{Command}{Machine_name} };

        $handler->($device);
    }
    else {
        say "Don't know how to $input";
    }
}
