package TAP::Formatter::Bamboo;

use Moose;
use MooseX::NonMoose;
use XML::LibXML;
use Encode qw(:all);

use TAP::Formatter::Bamboo::Session;

extends qw(
    TAP::Formatter::Console
);

our $VERSION = '0.04';

has _test_results => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

sub open_test {
    my ($self, $test, $parser) = @_;
    my $session = TAP::Formatter::Bamboo::Session->new( {
        name            => $test,
        formatter       => $self,
        parser          => $parser,
    } );
    return $session;
}

sub summary {
    my ($self, $aggregate) = @_;

    $self->_save_results( $ENV{TAP_FORMATTER_BAMBOO_OUTFILE} || 'results.xml');

    return if $self->silent();
     
    print { $self->stdout } "ALL DONE\n";
}

sub _save_results {
    my( $self, $file_path ) = @_;

    my $doc = XML::LibXML::Document->createDocument('1.0', 'UTF-8');
    $doc->setStandalone( 1 );
    my $suites = $doc->createElement( 'testsuites' );

    for my $test ( @{$self->_test_results} ) {

        my $suite = $doc->createElement( 'testsuite' );
        $suite->setAttribute( 'name', $test->{description} );
        $suite->setAttribute( 'errors', $test->{parse_errors} );
        $suite->setAttribute( 'failures', $test->{failed} );
        $suite->setAttribute( 'tests', $test->{tests_run} );

        my $output = $doc->createElement( 'system-out' );
        $suite->appendChild( $output );

        my $testcase = $doc->createElement( 'testcase' );
        $testcase->setAttribute( 'name', $test->{description} );
        $testcase->setAttribute( 'time', $test->{end_time} - $test->{start_time} );

        $suite->appendChild( $testcase );

        if( $test->{fail_reasons} ) {
            my $failure = $doc->createElement( 'failure' );
            my $fail_description = '';
            $fail_description .= "Fail reason(s):\n";
            for my $fail ( @{$test->{fail_reasons}} ) {
                $fail_description .= "    $fail\n";
            }
            $fail_description .= "Test output:\n" . $test->{output} . "\n";

            if (not is_utf8($fail_description)) {

                # this will quietly substitute any malformed UTF-8 data it finds
                # if you'd need to make it more facist, pass Encode::FB_CROAK as
                # a third parameter
                $fail_description = encode("UTF-8", $fail_description);
            }

            $failure->appendChild( XML::LibXML::CDATASection->new( $fail_description ) );
            $testcase->appendChild( $failure );
        }

        $suite->appendChild( $testcase );
        $suites->appendChild( $suite );
    }

    $doc->setDocumentElement( $suites );
    $doc->toFile( $file_path, 2 );
    return;
}
1;

=encoding utf8

=head1 NAME

TAP::Formatter::Bamboo - Harness output delegate for Atlassian's Bamboo CI server

=head1 SYNOPSIS

On the command line, with F<prove>:

  prove --formatter TAP::Formatter::Bamboo ...

Or, in your own scripts:

  use TAP::Harness;
  my $harness = TAP::Harness->new( {
      formatter_class => 'TAP::Formatter::Bamboo',
      merge => 1,
  } );
  $harness->runtests(@tests);

=head1 DESCRIPTION

C<TAP::Formatter::Bamboo> provides JUnit output formatting for C<TAP::Harness>,
which can be used in Atlassian's Bamboo CI server.

This module is based on TAP::Formatter::JUnit by Graham TerMarsch
<cpan@howlingfrog.com>, main differences are:

=over

=item * if environment variable TAP_FORMATTER_BAMBOO_OUTFILE is present then it
will be used as filepath for output XML (otherwise "results.xml file will be
created in current directory)

=item * information about passing/failing tests is put to the STDOUT/STDERR respectively,
so it can be watched in Bamboo's build logs (also live during build)

=item * output of failed tests is saved in 'failure' tag, as Bamboo doesn't care about
'system-out' and 'system-err' tags (but shows content of 'failure')

=item * short information about failure reason is put in the first line of 'failure' tag

=back

=head1 METHODS

=over

=item B<open_test($test, $parser)>

Over-ridden C<open_test()> method.

Creates a C<TAP::Formatter::Bamboo::Session> session, instead of a console
formatter session.

=item B<summary($aggregate)>

Save resulting XML in results.xml file.

=back

=head1 AUTHOR

Piotr Piatkowski <pp@idea7.pl>

Graham TerMarsch <cpan@howlingfrog.com> (original C<TAP::Formatter::JUnit>)

Credits from the original module:

Many thanks to Andy Armstrong et al. for the B<fabulous> set of tests in
C<Test::Harness>; they became the basis for the unit tests here.

Other thanks go out to those that have provided feedback, comments, or patches:

  Mark Aufflick
  Joe McMahon
  Michael Nachbaur
  Marc Abramowitz
  Colin Robertson
  Phillip Kimmey
  Dave Lambley

=head1 COPYRIGHT

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<TAP::Formatter::JUnit>,
L<TAP::Formatter::Console>,
L<http://confluence.atlassian.com/display/BAMBOO/JUnit+parsing+in+Bamboo>.

=cut
