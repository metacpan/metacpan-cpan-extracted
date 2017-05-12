package OpenFrame::AppKit::Examples::NameForm;

use strict;

use OpenFrame::AppKit::App;
use base qw ( OpenFrame::AppKit::App );

sub entry_points {
  return {
	  form_filled => [ qw(name) ]
	 }
}

sub default {
  my $self = shift;
  $self->{name} = undef;
}

sub form_filled {
  my $self = shift;
  my $args = $self->request->arguments();
  $self->{name} = $args->{name};
}

1;

__END__

=head1 NAME

OpenFrame::AppKit::Examples::NameForm - A simple form

=head1 DESCRIPTION

C<OpenFrame::AppKit::Examples::NameForm> is a very small application
that shows off subclassing C<OpenFrame::AppKit::Exmaples>. It has two
entry points, the default one (which resets the name) and form_filled
(which save the name inside the object).

=head1 AUTHOR

James Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright (C) 2002, Fotango Ltd.

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
