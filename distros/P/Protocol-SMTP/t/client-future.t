use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Protocol::SMTP::Client;

{
	package Local::MyFuture;
	use parent qw(Future);
}
{
	my $smtp = Protocol::SMTP::Client->new;
	my $f = $smtp->new_future;
	isa_ok($f, 'Future');
}
{
	my $smtp = Protocol::SMTP::Client->new(future_factory => sub { Local::MyFuture->new(@_) });
	my $f = $smtp->new_future;
	isa_ok($f, qw(Local::MyFuture));
}

done_testing;


