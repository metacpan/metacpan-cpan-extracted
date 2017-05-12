use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Net::DNS::Async',
    'VERSION_FROM'	=> 'lib/Net/DNS/Async.pm',
    'PREREQ_PM'		=> {
				'Test::More'	=> 0,
				'Net::DNS'		=> 0,
				'IO::Select'	=> 0,
				'Storable'		=> 0,
			},
	ABSTRACT_FROM => 'lib/Net/DNS/Async.pm',
	AUTHOR     => 'Shevek <cpan@anarres.org>',
);

sub MY::postamble {
	my $self = shift;
	my $old = $self->MM::postamble(@_);
	chomp($old);
	my $new = <<'EON';

.PHONY : aux readme

aux : readme

readme : lib/Net/DNS/Async.pm
	perldoc -t lib/Net/DNS/Async.pm > README

EON
	return $old . $new;
}
