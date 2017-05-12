package DemoUser;

use Pod::ToDemo sub
{
	(undef, my $file) = @_;
	$file           ||= 'foo';

	Pod::ToDemo::write_demo( $file, 'here is some text' );
};

1;
