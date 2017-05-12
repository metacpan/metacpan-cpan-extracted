use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Net::Amazon::ATS',
	'VERSION_FROM'	=> 'lib/Net/Amazon/ATS.pm',
	'PREREQ_PM'		=> {
				'IO::Prompt'		=> 0,
				'Test::Exception'	=> 0,
			},
	ABSTRACT_FROM => 'lib/Net/Amazon/ATS.pm',
	AUTHOR		=> 'Shevek <cpan@anarres.org>',
);

sub MY::postamble {
	my $self = shift;
	my $old = $self->MM::postamble(@_);
	chomp($old);
	my $new = <<'EON';

.PHONY : aux readme

aux : readme

readme : lib/Net/Amazon/ATS.pm
	perldoc -t lib/Net/Amazon/ATS.pm > README

EON
	return $old . $new;
}
