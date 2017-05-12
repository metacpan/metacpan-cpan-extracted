use strict;
use warnings;
use File::Spec;
use File::Temp qw(tempdir);
use Log::Log4perl;
use MojoX::Log::Log4perl::Tiny;
use Test::Deep;
use Test::More;

my $tmpdir = tempdir(CLEANUP => 1);
my $logfile = File::Spec->catfile($tmpdir, 'file.log');
my $conf = qq{
    log4perl.logger.Hoge = DEBUG, File
    log4perl.logger.Fuga = ERROR, File
    log4perl.appender.File = Log::Log4perl::Appender::File
    log4perl.appender.File.filename = $logfile
    log4perl.appender.File.layout   = PatternLayout
    log4perl.appender.File.layout.ConversionPattern = [\%p] %C - %m%n
};

Log::Log4perl::init(\$conf);

subtest 'Test instance' => sub {
    my $logger = MojoX::Log::Log4perl::Tiny->new(logger => Log::Log4perl->get_logger('Hoge'));

    isa_ok $logger, 'MojoX::Log::Log4perl::Tiny';
    isa_ok $logger->logger,       'Log::Log4perl::Logger';
    is $logger->level,            'debug';
    is $logger->max_history_size, 5;
    is_deeply $logger->history, [];
    isa_ok $logger->format, 'CODE';
    like $logger->format->(12345678, 'AAA', 'BBB', 'CCC'), qr{
        \A
        \[ \w{3} \s \w{3} \s+ \d+ \s \d{2}\:\d{2}\:\d{2} \s \d{4} \] \s
        \[AAA\] \s
        BBB \n
        CCC \n
        \z
    }msix;
};

subtest 'Test log methods' => sub {
    my $logger = MojoX::Log::Log4perl::Tiny->new(logger => Log::Log4perl->get_logger('Hoge'));

    can_ok $logger, $_ for qw( debug info warn error fatal );
};

subtest 'Test is_level' => sub {
    my $logger = MojoX::Log::Log4perl::Tiny->new(
        logger => Log::Log4perl->get_logger('Hoge'),
        level  => 'error',
    );

    subtest 'Without MOJO_LOG_LEVEL' => sub {
        ok !$logger->is_level('warn'), 'warn is not logging level';
        ok $logger->is_level('error'), 'error is logging level';
    };

    subtest 'With MOJO_LOG_LEVEL' => sub {
        local $ENV{MOJO_LOG_LEVEL} = 'info';

        ok !$logger->is_level('debug'), 'debug is not logging level';
        ok $logger->is_level('info'), 'info is logging level';
    };
};

subtest 'Test logging' => sub {
    my $logger = MojoX::Log::Log4perl::Tiny->new(
        logger => Log::Log4perl->get_logger('Hoge'),
        level  => 'error',
    );

    subtest 'warn is not logged' => sub {
        $logger->warn('AAAAA');

        my $content = slurp_file($logfile);

        is $content, '';
    };

    subtest 'error is logged' => sub {
        $logger->error('BBBBB');
        $logger->error('BBBBB');

        my $content = slurp_file($logfile);

        is $content, <<END;
[ERROR] main - BBBBB
[ERROR] main - BBBBB
END
    };
};

subtest 'Test history' => sub {
    my $logger = MojoX::Log::Log4perl::Tiny->new(
        logger           => Log::Log4perl->get_logger('Hoge'),
        level            => 'error',
        max_history_size => 3,
    );
    $logger->error("CCCC$_") for 1 .. 5;

    my $content = slurp_file($logfile);

    is $content, <<END;
[ERROR] main - BBBBB
[ERROR] main - BBBBB
[ERROR] main - CCCC1
[ERROR] main - CCCC2
[ERROR] main - CCCC3
[ERROR] main - CCCC4
[ERROR] main - CCCC5
END
    is @{ $logger->history }, 3;
    cmp_deeply $logger->history,
        [
        [ re('^\d+$'), 'error', 'CCCC3', ],
        [ re('^\d+$'), 'error', 'CCCC4', ],
        [ re('^\d+$'), 'error', 'CCCC5', ],
        ];
};

done_testing;

sub slurp_file {
    my $file = shift;
    local $/ = undef;
    open my $fh, '<', $file or die "Failed reading file: $!";
    <$fh>;
}
