package TAP::Formatter::BambooExtended;

use strict;
use warnings;

use parent qw(TAP::Formatter::Console);

use XML::LibXML;
use Encode qw(is_utf8 decode);
use HTML::Entities qw(encode_entities);
use Cwd ();
use File::Path ();

use TAP::Formatter::BambooExtended::Session;

our $VERSION = '1.01';

sub _initialize {
    my ($self, $arg_for) = @_;

    # variables that we use for ourselves
    $self->{'_test_results'} = [];

    return $self->SUPER::_initialize($arg_for || {});
}

sub add_test_results {
    my ($self, $results) = @_;
    push(@{$self->{'_test_results'}}, $results) if defined($results);
    return;
}

sub open_test {
    my ($self, $test, $parser) = @_;
    my $session = TAP::Formatter::BambooExtended::Session->new({
        'name'      => $test,
        'formatter' => $self,
        'parser'    => $parser,
    });
    return $session;
}

sub summary {
    my ($self, $aggregate) = @_;

    my $output_path = Cwd::cwd() . "/prove_db";
    $output_path = $ENV{'FORMATTER_OUTPUT_DIR'} if defined($ENV{'FORMATTER_OUTPUT_DIR'});
    File::Path::make_path($output_path) unless (-e $output_path);

    for my $test (@{$self->{'_test_results'}}) {
        my $test_name = $test->{'description'};
        $test_name =~ s/^[\.\/\\]+//g;
        $test_name =~ s/\/|\\/-/g;
        $test_name =~ s/\./_/g;
        $self->_save_results($test, "${output_path}/${test_name}.xml");
    }

    return if $self->silent();

    print { $self->stdout } "ALL DONE\n";
    return;
}

sub _save_results {
    my ($self, $test, $file_path) = @_;
    my $doc = XML::LibXML::Document->createDocument('1.0', 'UTF-8');

    my $testsuite_name = $test->{'description'};
    $testsuite_name =~ s/^[\.\/\\]+//g;
    $testsuite_name =~ s/\/|\\/-/g;
    $testsuite_name =~ s/\./_/g;
    $testsuite_name =~ s/^\s+|\s+$//g;

    my $suite = $doc->createElement('testsuite');
    $suite->setAttribute('name', $testsuite_name);
    $suite->setAttribute('errors', $test->{'parse_errors'});
    $suite->setAttribute('failures', $test->{'failed'});
    $suite->setAttribute('tests', $test->{'tests_run'});
    $suite->setAttribute('time', $test->{'end_time'} - $test->{'start_time'});

    my $skipped = 0;
    for my $result (@{$test->{'results'}}) {
        next unless ($result->is_test() || $result->is_bailout());

        # bump the skip count?
        ++$skipped if ($result->has_skip());

        # give it a name if there isn't one
        my $testcase_name = $result->description();

        # clean up invalid characters
        $testcase_name = decode("UTF-8", $testcase_name) unless is_utf8($testcase_name);
        $testcase_name = encode_entities($testcase_name);

        # trim trailing/leading space
        $testcase_name =~ s/^\s+|\s+$//g;

        my $testcase = $doc->createElement('testcase');
        $testcase->setAttribute('name', $testcase_name || "test ${\$result->number()}");

        my @fail_reasons = _fail_reasons($result);
        if (scalar(@fail_reasons)) {
            my $failure = $doc->createElement('failure');
            my $fail_description = '';

            $fail_description .= "Fail reason(s):\n";
            for my $fail (@fail_reasons) {
                $fail_description .= "    $fail\n";
            }

            my $explanation = $result->explanation();
            if (defined($explanation)) {
                chomp($explanation);
                $explanation =~ s/^\s+|\s+$//g;
                $explanation = decode("UTF-8", $explanation) unless is_utf8($explanation);
                $fail_description .= "Explanation:\n    " . $explanation . "\n" if ($explanation);
            }

            my $output = $result->raw();
            if (defined($output)) {
                chomp($output);
                $output =~ s/^\s+|\s+$//g;
                $output = decode("UTF-8", $output) unless is_utf8($output);
                $fail_description .= "Test output:\n    " . $output . "\n" if ($output);
            }

            $failure->appendChild(XML::LibXML::CDATASection->new($fail_description));
            $testcase->appendChild($failure);
        }

        $suite->appendChild($testcase);
    }

    $suite->setAttribute('skipped', $skipped);
    $doc->setDocumentElement($suite);
    $doc->toFile($file_path, 2);

    return;
}

sub _fail_reasons {
    my $result = shift;
    my @reasons = ();

    if (!$result->is_actual_ok()) {
        push(@reasons, "failed test");
    }
    if ($result->todo_passed()) {
        push(@reasons, "unexpected TODO passed");
    }
    if ($result->is_unplanned()) {
        push(@reasons, "unplanned test");
    }

    return wantarray ? @reasons : \@reasons;
}

1;

=encoding utf8

=head1 NAME

TAP::Formatter::BambooExtended - Harness output delegate for Atlassian's Bamboo CI server

=head1 SYNOPSIS

On the command line, with F<prove>:

    prove --formatter TAP::Formatter::BambooExtended ...

Or, in your own scripts:

    use TAP::Harness;
    my $harness = TAP::Harness->new({
        formatter_class => 'TAP::Formatter::BambooExtended',
        merge => 1,
    });
    $harness->runtests(@tests);

=head1 DESCRIPTION

C<TAP::Formatter::BambooExtended> provides JUnit output formatting for C<TAP::Harness>,
which can be used in Atlassian's Bamboo CI server or any other CI server that
looks for JUnit files.

This module is based on TAP::Formatter::Bamboo by Piotr Piatkowski
<pp@idea7.pl>, main differences are:

=over

=item Resulting XML is saved as one output file per source test script.

=item Each test gets its own result line in the JUnit output rather than
grouping all the tests from one test script into one result.

=item A summary test result is appended to indicate if there were any problems
with the test script itself outside of individual tests.

=item Output of failed tests are attached to the test that failed AND the test
script itself. Each test script will create one JUnit compatible test result
file. The test result file names will match the full path and file name of the
test script. By default these files are created in a directory called
C<prove_db> that is created in your current working directory. This can be
changed by setting the environment variable C<FORMATTER_OUTPUT_DIR> to a
relative or absolute path.

=back

By way of example, when you run a test like this:

    prove -l --formatter TAP::Formatter::BambooExtended

You might see these results on the command line:

    PASS t/00-load.t
    ALL DONE

Then you'll see a new directory called C<$ENV{'FORMATTER_OUTPUT_DIR'}>. By
default, this directory will be created as C<prove_db> in your current working
directory. In the output directory you'll see one file for each test script,
like this:

    > ls
    t-00-load_t.xml

In that file you will see one test output for the file itself, named after the
file. You'll also see one test output for each individual test in the test
script. So if your test script has twenty C<ok> statements, you'll have twenty-
one tests in Bamboo -- one for the file itself and then one for each C<ok>
statement. This makes it easier to track exactly which tests are failing with
Bamboo.

=head1 AUTHOR

Paul Lockaby <plockaby@cpan.org>

Piotr Piatkowski <pp@idea7.pl> (original C<TAP::Formatter::Bamboo>)

Graham TerMarsch <cpan@howlingfrog.com> (original C<TAP::Formatter::JUnit>)

=head1 COPYRIGHT

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<TAP::Formatter::Bamboo>,
L<TAP::Formatter::JUnit>,
L<TAP::Formatter::Console>,
L<http://confluence.atlassian.com/display/BAMBOO/JUnit+parsing+in+Bamboo>.

=cut
