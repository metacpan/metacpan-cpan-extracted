#!perl
use 5.008001; use utf8; use strict; use warnings;

use Test::More;
use version;
use only 'Rosetta::Validator' => '0.71.0-';

my $_total_possible = Rosetta::Validator->total_possible_tests();
$_total_possible += 4; # tests 1-4 are that 2 core modules compile and are correct versions
$_total_possible += 1; # test 5 is that SQL::Validator->main() doesn't die
plan( 'tests' => $_total_possible );

######################################################################
# First ensure the modules to test will compile, are correct versions:

use_ok( 'Rosetta::Engine::Generic' );
is( $Rosetta::Engine::Generic::VERSION, qv('0.22.0'), 'Rosetta::Engine::Generic is the correct version' );

use_ok( 'Rosetta::Engine::Generic::L::en' );
is( $Rosetta::Engine::Generic::L::en::VERSION, qv('0.14.0'), 'Rosetta::Engine::Generic::L::en is the correct version' );

######################################################################
# Here are some utility methods:

sub print_result {
    my ($result) = @_;
    my ($feature_key, $feature_status, $feature_desc_msg, $val_error_msg, $eng_error_msg)
        = @{$result}{'FEATURE_KEY', 'FEATURE_STATUS', 'FEATURE_DESC_MSG', 'VAL_ERROR_MSG', 'ENG_ERROR_MSG'};
    my $result_str
        = $feature_key . ' - ' . object_to_string( $feature_desc_msg )
          . ($val_error_msg ? ' - ' . object_to_string( $val_error_msg ) : q{})
          . ($eng_error_msg ? ' - ' . object_to_string( $eng_error_msg ) : q{});
    if ($feature_status eq 'PASS') {
        pass( $result_str ); # prints "ok N - $result_str\n"
    }
    elsif ($feature_status eq 'FAIL') {
        fail( $result_str ); # prints "not ok N - $result_str\n"
    }
    else { # $feature_status eq 'SKIP'
        SKIP:
        {
            skip( $result_str, 1 ); # prints "ok N # skip $result_str\n"
            fail( q{} ); # this text will NOT be output; call required by skip()
        }
    }
}

sub object_to_string {
    my ($message) = @_;
    if (ref $message and UNIVERSAL::isa( $message, 'Rosetta::Interface' )) {
        $message = $message->get_error_message();
    }
    if (ref $message and UNIVERSAL::isa( $message, 'Locale::KeyedText::Message' )) {
        my $translator = Locale::KeyedText->new_translator( ['Rosetta::Validator::L::',
            'Rosetta::Engine::Generic::L::', 'Rosetta::Utility::SQLBuilder::L::',
            'Rosetta::Utility::SQLParser::L::', 'Rosetta::L::', 'Rosetta::Model::L::'], ['en'] );
        my $user_text = $translator->translate_message( $message );
        return q{internal error: can't find user text for a message: }
            . $message->as_string() . ' ' . $translator->as_string()
            if !$user_text;
        return $user_text;
    }
    return $message; # if this isn't the right kind of object
}

sub import_setup_options {
    my ($setup_filepath) = @_;
    my $err_str = "can't obtain test setup specs from Perl file '$setup_filepath'; ";
    my $setup_options = do $setup_filepath;
    if (ref $setup_options ne 'HASH') {
        if (defined $setup_options) {
            $err_str .= "result is not a hash ref, but '$setup_options'";
        }
        elsif ($@) {
            $err_str .= "compilation or runtime error of '$@'";
        }
        else {
            $err_str .= "file system error of '$!'";
        }
        die "$err_str\n";
    }
    die $err_str . "result is a hash ref that contains no elements\n"
        if !keys %{$setup_options};
    eval {
        Rosetta::Validator->validate_connection_setup_options( $setup_options ); # dies on problem
    };
    if (my $exception = $@) {
        if ($exception->get_message_key() ne 'ROS_I_V_CONN_SETUP_OPTS_NO_ENG_NM') {
            die $err_str . 'result is a hash ref having invalid elements; '
                . object_to_string( $exception ) . "\n";
        }
    }
    $setup_options->{'data_link_product'} ||= {};
    # Shouldn't be an Engine set already, but if there is, we override it.
    $setup_options->{'data_link_product'}->{'product_code'} = 'Rosetta::Engine::Generic';
    return $setup_options;
}

######################################################################
# Now perform the actual tests:

my $setup_filepath = (shift @ARGV) || 't_setup.pl'; # set from first command line arg; '0' means use default name
my $trace_to_stdout = (shift @ARGV) ? 1 : 0; # set from second command line arg

my $setup_options = eval {
    return import_setup_options( $setup_filepath );
};
if (my $exception = $@) {
    warn "# NOTICE: could not load any test setup options from file '$setup_filepath': $exception";
    warn "# NOTICE: defaulting to test with a file-based SQLite database named 'test'\n";
    $setup_options = {
        'data_storage_product' => {
            'product_code' => 'SQLite',
            'is_file_based' => 1,
        },
        'data_link_product' => {
            'product_code' => 'Rosetta::Engine::Generic',
        },
        'catalog_instance' => {
            'file_path' => 'test',
        },
    };
    -e 'test' and unlink( 'test' ); # remove any existing file from previous run of this test
}

my $trace_fh = $trace_to_stdout ? \*STDOUT : undef;

my $test_results = eval {
    return Rosetta::Validator->main( $setup_options, $trace_fh );
};
if (my $exception = $@) {
    # errors in test suite itself, or core modules, it seems
    fail( 'Rosetta::Validator->main() execution - ' . object_to_string( $exception ) );
} else {
    # test suite itself seems to be fine
    pass( 'Rosetta::Validator->main() execution' );
    for my $result (@{$test_results}) {
        print_result( $result );
    }
}

######################################################################

1;
