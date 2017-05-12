use Test::More;

use Template::Directive::XSSAudit;
use Template;

my @tests = (
    sub {
        my $t = "Callback parameter format";

        my $TT2 = Template->new({ FACTORY => 'Template::Directive::XSSAudit' });

        my $input = "[% user.email | html %]";

        my $RESPONSE;
        Template::Directive::XSSAudit->on_filtered( sub {
            $RESPONSE = \@_;
        });

        $TT2->process(\$input,{},\my $out) || die $TT2->error();

        Template::Directive::XSSAudit->on_filtered(
            $Template::Directive::XSSAudit::DEFAULT_OK_HANDLER,
        );

        my $param = $RESPONSE->[0];
        my $expected_param = {
          'filtered_by' => [ 'html' ],
          'file_name' => 'input text',
          'file_line' => '1',
          'variable_name' => 'user.email'
        };
        my @expected_keys = sort qw( variable_name filtered_by file_name file_line );
        my @has_keys      = sort keys %$param;

        is( scalar @$RESPONSE, 1, "$t - callback was passed only one parameter" );
        is( ref($param), "HASH", "$t - parameter is a hash ref" );
        is_deeply( \@has_keys, \@expected_keys, "$t - expected hash keys were provided" );
        is_deeply( $param, $expected_param, "$t - expected hash values were provided" );
        
    },
    sub {
        my $t = "Default event handler is installed";

        is(
            $Template::Directive::XSSAudit::DEFAULT_OK_HANDLER,
            Template::Directive::XSSAudit->on_filtered(),
            $t
        );

    },
    sub {
        my $t = "Setting event handler - coderef";

        my $code = sub { 1; };
        Template::Directive::XSSAudit->on_filtered( $code );
        is( $code, Template::Directive::XSSAudit->on_filtered, $t );

    },
    sub {
        my $t = "Setting event handler - set to string (should die)";

        eval {
            Template::Directive::XSSAudit->on_filtered( "asdf" );
        };
        my $err = $@;
        ok( $err, $t );

    },
    sub {
        my $t = "Event handler stays the same when reading it";

        my $code1 = sub { 1; };
        Template::Directive::XSSAudit->on_filtered( $code1 );

        my $code2 = Template::Directive::XSSAudit->on_filtered();
        is( $code1, $code2, $t );

    },
    sub {
        my $t = "Get and set operation at the same time";

        my $code1 = sub { 9999; };
        my $code2 = Template::Directive::XSSAudit->on_filtered( $code1 );
        is( $code1, $code2, $t );

    },

);

plan tests => scalar @tests + 3;

$_->() for @tests;
