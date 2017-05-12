#!/usr/bin/env perl
use warnings;
use strict;
use PerlIO::via::Pipe 'set_io_pipe';
use Text::Pipe 'PIPE';
use Test::More tests => 1;
my $pipe = PIPE('Trim') | PIPE('Uppercase') | PIPE('Repeat', times => 2);
set_io_pipe $pipe;
open my $fh, '<:via(Pipe)', $0 or die "can't open $0: $!\n";
chomp(my @result = <$fh>);
close $fh or die "can't close $0: $!\n";
splice(@result, 10);
is_deeply(
    \@result,
    [   '#!/USR/BIN/ENV PERL',
        '#!/USR/BIN/ENV PERL',
        'USE WARNINGS;',
        'USE WARNINGS;',
        'USE STRICT;',
        'USE STRICT;',
        'USE PERLIO::VIA::PIPE \'SET_IO_PIPE\';',
        'USE PERLIO::VIA::PIPE \'SET_IO_PIPE\';',
        'USE TEXT::PIPE \'PIPE\';',
        'USE TEXT::PIPE \'PIPE\';',
    ],
    'read from filehandle via pipe'
);
