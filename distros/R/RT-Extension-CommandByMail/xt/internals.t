use strict;
use warnings;

use RT::Extension::CommandByMail::Test tests => undef, nodb => 1;

use_ok('RT::Extension::CommandByMail');

diag( "test _ParseAdditiveCommand") if $ENV{'TEST_VERBOSE'};
{
    my %res = RT::Extension::CommandByMail::_ParseAdditiveCommand({}, 0, 'Foo');
    is_deeply( \%res, {}, 'empty' );

    my $cmd = { foo => 'qwe' };
    %res = RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo');
    is_deeply(\%res, { Set => ['qwe'] }, 'simple set');

    $cmd = { foo => ['qwe', 'asd'] };
    %res = RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo');
    is_deeply(\%res, { Set => ['qwe', 'asd'] }, 'simple set with array ref');

    $cmd = { foos => 'qwe' };
    %res = RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 1, 'Foo');
    is_deeply(\%res, { Set => ['qwe'] }, 'simple set with plural form');

    $cmd = { foos => 'qwe' };
    %res = RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo');
    is_deeply(\%res, { }, 'single form shouldnt eat plural forms');

    $cmd = { foo => 'qwe', foos => 'qwe' };
    %res = RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 1, 'Foo');
    is_deeply(\%res, { Set => ['qwe', 'qwe'] }, 'set with plural and single form at the same time');

    $cmd = { foo => 'qwe', addfoo  => 'asd' };
    %res = RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo');
    is_deeply(\%res, { Set => ['qwe'], Add => ['asd'] }, 'set+add');

    $cmd = { foo => ['qwe'], addfoo  => ['asd'], delfoo => ['zxc'] };
    %res = RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo');
    is_deeply(\%res, { Set => ['qwe'], Add => ['asd'], Del => ['zxc'] }, 'set+add+del');
}

diag( "test _CompileAdditiveForCreate") if $ENV{'TEST_VERBOSE'};
{
    my @res = RT::Extension::CommandByMail::_CompileAdditiveForCreate(
        RT::Extension::CommandByMail::_ParseAdditiveCommand({}, 0, 'Foo')
    );
    is_deeply(\@res, [], 'empty');

    my $cmd = { foo => 'qwe' };
    @res = RT::Extension::CommandByMail::_CompileAdditiveForCreate(
        RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo')
    );
    is_deeply(\@res, ['qwe'], 'simple set');

    $cmd = { foo => 'qwe', addfoo => 'asd' };
    @res = RT::Extension::CommandByMail::_CompileAdditiveForCreate(
        RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo')
    );
    is_deeply(\@res, ['qwe', 'asd'], 'set+add');

    $cmd = { foo => 'qwe' };
    @res = RT::Extension::CommandByMail::_CompileAdditiveForCreate(
        Default => 'def',
        RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo')
    );
    is_deeply(\@res, ['qwe'], 'set+default: set overrides defaults');

    $cmd = { addfoo => 'qwe' };
    @res = RT::Extension::CommandByMail::_CompileAdditiveForCreate(
        Default => 'def',
        RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo')
    );
    is_deeply(\@res, ['def', 'qwe'], 'add+default: add adds to defaults');

    $cmd = { addfoo => 'qwe', delfoo => 'def' };
    @res = RT::Extension::CommandByMail::_CompileAdditiveForCreate(
        Default => 'def',
        RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo')
    );
    is_deeply(\@res, ['qwe'], 'add+default+del: delete default');
}

diag( "test _CompileAdditiveForUpdate") if $ENV{'TEST_VERBOSE'};
{
    my @res = RT::Extension::CommandByMail::_CompileAdditiveForUpdate(
        RT::Extension::CommandByMail::_ParseAdditiveCommand({}, 0, 'Foo')
    );
    is_deeply(\@res, [[], []], 'empty');

    my $cmd = { foo => 'qwe' };
    @res = RT::Extension::CommandByMail::_CompileAdditiveForUpdate(
        RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo')
    );
    is_deeply(\@res, [['qwe'],[]], 'simple set');

    $cmd = { foo => 'qwe', addfoo => 'asd' };
    @res = RT::Extension::CommandByMail::_CompileAdditiveForUpdate(
        RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo')
    );
    is_deeply(\@res, [['qwe', 'asd'],[]], 'set+add');

    $cmd = { foo => 'qwe' };
    @res = RT::Extension::CommandByMail::_CompileAdditiveForUpdate(
        Default => 'def',
        RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo')
    );
    is_deeply(\@res, [['qwe'],['def']], 'set+default: set overrides defaults');

    $cmd = { addfoo => 'qwe' };
    @res = RT::Extension::CommandByMail::_CompileAdditiveForUpdate(
        Default => 'def',
        RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo')
    );
    is_deeply(\@res, [['qwe'],[]], 'add+default: add adds to defaults');

    $cmd = { addfoo => 'def' };
    @res = RT::Extension::CommandByMail::_CompileAdditiveForUpdate(
        Default => 'def',
        RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo')
    );
    is_deeply(\@res, [[],[]], 'add current: do nothing');

    $cmd = { addfoo => 'qwe', delfoo => 'def' };
    @res = RT::Extension::CommandByMail::_CompileAdditiveForUpdate(
        Default => 'def',
        RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo')
    );
    is_deeply(\@res, [['qwe'],['def']], 'add+default+del: delete default');

    $cmd = { delfoo => 'qwe' };
    @res = RT::Extension::CommandByMail::_CompileAdditiveForUpdate(
        Default => 'def',
        RT::Extension::CommandByMail::_ParseAdditiveCommand($cmd, 0, 'Foo')
    );
    is_deeply(\@res, [[],[]], 'del not current: do nothing');
}

done_testing();
