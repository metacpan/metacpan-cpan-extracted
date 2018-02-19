#!/usr/bin/perl -w
#
# Jan 2016  M.Eckardt, imunixx GmbH			<Matthias.Eckardt@imunixx.de>
# SDG
############################################################################
use strict;
use Script::Toolbox qw(:all);
use Script::Toolbox::TableO;
############################################################################
my $O = {
    'file' => { 'mod' => '=s', 'desc' => 'Get a file name.', 'mand' => 1, 'default'	=> '/bin/cat', },
};
############################################################################
############ generate prototypes with the following line ###################
# :r! echo $(grep '^sub' queue_blocking.pl | sed -e 's/$/;/') | fold -s -80
############################################################################
############################################################################
#$SIG{'INT'} = 'sigExit';
#$SIG{'HUP'} = 'sigExit';
#$SIG{'QUIT'}= 'sigExit';
#$SIG{'TERM'}= 'sigExit';
############################################################################
#------------------------------------------------------------------------------
# Signal handler.
#------------------------------------------------------------------------------
#sub sigExit($)
#{
#    my ($sig) = @_;
#    Exit( 1, "program aborted by signal SIG$sig." );
#}



#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub main
{
    my $M =[
            {'label'=>'rwValue', 'value'=>1 },
            {'label'=>'roValue', 'value'=>'readOnly','readOnly'=>1},
            {'label'=>'rwValDef','value'=>30, 'default'=>50},
            {'label'=>'roValDef','value'=>30, 'default'=>50, 'readOnly'=>1},
            {'label'=>'roNoValNoDef',                        'readOnly'=>1},
            {'label'=>'roNoValDef',           'default'=>50, 'readOnly'=>1},
            {'label'=>'roValNoDef','value'=>30,              'readOnly'=>1},
            {'label'=>'test8',},
            {'label'=>'test9',},
            {'label'=>'test10',          'value'=>30, },
            {'label'=>'Untermenue 1',    'jump'=>'SubMenu1'},
            {'label'=>'Untermenue 2',    'jump'=>'SubMenu2'},
            {'label'=>'InvalidSubMenu', 'jump'=>'SubMenuX'}
           ];
	my ($self) = @_;
    my $o = Script::Toolbox->new( $O );

    my $m = Script::Toolbox::Util::Menus->new({'SubMenu2'=>[{'label'=>'test','value'=>10}]});
       $m->addMenu({'MainMenu'=>$M});
       $m->addMenu({'SubMenu1'=>[{'label'=>'SubMenu1 Test','value'=>40}]});
       $m->addOption('MainMenu', {'label'=>'Untermenue 2 via addOption()',    'jump'=>'SubMenu2'});

       $m->setAutoHeader();
       $m->setFooter('MainMenu', 'Test:Autoheader, infinite run');
    my $r = $m->run('MainMenu',-1);

    printf "\n%s\n", '-' x 20;
    my $v = $m->getMatching('MainMenu','test','label','value');
    printf "Values of Labels /test/  : %s\n", join ' ', @{$v};
       $v = $m->getMatching('MainMenu','(1|3)','number','value');
    printf "Values of Numbers /(1|3)/: %s\n", join ' ', @{$v};
       $v = $m->getMatching('MainMenu','\d+','value','label');
    printf "Labels of Values /%s/   : %s\n", '\d+', join ' ',  @{$v};
    printf "\n%s\n", '-' x 20;

    $m->setFooter('MainMenu', 'Test:Autoheader, single run with reaction code');
    while( $m->run('MainMenu')) {
            if( $m->currNumber('MainMenu') == 2 ) {
                my $v = $m->currValue('MainMenu');
                my $nv= $v == 0 ? 1 : 0;
                my $lb= $nv == 0 ? 'test1-off' : 'test1-on';
                $m->setCurrValue('MainMenu',$nv);
                $m->setCurrLabel('MainMenu',$lb);

            }
    }

    $m->addMenu({'MultiSel'=>$M});
    $m->run('MultiSel',0);
    $m->run('MultiSel',0);
    $m->setCurrDefault('bla','blu');     # err-test
    $m->setCurrDefault('MultiSel','ok'); #  ok-test
    $m->setCurrReadOnly('bla','blu');     # err-test
    $m->setCurrReadOnly('MultiSel','ok'); #  ok-test
    print;


#    my $t = Table([ 'Util-Table',
#                    [ '--H1--',  '--H2--', '--H3--'],
#                    [ '11:11:11',  33.456, 'cc  '  ],
#                    [ '12:23:00', 2222222, 3       ],
#                    [ '11:11', 222, 3333333333333333 ]]);
#    print join "\n", @{$t};
#
#       $t = $o->Table([ 'Util-Table as Script::Toolbox Object',
#                    [ '--H1--',  '--H2--', '--H3--'],
#                    [ '11:11:11',  33.456, 'cc  '  ],
#                    [ '12:23:00', 2222222, 3       ],
#                    [ '11:11', 222, 3333333333333333 ]]);
#    print join "\n", @{$t};
#
#    my $T = Script::Toolbox::TableO->new([ 'TableO',
#                         [ '--H1--',  '--H2--', '--H3--'],
#                         [ '11:11:11',  33.456, 'cc  '  ],
#                         [ '12:23:00', 2222222, 3       ],
#                         [ '11:11', 222, 3333333333333333 ]]);
#    print $T->asString("\n\n");
#	return;
}
main();

############################################################################
1;
__END__
