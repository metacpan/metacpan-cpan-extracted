use Plack::Builder;
use Data::Dumper;
use Plack::Middleware::GepokX::ModSSL;

builder
{
	enable 'GepokX::ModSSL',
		vars => [ Plack::Middleware::GepokX::ModSSL->all ];
	
	my $app = sub
	{
		local $Data::Dumper::Sortkeys = 1;
		local $Data::Dumper::Terse    = 1;
		
		return [
			200,
			[ 'Content-Type' => 'text/plain' ],
			[ Dumper(shift) ]
		]
	}
}

