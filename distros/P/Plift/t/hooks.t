use strict;
use warnings;
use Test::More;
use FindBin;
use Plift;


my $plift = Plift->new( paths => ["$FindBin::Bin/templates"] );

subtest 'after_load_template' => sub {

    $plift->hook( after_load_template => sub {
        my ($c, $tpl) = @_;
        $tpl->append('<after-load-template />');
    });

    $plift->hook( after_load_template => sub {
        my ($c, $tpl) = @_;
        $tpl->find('after-load-template')->text('ok');
    });

    my $doc = $plift->process('hooks');

    is $doc->find('after-load-template')->text, 'ok';
};

subtest 'before/after_process_templete' => sub {

    $plift->hook( before_process_template => sub {
        my ($c, $tpl) = @_;
        $tpl->find('#process-template')->append('<before/>');
    });

    $plift->hook( after_process_template => sub {
        my ($c, $tpl) = @_;
        $tpl->find('#process-template')->append('<after/>');
    });

    my $doc = $plift->process('hooks');

    is $doc->find('#process-template')->contents->as_html, '<before></before><after></after>';
};



done_testing;
