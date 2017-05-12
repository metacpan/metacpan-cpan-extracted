package RunApp::Template;
use strict;
use base qw(RunApp::Base);
use Template;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new (@_);
  unless ($self->{source}) {
    my $source = $self->{file}.'.default';
    if (-e $source) {
      $self->{source} = $source;
    }
    else {
      $self->{source} = $self->get_data;
    }
  }
  return $self;
}

sub get_template {
  Template->new({ ABSOLUTE => 1,
                  DEBUG_UNDEF => 1 });
}

sub build {
  my ($self, $conf) = @_;
  #warn ". building $self->{file}\n";
  my $tt = $self->get_template ($conf);
  $self->{source} ||= $self->{file}.'.default';
  $tt->process($self->{source}, {%$conf, PACKAGE => ref($self)}, $self->{file})
      or die $tt->error(), "\n";
}

sub get_data {
  my ($self) = @_;
  my $class = ref $self || $self;
  no strict 'refs';
  local $/;
  my $data = "${class}::DATA";
  ${$class.'::_DATA'} ||= \<$data>;
}

=head1 NAME

RunApp::Template - Base class for RunApp template service

=head1 SYNOPSIS

  my $cron = RunApp::Template->new(
    file => "file to be generated",
    source => "template file",
    .. other params, passed to template ..
  );
  

=head1 DESCRIPTION

The class allows inherited classes to use L<Template>, and will use
the DATA section of the subclass as default template if not otherwise
specified.

=head1 AUTHORS

Chia-liang Kao <clkao@clkao.org>

Refactored from works by Leon Brocard E<lt>acme@astray.comE<gt> and
Tom Insam E<lt>tinsam@fotango.comE<gt>.

=head1 COPYRIGHT

Copyright (C) 2002-5, Fotango Ltd.

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;


