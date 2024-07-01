use 5.022;

use warnings;
use experimental qw< refaliasing >;
use Multi::Dispatch;

use Test::More;

multi foo ( $text, {decon=>$s}   ) {
    is $text, 'deconstructed' => 'deconstructed';
}

multi foo ( $text, \%options = {def=>'default'} ) {
    if ($text eq 'default') {
        is $text, $options{def} => 'default';
    }
    else {
        is $text, $options{text} => 'alias';
    }
}

multi foo (\%options = 7) { 'empty' }

foo('deconstructed', { decon => 'deconstructed' });
foo('aliased',       { text  => 'aliased'       });

foo('default'                                    );
ok !defined eval { foo() } => 'Empty arglist';
like $@, qr/\ANo suitable variant/  => '...with correct error message';

done_testing();

