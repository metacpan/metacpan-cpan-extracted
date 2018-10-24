#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck qw{mock_file_check unmock_file_check unmock_all_file_checks CHECK_IS_TRUE};

my $not_there = q{/should/not/be/there};    # improve

ok( !-e $not_there, "-e 'not_there' file is missing when unmocked" );
ok( !-f $not_there, "-f 'not_there' file is missing when unmocked" );

mock_file_check( 'e' => sub { CHECK_IS_TRUE } );
ok( -e $not_there,  "-e 'not_there' missing file exists when mocked" );
ok( !-f $not_there, "-f 'not_there' still false" );

mock_file_check( f => sub { CHECK_IS_TRUE } );
ok( -e $not_there, "-e mocked => true" );
ok( -f $not_there, "-f mocked => true" );

unmock_all_file_checks();
ok( !-e $not_there, "-e unmocked  => false" );
ok( !-f $not_there, "-f unmocked => false" );

done_testing;
