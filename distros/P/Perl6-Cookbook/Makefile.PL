use strict;
use warnings;
use lib 'privinc';
use inc::Module::Install;

#if (not $ENV{PARROT_PATH}) {
#	warn "PARROT_PATH needs to be defined\n";
#	exit 0;
#}

name           'Perl6-Cookbook';
license        'perl';
author         'Gabor Szabo <szabgab@gmail.com>';
requires       'perl'                     => '5.008000';
requires       'File::ShareDir'           => '1.00';
all_from       'lib/Perl6/Cookbook.pm';

test_requires  'Test::More'               => '0.47';
no_index       'directory'                => qw{ t xt share inc privinc eg };
install_share  'eg';

#homepage       'http://www.szabgab.com/perl6.html';
repository     'http://svn1.hostlocal.com/szabgab/trunk/Perl6-Cookbook';
# MailingList  'http://mail.perlide.org/mailman/listinfo/padre-dev';
install_script 'script/perl6_cookbook';


postamble(<<"END_MAKEFILE");

examples :: all
\t\$(NOECHO) \$(PERL) setup_examples.pl

END_MAKEFILE


WriteAll;

use File::Spec;

