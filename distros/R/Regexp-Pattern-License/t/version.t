use Test2::V0;

use Regexp::Pattern;

plan 37;

my $version = re( 'License::version', { capture => 'named' } );
my $todo;

note re( 'License::version', { capture => 'named', engine => 'pseudo' } );

'GPL ( version 2 of the License ).' =~ $version;
is $&, ' ( version 2 of the License )';
is \%+, { version_number => 2 };

'LGPL version 2.1 or version 3 as published.' =~ $version;
is $&, ' version 2.1 or version 3 ';
is \%+, {
	version_number   => '2.1',
	version_number_2 => '3',
};

'LGPL license version 2.0 or 2.1.' =~ $version;
is $&, ' version 2.0 or 2.1';
is \%+, {
	version_number   => '2.0',
	version_number_2 => '2.1',
};

'GPL ( version 2 or version 3 of the License ).' =~ $version;
is $&, ' ( version 2 or version 3 of the License )';
is \%+, {
	version_number   => 2,
	version_number_2 => 3,
};

'GPL, version 2 or 3.' =~ $version;
is $&, ', version 2 or 3';
is \%+, {
	version_number   => 2,
	version_number_2 => 3,
};

'GPL version 2 or version 3.' =~ $version;
is $&, ' version 2 or version 3';
is \%+, {
	version_number   => 2,
	version_number_2 => 3,
};

'GPL, either version 2 or version 3 of the License.' =~ $version;
is $&, ', either version 2 or version 3 of the License';
is \%+, {
	version_number   => 2,
	version_number_2 => 3,
};

'GPL either version 2, or version 3 (at your option).' =~ $version;
is $&, ' either version 2, or version 3 (at your option)';
is \%+, {
	version_number   => 2,
	version_number_2 => 3,
};

'GPL, either version 2 or 3 of the License (at your option).' =~ $version;
is $&, ', either version 2 or 3 of the License (at your option)';
is \%+, {
	version_number   => 2,
	version_number_2 => 3,
};

'GPL, either version 2 or (at your option) version 3 of the License.'
	=~ $version;
is $&, ', either version 2 or (at your option) version 3 of the License';
is \%+, {
	version_number   => 2,
	version_number_2 => 3,
};

'LGPL version 2.1 or version 3.0 only.' =~ $version;
is $&, ' version 2.1 or version 3.0 only';
is \%+, {
	version_number   => '2.1',
	version_number_2 => '3.0',
	version_only     => 'only',
};

'LGPL; either version 2 or version 3 of the License.' =~ $version;
is $&, '; either version 2 or version 3 of the License';
is \%+, {
	version_number   => 2,
	version_number_2 => 3,
};

'terms of version 2 of the GPL.' =~ $version;
is $&, ' version 2 of ';
is \%+, {
	version_number => '2',
	version_of     => 'of',
};

'under version 2 or later of the GPL.' =~ $version;
is $&, ' version 2 or later of ';
is \%+, {
	version_number => 2,
	version_later  => 'or later',
	version_of     => 'of',
};

'the license, version 1.3c or higher (your choice):' =~ $version;
is $&, ', version 1.3c or higher (your choice)';
is \%+, {
	version_number => '1.3c',
	version_later  => 'or higher (your choice)',
};

'GPL version 2.0 or (at your choice) any later version.' =~ $version;
is $&, ' version 2.0 or (at your choice) any later version';
is \%+, {
	version_number => '2.0',
	version_later  => 'or (at your choice) any later version',
};

'GPLv2 or any later at your option.' =~ $version;
is $&, 'v2 or any later at your option';
is \%+, {
	version_number => '2',
	version_later  => 'or any later at your option',
};

'License version 2 as published by the FSF (or any later at your option).'
	=~ $version;
is $&, ' version 2 ';
$todo = todo 'not yet implemented';
is \%+, {
	version_number        => '2',
	version_later         => 'or any later',
	version_later_postfix => 'or any later at your option',
};
$todo = undef;
like \%+, { version_number => '2' };

done_testing;
