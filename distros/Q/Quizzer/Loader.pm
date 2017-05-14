#!/usr/bin/perl -w

=head1 NAME

Quizzer::Loader - Quizzer Loader

=cut

=head1 DESCRIPTION

This package contains some helper functions taken by Joey Hess's ConfigDb
module.

=cut

=head1 METHODS

=cut

package Quizzer::Loader;
use Quizzer::Template;
use Quizzer::Question;
use Quizzer::AutoSelect;
use strict;

my $VERSION='0.01';

use vars qw(@ISA %templates %questions @EXPORT);

@ISA = qw(Exporter);
@EXPORT =qw(loadtemplatefile getquestion);

=head2 getquestion

Pass in the name of the question and this will return the specified question
object.

=cut

sub getquestion {
	return $questions{(shift)};
}

=head2 gettree

Pass in a string denoting the root of a tree of questions in the question 
hierarchy. All questions under that root will be returned.

=cut

sub gettree {
	my $root=shift;

	my @ret=();
	foreach my $name (keys %questions) {
		if ($name=~m:^\Q$root/\E:) {
			push @ret, $questions{$name};
		}
	}
	
	return @ret;
}

=head2 isunder

Pass in a string denoting the root of a tree of questions in the question
hierarchy, and a Question. If the Question is under that tree, a true value
is returned.

=cut

sub isunder {
	my $root=shift;
	my $name=shift->name;
	
	return $name=~m:^\Q$root/\E:;
}

=head2 loadtemplatefile

Loads up a file containing templates (pass the filename to load). Creates
Template objects and corresponding Question objects. The second parameter is
the name of the owner of the created templates and questions.

=cut

sub loadtemplatefile {
	my $fn=shift;
	my $owner=shift;
	
	my $collect;
	open (TEMPLATE_IN, $fn) || die "$fn: $!";
	while (<TEMPLATE_IN>) {
		if ($_ ne "\n") {
			$collect.=$_;
		}
		if ($_ eq "\n" || eof TEMPLATE_IN) {
			loadtemplatedata($collect, $owner);
			$collect='';
		}
	}
	close TEMPLATE_IN;      
	return 1;
}

=head2 loadtemplatedata

Pass this a string containing one of more templates, and it will 
process it and instantiate the Template objects and
corresponding Question objects.

The second parameter is the name of the owner of the created
templates and questions.

=cut

sub loadtemplatedata {
	my $data=shift;
	my $owner=shift;

	# Have to be careful here to ensure that if a template
	# already exists in the db and we load it up, the
	# changes replace the old template without
	# instantiating a new template.
	my $template=Quizzer::Template->new();
	$template->parse($data);

	if ($templates{$template->template}) {
		# An old template with this name exists. Merge
		# all info from the new template into it.
		$template->merge($templates{$template->template});
	}
	else {
		$templates{$template->template}=$template;
	}

	# Make a question to go with this template.
	addquestion($template->template, $template->template,
		    $owner);
}

=head2 addquestion

Create a Question and add it to the database. Pass the name of the template
the question will use, and the name to use for the question. Finally, pass
the name of the owner of the new question.

If a question by this name already exists, it will be modified to add the
new owner and to use the correct template.

=cut

sub addquestion {
	my $template=shift;
	my $name=shift;
	my $owner=shift;

	my $question=$questions{$name} || Quizzer::Question->new;	

	$question->name($name);
	$question->template($templates{$template});
	$question->addowner($owner);
	$questions{$name}=$question;
}

=head2 disownquestion

Give up ownership of a given question. Pass the name of the question and the
owner that is giving it up. When the number of owners reaches 0, the question
itself is removed. If the template the question used has no more questions
using it, it too is removed.

=cut

sub disownquestion {
	my $name=shift;
	my $owner=shift;
	
	return unless $questions{$name};
	
	$questions{$name}->removeowner($owner);
	if ($questions{$name}->owners eq '') {
		my $template=$questions{$name}->template;
		# Does the template go away too? Look at how many questions
		# use it.
		my $users=0;
		foreach my $question (keys %questions) {
			$users++ if $questions{$question}->template eq $template;
		}
		delete $questions{$name};

		# Only the current question uses it.
		if ($users == 1) {
			delete $templates{$template->template};
		}
	}
}

=head2 disownall

This runs disownquestion() on all Questions. Pass the owner.

=cut

sub disownall {
	my $owner=shift;
	
	foreach my $question (keys %questions) {
		disownquestion($question, $owner);
	}
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>
Modified by Stefano Corsi <ippo@madeinlinux.com>

=cut

1
