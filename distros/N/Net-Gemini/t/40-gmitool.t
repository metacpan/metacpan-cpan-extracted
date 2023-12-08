#!perl
# bin/gmitool tests
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Command;

use lib './t/lib';
use GemServ;

my @command = ( $^X, qw{-- ./bin/gmitool} );

# KLUGE is there a better way to apply coverage to gmitool? because the
# coverage report is all red for code that is being reached
# (setting $ENV{PERL5OPT}='-MDevel::Cover' gives the same result)
#if ( $ENV{AUTHOR_TEST_JMATES} ) {
#    splice @command, 1, 0, '-MDevel::Cover=-silent,1';
#}

$ENV{GMITOOL_HOSTS} = 't/known_hosts';

# POLLUTE the initial tests must not pollute the known hosts file
unlink $ENV{GMITOOL_HOSTS};
-e $ENV{GMITOOL_HOSTS} and bail_out("known hosts not removed??");

my $The_Host =
  exists $ENV{GEMINI_HOST} ? $ENV{GEMINI_HOST} : '127.0.0.1';
my $The_Sni =
  exists $ENV{GEMINI_SNI} ? $ENV{GEMINI_SNI} : 'localhost';
my $The_Cert =
  exists $ENV{GEMINI_CERT} ? $ENV{GEMINI_CERT} : 't/host.cert';
my $The_Key =
  exists $ENV{GEMINI_KEY} ? $ENV{GEMINI_KEY} : 't/host.key';
my $wsargs =
  { host => $The_Host, cert => $The_Cert, key => $The_Key };

@Test2::Tools::Command::command = @command;

command {
    stderr       => qr/gmitool: command/,
    munge_status => 1,
    status       => 1
};

command {
    args         => ['there-is-no-such-command'],
    stderr       => qr/gmitool: no such command/,
    munge_status => 1,
    status       => 1
};

########################################################################
#
# GET

@Test2::Tools::Command::command = ( @command, 'get' );

{
    my ( $pid, $port ) = GemServ::with_server(
        $wsargs,
        sub {
            my ( $socket, $length, $from_client ) = @_;
            if ( $from_client =~ m/yada-yada-yada/ ) {
                $socket->print("20 \r\n\x{2026}");
            } elsif ( $from_client =~ m/ISO-8859-1a/ ) {
                $socket->print("20 text/plain;charset=ISO-8859-1\r\n\x{a9}");
            } elsif ( $from_client =~ m/ISO-8859-1b/ ) {
                $socket->print("20 Text/Plain;CharSet=ISO-8859-1\r\n\x{a9}");
            } elsif ( $from_client =~ m/links/ ) {
                $socket->print(
                    "20 text/gemini\r\nfoo\n=> gemini://$The_Sni/1\nbar\n=>gemini://$The_Sni/2\n"
                );
            } elsif ( $from_client =~ m/redirect-yyy-([0-9]{1,5})/ ) {
                $socket->print("30 gemini://$The_Sni:$1/yada-yada-yada\r\n");
            } elsif ( $from_client =~ m/redirect-y3/ ) {
                $socket->print("30 /yada-yada-yada\r\n");
            }
            $socket->flush;
        },
    );

    my $base = "gemini://$The_Sni:$port";
    # KLUGE how to poke at the server with clients manually
    #diag "BASE $base";
    #sleep 333;

    command {
        stderr       => qr/Usage: gmitool/,
        munge_status => 1,
        status       => 1
    };

    command {
        args   => ['--there-is-no-such-option'],
        stderr => qr/Unknown option/,
        status => 64
    };

    command {
        args         => [''],
        stderr       => qr/Usage: gmitool get/,
        munge_status => 1,
        status       => 1
    };

    command {
        args         => ['-q'],
        stderr       => qr/Usage: gmitool get/,
        munge_status => 1,
        status       => 1
    };

    command {
        args =>
          [ '-A', '-C', $The_Cert, '-K', $The_Key, "$base/yada-yada-yada" ],
        binmode => ':encoding(UTF-8)',
        env     => { SSL_CERT_FILE => $The_Cert },
        stdout  => qr/^\x{2026}$/,
    };

    command {
        args    => [ '-V', 'none', "$base/redirect-yyy-$port" ],
        binmode => ':encoding(UTF-8)',
        stdout  => qr/^\x{2026}$/,
    };

    command {
        args    => [ '-S', '-V', 'peer', "$base/redirect-y3" ],
        binmode => ':encoding(UTF-8)',
        env     => { SSL_CERT_FILE => $The_Cert },
        stdout  => qr/^\x{2026}$/,
        stderr  => qr/REDIRECT/,
    };

    # POLLUTE tests beyond here will use the known hosts file
    ok( !-e $ENV{GMITOOL_HOSTS} );

    command {
        args    => [ '-E', ':encoding(ISO-8859-1)', "$base/ISO-8859-1a" ],
        binmode => ':encoding(ISO-8859-1)',
        stdout  => qr/^\x{a9}$/,
    };

    command {
        args    => [ '-H', $The_Sni, '-t', '17', "$base/ISO-8859-1b" ],
        binmode => ':encoding(UTF-8)',
        stdout  => qr/^\x{a9}$/,
    };

    command {
        args   => [ '-l', "$base/links" ],
        stdout => qr{gemini://$The_Sni/1\ngemini://$The_Sni/2},
    };

    ok( -s $ENV{GMITOOL_HOSTS} > 0 );

    # corrupt the known hosts to force a digest mismatch
    open my $fh, '+<', $ENV{GMITOOL_HOSTS}
      or bail_out("could not open '$ENV{GMITOOL_HOSTS}': $!");
    my $buf = do { local $/; readline $fh };
    $buf =~ s/("digest":")./${1}!/;
    seek $fh, 0, 0;
    print $fh $buf;
    close $fh;

    command {
        args   => ["$base/yada-yada-yada"],
        stderr => qr/digest mismatch/,
        status => 1,
    };

    command {
        args    => [ '-f', '-q', "$base/yada-yada-yada" ],
        binmode => ':encoding(UTF-8)',
        stdout  => qr/^\x{2026}$/,
    };

    # special case: gemini:// as first argument is a 'get'
    @Test2::Tools::Command::command = @command;

    command {
        args    => ["$base/yada-yada-yada"],
        binmode => ':encoding(UTF-8)',
        stdout  => qr/^\x{2026}$/,
    };

    kill SIGTERM => $pid;
}

########################################################################
#
# LINK

@Test2::Tools::Command::command = ( @command, 'link' );

command {
    args   => ['--there-is-no-such-option'],
    stderr => qr/Unknown option/,
    status => 64
};

command {
    stdin  => "=> gemini://example.org\n",
    stdout => "gemini://example.org/\n",
};
command {
    stdin  => "=> https://example.org\n",
    stdout => "https://example.org/\n",
};
command {
    args   => [ '-b', 'file:///' ],
    stdin  => "=>https://example.org\n=>foo\n",
    stdout => "https://example.org/\nfile:///foo\n",
};
command {
    args   => ['-r'],
    stdin  => "=>https://example.org\n=>foo\n",
    stdout => "foo\n",
};

# hosts file must be present but empty for commit or make dist
open my $fh, '>', $ENV{GMITOOL_HOSTS}
  or bail_out("could not empty $ENV{GMITOOL_HOSTS}??");

done_testing;
