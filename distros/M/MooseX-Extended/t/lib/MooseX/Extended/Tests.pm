package MooseX::Extended::Tests {
    use v5.20.0;
    use base 'Exporter';
    use Carp 'croak';
    use Module::Load 'load';
    use Test::Builder;
    use Test::Most ();
    use Import::Into;
    use Capture::Tiny ();
    use Ref::Util 'is_plain_arrayref';
    use feature 'postderef';
    no warnings 'experimental::postderef';

    sub import {
        my ( $class, %arg_for ) = @_;
        my ( $package, $filename, undef ) = caller;

        my $name = $arg_for{name} // $filename;

        my $builder = Test::Builder->new;
        if ( my $version = $arg_for{version} ) {
            if ( $^V lt $version ) {
                $builder->plan( skip_all => "Version $version required for $name. You have version $^V" );
            }
        }

        if ( my $module = $arg_for{module} ) {
            my ( $package, $version )
              = is_plain_arrayref $module
              ? $module->@*
              : ( $module, 0 );
            eval {
                load $package;
                my $package_version = $package->VERSION;
                if ( $version && $package_version < $version ) {
                    croak("$package required version $version, but we loaded $package_version");
                }
                1;
            } or do {
                my $error = $@ // '<unknown error>';
                $builder->plan( skip_all => "Could not load $package: $error" );
            }
        }

        Test::Most->import::into($package);
        Capture::Tiny->import::into( $package, ':all' );
    }
}

1;
