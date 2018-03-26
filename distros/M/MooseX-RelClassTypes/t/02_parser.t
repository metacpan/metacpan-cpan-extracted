use strict;
use warnings;

use Test::More;

{
    package TestParser::AngleBK;

    use Moose;
    with 'MooseX::RelClassTypes' => { parser => sub {
        my @args = @_;
        $args[0] =~ s/<CLASS>/$args[1]/;
        return $args[0] ne $_[0] ? $args[0] : undef;
    }};
      
    has rel_pack => (is => 'ro', isa => '<CLASS>::RelPack', default => sub{
        my $module = ref( $_[0] )."::RelPack";
        $module->new( param => 'AngleBK rel_pack');
    });

    has alt_pack => (is => 'ro', isa => 'RelPack::<CLASS>', default => sub{
        my $module = 'RelPack::'.ref( $_[0] );
        $module->new( param => 'AngleBK alt_pack');
    });

}


{
    package TestParser::RoundBK;

    use Moose;
    with 'MooseX::RelClassTypes' => { parser => sub {
        my @args = @_;
        $args[0] =~ s/\(package\)/$args[1]/g;
        return $args[0] ne $_[0] ? $args[0] : undef;
    }};
      
    has rel_pack => (is => 'ro', isa => '(package)::RelPack', lazy => 1, default => sub{
        my $module = ref( $_[0] )."::RelPack";
        $module->new( param => 'RoundBK rel_pack');
    });

    has alt_pack => (is => 'ro', isa => 'RelPack::(package)', default => sub{
        my $module = 'RelPack::'.ref( $_[0] );
        $module->new( param => 'RoundBK alt_pack');
    });

}

{
    package TestParser::AngleBK::RelPack;
    use Moose;
    has param => (is => 'rw', isa => 'Str');
}

{
    package RelPack::TestParser::AngleBK;
    use Moose;
    has param => (is => 'rw', isa => 'Str');
}

{
    package TestParser::RoundBK::RelPack;
    use Moose;
    has param => (is => 'rw', isa => 'Str');
}

{
    package RelPack::TestParser::RoundBK;
    use Moose;
    has param => (is => 'rw', isa => 'Str');
}

use TestParser::AngleBK;
use TestParser::RoundBK;
use TestParser::AngleBK::RelPack;
use RelPack::TestParser::AngleBK;
use TestParser::RoundBK::RelPack;
use RelPack::TestParser::RoundBK;


foreach my $type ( qw(AngleBK RoundBK) ){

    my $module = 'TestParser::'.$type;

    my $tp = $module->new;

    isa_ok( $tp, $module, '->new' );
    
    foreach my $method ( qw(rel_pack alt_pack) ){

        my $expected_package;

        if ( $method eq 'rel_pack' ){

            $expected_package = $module.'::RelPack';

        } else {

            $expected_package = 'RelPack::'.$module;

        }

        isa_ok( $tp->$method, $expected_package, "->$method" );
        is( $tp->$method->param, "$type $method", "->$method has corrrect value");

    }
}


done_testing();





