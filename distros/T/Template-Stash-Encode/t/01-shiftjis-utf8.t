#!perl -T

use Test::Base;

plan tests => 1;

use Template;
use Template::Stash::Encode;

run_is input => 'expected';

sub sjis_to_utf8 {
    my $value = shift;
    my $tmpl  = '[% value %]';

    my $tt =
      Template->new( STASH =>
          Template::Stash::Encode->new( icode => 'shiftjis', ocode => 'utf8' )
      );

    $tt->process( \$tmpl, { value => $value }, \my $result );
    return $result;
}

__END__

=== First test
--- input eval sjis_to_utf8
qq|\x91\x9D\x93\x63\x5A\x49\x47\x4F\x52\x4F\x83\x44|
--- expected eval
qq|\xE5\xA2\x97\xE7\x94\xB0\x5A\x49\x47\x4F\x52\x4F\xE3\x82\xA5|
