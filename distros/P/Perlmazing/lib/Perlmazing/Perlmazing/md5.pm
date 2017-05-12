use Perlmazing;
use Digest::MD5;
our @ISA = qw(Perlmazing::Listable);

sub main {
	my $ctx = Digest::MD5->new;
	$ctx->add($_[0]);
	$_[0] = $ctx->hexdigest;
}

1;