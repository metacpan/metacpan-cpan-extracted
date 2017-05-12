use strict;
use warnings;

#use lib 't/lib';

#use Moose ();
#use NoInlineAttribute;
use Test::More;
use Test::Exception;
#use Test::Moose;

{
    my $name = 'Foo1';

    sub build_class {
        my ( $attr1, $attr2, $attr3 ) = @_;

        eval qq?
            package $name;

            use Moo;
            use MooX::HandlesVia;
            use MooX::Types::MooseLike::Base qw/CodeRef/;

            has callback => (
                is => 'rw',
                isa => CodeRef,
                handles_via => 'Code',
                handles => { 'invoke_callback' => 'execute' },
                required => 1,
                %{ \$attr1 || {} },
            );

            has callback_method => (
                is => 'rw',
                isa => CodeRef,
                handles_via => 'Code',
                handles => { 'invoke_method_callback' => 'execute_method' },
                required => 1,
                %{ \$attr2 || {} },
            );

            has multiplier => (
                is => 'rw',
                isa => CodeRef,
                handles_via => 'Code',
                handles => { 'multiply' => 'execute' },
                required => 1,
                %{ \$attr3 || {} },
            );

            1;
        ?;

        return $name++;
    }
}

{
    my $i;

    my %subs = ( callback        => sub { ++$i },
        callback_method => sub { shift->multiply(@_) },
        multiplier      => sub { $_[0] * 2 },
    );

    run_tests( build_class, \$i, \%subs );

    run_tests( build_class( undef, undef, undef, 1 ), \$i, \%subs );

    run_tests(
        build_class(
            {
                lazy => 1, default => sub { $subs{callback} }
            }, {
                lazy => 1, default => sub { $subs{callback_method} }
            }, {
                lazy => 1, default => sub { $subs{multiplier} }
            },
        ),
        \$i,
    );
}

sub run_tests {
    my ( $class, $iref, @args ) = @_;

    #ok(
        #!$class->can($_),
        #"Code trait didn't create reader method for $_"
    #) for qw(callback callback_method multiplier);

    ${$iref} = 0;
    my $obj = $class->new(@args);

    $obj->invoke_callback;

    is( ${$iref}, 1, '$i is 1 after invoke_callback' );

    throws_ok { $obj->invoke_method_callback } qr/unimplemented/, 'Call as method remains unimplemented';
        #'invoke_method_callback calls multiply with @_'

    is( $obj->multiply(3), 6, 'multiple double value' );
}

done_testing;
