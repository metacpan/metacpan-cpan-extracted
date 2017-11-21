use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('Syntax::Kamelon::Format::Base') };

use Syntax::Kamelon;


my $formattable = {
	Normal => 'Normal'
};

my $base = Syntax::Kamelon::Format::Base->new(1,
	format_table => $formattable,
);

ok(defined $base, 'Creation');

ok(($base->{ENGINE} eq 1), 'Engine');

my $folder = './t';

my $kam = Syntax::Kamelon->new(
	noindex => 1,
	xmlfolder => $folder,
);
$kam->Syntax("Test");

