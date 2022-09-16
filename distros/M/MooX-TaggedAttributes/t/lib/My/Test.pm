package My::Test;

use Test2::V0;
use Module::Load ();

# BEGIN {
# # this returns the platform specific path; need path with '/' between components.
#     use Module::Path 'module_path';
#     my $test_module = $ENV{TEST_MODULE} // 'My::Class';
#     ( my $path = module_path( $test_module ) ) =~ s/[.]pm$//;
#     defined $path or bail_out "can't find path to '$test_module'";
#     unshift @INC, $path;
#     $_test_role = $test_module =~ /Role/;
# }

use Exporter 'import';

our @EXPORT = ( 'test_role', 'load' );

sub load {
    my ( $base, $type ) = @_;
    my $class = join '::', $type, $base;
    Module::Load::load( $class );
    return ( $class, $type =~ 'Role' );
}


sub name {
    my ( $map, $class, $desc ) = @_;

    my $re = join( '|', reverse sort { length $a <=> length $b } keys %$map );

    1 while ( $desc =~ s/($re)(?!\()/"$1($map->{$1})"/ge );

    $map->{$class} = $desc;

    return "$class($desc)";
}

1;

