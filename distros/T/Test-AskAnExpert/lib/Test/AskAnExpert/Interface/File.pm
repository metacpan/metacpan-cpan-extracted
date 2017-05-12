package Test::AskAnExpert::Interface::File;

use strict;
use warnings;
use base qw(Test::AskAnExpert::Interface);

our $VERSION = 0.5;

use File::Spec::Functions;
use File::Path;

use Test::AskAnExpert::Question;

=head1 NAME

Test::AskAnExpert::Interface::File - File based human interface layer for Test::AskAnExpert

=head1 SYNOPSIS

In the test:

  use Test::AskAnExpert import => [qw(is_yes)],plan => 2;

  Test::AskAnExpert->initialize('Test::AskAnExpert::Interface::File',directory => '/home/tester');

  is_yes("Does the source code of Foo::Bar conform to in house style spec 7.9 subsection a?","style");
  is_yes("Could a child understand the underlying algorithm of Foo::Bar?","simple");

For the expert:

  # This assumes *nix, because thats what experts use, right?
  % cd /home/tester
  % cat 1.q
  style
  ----------
  Does the source code of Foo::Bar conform to in house style spec 7.9 subsection a?
  % touch 1.y # The test will recieve an answer of yes, passing in this case.
  % cat 2.q
  simple
  ----------
  Could a child understand the underlying algorithm of Foo::Bar?
  % echo "A child would not understand the sexual innuendo used in the variable \
  % names. Please consider being more professional to conform to company expectations." \
  % > 2.n # The test will recieve an answer of no, failing in this case and 
	  # providing the message in the file as diagnostics.


=head1 DESCRIPTION

Test::AskAnExpert::Interface::File creates files containing the asked questions
and recieves the answer by checking for similarly named files to receive
answers.

=head2 C<initialize> arguments

Test::AskAnExpert::Interface::File takes its initializing agruments in a hash
passed to Test::AskAnExpert::initialize after the interface name.

=over 4

=item directory

Path to the directory (relative or absolute) in which to place the question
files and search for the answer files. If it does not exist it will be created
during the test and destroyed afterward.

If no directory is specified it defaults to the current working directory.

=back

=head2 Question Files

When the test asks a question (through any of is_yes,is_no, or ask)
Test::AskAnExpert::Interface::File creates a file with the name $question_id.q
contaning the test name and question being asked. The expert is expected to
read the question and create one of the three types of answer files specified
in the section L</Answer Files>.

These will be deleted after the test.

=head2 Answer Files

There are three types of answer file: a yes file, a no file, and a skip file, 
and their names suggest the type of answer provided to the test.

These files should be placed in the same directory as the question files by
the expert answering the questions. The $question_id is the name of the 
question file before the '.q' extension.

=over 4

=item yes file

Yes files have the name $question_id.y and optionally contain commentary about
the reason for the answer being yes.

=item no file

No files are like yes files except they indicate a no answer, contain reasons
for the answer being no, and are named $question_id.n .

=item skip file

Skip files indicate the test should be skipped and contain a reason for the
skip (experts caught outside their expertise should use these). They are named
expectedly $question_id.s .

=back

All answer files are cleaned up after the test.

=cut

sub load {
  my $class = shift;
  my %args  = @_;
  my $self  = {};
  $self->{_nextid}     = 0;
  $self->{_dir}       = $args{directory} ||= '.';
  $self->{_questions} = [];

  unless( -e $self->{_dir}) {
    $self->{_dircreat} = 1;
    mkpath($self->{_dir}) or return undef;
  }

  bless $self,$class;
}

sub submit {
  my ($self,$question,$name) = @_;
  
  my $Qobj = Test::AskAnExpert::Question->new(
               question =>$question,
               name     =>$name,
               id       =>$self->{_nextid});

  push @{$self->{_questions}},$self->{_nextid};

  $self->{_nextid}++;

  open my $qfile, '>', $self->_get_filename($Qobj->id ,"q") or
    $self->err("Could not open question file: $!") and return undef;

  print $qfile <<QUESTION;
$name
---------
$question
QUESTION

  close $qfile;

  return $Qobj;
}

sub has_answer {
  my ($self,$Qobj) = @_;

  my @names = map { $self->_get_filename($Qobj->id,$_) } qw(y n s);

  foreach (@names) {
    return 1 if -e $_;
  }

  return 0;
}

sub answer {
  my ($self,$Qobj) = @_;

  $self->err('Question does not have an answer yet') and return undef unless $self->has_answer($Qobj);
  my $id = $Qobj->id;

  $Qobj->answer('yes',scalar $self->_getcomments($id,'y')), return 1 if $self->_is_y($id);
  $Qobj->answer('no',scalar $self->_getcomments($id,'n')), return 1 if $self->_is_n($id);
  $Qobj->skip(scalar $self->_getcomments($id,'s')),  return 1 if $self->_is_s($id);

  return undef;
}

sub _get_filename {
  my ($self,$id,$suffix) = @_;
  
  return catfile($self->{_dir},"question-$id.$suffix");
}

sub _getcomments {
  my ($self,$id,$suffix) = @_;

  open my $commentfile,'<',$self->_get_filename($id,$suffix);
  my @commentlines = <$commentfile>;
  close $commentfile;
  
  return wantarray ? @commentlines : join '',@commentlines;
}

foreach my $suffix (qw(y n s)){
  no strict 'refs';
  *{__PACKAGE__."::_is_$suffix"} = sub {
    my ($self,$id) = @_;
    return -e $self->_get_filename($id,$suffix);
  };
}

sub DESTROY {
  my $self = shift;

  foreach my $qid (@{$self->{_questions}}) {
    unlink glob catfile $self->_get_filename($qid,"*");
  }

  rmdir $self->{_dir} if $self->{_dircreat};
}

=head1 TODO

Add a preserve option that prevents cleanup of answers to leave an auditable
trail.

=head1 AUTHOR

Edgar A. Bering, E<lt>trizor@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Edgar A. Bering

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic 2.0 liscence as provided in the
LICENSE file of this distribution.

=cut

1;
