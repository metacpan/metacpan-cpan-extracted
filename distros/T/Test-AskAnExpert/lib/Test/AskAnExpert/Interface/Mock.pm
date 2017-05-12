package Test::AskAnExpert::Interface::Mock;

use strict;
use warnings;
use base 'Test::AskAnExpert::Interface';

our $VERSION = 1.1;

=head1 NAME

Test::AskAnExpert::Interface::Mock - Mock interface for testing Test::AskAnExpert

=head1 SYNOPSIS

  use Test::AskAnExpert;

  initialize('Test::AskAnExpert::Interface::Mock',
              answer  => 'always do this',
              comment => 'saying this about it',
              skip    => 'or skip because of this',
              error   => 'or give this error'
	      never_answer => 0);

  # do some testing here to make sure Test::AskAnExpert
  # reacts properly.

=head1 DESCRIPTION

This is for internal testing. If you're re-implementing Test::AskAnExpert you might
find it useful yourself.

=cut

sub load {
  my $class = shift;
  my %args = @_;
  my $self = {};

  $self->{_answer} = $args{answer};
  $self->{_comment} = $args{comment};
  $self->{_skip} = $args{skip};
  $self->{_error} = $args{error};
  $self->{_dont} = $args{never_answer};

  bless $self,$class;
}

sub submit {
  my ($self,$question,$name) = @_;

  $self->err($self->{_error}), return undef if $self->{_error};
  return Test::AskAnExpert::Question->new(question=>$question,
                                    name=>$name,
                                    id=>"id",
                                    skip=>$self->{_skip}) if $self->{_skip};
  return Test::AskAnExpert::Question->new(question=>$question,name=>$name,id=>"id");
}

sub has_answer {
  my $self = shift;
  return !$self->{_dont};
}

sub answer {
  my ($self,$Qobj) = @_;

  $self->err($self->{_error}), return undef if $self->{_error};
  $Qobj->answer($self->{_answer},$self->{_comment});
}

=head1 AUTHOR

Edgar A. Bering, E<lt>trizor@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Edgar A. Bering

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic 2.0 liscence as provided in the
LICENSE file of this distribution.

=cut


1;
