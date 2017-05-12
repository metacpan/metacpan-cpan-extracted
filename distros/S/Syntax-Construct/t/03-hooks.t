#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 1;

SKIP: { $^V gt '5.010' or skip('5.010 needed to test', 1);

        my $flag;
        require Syntax::Construct;

        {   no strict 'refs';
            no warnings 'redefine';
            *Syntax::Construct::_hook = sub {
                { '//' => sub { $flag = 1 } }
            };
        }

        eval {
            'Syntax::Construct'->import('//');
            ok $flag, 'hook called';
        };
}




