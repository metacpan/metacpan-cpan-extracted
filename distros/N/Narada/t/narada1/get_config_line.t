use lib 't'; use narada1::share; guard my $guard;

use Narada::Config qw( get_config_line );


throws_ok { get_config_line('no_file') }        qr/no such file/i,
    'no such file';

Echo('config/empty', "\n");
is get_config_line('empty'), q{}, 'empty with \n';
Echo('config/empty-n', q{});
is get_config_line('empty-n'), q{}, 'empty without \n';
Echo('config/test', "test\n");
is get_config_line('test'), 'test', 'single line with \n';
Echo('config/test-n', "test");
is get_config_line('test-n'), 'test', 'single line without \n';
Echo('config/test_multi_newline', "test\n  \n  \n");
is get_config_line('test_multi_newline'), 'test', 'single line with multi newlines';
Echo('config/test_multi_space', "test\n  \n  ");
is get_config_line('test_multi_space'), 'test',   'single line with multi newlines and spaces';
Echo('config/test_multi', "test\ntest2");
throws_ok { get_config_line('test_multi') }         qr/more than one line/,
    'multi line';


done_testing();


sub Echo {
    my ($file, $data) = @_;
    open my $fh, '>', $file or die "open: $!";
    print {$fh} $data;
    close $fh or die "close: $!";
    return;
}
