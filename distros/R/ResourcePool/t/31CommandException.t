#! /usr/bin/perl -w
#*********************************************************************
#*** t/05Exceptions.t
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: 31CommandException.t,v 1.1 2003-03-16 14:57:56 mws Exp $
#*********************************************************************
use ResourcePool::Command::Exception;
use ResourcePool::Command::NoFailoverException;
use ResourcePool::Command::Execute;
use Test;

BEGIN { plan tests => 51;};

my $rootex = 'hirsch';
my $ex = ResourcePool::Command::Exception->new($rootex);
ok ($ex->getException() eq 'hirsch');
ok ($ex->rootException() eq 'hirsch');

$ex = ResourcePool::Command::NoFailoverException->new($rootex);
#ok ($ex->getException() eq 'hirsch');
ok ($ex->rootException() eq 'hirsch');

my $ex2 = ResourcePool::Command::Exception->new($ex);
ok ($ex2->getException() == $ex);
#ok ($ex2->getException()->getException() eq 'hirsch');
ok ($ex2->rootException() eq 'hirsch');

#####
#
# test reports

my $rep = ResourcePool::Command::Execute::Report->new();
ok (! defined ($rep->getException()));
ok ($rep->ok());
ok (!$rep->tobeRepeated());
$rep->setInitException('hirsch');
ok ($rep->getInitException() eq 'hirsch');
ok ($rep->getException() eq 'hirsch');
ok (!$rep->ok());
ok ($rep->tobeRepeated());

$rep = ResourcePool::Command::Execute::Report->new();
$rep->setPreExecuteException('hirsch');
ok ($rep->getPreExecuteException() eq 'hirsch');
ok ($rep->getException() eq 'hirsch');
ok (!$rep->ok());
ok ($rep->tobeRepeated());

$rep = ResourcePool::Command::Execute::Report->new();
$rep->setExecuteException('hirsche');
ok ($rep->getExecuteException() eq 'hirsche');
ok ($rep->getException() eq 'hirsche');
ok (!$rep->ok());
ok ($rep->tobeRepeated());

$rep = ResourcePool::Command::Execute::Report->new();
$rep->setPostExecuteException('hirschp');
ok ($rep->getPostExecuteException() eq 'hirschp');
ok ($rep->getException() eq 'hirschp');
ok (!$rep->ok());
ok ($rep->tobeRepeated());


$rep = ResourcePool::Command::Execute::Report->new();
$rep->setCleanupException('hirschc');
ok ($rep->getCleanupException() eq 'hirschc');
ok ($rep->getException() eq 'hirschc');
ok ($rep->ok());
ok (!$rep->tobeRepeated());

#####
#
# same with NoFailoverExection

my $nfe = ResourcePool::Command::NoFailoverException->new('reh');

$rep = ResourcePool::Command::Execute::Report->new();
ok (! defined ($rep->getException()));
ok ($rep->ok());
ok (!$rep->tobeRepeated());
$rep->setInitException($nfe);
ok ($rep->getInitException() == $nfe);
ok ($rep->getException() == $nfe);
ok (!$rep->ok());
ok (!$rep->tobeRepeated());

$rep = ResourcePool::Command::Execute::Report->new();
$rep->setPreExecuteException($nfe);
ok ($rep->getPreExecuteException() == $nfe);
ok ($rep->getException() == $nfe);
ok (!$rep->ok());
ok (!$rep->tobeRepeated());

$rep = ResourcePool::Command::Execute::Report->new();
$rep->setExecuteException($nfe);
ok ($rep->getExecuteException() == $nfe);
ok ($rep->getException() == $nfe);
ok (!$rep->ok());
ok (!$rep->tobeRepeated());

$rep = ResourcePool::Command::Execute::Report->new();
$rep->setPostExecuteException($nfe);
ok ($rep->getPostExecuteException() eq $nfe);
ok ($rep->getException() eq $nfe);
ok (!$rep->ok());
ok (!$rep->tobeRepeated());


$rep = ResourcePool::Command::Execute::Report->new();
$rep->setCleanupException($nfe);
ok ($rep->getCleanupException() == $nfe);
ok ($rep->getException() == $nfe);
ok ($rep->ok());
ok (!$rep->tobeRepeated());
