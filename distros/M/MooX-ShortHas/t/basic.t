use strictures 2;

use Test::InDistDir;
use Test::More;
use Test::Fatal;

BEGIN {

    package Thing;
    use Moo;
    use MooX::ShortHas;

    ro "hro";
    lazy hlazy => sub { 2 } => predicate => 1;
    rwp "hrwp";
    rw "hrw";
    ro hro_opt => required => 0;
}

run();
done_testing;
exit;

sub run {
    Thing->can( "rw" )->( "hrw_dyn" );

    my $self = Thing->new( qw( hro 2 hrwp 3 hrw 3 hrw_dyn 3 ) );

    is $self->hro_opt, undef, "hro_opt works but did not cause blow-up on construction";

    like exception { $self->hro( 2 ) }, qr/(Usage: Thing::hro\(self\)|hro is a read-only accessor)/, "hro is ro";
    like exception { $self->_set_hro( 2 ) }, qr/Can't locate object method "_set_hro" via package "Thing"/,
      "hro has no setter";
    is $self->hro, 2, "hro as getter works";

    is $self->has_hlazy, "", "hlazy builder not yet called";
    is $self->hlazy,     2,  "hlazy returns correct value";

    is $self->hrwp, 3, "hrwp initial state correct";
    like exception { $self->hrwp( 2 ) }, qr/(Usage: Thing::hrwp\(self\)|hrwp is a read-only accessor)/, "hrwp is ro";
    $self->_set_hrwp( 2 );
    is $self->hrwp, 2, "hrwp setter worked";

    is $self->hrw, 3, "hrw initial state correct";
    $self->hrw( 2 );
    is $self->hrw, 2, "hrw as setter worked";

    is $self->hrw_dyn, 3, "hrw_dyn initial state correct";
    $self->hrw_dyn( 2 );
    is $self->hrw, 2, "hrw_dyn installation worked";

    {

        package Nothing;
        use Test::More;
        use Test::Fatal;
        like exception { MooX::ShortHas->import }, qr/Moo not loaded in caller: Nothing/, "require Moo to be loaded";
    }

    return;
}
