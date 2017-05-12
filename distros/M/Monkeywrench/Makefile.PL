
use ExtUtils::MakeMaker;
WriteMakefile(
				NAME	=> 'Monkeywrench',
				VERSION => '1.0',
				PREREQ_PM	=>	{
									CGI				=> 0,
									Net::SMTP		=> 0,
									HTTP::Cookies	=> 0,
									LWP::UserAgent	=> 0
								}
			);
