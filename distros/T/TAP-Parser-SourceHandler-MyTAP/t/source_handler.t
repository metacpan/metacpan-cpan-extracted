#!/usr/bin/perl -w

BEGIN {
    unshift @INC, 't/lib';
}

use strict;

use Test::More tests => 37;

use IO::File;
use IO::Handle;
use File::Spec::Functions;

use TAP::Parser::Source;
use TAP::Parser::SourceHandler;

my $ext = $^O eq 'MSWin32' ? '.bat' : '';

my $dir = catdir curdir, 't', 'scripts';
$dir    = catdir curdir, 't', 'bin' unless -d $dir;

# MyTAP source tests
{
    my $class   = 'TAP::Parser::SourceHandler::MyTAP';
    my $test    = File::Spec->catfile( 't', 'source.my' );
    my $mysql   = File::Spec->catfile( $dir, "mysql$ext" );
    my @command = qw(
      --disable-pager
      --batch
      --raw
      --skip-column-names
      --unbuffered
    );
    my $tests = {
        default_vote => 0,
        can_handle   => [
            {   name => '.my',
                meta => {
                    is_file => 1,
                    file    => { lc_ext => '.my' }
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
                config => { MyTAP => { suffix => '.foo' } },
                vote   => 1,
            },
            {   name => 'config_suffixes',
                meta => {
                    is_file => 1,
                    file    => { lc_ext => '.foo' }
                },
                config => { MyTAP => { suffix => [qw(.foo .bar)] } },
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
            {   name   => 'mysql',
                raw    => \$test,
                config => { MyTAP => { mysql => $mysql } },
                iclass => 'TAP::Parser::Iterator::Process',
                output => [ @command, '--execute', "source $test" ],
            },
            {   name   => 'config',
                raw    => $test,
                config => {
                    MyTAP => {
                        mysql     => $mysql,
                        user => 'who',
                        host     => 'f',
                        port     => 2,
                        database   => 'fred',
                    }
                },
                iclass => 'TAP::Parser::Iterator::Process',
                output => [
                    @command,
                    qw(--user who --host f --port 2 --database fred --execute),
                    "source $test"
                ],
            },
            {   name   => 'error',
                raw    => 'blah.my',
                iclass => 'TAP::Parser::Iterator::Process',
                error  => qr/^No such file or directory: blah[.]my/,
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
        my $source = TAP::Parser::Source->new;
        is( $class->can_handle($source), $default_vote,
            '... can_handle default vote'
        );
    }

    for my $test ( @{ $tests->{can_handle} } ) {
        my $source = TAP::Parser::Source->new;
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
