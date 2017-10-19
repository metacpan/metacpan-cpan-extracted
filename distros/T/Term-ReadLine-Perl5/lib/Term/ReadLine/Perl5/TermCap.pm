=encoding utf8

=head1 Term::ReadLine::Perl5::TermCap

This is copied from L<Term::ReadLine> to remove the cyclic dependency
I<Term::ReadLine> -> I<Term::ReadLine::Perl5> -> I<Term::ReadLine>
With this, I have modifed I<Term::ReadLine::Perl5> to no longer depend
on I<Term::Readline>.

=cut

package Term::ReadLine::Perl5::TermCap;

# Prompt-start, prompt-end, command-line-start, command-line-end
#     -- zero-width beautifies to emit around prompt and the command line.
our @rl_term_set = ("","","","");
# string encoded:
our $rl_term_set = ',,,';

our $terminal;
sub LoadTermCap {
  return if defined $terminal;

  require Term::Cap;
  $terminal = Tgetent Term::Cap ({OSPEED => 9600}); # Avoid warning.
}

sub ornaments {
  shift;
  return $rl_term_set unless @_;
  $rl_term_set = shift;
  $rl_term_set ||= ',,,';
  $rl_term_set = 'us,ue,md,me' if $rl_term_set eq '1';
  my @ts = split /,/, $rl_term_set, 4;
  eval { LoadTermCap };
  unless (defined $terminal) {
    warn("Cannot find termcap: $@\n") unless $Term::ReadLine::termcap_nowarn;
    $rl_term_set = ',,,';
    return;
  }
  @rl_term_set = map {$_ ? $terminal->Tputs($_,1) || '' : ''} @ts;
  return $rl_term_set;
}

1;
