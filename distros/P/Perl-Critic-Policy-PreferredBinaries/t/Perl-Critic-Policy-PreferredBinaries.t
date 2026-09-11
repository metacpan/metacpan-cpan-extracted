#!/usr/bin/env perl

use 5.014;

use strict;
use warnings FATAL => 'all';

use re '/aa';

=head1 NAME

t/Perl-Critic-Policy-PreferredBinaries.t - which shell-outs it finds, which it
does not, and what it says about them

=head1 DESCRIPTION

The interesting half of a policy like this is the second list.  A policy that
reports too much gets switched off, and a policy switched off is worth less than
no policy at all -- so the cases it deliberately says nothing about are asserted
here as firmly as the ones it catches.

=cut

use Test::More;
use Test::NoWarnings;
use File::Temp qw{tempdir};

use FindBin::libs;

use Perl::Critic ();

my $CONFIG = <<'INI';
[ssh-keygen]
prefer = Provisioner::Utils::write_ssh_keypair
reason = "In-process, and no quoting to get wrong"

[ssh-keygen -y]
prefer = Provisioner::Utils::ssh_pubkey_from_private
reason = "Derives the public half with CryptX"

[wget]
reason = "Nothing here should be fetching anything with this"

[curl]
prefer = HTTP::Tiny

[dig]
prefer = Net::DNS
severity = 5
INI

my $DIR = tempdir( CLEANUP => 1 );
my $INI = "$DIR/preferred_binaries.ini";
open( my $fh, '>', $INI ) or die $!;
print {$fh} $CONFIG;
close($fh);

# One critic, configured with this policy alone and through a real profile:
# everything below asserts on what this policy says, and reaching into it to set
# the parsed configuration by hand would leave the configuration path itself
# untested.
sub critic_for {
    my ( $config, $runners ) = @_;

    my $profile = "[PreferredBinaries]\nconfig = $config\n";
    $profile .= "runners = $runners\n" if defined $runners;

    return Perl::Critic->new(
        '-profile'       => \$profile,
        '-single-policy' => 'PreferredBinaries',
        '-severity'      => 1,
        '-force'         => 1,
    );
}

sub violations {
    my ( $source, $config, $runners ) = @_;
    return [ critic_for( $config // $INI, $runners )->critique( \$source ) ];
}

sub found {
    my ($source) = @_;
    return [ map { $_->description } @{ violations($source) } ];
}

subtest 'the ways a command reaches a shell' => sub {
    foreach my $case (
        [ q{system( 'ssh-keygen', '-t', 'rsa' );},                        'system, as a list' ],
        [ q{system('ssh-keygen -t rsa');},                                'system, as one string' ],
        [ q{exec( 'ssh-keygen', '-t', 'rsa' );},                          'exec' ],
        [ q{my $out = `ssh-keygen -l -f x`;},                             'backticks' ],
        [ q{my $out = qx{ssh-keygen -l -f x};},                           'qx' ],
        [ q{open( my $fh, '-|', 'ssh-keygen', '-l' );},                   'a three-argument piped open' ],
        [ q{open( my $fh, 'ssh-keygen -l |' );},                          'and the two-argument form' ],
        [ q{IPC::Run3::run3( [ 'ssh-keygen', '-t', 'rsa' ], \undef );},   'run3, which takes an arrayref' ],
        [ q{my $o = IPC::System::Simple::capture( 'ssh-keygen', '-l' );}, 'IPC::System::Simple::capture' ],
    ) {
        my ( $source, $what ) = @$case;
        is( scalar @{ found($source) }, 1, $what );
    }

    # qw{} is how half the calls in the wild are written, and a policy that
    # missed it would miss them.
    is( scalar @{ found(q{system( qw{ssh-keygen -t rsa}, $path );}) }, 1, 'a qw list is words like any other' );

    # An absolute path is the same binary.
    is( scalar @{ found(q{system( '/usr/bin/ssh-keygen', '-t', 'rsa' );}) }, 1, 'and a path in front of it changes nothing' );
};

subtest 'what it deliberately says nothing about' => sub {
    foreach my $case (
        [ q{system( $command, '-t', 'rsa' );},    'a command in a variable, which cannot be read here' ],
        [ q{system( $ENV{SSH_KEYGEN}, '-t' );},   'nor one out of the environment' ],
        [ q{my $out = `$tool -l -f x`;},          'nor an interpolated one' ],
        [ q{system( 'ssh-add', '-l' );},          'a binary nothing was said about' ],
        [ q{open( my $fh, '<', 'ssh-keygen' );},  'a plain open of a file that happens to be named like one' ],
        [ q{my %h = ( system => 'ssh-keygen' );}, 'the word system as a hash key' ],
        [ q{$obj->system('ssh-keygen');},         'and as a method name' ],
    ) {
        my ( $source, $what ) = @$case;
        is( scalar @{ found($source) }, 0, $what );
    }
};

subtest 'runners are matched by name, methods included, and not as hash keys' => sub {

    # By name, because a runner is usually wrapped in a method of the same name
    # and a policy cannot see what a method does.  So the way to keep a method
    # that runs commands elsewhere off this list is its name.
    is( scalar @{ found(q{$machine->run( 'ssh-keygen', '-t', 'rsa' );}) },     1, 'a method called run is read as a runner' );
    is( scalar @{ found(q{$machine->run_cmd( 'ssh-keygen', '-t', 'rsa' );}) }, 0, 'and one named for what it does is not' );

    # Measured against 0.001: this was reported, a hash key read as a call.
    is( scalar @{ found(q{my %how = ( run => 'ssh-keygen' );}) }, 0, 'a runner name as a hash key is not a call' );

    # IPC::Cmd takes its command as a named argument.  0.001 said it read these
    # and did not.
    is( scalar @{ found(q{IPC::Cmd::run( command => 'ssh-keygen -t rsa' );}) },               1, 'IPC::Cmd, as a string' );
    is( scalar @{ found(q{IPC::Cmd::run( command => [ 'ssh-keygen', '-t', 'rsa' ] );}) },     1, 'as an arrayref' );
    is( scalar @{ found(q{IPC::Cmd::run( verbose => 0, command => 'ssh-keygen -t rsa' );}) }, 1, 'and wherever it falls among the other named arguments' );
    is( scalar @{ found(q{IPC::Cmd::run( command => $cmd );}) },                              0, 'but not a command in a variable, which it cannot read' );
};

subtest 'IPC::System::Simple, which never goes through a shell' => sub {
    is( scalar @{ found(q{systemx( 'ssh-keygen', '-t', 'rsa' );}) },                   1, 'systemx' );
    is( scalar @{ found(q{IPC::System::Simple::runx( 'ssh-keygen', '-t', 'rsa' );}) }, 1, 'runx' );
    is( scalar @{ found(q{my $o = capturex( [ 0, 1 ], 'ssh-keygen', '-l' );}) },       1, 'and capturex, past the exit values it allows' );
};

subtest 'more runners can be named, and are added to the defaults' => sub {
    my $wrapper = q{run_local( 'ssh-keygen', '-t', 'rsa' );};

    is( scalar @{ violations( $wrapper, $INI ) }, 0, 'a wrapper nobody named is not a runner' );
    is( scalar @{ violations( $wrapper, $INI, 'run_local' ) }, 1, 'and one named in runners is' );

    # The point of the list being additive: naming one's own runner must not
    # quietly stop the policy reading the ones everybody uses.
    is( scalar @{ violations( q{IPC::Run3::run3( [ 'ssh-keygen', '-t', 'rsa' ], \undef );}, $INI, 'run_local' ) }, 1, 'run3 is still read beside it' );

    my $qualified = 'My::Util::run_local';
    is( scalar @{ violations( q{My::Util::run_local( 'ssh-keygen', '-l' );}, $INI, $qualified ) }, 1, 'a runner named with its package is matched on its name' );
    is( scalar @{ violations( q{$self->run_local( 'ssh-keygen', '-l' );},    $INI, $qualified ) }, 1, 'as a method too' );
};

subtest 'Capture::Tiny captures perl, not a command' => sub {

    # What runs inside the block is caught by what it is, and caught once.
    is( scalar @{ found(q{my ( $o, $e ) = capture { system( 'ssh-keygen', '-t', 'rsa' ) };}) }, 1, 'system inside capture' );
    is( scalar @{ found(q{my $o = Capture::Tiny::capture_merged { `ssh-keygen -l` };}) },       1, 'backticks inside capture_merged' );
    is( scalar @{ found(q{my $o = capture { 1 };}) },                                           0, 'and a block that shells out to nothing is nothing' );
};

subtest 'the longest matching section wins' => sub {

    # Which is the whole point of allowing arguments in a section name: one
    # binary, two jobs, two answers.
    my $general = found(q{system( 'ssh-keygen', '-t', 'rsa', '-f', $path );});
    like( $general->[0], qr/write_ssh_keypair/, 'the bare binary gets the general answer' );

    my $specific = found(q{system( 'ssh-keygen', '-y', '-f', $path );});
    like( $specific->[0], qr/ssh_pubkey_from_private/, 'and the one with the flag gets its own' );

    # Only leading words, and only literally: whether `-q -y` means the same as
    # `-y` is a question about ssh-keygen rather than about perl.
    my $reordered = found(q{system( 'ssh-keygen', '-q', '-y', '-f', $path );});
    like( $reordered->[0], qr/write_ssh_keypair/, 'a flag that is not leading falls back to the general one' );
};

subtest 'a section with no prefer is a ban rather than a recommendation' => sub {

    # Which is what Perl::Critic::Policy::PreferredModules does with one, and
    # worth pinning because consecutive sections look like they share the entry
    # below them: measured against that policy, `[JSON]` above a `[JSON::XS]`
    # carrying `prefer` reports "Using module JSON is not recommended" for the
    # first and the full recommendation only for the second.  Config::INI
    # carries nothing forward.
    like( found(q{system( 'curl', '-s', $url );})->[0], qr/\QPrefer HTTP::Tiny\E/,                         'a section with prefer recommends' );
    like( found(q{system( 'wget', '-q', $url );})->[0], qr/\QShelling out to 'wget' is not recommended\E/, 'and one without it bans' );
};

subtest 'what it says, and how loudly' => sub {
    my ($violation) = @{ violations(q{system( 'ssh-keygen', '-t', 'rsa' );}) };

    like( $violation->description, qr/\QPrefer Provisioner::Utils::write_ssh_keypair to shelling out to 'ssh-keygen'\E/, 'names both halves' );

    # The reason is what turns a rule into advice.  Quotes come off, because
    # Config::INI keeps them and nobody wants them in the output.
    is( $violation->explanation, 'In-process, and no quoting to get wrong', 'and gives the reason, unquoted' );

    my ($loud) = @{ violations(q{my $ip = `dig +short $name`;}) };
    is( $loud->severity, 5, 'an entry can be louder than the policy' );
};

subtest 'no configuration is no opinion' => sub {

    # Not an error: this policy sits in a default profile, and most
    # distributions have nothing to say about binaries.  Refusing to run would
    # make every one of those a configuration problem to suppress.
    my $missing = violations( q{system( 'ssh-keygen', '-t', 'rsa' );}, "$DIR/there-is-no-such-file" );
    is( scalar @$missing, 0, 'a config that is not there reports nothing rather than failing' );
};

subtest 'a binary nothing was said about is still nothing to say' => sub {
    my $file = "$DIR/partial.ini";
    open( my $out, '>', $file ) or die $!;
    print {$out} "[curl]\nprefer = HTTP::Tiny\n";
    close($out);

    is( scalar @{ violations( q{system( 'wget', '-q', $url );}, $file ) }, 0, 'no section, no violation' );
};

Test::NoWarnings::had_no_warnings();

done_testing;
