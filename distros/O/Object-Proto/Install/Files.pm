package Object::Proto::Install::Files;

$self = {
          'deps' => [],
          'inc' => '-I.',
          'libs' => '',
          'typemaps' => []
        };

@deps = @{ $self->{deps} };
@typemaps = @{ $self->{typemaps} };
$libs = $self->{libs};
$inc = $self->{inc};

	$CORE = undef;
	foreach (@INC) {
		if ( -f $_ . "/Object/Proto/Install/Files.pm") {
			$CORE = $_ . "/Object/Proto/Install/";
			last;
		}
	}

	sub deps { @{ $self->{deps} }; }

	sub Inline {
		my ($class, $lang) = @_;
		+{ map { (uc($_) => $self->{$_}) } qw(inc libs typemaps) };
	}

1;
