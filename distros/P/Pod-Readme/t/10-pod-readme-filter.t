use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

use Cwd;
use File::Compare qw/ compare_text /;
use File::Temp qw/ tempfile /;
use Path::Tiny qw/ path /;

use lib 't/lib';
use Pod::Readme::Test;

# use Pod::Readme::Test::Kit;

my $class = 'Pod::Readme::Filter';
use_ok $class;

isa_ok $prf = $class->new( output_fh => $io, ), 'Pod::Readme::Filter';

{
    can_ok( $prf, "cmd_" . $_ ) for qw/ stop start continue plugin /;

    ok $prf->in_target, 'default in target';
    is $prf->mode, 'default', 'mode';

    is $prf->base_dir->stringify, '.', 'base_dir';
}

{
    ok !$prf->cmd_stop,  'cmd_stop';
    ok !$prf->in_target, 'not in target';

    ok $prf->cmd_start, 'cmd_start';
    ok $prf->in_target, 'in target';

    ok !$prf->cmd_stop,  'cmd_stop';
    ok !$prf->in_target, 'not in target';

    ok $prf->cmd_continue, 'cmd_continue';
    ok $prf->in_target,    'in target';
};

{
    filter_lines('=pod');
    is $out, "=pod\n", 'expected output';
    is $prf->mode, 'pod', 'mode';
    ok $prf->in_target, 'in target';
    reset_out();
};

{
    filter_lines('=for readme stop');
    is $prf->mode, 'pod:for', 'mode';

    filter_lines('');
    is $prf->mode, 'pod', 'mode';

    is $out, '', 'no output';
    ok !$prf->in_target, 'not in target';

    filter_lines( 'This should not be copied.', '', 'Boop!', '' );

    is $out, '', 'no output';

    filter_lines('=for readme continue');
    is $prf->mode, 'pod:for', 'mode';

    filter_lines('');
    is $prf->mode, 'pod', 'mode';
    ok $prf->in_target, 'in target';

    is $out, '', 'no output';
};

{
    filter_lines('=for readme stop');
    is $prf->mode, 'pod:for', 'mode';

    filter_lines('');
    is $prf->mode, 'pod', 'mode';

    is $out, '', 'no output';

    ok !$prf->in_target, 'not in target';

    filter_lines( 'This should not be copied.', '', 'Boop!', '' );

    is $out, '', 'no output';

    filter_lines('=for readme start');
    is $prf->mode, 'pod:for', 'mode';

    filter_lines('');
    is $prf->mode, 'pod', 'mode';
    ok $prf->in_target, 'in target';

    is $out, '', 'no output';
};

{
    throws_ok {
        filter_lines('=for readme plugin noop::invalid');
        is $prf->mode, 'pod:for', 'mode';
        filter_lines('');
    }
    qr/Unable to locate plugin 'noop::invalid'/, 'bad plugin';

    is $prf->mode('pod'), 'pod', 'mode reset';
};

{
    filter_lines('=cut');
    is $prf->mode, 'default', 'default mode';
    filter_lines('');

    is $out, '', 'no content';

    filter_lines('=head1 TEST');
    is $prf->mode, 'pod', 'pod mode';
    filter_lines('');

    is $out, "=head1 TEST\n\n", 'expected content';
    reset_out();
};

{
    filter_lines( "This should be copied.", '' );

    is $out, "This should be copied.\n\n", 'output';
    reset_out();
};

{
    filter_lines('=begin text');
    is $prf->mode, 'target:text', 'mode';
    filter_lines( '', 'Something', '', '=end text', '' );
    is $out, '', 'no content';
    reset_out();
}

{
    filter_lines('=begin readme');
    is $prf->mode, 'pod:begin', 'mode';
    filter_lines( '', 'Something', '', '=end readme', '' );

    like $out, qr/^Something\n/, 'expected content (minimal)';
  TODO: {
        local $TODO = 'extra newline';
        is $out, "Something\n", 'expected content';
    }
    reset_out();
}

{
    filter_lines('=begin readme text');
    is $prf->mode, 'pod:begin', 'mode';
    filter_lines( '', 'Something', '', '=end readme', '' );

  TODO: {
        is $out, "=begin text\n\nSomething\n\n=end text\n\n",
          'expected content';
    }
    reset_out();
}

{
    filter_lines('=begin :readme');
    is $prf->mode, 'pod:begin', 'mode';
    filter_lines( '', 'Something', '', '=end :readme', '' );

    like $out, qr/^Something\n/, 'expected content (minimal)';
  TODO: {
        local $TODO = 'extra newline';
        is $out, "Something\n", 'expected content';
    }
    reset_out();
}

{
    can_ok $prf, qw/ parse_cmd_args /;

    lives_ok {
        my $res = $prf->parse_cmd_args( undef, 'arg1', 'no-arg2',
            'arg3="This is a string"', 'arg4=value', );

        note( explain $res);

        is_deeply $res,
          {
            'arg1' => 1,
            'arg2' => 0,
            'arg3' => 'This is a string',
            'arg4' => 'value'
          },
          'expected parsing of arguments list';

    }
    'parse_cmd_args';

    throws_ok {
        my $res =
          $prf->parse_cmd_args( [qw/ arg1 arg2 arg3 /], 'arg1', 'no-arg2',
            'arg3="This is a string"', 'arg4=value', );
    }
    qr/Invalid argument key 'arg4'/, 'bad arguments';

}

{
    can_ok $prf, qw/ depends_on /;
    is_deeply [ $prf->depends_on ], [], 'depends_on';
}

done_testing;
