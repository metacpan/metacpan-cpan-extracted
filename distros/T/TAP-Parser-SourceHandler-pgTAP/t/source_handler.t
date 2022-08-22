#!/usr/bin/perl -w

use strict;

use Test::More tests => 47;

use IO::File;
use IO::Handle;
use File::Spec::Functions;

use TAP::Parser::Source;
use TAP::Parser::SourceHandler;

my $ext = $^O eq 'MSWin32' ? '.bat' : '';

my $dir = catdir curdir, 't', 'scripts';
$dir    = catdir curdir, 't', 'bin' unless -d $dir;

# pgTAP source tests
{
    my $class = 'TAP::Parser::SourceHandler::pgTAP';
    my $test  = File::Spec->catfile( 't', 'source.pg' );
    my $psql  = File::Spec->catfile( $dir, "psql$ext" );
    my @command = qw(
      --no-psqlrc
      --no-align
      --quiet
      --pset pager=off
      --pset tuples_only=true
      --set ON_ERROR_STOP=1
    );
    my $tests = {
        default_vote => 0,
        can_handle   => [
            {   name => '.pg',
                meta => {
                    is_file => 1,
                    file    => { lc_ext => '.pg' }
                },
                config => {},
                vote   => 0.9,
            },
            {   name => '.sql',
                meta => {
                    is_file => 1,
                    file    => { lc_ext => '.sql' }
                },
                config => {},
                vote   => 0.8,
            },
            {   name => '.s',
                meta => {
                    is_file => 1,
                    file    => { lc_ext => '.s' }
                },
                config => {},
                vote   => 0.75,
            },
            {   name => 'config_suffix',
                meta => {
                    is_file => 1,
                    file    => { lc_ext => '.foo' }
                },
                config => { pgTAP => { suffix => '.foo' } },
                vote   => 1,
            },
            {   name => 'config_suffixes',
                meta => {
                    is_file => 1,
                    file    => { lc_ext => '.foo' }
                },
                config => { pgTAP => { suffix => [qw(.foo .bar)] } },
                vote   => 1,
            },
            {   name => 'not_file',
                meta => {
                    is_file => 0,
                },
                vote => 0,
            },
        ],
        make_iterator => [
            {   name   => 'psql',
                raw    => \$test,
                config => { pgTAP => { psql => $psql } },
                iclass => 'TAP::Parser::Iterator::Process',
                output => [ @command, '--file', $test ],
            },
            {   name   => 'config',
                raw    => $test,
                config => {
                    pgTAP => {
                        psql     => $psql,
                        username => 'who',
                        host     => 'f',
                        port     => 2,
                        dbname   => 'fred',
                        set      => { whatever => 'foo' },
                    }
                },
                iclass => 'TAP::Parser::Iterator::Process',
                output => [
                    @command,
                    qw(--username who --host f --port 2 --dbname fred --set whatever=foo --file),
                    $test
                ],
            },
            {   name   => 'error',
                raw    => 'blah.pg',
                iclass => 'TAP::Parser::Iterator::Process',
                error  => qr/^No such file or directory: blah[.]pg/,
            },
            {   name   => 'undef error',
                raw    => undef,
                iclass => 'TAP::Parser::Iterator::Process',
                error  => qr/^No such file or directory: /,
            },
        ],
    };

    test_handler( $class, $tests );
}

exit;

###############################################################################
# helper sub

sub test_handler {
    my ( $class, $tests ) = @_;
    my ($short_class) = ( $class =~ /\:\:(\w+)$/ );

    use_ok $class;
    can_ok $class, 'can_handle', 'make_iterator';

    {
        my $default_vote = $tests->{default_vote} || 0;
        my $source = TAP::Parser::Source->new->raw(\'');
        is( $class->can_handle($source), $default_vote,
            '... can_handle default vote'
        );
    }

    for my $test ( @{ $tests->{can_handle} } ) {
        my $source = TAP::Parser::Source->new->raw(\'');
        $source->raw( $test->{raw} )       if $test->{raw};
        $source->meta( $test->{meta} )     if $test->{meta};
        $source->config( $test->{config} ) if $test->{config};
        $source->assemble_meta             if $test->{assemble_meta};
        my $vote = $test->{vote} || 0;
        my $name = $test->{name} || 'unnamed test';
        $name = "$short_class->can_handle( $name )";
        is( $class->can_handle($source), $vote, $name );
    }

    for my $test ( @{ $tests->{make_iterator} } ) {
        my $name = $test->{name} || 'unnamed test';
        $name = "$short_class->make_iterator( $name )";

        SKIP:
        {
            my $planned = 1;
            $planned += 1 + scalar @{ $test->{output} } if $test->{output};
            skip $test->{skip_reason}, $planned if $test->{skip};

            my $source = TAP::Parser::Source->new;
            $source->raw( $test->{raw} )       if $test->{raw};
            $source->test_args( $test->{test_args} ) if $test->{test_args};
            $source->meta( $test->{meta} )     if $test->{meta};
            $source->config( $test->{config} ) if $test->{config};
            $source->assemble_meta             if $test->{assemble_meta};

            my $iterator = eval { $class->make_iterator($source) };
            my $e = $@;
            if ( my $error = $test->{error} ) {
                $e = '' unless defined $e;
                like $e, $error, "$name threw expected error";
                next;
            }
            elsif ($e) {
                fail("$name threw an unexpected error");
                diag($e);
                next;
            }

            isa_ok $iterator, $test->{iclass}, $name;
            if ( $test->{output} ) {
                my $i = 1;
                for my $line ( @{ $test->{output} } ) {
                    is $iterator->next, $line, "... line $i";
                    $i++;
                }
                ok !$iterator->next, '... and we should have no more results';
            }
        }
    }
}
