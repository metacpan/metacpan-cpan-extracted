package RunApp::Base;

=head1 NAME

RunApp::Base - Base class for RunApp

=head1 SYNOPSIS

 use base 'RunApp::Base';

=cut

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  %$self = @_;
  return $self;
}

sub load {
  my ($self, $class) = @_;
  {
    no strict 'refs';
    return if keys %{$class.'::'};
  }
  $class =~ s{::}{/}g;
  require "$class.pm";
}

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

