package PerlX::Generator::Runtime;

use strictures 2;
use PerlX::Generator::Object;
use Exporter qw(import);

our @EXPORT = qw(generator yield __gen_resume __gen_suspend __gen_sent);

sub generator (&) {
  my ($code) = @_;
  return PerlX::Generator::Object->new(code => $code);
}

sub yield { die "Unrewrittten yield call - yield outside of generator?" }

sub __gen_resume { $PerlX::Generator::Invocation::Current->_gen_resume }
sub __gen_suspend { $PerlX::Generator::Invocation::Current->_gen_suspend(@_) }
sub __gen_sent { $PerlX::Generator::Invocation::Current->_gen_sent }

1;
