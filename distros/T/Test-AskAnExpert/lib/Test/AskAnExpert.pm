package Test::AskAnExpert;

use strict;
use warnings;

our $VERSION = '0.03';
my $CLASS = __PACKAGE__;

use base 'Test::Builder::Module';
use Test::AskAnExpert::Question;
use Test::AskAnExpert::Interface;

our @EXPORT_OK = qw(ask answer is_yes is_no);


=head1 NAME

Test::AskAnExpert - Automatically test things that require Human Intelligence (by asking someone). 

=head1 SYNOPSIS

  use Test::AskAnExpert import => [qw(is_yes is_no ask answer)],tests => 7;

Start up the Human Interface:

  Test::AskAnExpert->initialize("Test::AskAnExpert::Interface::Subclass",'Subclass args'...);
  
Synchronously submit and wait for a yes or a no answer:

  is_yes("Can you read this captcha?");
  is_no("Is this a quality CPAN distribution?");

Same, but with timeouts: (In seconds)

  is_yes("Can you read this captcha very fast?",10);
  is_no("Is the skew-t log-p diagram located at /images/charts/stlp.png correct for the 12Z GFS data?",10);

Submit an asynchronous question:

  # Not a good example question because its not yes/no, but answering will take about 70000 years
  $question_object = ask("What is the meaning of life, the universe, and everything?");

Check the answer:

  answer($question_object,'yes');
  answer($question_object,'no');

Checking the answer also accepts a timeout parameter:

  answer($question_object,'yes',10);

=head1 DESCRIPTION

Test::AskAnExpert aims to fill a hole in the current set of testing tools by
integrating an automated method for asking testing questions that computers
cannot easily answer like: "Is this meteorologically sound?" or "Does this
output fit into category x?" or "Is this distrobution quality?" and still
allow standard test tools to work properly in terms of generating reports,
locking the doors if the tests aren't passing, etc. etc.

Test::AskAnExpert is built on Test::Builder and will play nice with Test::Simple,
Test::More, and anything they play nice with. To provide correct answers to
conceptual questions we cheat by asking people instead of actually solving a
Very Hard Problem regarding machine intelligence. This requires a little more
overhead as we need to set up a way to talk to people, and provide them some
(but not too much) time to tender an answer.

=head2 Test::AskAnExpert->initialize($interface_name, @interface_params)

The initialize function must be called before using any of Test::AskAnExpert's
functions to load a Human Interface, otherwise the default (skip all tests) will
load. To specify something other than the default pass a subclass of 
Test::AskAnExpert::Interface. @interface_params are any Interface specific
parameters, consult the documentation of the Interface you're using for what 
(if anything) to pass here.

On error it returns false, allowing you to try to load multipule Interfaces in a
short-circuit style before giving up:

  Test::AskAnExpert->initialize("Test::AskAnExpert::Interface::Custom::InHouse::System")
    or Test::AskAnExpert->initialize("Test::AskAnExpert::CGI")
    or skip_all("No good interfaces available");

Note that skip_all isn't required, if no Interface is specified Test::AskAnExpert will
use a default Interface that simply skips if its asked to test anything.

=cut

#### sub initialize ####
# Loads an interface, but can be subclassed. Places the interface in
# the classes _interface variable. There should only ever be one running
# interface at a time, dealing with multiple IO for the same purpose is
# obnoxious and adds unneeded complexity.
sub initialize {
  my ($class,$interface_name,@interface_params) = @_;

  eval " require $interface_name ";

  return undef if $@;

  my $interface;

  {
    no strict 'refs';
    $interface = \${ "$class\::_interface" };
  }

  $$interface = $interface_name->load(@interface_params);

  return 1 if defined($$interface);
  $$interface = Test::AskAnExpert::Interface->load();
  return undef;
}

#### sub _get_interface ####
# Internal accessor for the current interface, so that inherited functions work
# right.

sub _get_interface {
  my $class = shift;

  no strict 'refs';
  return ${ "$class\::_interface" };
}

=head2 is_yes/is_no ($question, $name, [$Timeout])

Test::AskAnExpert provides two methods for the programmers who don't want to muck
with asynchronous interaction, is_yes and is_no. is_yes passes when the question asked
is answered yes, is_no the opposite. They are slim wrappers arround ask and
answer, taking a plain text question, test name, and optionally a timeout
in the same way.

=cut

#### subs is_yes and is_no ####
# Thin wrappers arround ask and answer
# they handle all the mucking about with the question object
# and making sure the expected answer is yes or no.
sub is_yes {
  my ($question,$name,$timeout) = @_;
  my $Qobj = ask($question,$name);
  answer($Qobj,'yes',$timeout);
}

sub is_no {
  my ($question,$name,$timeout) = @_;
  my $Qobj = ask($question,$name);
  answer($Qobj,'no',$timeout);
}

=head2 ask($question_text, $test_name)

B<NOTE:> This does not actually run any tests!

ask is a very self explanatory function: it sends a question to be answered by
whatever is on the other side of the Interface (Test::AskAnExpert::Pass anyone?). 
It returns a Test::AskAnExpert::Question object which is later used for retrieving
the answer. Since this is the factory for Test::AskAnExpert::Question objects it also
optionally takes the test name the question is bound to, though this can
be changed with the C<name> method. If there was an error in asking the question
the object will have its skip parameters set so when C<answer> is called on it
the test will be skipped. Read the L<Test::AskAnExpert::Question> documentation if you'd
like to query the object your self and do something other than skip the test
(like re-initialize to a different Interface and ask again, or BAIL_OUT).

$QuestionText should be plaintext with no markup, the Interface is expected to
format it nicely for the human on the other side (e.g. if its an HTML interface
give them nice links) to make their life a little easier.

=cut

#### sub ask ####
# This sub takes a text question and a name for it and sends it to the
# interface. If the interface has errors or does something unexpected it will
# flag the question to skip and provide any error message the interface has,
# which will then hit the end user as a skip reason.
sub ask {
  my ($question,$name) = @_;

  # Ask the interface
  my $interface = $CLASS->_get_interface();
  my $Qobj = $interface->submit($question,$name);

  return $Qobj if defined $Qobj and $Qobj->isa('Test::AskAnExpert::Question');

  # Error! The interface has failed us! Skip this question when someone
  # looks for the answer.
  $Qobj = Test::AskAnExpert::Question->new(question=>$question,id=>"skip",name=>$name);
  $Qobj->skip("Interface Error: ".$interface->err);
  return $Qobj;
}

=head2 answer($question_obj, $expected, [$timeout])

answer takes a previously asked question and waits until an answer is ready
or optionally $Timeout seconds have passed and then executes typical test
magic.

$QuestionObj should be a Test::AskAnExpert::Question object returned by ask or
correctly constructed otherwise. $Expected can be any capitalization of yes or
no and will be checked against the answer in the question for the test.

=cut

#### sub answer ####
# This sub takes in a question object, the expected answer, and a timeout in
# seconds and polls the interface instance for an answer, skipping the test
# on encountering errors (bad question object, error retrieving answer,
# question object specified skip) and otherwise does the usual test
# ok or diag to print any message passed through the human interface if an
# unexpected answer was recieved. This assumes that the human on the other
# side can provide an intelligent reason for the test to fail.
sub answer {
  my ($Qobj,$expected,$timeout) = @_;
  my $tb = $CLASS->builder;
  my $interface = $CLASS->_get_interface();
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  # This should be something smarter than die in the future...
  die "Expecting something other than yes or no" if $expected !~ /yes|no/i;

  # Skips
  return $tb->skip("Invalid Question") unless defined $Qobj and $Qobj->isa('Test::AskAnExpert::Question');
  return $tb->skip($Qobj->skip) if defined($Qobj->skip);

  # Wait for it..
  # Needs timestamps
  my $quit_time = time + $timeout if defined $timeout;
  until($interface->has_answer($Qobj) or defined $timeout and time > $quit_time) {
    sleep 1;
  }

  #if we still don't have an answer we timed out, skip the test
  unless ($interface->has_answer($Qobj)) {
    return $tb->skip($Qobj->name . " timed out while waiting for answer");
  }

  # Get the answer and skip on error
  $interface->answer($Qobj) or return $tb->skip("Interface Error: ".$interface->err);

  # The ok call checks the answer against yes or no and takes the name provided earlier.
  my ($answer,$comment) = $Qobj->answer;
  return $tb->skip($Qobj->skip) if defined($Qobj->skip); # The expert decided to skip
  $tb->ok($answer eq $expected,$Qobj->name) or 
    $tb->diag("Got: $answer Expected: $expected\n","Commentary: $comment\n");
}

=head1 EXPORTS

Nothing is exported by default, you must ask for whatever you want by passing
import => [qw(functions you want)] as arguments to use like this

  use Test::AskAnExpert import => [qw(is_yes)]; #we just deal with yes-men

=head1 BUGS

This is very young code, it probably has some. Bug reports, failing tests,
and patches are all welcome.

=head1 TODO

Test::AskAnExpert::Interface::CGI and Test::AskAnExpert::Interface::DBI. These would 
probably be more useful than the current File interface which exists more to
prove it can be done than anything. Maybe also a
Test::AskAnExpert::Interface::Terminal if the person running the tests is the
expert.

Set up a way to make sure an expert is indeed being asked. This is a hard one
since it would require the test-writer (who may also not be qualified) to write
some sort of captcha. This might get on an indefinite hold, you have to start
trusting people at some point (hey, they let us write software... ).

=head1 SUPPORT

All bugs should be filed via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-AskAnExpert>

For other issues, or commercial enhancement or support, contact the author.

=head1 SEE ALSO

L<Test::AskAnExpert::Interface>,L<Test::AskAnExpert::Question>

=head1 AUTHOR

Edgar A. Bering, E<lt>trizor@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Edgar A. Bering

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic 2.0 liscence as provided in the
LICENSE file of this distribution.

=cut

1;
