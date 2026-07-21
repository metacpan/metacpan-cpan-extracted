package PDF::Make::Install::Files;

$self = {
          'deps' => [],
          'inc' => '-Iinclude',
          'libs' => '',
          'typemaps' => []
        };

@deps = @{ $self->{deps} };
@typemaps = @{ $self->{typemaps} };
$libs = $self->{libs};
$inc = $self->{inc};

	$CORE = undef;
	foreach (@INC) {
		if ( -f $_ . "/PDF/Make/Install/Files.pm") {
			$CORE = $_ . "/PDF/Make/Install/";
			last;
		}
	}

	sub deps { @{ $self->{deps} }; }

	sub Inline {
		my ($class, $lang) = @_;
		+{ map { (uc($_) => $self->{$_}) } qw(inc libs typemaps) };
	}

1;
