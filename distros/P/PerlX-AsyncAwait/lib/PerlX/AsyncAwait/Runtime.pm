package PerlX::AsyncAwait::Runtime;

use strictures 2;
use PerlX::AsyncAwait::AsyncSub;
use PerlX::Generator::Runtime qw(__gen_suspend __gen_resume __gen_sent);
use Exporter 'import';

our @EXPORT = qw(async_sub async_do await __gen_suspend __gen_resume __gen_sent);

sub async_sub (&) {
  my ($code) = @_;
  return PerlX::AsyncAwait::AsyncSub->new(code => $code);
}

sub async_do (&;@) {
  my ($code, @args) = @_;
  return PerlX::AsyncAwait::AsyncSub->new(code => $code)->start(@args);
}

sub await { die "Unrewritten await call - await outside of async?" }

1;
