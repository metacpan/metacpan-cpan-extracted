use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Net::Amazon::AWIS',
	'VERSION_FROM'	=> 'lib/Net/Amazon/AWIS.pm',
	'PREREQ_PM'		=> {
		'IO::Prompt'					=> 0,
		'DateTime::Format::Strptime'	=> 0,
		'Digest::HMAC_SHA1'				=> 0,
		'IO::Prompt'					=> 0,
		'LWP::UserAgent'				=> 0,
		'URI'							=> 0,
		'XML::LibXML'					=> 0,
		'Test::Exception'				=> 0,
			},
	ABSTRACT_FROM => 'lib/Net/Amazon/AWIS.pm',
	AUTHOR		=> 'Shevek <cpan@anarres.org>',
);

sub MY::postamble {
	my $self = shift;
	my $old = $self->MM::postamble(@_);
	chomp($old);
	my $new = <<'EON';

.PHONY : aux readme

aux : readme

readme : lib/Net/Amazon/AWIS.pm
	perldoc -t lib/Net/Amazon/AWIS.pm > README

EON
	return $old . $new;
}
