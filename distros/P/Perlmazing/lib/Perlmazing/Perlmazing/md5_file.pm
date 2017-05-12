use Perlmazing;
use Digest::MD5;

sub main {
	my $file = shift;
	croak "This function requires a file name as argument." unless defined $file;
	croak "File '$file' is not a valid file or cannot be read." unless -f $file;
	my $ctx = Digest::MD5->new;
	$ctx->add(slurp $file);
	$ctx->hexdigest;
}

1;
