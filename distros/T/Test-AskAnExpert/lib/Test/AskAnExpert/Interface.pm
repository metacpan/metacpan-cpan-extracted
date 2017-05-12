package Test::AskAnExpert::Interface;

use strict;
use warnings;
use Test::AskAnExpert::Question;

our $VERSION = 1.0;

=head1 NAME

Test::AskAnExpert::Interface - the superclass of all L<Test::AskAnExpert> Interfaces

=head1 DESCRIPTION

Test::AskAnExpert::Interface provides a base class for classes providing an Interface
to the testing system, simulating a computer actually answering the Human
Intelligent question. Any implementing class should override all of the
provided placeholders or else tests will be skipped.

=head1 SYNOPSIS

  package Test::AskAnExpert::Interface::Implementation;
  use base qw(Test::AskAnExpert::Interface);

  sub load {
    # Do any loading
  }

Methods:

  sub submit {
    # Submit a question
  }

  sub has_answer {
    # See if theres an answer
  }

  sub answer {
    # Go get it
  }

If you have problems, return undef on error and set the error using your
inherited err method:
  SUPER->err("The moon is in the wrong phase");

=head1 DETAILS

Test::AskAnExpert::Interface is just that, an interface specification. Please fully
implement any subclass, otherwise tests will just skip. Except for maybe the
constructor, if you don't need to do anything there.

=head2 load()

This is your constructor, you may specify any other parameters you like or need
to set your interface up, just document them well.

=cut

sub load {
  my $class = shift;
  return bless({},$class);
}

=head2 submit($question,$name)

Questions are submitted to the Interface through this method, which recieves
a plain text question and a test name. Do whatever magic is necessary to
send your question here and return an instance of Test::AskAnExpert::Question with
the appropriate and any extra fields you may need populated. Or return undef
and set err if you run into problems.

Consult the documentation of L<Test::AskAnExpert::Question> for details on populating
it. The provided submit creates one with the skip flag set, you probably don't
want this.

=cut

sub submit {
  my ($self,$question,$name) = @_;
  return Test::AskAnExpert::Question->new(question => $question, name => $name, id => "skip", skip => "No Interface Loaded");
}

=head2 answer($question_obj)

This method is used to retrieve an answer and populate it into the $QuestionObj
provided. Consult L<Test::AskAnExpert::Question>'s documentation on how to do that.
It should return true on success and undef on failure. You are allowed to set
the skip flag here, its what the default does.

=cut

sub answer {
  my($self,$Qobj) = @_;
  return undef unless $Qobj->isa('Test::AskAnExpert::Question');

  $Qobj->skip("No Interface Loaded");
  return 1;
}

=head2 has_answer($Qobj)

This method should return true when there is an answer available for the passed
question, but should not modify the object. This is because it is often easier
or cheaper to see if the answer is there than to actually go get it. The
default just returns true, you probably shouldn't use it.

=cut

sub has_answer {
  return 1;
}

=head2 err([$message])

If there was an error in calling any of the above methods set an error string
with this method. Calling err with no arguments returns the current error (if
any).

=cut

sub err {
  my($self,$err) = @_;
  $self->{err} = $err if $err;
  return $self->{err};
}

=head1 SEE ALSO

L<Test::AskAnExpert>, L<Test::AskAnExpert::Question>

=head1 AUTHOR

Edgar A. Bering, E<lt>trizor@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Edgar A. Bering

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic 2.0 liscence as provided in the
LICENSE file of this distribution.

=cut


1;
