package Term::Completion::Path;

use strict;
use warnings;
use File::Spec;

our $VERSION = '0.90';

our @EXPORT_OK = qw(Complete);
use base qw(Term::Completion);

# ugly way to get the separator - an API for that would be nice
my $sep = File::Spec->catfile(qw(A B));
if($sep) {
  $sep =~ s/^A|B$//g;
} else {
  $sep = ($^O =~ /win/i ? "\\" : "/");
}

our %DEFAULTS = (
    sep => $sep
);

sub _get_defaults
{
  return(__PACKAGE__->SUPER::_get_defaults(), %DEFAULTS);
}

sub Complete
{
  my $prompt = shift;
  $prompt = '' unless defined $prompt;
  __PACKAGE__->new(prompt => $prompt)->complete;
}

sub get_choices
{
  my __PACKAGE__ $this = shift;
  my $sep = $this->{sep};
  map { (-d) ? "$_$sep" : $_ } glob("$_[0]*");
}

sub post_process
{
  my __PACKAGE__ $this = shift;
  my $return = $this->SUPER::post_process(shift);
  my $sep = $this->{sep};
  $return =~ s/\Q$sep\E$//;
  $return;
}

# TODO validate should have methods to check for file/dir/link

1;

__END__

=head1 NAME

Term::Completion::Path - read a path with completion like on a shell

=head1 USAGE

  use Term::Completion::Path;
  my $tc = Term::Completion::Path->new(
    prompt  => "Enter path to your signature file: "
  );
  my $path = $tc->complete();
  print "You entered: $path\n";

=head1 DESCRIPTION

Term::Completion::Path is a derived class of L<Term::Complete>. It prompts
the user to interactively enter a path with completion like on a shell. The
currently accessible file system is used to get the completion choices.

See L<Term::Complete> for details.

=head2 Configuration

Term::Completion::Path adds one additional configuration parameter,
namely "sep". This is the directory separator of the current operating system.

=head1 SEE ALSO

L<Term::Completion>, L<File::Spec>

=head1 AUTHOR

Marek Rouchal, E<lt>marekr@cpan.org<gt>

=head1 BUGS

Please submit patches, bug reports and suggestions via the CPAN tracker
L<http://rt.cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2013 by Marek Rouchal

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

