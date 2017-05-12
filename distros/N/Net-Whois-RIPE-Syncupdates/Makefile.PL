# Copyright (c) 1993 - 2002 RIPE NCC
#
# All Rights Reserved
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose and without fee is hereby granted,
# provided that the above copyright notice appear in all copies and that
# both that copyright notice and this permission notice appear in
# supporting documentation, and that the name of the author not be
# used in advertising or publicity pertaining to distribution of the
# software without specific, written prior permission.
#
# THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
# ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS; IN NO EVENT SHALL
# AUTHOR BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
# DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
# AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

#
# $Id: Makefile.PL,v 1.29 2003/08/01 13:46:11 peter Exp $
#

use strict;
use ExtUtils::MakeMaker qw(WriteMakefile prompt);
use Config;
use Data::Dumper;

eval {
    use Storable;
};

my $HAVE_STORABLE = $@ ? 0 : 1;

my $CONFIG_CACHE = '.pkg-config';
my $PKG_CONFIG = {};

# Pull in user configuration if we have it cached
if($HAVE_STORABLE and -f $CONFIG_CACHE){

    $PKG_CONFIG = retrieve($CONFIG_CACHE);

} else {
    $PKG_CONFIG = {
        TEST_URL => 'none',
        DEFAULT_URL => 'http://www.ripe.net/syncupdates',
    };
}

user_config($PKG_CONFIG);

my %PARAM = (
    NAME              => 'Net::Whois::RIPE::Syncupdates',
    VERSION_FROM      => 'Syncupdates.pm',

    ABSTRACT          => 'Perl Syncupdates client interface',
    AUTHOR            => 'Peter Banik <peter@ripe.net>, Ziya Suzen <ziya@ripe.net>',

    PREREQ_PM         => {
        'HTTP::Request::Common' => 1,
        'LWP::UserAgent' => '2.0',
        'Params::Validate' => '0.04',
    },

    PM_FILTER         => "sed -e \\\"s\\#__DEFAULT_URL__\\#$PKG_CONFIG->{DEFAULT_URL}\\#g\\\"",

    dist => {
       COMPRESS  => 'gzip -9f', 
       SUFFIX    => '.gz',
       CI        => 'cvs ci',
       RCS_LABEL => 'cvs tag -c -F $(NAME_SYM)-$(VERSION_SYM)',
    },
);

        
# RIPE NCC common configuration
if ($Config{vendorprefix} eq '/usr/local/ncc') {
    warn "\nConfiguring for RIPE NCC Perl installation...\n\n";
    $PARAM{'INSTALLDIRS'} = 'vendor';
    $PARAM{'macro'} = {
        INSTALLPREFIX => '$(VENDORPREFIX)',
    },
}

# User configuration will be cached if storable is installed
if($HAVE_STORABLE){
    store($PKG_CONFIG, $CONFIG_CACHE);
}

WriteMakefile(
   %PARAM
);


sub MY::test {
    package MY;
    my $rules = shift->SUPER::test(@_);

    $rules =~ s/^test ::/_run_test ::/m;

    if($PKG_CONFIG->{TEST_URL}){
        my $url = $PKG_CONFIG->{TEST_URL};
        $rules = "export TEST_URL=$url\n" . $rules;
    }
    $rules .= "test:  _run_test";
    return $rules;
}


sub user_config {
    my $PKG_CONFIG = shift;

    warn "\nYou will now be asked to specify some configuration parameters.\n\n";

    my $hints = {
        TEST_URL => <<__END_1__,
            TEST syncupdates backend URL
            ============================
            
            This URL will be used by the test suite.  Please note that
            the test suite will send updates to the backend, so DO NOT enter
            the URL to your production database/syncupdates backend.

            Unless you are debugging Net::Whois::RIPE::Syncupdates itself,
            you should say 'none' here (which is the default).

__END_1__

        DEFAULT_URL => <<__END_2__,
            DEFAULT syncupdates backend URL
            ===============================

            This will be set as system-wide default, which the module will use 
            unless the calling code overrides it.
            You may want to enter 'none' here, in which case there will be no
            default.

__END_2__
    };

    my $prompts = {
        TEST_URL => 'TEST syncupdates frontend URL',
        DEFAULT_URL => 'DEFAULT syncupdates frontend URL',
    };

    foreach my $param (qw(TEST_URL DEFAULT_URL)){

        $hints->{$param} =~ s/^ +//gm;
        print $hints->{$param};
        
        do {
            $PKG_CONFIG->{$param} = prompt($prompts->{$param}, $PKG_CONFIG->{$param});
        } while($PKG_CONFIG->{$param} !~ /^(\s*$|none$|https?:\/\/)/i );

        $PKG_CONFIG->{$param} = '' if $PKG_CONFIG->{$param} eq 'none';
        print "\n";
    }
}

