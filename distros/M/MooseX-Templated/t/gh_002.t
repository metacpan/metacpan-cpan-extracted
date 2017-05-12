

package Farm::Cow;
use Moose;
with 'MooseX::Templated';
has 'spots' => ( is => 'ro', isa => 'Num', required => 1 );
sub _template {<<'_TT'}
This cow has [% self.spots %] spots.
_TT
sub _template_xml {<<'_TT_XML'}
<cow spots="[% self.spots %]"></cow>
_TT_XML
no Moose;
1;

package main;
use Test::More tests => 6;
use Test::Warn;
use strict;
use warnings;

my $cow = Farm::Cow->new( spots => 8 );

isa_ok( $cow, 'Farm::Cow' );
can_ok( $cow, 'render' );

is( $cow->render(), "This cow has 8 spots.\n" );
is( $cow->render( source => "xml" ), "<cow spots=\"8\"></cow>\n" );

warning_like { $cow->render("xml") } qr/DEPRECATED/, 'deprecation notice on incorrect usage';

diag( "expect a warning here..." );
is( $cow->render( "xml" ), "<cow spots=\"8\"></cow>\n" );
