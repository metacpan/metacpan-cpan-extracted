use strict;
use warnings;
use Test::More;
use System::Command;
use File::Spec;

BEGIN {
    eval 'use Scalar::Util qw( refaddr ); 1;'
        or plan skip_all =>
        "Scalar::Util $Scalar::Util::VERSION does not provide refaddr";
}

plan tests => my $tests;

my @cmd = ( $^X, File::Spec->catfile( t => 'lines.pl' ) );

# record destruction
my @destroyed;
{
    no strict 'refs';
    for my $suffix ( '', '::Reaper' ) {
        my $class   = "System::Command$suffix";
        my $destroy = *{"$class\::DESTROY"}{CODE};
        *{"$class\::DESTROY"} = sub {
            diag "DESTROY $_[0]";
            push @destroyed, refaddr $_[0];
            $destroy->(@_) if $destroy;
        };
    }
}

# test various scope situations and object destruction time
my ( $cmd_addr, $reap_addr );

# test 1
BEGIN { $tests += 6 }
{
    my $cmd = System::Command->new(@cmd);
    $cmd_addr  = refaddr $cmd;
    $reap_addr = refaddr $cmd->{reaper};
    my ( $out, $err ) = ( $cmd->stdout, $cmd->stderr );
    ok( eof $out, 'No output' );
    ok( eof $err, 'No errput' );
    is( scalar @destroyed, 0, "Destroyed no object yet" );
}
is( scalar @destroyed, 2,          "Destroyed 2 objects" );
is( shift @destroyed,  $cmd_addr,  "... command object was destroyed" );
is( shift @destroyed,  $reap_addr, "... reaper object was destroyed" );
@destroyed = ();

# test 2
BEGIN { $tests += 6 }
{
    my $cmd = System::Command->new( @cmd, 1, 1, 1 );
    $cmd_addr  = refaddr $cmd;
    $reap_addr = refaddr $cmd->{reaper};

    {
        my $fh = $cmd->stdout;
        my $ln = <$fh>;
        is( $ln, "STDOUT line 1\n", 'scope: { $cmd { $fh } { $fh } }' );
    }
    {
        my $fh = $cmd->stdout;
        my $ln = <$fh>;
        is( $ln, "STDOUT line 2\n", 'scope: { $cmd { $fh } { $fh } }' );
    }
    is( scalar @destroyed, 0, "Destroyed no object yet" );
}
is( scalar @destroyed, 2,          "Destroyed 2 objects" );
is( shift @destroyed,  $cmd_addr,  "... command object was destroyed" );
is( shift @destroyed,  $reap_addr, "... reaper object was destroyed" );
@destroyed = ();

# test 3
BEGIN { $tests += 3 }
{
    my $fh = System::Command->new( @cmd, 1 )->stdout;
    is( scalar @destroyed, 1, "Destroyed 1 object (command)" );
    @destroyed = ();
    my $ln = <$fh>;
    is( $ln, "STDOUT line 1\n", 'scope: { $fh = cmd->fh }' );
}
is( scalar @destroyed, 1, "Destroyed 1 object (reaper)" );
@destroyed = ();

# test 4
BEGIN { $tests += 1 }
System::Command->new(@cmd);
is( scalar @destroyed, 2, "Destroyed 2 objects (command + reaper)" );
@destroyed = ();

# test 5
BEGIN { $tests += 5 }
{
    my $fh;
    {
        my $cmd = System::Command->new( @cmd, 2 );
        $cmd_addr  = refaddr $cmd;
        $reap_addr = refaddr $cmd->{reaper};
        $fh        = $cmd->stdout;
    }
    is( scalar @destroyed, 1,         "Destroyed 1 object (command)" );
    is( shift @destroyed,  $cmd_addr, "... command object was destroyed" );
    @destroyed = ();
    my $out = join '', <$fh>;
    is( $out, << 'OUT', 'scope: { $fh = $cmd->fh }; $fh }' );
STDOUT line 1
STDOUT line 2
OUT
}
is( scalar @destroyed, 1,          "Destroyed 1 objects (reaper)" );
is( shift @destroyed,  $reap_addr, "... reaper object was destroyed" );
@destroyed = ();

# test 6
BEGIN { $tests += 6 }
{
    my $cmd = System::Command->new( @cmd, 1, 2, 2, 1 );
    $cmd_addr  = refaddr $cmd;
    $reap_addr = refaddr $cmd->{reaper};

    {
        my $fh = $cmd->stdout;
        my $out = join '', <$fh>;
        is( $out, << 'OUT', 'scope: { $cmd { $fh } { $fh } }' );
STDOUT line 1
STDOUT line 2
STDOUT line 3
OUT
    }
    {
        my $fh = $cmd->stderr;
        my $err = join '', <$fh>;
        is( $err, << 'ERR', 'scope: { $cmd { $fh } { $fh } }' );
STDERR line 1
STDERR line 2
STDERR line 3
ERR
    }
    is( scalar @destroyed, 0, "Destroyed no object yet" );
}
is( scalar @destroyed, 2,          "Destroyed 2 objects" );
is( shift @destroyed,  $cmd_addr,  "... command object was destroyed" );
is( shift @destroyed,  $reap_addr, "... reaper object was destroyed" );
@destroyed = ();

# test 7
BEGIN { $tests += 4 }
{
    my ( $pid, $in, $out, $err ) = System::Command->spawn( @cmd, 1, 2, 2, 1 );
    is( scalar @destroyed, 1, "Destroyed command object" );
    shift @destroyed;
    my $errput = join '', <$err>;
    my $output = join '', <$out>;
    is( $output, << 'OUT', 'scope: spawn()' );
STDOUT line 1
STDOUT line 2
STDOUT line 3
OUT
    is( $errput, << 'ERR', 'scope: spawn()' );
STDERR line 1
STDERR line 2
STDERR line 3
ERR
}
is( scalar @destroyed, 1, "Destroyed reaper object" );
@destroyed = ();

