use strict;
use warnings;
use inc::Module::Install;

use File::Spec;
use File::Copy qw(copy);

my $failed;
if ( not $ENV{PARROT_DIR} ) {
	warn "PARROT_DIR needs to be defined and has to point to the checked out trunk of Parrot\n";
	$failed = 1;
}
if ( not $ENV{RAKUDO_DIR} ) {
	warn "RAKUDO_DIR needs to be defined and has to point to the checked out trunk of Rakudo\n";
	$failed = 1;
}
exit 0 if $failed;

my $parrot = File::Spec->catfile($ENV{PARROT_DIR}, 'parrot') . ($^O eq "MSWin32" ? '.exe' : '');
if (not -e $parrot) {
	warn "$parrot does not exist. Parrot needs to be compiled\n";
	$failed = 1;
}
my $rakudo = File::Spec->catfile($ENV{RAKUDO_DIR}, 'perl6.pbc');
if (not -e $rakudo) {
	warn "$rakudo does not exist. Rakudo needs to be compiled\n";
	$failed = 1;
}
exit 0 if $failed;

foreach my $t6 (glob File::Spec->catfile('t', '*.t6')) {
	(my $t = $t6) =~ s/6$//;
	copy 'shim.pl', $t;
}

name           'Perl6-Conf';
license        'artistic2';
author         'Gabor Szabo <szabgab@gmail.com>';
abstract       'Experimental Perl 6 implementation of an INI file reader';
distribution_type 'module';

version        '0.04';
requires       'perl'                     => '5.008000';
requires       'File::Spec'               => '0';
requires       'File::Copy'               => '0';
#all_from       'lib/Perl6/Conf.pm';

provides 'Perl6::Conf', {file => 'lib/Perl6/Conf.pm', version => '0.04'};

test_requires  'Test::More'               => '0.47';
no_index       'directory'                => qw{ t xt share inc eg };

#homepage       'http://www.szabgab.com/perl6.html';
repository     'http://svn1.hostlocal.com/szabgab/trunk/Perl6-Conf';
# MailingList  'http://mail.perlide.org/mailman/listinfo/padre-dev';


#postamble(<<"END_MAKEFILE");
#test :: all
#\t\$(NOECHO) \$(PERL) wrap.pl
#
#END_MAKEFILE


WriteAll;

use File::Spec;

