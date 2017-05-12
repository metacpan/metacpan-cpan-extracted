package My::Test;

use Exporter 'import';
use base 'Test::Builder::Module';
use Test::Deep::NoTest qw[ cmp_details methods deep_diag ];

our @EXPORT = qw[ check_class ];

my $CLASS = __PACKAGE__;


sub name {
    my ( $map, $class, $desc ) = @_;

    my $re = join( '|', reverse sort { length $a <=> length $b } keys %$map );

    1 while( $desc =~ s/($re)(?!\()/"$1($map->{$1})"/ge );

    $map->{$class} = $desc;

    return "$class($desc)";
}

sub check_class {

    my($class, $attr, $tags, $map, $desc ) = @_;

    my $Test = $CLASS->builder;

    $desc = name( $map, $class, $desc );

    {
	my ($ok, $stack ) = cmp_details( $class->_tags, $tags );

	unless ($Test->ok($ok, "$desc: Class Tags" )) {
	    my $diag = deep_diag($stack);
	    $Test->diag($diag);
	}
    }

    {
	my ($ok, $stack ) = cmp_details( $class->new,
					 methods( %$attr, _tags => $tags ),
	    );

	unless ($Test->ok($ok, "$desc: object" )) {
	    my $diag = deep_diag($stack);
	    $Test->diag($diag);
	}
    }
}

1;

