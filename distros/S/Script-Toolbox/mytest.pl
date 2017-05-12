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
	my ($self) = @_;
    my $o = Script::Toolbox->new( $O );

    my $m = Script::Toolbox::Util::Menues->new({'SubMenue2'=>[{'label'=>'test','value'=>10}]});
       $m->addMenue({'MainMenue'=>[{'label'=>'test1', 'value'=>1 },
                                   {'label'=>'test2', 'value'=>'readOnly','readOnly'=>1},
                                   {'label'=>'test3', 'value'=>30,},
                                   {'label'=>'test4',},
                                   {'label'=>'test5',},
                                   {'label'=>'test6',},
                                   {'label'=>'test7',},
                                   {'label'=>'test8',},
                                   {'label'=>'test9',},
                                   {'label'=>'test10',          'value'=>30,},
                                   {'label'=>'Untermenue 1',    'jump'=>'SubMenue1'},
                                   {'label'=>'Untermenue 2',    'jump'=>'SubMenue2'},
                                   {'label'=>'InvalidSubMenue', 'jump'=>'SubMenueX'}
                                  ]});
       $m->addMenue({'SubMenue1'=>[{'label'=>'SubMenue1 Test','value'=>40}]});
       $m->addOption('MainMenue', {'label'=>'Untermenue 2 via addOption()',    'jump'=>'SubMenue2'});

       $m->setAutoHeader();
       $m->setFooter('MainMenue', 'Test:Autoheader, ininite run');
    my $r = $m->run('MainMenue',-1);

    printf "\n%s\n", '-' x 20;
    my $v = $m->getMatching('MainMenue','test','label','value');
    printf "Values of Labels /test/  : %s\n", join ' ', @{$v};
       $v = $m->getMatching('MainMenue','(1|3)','number','value');
    printf "Values of Numbers /(1|3)/: %s\n", join ' ', @{$v};
       $v = $m->getMatching('MainMenue','\d+','value','label');
    printf "Labels of Values /%s/   : %s\n", '\d+', join ' ',  @{$v};
    printf "\n%s\n", '-' x 20;

    $m->setFooter('MainMenue', 'Test:Autoheader, single run with reaction code');
    while( $m->run('MainMenue')) {
            if( $m->currNumber('MainMenue') == 2 ) {
                my $v = $m->currValue('MainMenue');
                my $nv= $v == 0 ? 1 : 0;
                my $lb= $nv == 0 ? 'test1-off' : 'test1-on';
                $m->setCurrValue('MainMenue',$nv);
                $m->setCurrLabel('MainMenue',$lb);

            }
    }

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
