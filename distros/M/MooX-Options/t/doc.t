#!perl
#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use t::Test;
use Test::Trap;
use Carp;
use FindBin qw/$RealBin/;
use Try::Tiny;

local $ENV{TEST_FORCE_COLUMN_SIZE} = 78;

{

    package t;
    use Moo;
    use MooX::Options;

    option 't' => (
        is            => 'ro',
        documentation => 'this is a test',
    );

    1;
}

{

    package t1;
    use Moo;
    use MooX::Options;

    option 't' => (
        is            => 'ro',
        doc           => 'this pass first',
        documentation => 'this is a test',
    );

    1;
}

{

    package t2;
    use Moo;
    use t::Test;

    sub filter_opt {
        my ( $attr, %opt ) = @_;

        ok !defined $opt{doc},          'doc has been filtered';
        ok defined $opt{documentation}, 'documentation has been keeped';

        return has( $attr, %opt );
    }

    use MooX::Options option_chain_method => 'filter_opt';

    option 't' => (
        is            => 'ro',
        doc           => 'this pass first',
        documentation => 'this is a test',
    );

    1;
}

{
    my $opt = t->new_with_options;
    trap { $opt->options_usage };
    like $trap->stdout, qr/\s+\-t\s+this\sis\sa\stest/x, 'documentation work';
    trap { $opt->options_help };
    like $trap->stdout, qr/\s+\-t:\n\s+this\sis\sa\stest/x,
        'documentation work';
}

{
    my $opt = t1->new_with_options;
    trap { $opt->options_usage };
    like $trap->stdout, qr/\s+\-t\s+this\spass\sfirst/x, 'doc pass first';
    trap { $opt->options_help };
    like $trap->stdout, qr/\s+\-t:\n\s+this\spass\sfirst/x, 'doc pass first';
}

{
    my $opt = t2->new_with_options;
    trap { $opt->options_usage };
    like $trap->stdout, qr/\s+\-t\s+this\spass\sfirst/x, 'doc pass first';
    trap { $opt->options_help };
    like $trap->stdout, qr/\s+\-t:\n\s+this\spass\sfirst/x, 'doc pass first';
}

done_testing;
