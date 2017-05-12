use Test::More;

use Template::Directive::XSSAudit;
use Template;
use List::Util qw(sum);

my $TT2 = Template->new({
    FACTORY => 'Template::Directive::XSSAudit'
});
our @RESPONSES = ();

Template::Directive::XSSAudit->good_filters([ 'html', 'uri' ]);
Template::Directive::XSSAudit->on_error( sub {
    push @RESPONSES, [ @_ ];
});

my @tests = (
    {
        count => 2,
        code  => sub {
            my $t = "one variable - no filter";

            my $input = "[% user.email %]";

            @RESPONSES = ();

            $TT2->process(\$input,{},\my $out) || die $TT2->error();

            is( scalar @RESPONSES, 1, "$t - num responses is correct");
            is( $RESPONSES[0][0]->{variable_name}, 'user.email', "$t - variable name in response is correct");
        },
    },
    {
        count => 2,
        code  => sub {
            my $t = "one variable - filter not listed in good list";

            my $input = "[% user.email | format('%d') %]";

            @RESPONSES = ();

            $TT2->process(\$input,{},\my $out) || die $TT2->error();

            is( scalar @RESPONSES, 1, "$t - num responses is correct");
            is( $RESPONSES[0][0]->{variable_name}, 'user.email', "$t - variable name in response is correct");
        },
    },
    {
        count => 2,
        code  => sub {
            my $t = "one variable - after a literal";

            my $input = "[% 'Mr.' _ user.email %]";

            @RESPONSES = ();

            $TT2->process(\$input,{},\my $out) || die $TT2->error();

            is( scalar @RESPONSES, 1, "$t - num responses is correct");
            is( $RESPONSES[0][0]->{variable_name}, 'user.email', "$t - variable name in response is correct");
        },
    },
    {
        count => 2,
        code  => sub {
            my $t = "one variable - before a literal";

            my $input = "[% user.email _ 'number 2' %]";

            @RESPONSES = ();

            $TT2->process(\$input,{},\my $out) || die $TT2->error();

            is( scalar @RESPONSES, 1, "$t - num responses is correct");
            is( $RESPONSES[0][0]->{variable_name}, 'user.email', "$t - variable name in response is correct");
        },
    },
    {
        count => 2,
        code  => sub {
            my $t = "one variable - between literals";

            my $input = "[% 'number 1' _ user.email _ 'number 2' %]";

            @RESPONSES = ();

            $TT2->process(\$input,{},\my $out) || die $TT2->error();

            is( scalar @RESPONSES, 1, "$t - num responses is correct");
            is( $RESPONSES[0][0]->{variable_name}, 'user.email', "$t - variable name in response is correct");
        },
    },
    {
        count => 3,
        code  => sub {
            my $t = "the three types, ok, fail, not good";

            my $input = "[% user.fname | html %] [% user.lname %] [% user.email | format('%d') %]";

            @RESPONSES = ();

            $TT2->process(\$input,{},\my $out) || die $TT2->error();

            is( scalar @RESPONSES, 2, "$t - num responses is correct");
            is( $RESPONSES[0][0]->{variable_name}, 'user.lname', "$t - variable name in failure num 1 is correct");
            is( $RESPONSES[1][0]->{variable_name}, 'user.email', "$t - variable name in failure num 2 is correct");
        },
    },

);

plan tests =>  sum map { $_->{count} } @tests;

$_->{code}->() for @tests;
