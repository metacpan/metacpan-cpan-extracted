#!perl
use Modern::Perl;

package My::Cmd;
use Any::Moose;
extends any_moose('X::App::Cmd');

package My::Cmd::Command::pre_commit;
use Any::Moose;
extends any_moose('X::App::Cmd::Command');
with 'SVN::Simple::Hook::PreCommit';

sub execute {
    my ( $self, $opt, $args ) = @_;

    warn $self->author(), ' changed ',
        scalar keys %{ $self->paths_changed }, " paths\n";

    return;
}

package main;
use Const::Fast;
use English '-no_match_vars';
use File::Temp;
use SVN::Core;
use SVN::Repos;
use Test::More tests => 2;
use App::Cmd::Tester;

const my $USERID => scalar getpwuid $EFFECTIVE_USER_ID;
my $tmp_dir = File::Temp->newdir();
my $repos   = SVN::Repos::create( "$tmp_dir", (undef) x 4 );
my $txn     = $repos->fs_begin_txn_for_update( 0, "$USERID" );
$txn->root->make_file('/foo');

my $result = test_app(
    'My::Cmd' => [
        'pre_commit',
        -r => "$tmp_dir",
        -t => $txn->name(),
    ],
);
$txn->abort();

is( $result->exit_code(), 0, 'successful run' );
isnt( $result->output, q{}, 'got output' );
