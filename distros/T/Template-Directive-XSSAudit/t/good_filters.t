use Test::More;

use Template::Directive::XSSAudit;

my @tests = (
    sub {
        my $t = "Default good filters are installed";

        is_deeply(
            [ @Template::Directive::XSSAudit::DEFAULT_GOOD_FILTERS ],
            Template::Directive::XSSAudit->good_filters(),
            $t
        );

    },
    sub {
        my $t = "Setting good filters - arrayref";

        my $array = [ 'html', 'uri', 'html_attribute' ];
        Template::Directive::XSSAudit->good_filters( $array );
        is_deeply( $array, Template::Directive::XSSAudit->good_filters, $t );

    },
    sub {
        my $t = "Setting good filters - set to string (should die)";

        eval {
            Template::Directive::XSSAudit->good_filters( "asdf" );
        };
        my $err = $@;
        ok( $err, $t );

    },
    sub {
        my $t = "Good filters stays the same when reading it";

        my $array1 = [ 'a', 'b' ];
        Template::Directive::XSSAudit->good_filters( $array1 );

        my $array2 = Template::Directive::XSSAudit->good_filters();
        is_deeply( $array1, $array2, $t );

    },
    sub {
        my $t = "Get and set operation at the same time";

        my $array1 = [ 'c', 'd' ];
        my $array2 = Template::Directive::XSSAudit->good_filters( $array1 );
        is_deeply( $array1, $array2, $t );

    },

);

plan tests => scalar @tests;

$_->() for @tests;
