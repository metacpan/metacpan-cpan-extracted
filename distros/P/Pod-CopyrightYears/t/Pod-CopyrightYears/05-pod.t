use strict;
use warnings;

use File::Object;
use Pod::CopyrightYears;
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my $obj = Pod::CopyrightYears->new(
	'pod_file' => $data_dir->file('Ex1.pm')->s,
);
my $pod = $obj->pod;
my $expected_pod = <<'END';
package Ex1;

1;

__END__

=pod

=head1 LICENSE AND COPYRIGHT

© 2013-2022 Michal Josef Špaček

BSD 2-Clause License

=cut
END
is($pod, $expected_pod, 'Original pod (Ex1).');
$obj = Pod::CopyrightYears->new(
	'pod_file' => $data_dir->file('Ex1.pm')->s,
);
$obj->change_years(2023);
$pod = $obj->pod;
$expected_pod = <<'END';
package Ex1;

1;

__END__

=pod

=head1 LICENSE AND COPYRIGHT

© 2013-2023 Michal Josef Špaček

BSD 2-Clause License

=cut
END
is($pod, $expected_pod, 'Changed pod (Ex1 - changed last year).');

# Test.
$obj = Pod::CopyrightYears->new(
	'pod_file' => $data_dir->file('Ex2.pm')->s,
);
$pod = $obj->pod;
$expected_pod = <<'END';
package Ex2;

1;

__END__

=pod

=cut
END
is($pod, $expected_pod, 'Original pod (Ex2).');
$obj = Pod::CopyrightYears->new(
	'pod_file' => $data_dir->file('Ex2.pm')->s,
);
$obj->change_years(2023);
$pod = $obj->pod;
$expected_pod = <<'END';
package Ex2;

1;

__END__

=pod

=cut
END
is($pod, $expected_pod, 'Changed pod (Ex2 - not copyright years).');

# Test.
$obj = Pod::CopyrightYears->new(
	'pod_file' => $data_dir->file('Ex3.pm')->s,
	'section_names' => [
		'LICENSE',
	],
);
$pod = $obj->pod;
$expected_pod = <<'END';
package Ex3;

1;

__END__

=pod

=head1 LICENSE

© 2013 Michal Josef Špaček

BSD 2-Clause License

=cut
END
is($pod, $expected_pod, 'Original pod (Ex3).');
$obj = Pod::CopyrightYears->new(
	'pod_file' => $data_dir->file('Ex3.pm')->s,
	'section_names' => [
		'LICENSE',
	],
);
$obj->change_years(2023);
$pod = $obj->pod;
$expected_pod = <<'END';
package Ex3;

1;

__END__

=pod

=head1 LICENSE

© 2013-2023 Michal Josef Špaček

BSD 2-Clause License

=cut
END
is($pod, $expected_pod, 'Changed pod (Ex3 - added last year).');

# Test.
$obj = Pod::CopyrightYears->new(
	'pod_file' => $data_dir->file('Ex4.pm')->s,
);
$pod = $obj->pod;
$expected_pod = <<'END';
package Ex4;

1;

__END__
END
is($pod, $expected_pod, 'Original pod (Ex4).');
$obj = Pod::CopyrightYears->new(
	'pod_file' => $data_dir->file('Ex4.pm')->s,
);
$obj->change_years(2023);
$pod = $obj->pod;
$expected_pod = <<'END';
package Ex4;

1;

__END__
END
is($pod, $expected_pod, 'No POD (Ex4).');

# Test.
$obj = Pod::CopyrightYears->new(
	'pod_file' => $data_dir->file('Ex5.pm')->s,
);
$pod = $obj->pod;
# XXX Added ' ' after =cut
$expected_pod = <<'END';
package Ex5;

1;

=pod

=cut 

__DATA__
4:hmt:Husitské muzeum v Táboře:http\://kramerius.husitskemuzeum.cz/
END
is($pod, $expected_pod, 'Original pod (Ex5).');

# Test.
$obj = Pod::CopyrightYears->new(
	'pod_file' => $data_dir->file('Ex6.pm')->s,
	'section_names' => [
		'LICENSE',
	],
);
$pod = $obj->pod;
$expected_pod = <<'END';
package Ex6;

1;

__END__

=pod

=head1 LICENSE

 © 2013 Michal Josef Špaček
 BSD 2-Clause License

=cut
END
is($pod, $expected_pod, 'Original pod (Ex6).');
$obj = Pod::CopyrightYears->new(
	'pod_file' => $data_dir->file('Ex6.pm')->s,
	'section_names' => [
		'LICENSE',
	],
);
$obj->change_years(2023);
$pod = $obj->pod;
$expected_pod = <<'END';
package Ex6;

1;

__END__

=pod

=head1 LICENSE

 © 2013-2023 Michal Josef Špaček
 BSD 2-Clause License

=cut
END
is($pod, $expected_pod, 'Changed pod (Ex6 - added last year).');
