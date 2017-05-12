use strict;
use warnings;

{

    package MyApp::Role;
    use Moose::Role;
    use MooseX::Role::AttributeOverride;

    has_plus 'fun' => (
        default                 => 'yep',
        override_ignore_missing => 0,
    );

    no Moose::Role;

}
{

    package MyApp;
    use Moose;

    has 'notfun' => (
        is  => 'rw',
        isa => 'Str'
    );

    no Moose;

}
{

    package main;
    use Moose::Util;
    use Try::Tiny;
    use Test::More tests => 1;    # last test to print

    my $error = undef;
    try {
        Moose::Util::apply_all_roles( 'MyApp', 'MyApp::Role' );
        MyApp->meta->make_immutable;
        my $test = MyApp->new();
    }
    catch {
        $error = $_;
    };
    ok( $error =~ /Can't find attribute/, 'Missing Attribute dies' );

}
