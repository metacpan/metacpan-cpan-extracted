package MooseX::Extended::Tests {
    use v5.20.0;
    use base 'Exporter';
    use strict;
    use warnings;
    use version;
    use Carp 'croak';
    use Module::Load 'load';
    use Test::Builder;
    use Test::Most ();
    use Import::Into;
    use Capture::Tiny ();
    use Ref::Util 'is_plain_arrayref';
    use feature 'signatures';
    use feature 'postderef';
    no warnings 'experimental::postderef', 'experimental::signatures';

    sub import ( $class, %arg_for ) {
        my ( $caller, $filename, undef ) = caller;

        my $name = $arg_for{name} // $filename;

        my $builder = Test::Builder->new;
        if ( my $version = $arg_for{version} ) {
            if ( $^V lt $version ) {
                $builder->plan( skip_all => "Perl version $version required for $name. You have perl version $^V" );
            }
        }

        my $requires = $arg_for{requires} // {};
        foreach my $module ( sort keys $requires->%* ) {
            my $version = $requires->{$module};
            eval {
                load $module;
                my $module_version = $module->VERSION // 0;
                if ( version->parse($module_version) < version->parse($version) ) {
                    croak("$module requires version $version, but we loaded $module_version");
                }
                1;
            } or do {
                my $error = $@ // '<unknown error>';
                $builder->plan( skip_all => "Could not load $module: $error" );
            }
        }

        Test::Most->import::into($caller);
        Capture::Tiny->import::into( $caller, ':all' );
    }
}

1;
