package Moonshine::Test;

use strict;
use warnings;
use Test::More;
use Scalar::Util qw/blessed/;
use Params::Validate qw/:all/;
use B qw/svref_2object/;
use Exporter 'import';
use Acme::AsciiEmoji;

our @EMO = @Acme::AsciiEmoji::EXPORT_OK;
our @EXPORT = qw/render_me moon_test moon_test_one sunrise/;
our @EXPORT_OK = (qw/render_me moon_test moon_test_one sunrise/, @EMO);
our %EXPORT_TAGS = (
    all     => [qw/render_me moon_test moon_test_one sunrise/, @EMO],
    element => [qw/render_me sunrise/],
    emo     => [@EMO],
);

use feature qw/switch/;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

=head1 NAME

Moonshine::Test - Test!

=head1 VERSION

Version 0.16

=cut

our $VERSION = '0.16';

=head1 SYNOPSIS

    use Moonshine::Test qw/:all/;

    moon_test_one(
        test      => 'scalar',
        meth      => \&Moonshine::Util::append_str,
        args      => [
            'first', 'second'
        ],
        args_list => 1,
        expected  => 'first second',
    );

    sunrise(1);

=head1 EXPORT

=head2 all

=over

=item moon_test

=item moon_test_one

=item render_me

=item done_testing

=back

=head2 element

=over

=item render_me

=item done_testing

=back

=head1 SUBROUTINES/METHODS

=head2 moon_test_one

    moon_test_one(
        test      => 'render_me',
        instance  => Moonshine::Component->new(),
        func      => 'button',
        args      => {
            data  => '...'
        },
        expected  => '<button>...</button>',
    );

=head2 Instructions

Valid instructions moon_test_one accepts

=head3 test/expected

    test     => 'like'
    expected => 'a horrible death'
    ....
    like($test_outcome, qr/$expected/, "function: $func is like - $expected");

moon_test_one can currently run the following tests.

=over

=item ok - ok - a true value 

=item ref - is_deeply - expected [] or {}

=item scalar - is - expected '',

=item hash - is_deeply - expected {},

=item array - is_deeply - expected [],

=item obj - isa_ok - expected '',

=item like - like - '',

=item true - is - 1,

=item false - is - 0,

=item undef - is - undef

=item ref_key_scalar - is - '' (requires key)

=item ref_key_ref - is_deeply - [] or {} (requires key)

=item ref_key_like - like - ''

=item ref_index_scalar - is - '' (requires index)

=item ref_index_ref - is_deeply - [] or {} (required index)

=item ref_index_like - like - ''

=item ref_index_obj - isa_ok - ''

=item list_key_scalar - is - '' (requires key)

=item list_key_ref - is_deeply - [] or {} (requires key)

=item list_key_like - like - ''

=item list_index_scalar - is - '' (requires index)

=item list_index_ref - is_deeply - [] or {} (required index)

=item list_index_obj - isa_ok - ''

=item list_index_like - like - ''

=item count - is - ''

=item count_ref - is - ''

=item skip - ok(1)

=back

=head3 catch

when you want to catch exceptions....

    catch => 1,

defaults the instruction{test} to like.

=head3 instance

    my $instance = Moonshine::Element->new();
    instance => $instance,

=head3 func

call a function from the instance

    instance => $instance,
    func     => 'render'

=head3 meth

    meth => \&Moonshine::Element::render,

=head3 args

    {} or []

=head3 args_list

    args      => [qw/one, two/],
    args_list => 1,

=head3 index

index - required when testing - ref_index_*

=head3 key

key - required when testing - ref_key_*

=cut

sub moon_test_one {
    my %instruction = validate_with(
        params => \@_,
        spec   => {
            instance  => 0,
            meth      => 0,
            func      => 0,
            args      => { default => {} },
            args_list => 0,
            test      => 0,
            expected  => 0,
            catch     => 0,
            key       => 0,
            index     => 0,
            built     => 0,
        }
    );

    my @test      = ();
    my $test_name = '';
    my @expected  = $instruction{expected};

    if ( $instruction{catch} ) {
        $test_name = 'catch';
        exists $instruction{test} or $instruction{test} = 'like';
        eval { _run_the_code( \%instruction ) };
        @test = $@;
    }
    else {
        @test      = _run_the_code( \%instruction );
        $test_name = shift @test;
    }

    if ( not exists $instruction{test} ) {
        ok(0);
        diag 'No instruction{test} passed to moon_test_one';
        return;
    }

    given ( $instruction{test} ) {
        when ('ref') {
            return is_deeply( $test[0], $expected[0],
                "$test_name is ref - is_deeply" );
        }
        when ('ref_key_scalar') {
            return exists $instruction{key}
              ? is(
                $test[0]->{ $instruction{key} },
                $expected[0],
"$test_name is ref - has scalar key: $instruction{key} - is - $expected[0]"
              )
              : ok(
                0,
                "No key passed to test - ref_key_scalar - testing - $test_name"
              );
        }
        when ('ref_key_like') {
            return exists $instruction{key}
              ? like(
                $test[0]->{ $instruction{key} },
                qr/$expected[0]/,
"$test_name is ref - has scalar key: $instruction{key} - like - $expected[0]"
              )
              : ok( 0,
                "No key passed to test - ref_key_like - testing - $test_name" );
        }
        when ('ref_key_ref') {
            return exists $instruction{key}
              ? is_deeply(
                $test[0]->{ $instruction{key} },
                $expected[0],
"$test_name is ref - has ref key: $instruction{key} - is_deeply - ref"
              )
              : ok( 0,
                "No key passed to test - ref_key_ref - testing - $test_name" );
        }
        when ('ref_index_scalar') {
            return exists $instruction{index}
              ? is(
                $test[0]->[ $instruction{index} ],
                $expected[0],
"$test_name is ref - has scalar index: $instruction{index} - is - $expected[0]"
              )
              : ok(
                0,
"No index passed to test - ref_index_scalar - testing - $test_name"
              );
        }
        when ('ref_index_ref') {
            return exists $instruction{index}
              ? is_deeply(
                $test[0]->[ $instruction{index} ],
                $expected[0],
"$test_name is ref - has ref index: $instruction{index} - is_deeply - ref"
              )
              : ok(
                0,
                "No index passed to test - ref_index_ref - testing - $test_name"
              );
        }
        when ('ref_index_like') {
            return exists $instruction{index}
              ? like(
                $test[0]->[ $instruction{index} ],
                qr/$expected[0]/,
"$test_name is ref - has scalar index: $instruction{index} - like - $expected[0]"
              )
              : ok(
                0,
"No index passed to test - ref_index_like - testing - $test_name"
              );
        }
        when ('ref_index_obj') {
            return exists $instruction{index}
              ? isa_ok(
                $test[0]->[ $instruction{index} ],
                $expected[0],
"$test_name is ref - has obj index: $instruction{index} - isa_ok - $expected[0]"
              )
              : ok(
                0,
"No index passed to test - ref_index_obj - testing - $test_name"
              );
        }
        when ('list_index_scalar') {
            return exists $instruction{index}
              ? is(
                $test[ $instruction{index} ],
                $expected[0],
"$test_name is list - has scalar index: $instruction{index} - is - $expected[0]"
              )
              : ok(
                0,
"No index passed to test - list_index_scalar - testing - $test_name"
              );
        }
        when ('list_index_ref') {
            return exists $instruction{index}
              ? is_deeply(
                $test[ $instruction{index} ],
                $expected[0],
"$test_name is list - has ref index: $instruction{index} - is_deeply - ref"
              )
              : ok(
                0,
"No index passed to test - list_index_ref - testing - $test_name"
              );
        }
        when ('list_index_like') {
            return exists $instruction{index}
              ? like(
                $test[ $instruction{index} ],
                qr/$expected[0]/,
"$test_name is list - has scalar index: $instruction{index} - like - $expected[0]"
              )
              : ok(
                0,
"No index passed to test - list_index_like - testing - $test_name"
              );
        }
        when ('list_index_obj') {
             return exists $instruction{index}
              ? isa_ok(
                $test[ $instruction{index} ],
                $expected[0],
"$test_name is list - has obj index: $instruction{index} - isa_ok - $expected[0]"
              )
              : ok(
                0,
"No index passed to test - list_index_obj - testing - $test_name"
              );
        }
        when ('list_key_scalar') {
            return exists $instruction{key}
              ? is(
                {@test}->{ $instruction{key} },
                $expected[0],
"$test_name is list - has scalar key: $instruction{key} - is - $expected[0]"
              )
              : ok(
                0,
                "No key passed to test - list_key_scalar - testing - $test_name"
              );
        }
        when ('list_key_ref') {
            return exists $instruction{key}
              ? is_deeply(
                {@test}->{ $instruction{key} },
                $expected[0],
"$test_name is list - has ref key: $instruction{key} - is_deeply - ref"
              )
              : ok( 0,
                "No key passed to test - list_key_ref - testing - $test_name" );
        }
        when ('list_key_like') {
            return exists $instruction{key}
              ? like(
                {@test}->{ $instruction{key} },
                qr/$expected[0]/,
"$test_name is list - has scalar key: $instruction{key} - like - $expected[0]"
              )
              : ok(
                0,
                "No key passed to test - list_key_like - testing - $test_name"
              );
        }
        when ('count') {
             return is(
                scalar @test,
                $expected[0],
"$test_name is list - count - is - $expected[0]"
              );
        }
        when ('count_ref') {
             return is(
                scalar @{ $test[0] },
                $expected[0],
"$test_name is ref - count - is - $expected[0]"
              );
        }
        when ('scalar') {
            return is( $test[0], $expected[0], sprintf "%s is scalar - is - %s",
                $test_name, defined $expected[0] ? $expected[0] : 'undef' );
        }
        when ('hash') {
            return is_deeply( {@test}, $expected[0],
                "$test_name is hash - reference - is_deeply" );
        }
        when ('array') {
            return is_deeply( \@test, $expected[0],
                "$test_name is array - reference - is_deeply" );
        }
        when ('obj') {
            return isa_ok( $test[0], $expected[0],
                "$test_name is Object - blessed - is - $expected[0]" );
        }
        when ('like') {
            return like( $test[0], qr/$expected[0]/,
                "$test_name is like - $expected[0]" );
        }
        when ('true') {
            return is( $test[0], 1, "$test_name is true - 1" );
        }
        when ('false') {
            return is( $test[0], 0, "$test_name is false - 0" );
        }
        when ('undef') {
            return is( $test[0], undef, "$test_name is undef" );
        }
        when ('render') {
            return render_me(
                instance => $test[0],
                expected => $expected[0],
            );
        }
        when ('ok') {
            return ok(@test, "$test_name is ok");
        }
        when ('skip') {
            return ok(1, "$test_name - skip");
        }
        default {
            ok(0);
            diag "Unknown instruction{test}: $_ passed to moon_test_one";
            return;
        }
    }
}

=head2 moon_test
 
    moon_test(
        name => 'Checking Many Things'
        build => {
            class => 'Moonshine::Element', 
            args => {
                tag => 'p',
                text => 'hello'
            }
        },
        instructions => [
            {
                test => 'scalar',
                func => 'tag',
                expected => 'p',
            },
            {
                test => 'scalar',
                action => 'text',
                expected => 'hello',
            },
            { 
                test => 'render'
                expected => '<p>hello</p>'
            },
        ],
    );

=head3 name

The tests name

    name => 'I rule the world',

=head3 instance

    my $instance = My::Object->new();
    instance => $instance,

=head3 build

Build an instance

    build => {
        class => 'My::Object',
        args  => { },
    },

=head3 instructions

    instructions => [
        {
            test => 'scalar',
            func => 'tag',
            expected => 'hello',
        },
        {
            test => 'scalar',
            action => 'text',
            expected => 'hello',
        },
        { 
            test => 'render'
            expected => '<p>hello</p>'
        },
    ],

=head3 subtest

    instructions => [
        {
            test => 'obj',
            func => 'glyphicon',
            args => { switch => 'search' },
            subtest => [
                {
                   test => 'scalar',
                   func => 'class',
                   expected => 'glyphicon glyphicon-search',
                },
                ...
            ]
        }
    ]

=cut

sub moon_test {
    my %instruction = validate_with(
        params => \@_,
        spec   => {
            build        => { type => HASHREF, optional => 1, },
            instance     => { optional => 1, },
            instructions => { type => ARRAYREF },
            name         => { type => SCALAR },
        }
    );

    my $instance =
      $instruction{build}
      ? _build_me( $instruction{build} )
      : $instruction{instance};

    my %test_info = (
        fail   => 0,
        tested => 0,
    );

    foreach my $test ( @{ $instruction{instructions} } ) {
        $test_info{tested}++;
        if ( my $subtests = delete $test->{subtest} ) {
            my ( $test_name, $new_instance ) = _run_the_code(
                {
                    instance => $instance,
                    %{$test}
                }
            );

            $test_info{fail}++
                unless moon_test_one(
                    instance => $new_instance,
                    test => $test->{test},
                    expected => $test->{expected},
                );


            my $new_instructions = {
                instance     => $new_instance,
                instructions => $subtests,
                name         => "Subtest -> $instruction{name} -> $test_name",
            };
                        
            moon_test(%{$new_instructions});
            next;
        }

        $test_info{fail}++
          unless moon_test_one(
            instance => $instance,
            %{$test}
          );
    }

    $test_info{ok} = $test_info{fail} ? 0 : 1;
    return ok(
        $test_info{ok},
        sprintf(
"moon_test: %s - tested %d instructions - success: %d - failure: %d",
            $instruction{name},                        $test_info{tested},
            ( $test_info{tested} - $test_info{fail} ), $test_info{fail},
        )
    );
}

sub _build_me {
    my %instruction = validate_with(
        params => \@_,
        spec   => {
            class => 1,
            new   => { default => 'new' },
            args  => { optional => 1, type => HASHREF },
        }
    );

    my $new = $instruction{new};
    return $instruction{args}
      ? $instruction{class}->$new( $instruction{args} )
      : $instruction{class}->$new;
}

=head2 render_me

Test render directly on a Moonshine::Element.

    render_me(
        instance => $element,
        expected => '<div>echo</div>'
    );

Or test a function..

    render_me(
        instance => $instance,
        func => 'div',
        args     => { data => 'echo' },
        expected => '<div>echo</div>',
    );

=cut

sub render_me {
    my %instruction = validate_with(
        params => \@_,
        spec   => {
            instance => 0,
            func     => 0,
            meth     => 0,
            args     => { default => {} },
            expected => { type => SCALAR },
        }
    );

    my ( $test_name, $instance ) = _run_the_code( \%instruction );

    return is( $instance->render,
        $instruction{expected}, "render $test_name: $instruction{expected}" );
}

sub _run_the_code {
    my $instruction = shift;

    my $test_name;
    if ( my $func = $instruction->{func} ) {
        $test_name = "function: ${func}";
        
        return defined $instruction->{args} 
            ? defined $instruction->{args_list}
                ? (
                    $test_name,
                    $instruction->{instance}->$func( @{ $instruction->{args} } )
                  )
                : (
                    $test_name, $instruction->{instance}->$func( $instruction->{args} // {})
                  )
            : ( $test_name, $instruction->{instance}->$func );
    }
    elsif ( my $meth = $instruction->{meth} ) {
        my $meth_name = svref_2object($meth)->GV->NAME;
        $test_name = "method: ${meth_name}";
        return
          defined $instruction->{args_list}
          ? ( $test_name, $meth->( @{ $instruction->{args} } ) )
          : ( $test_name, $meth->( $instruction->{args} ) );
    }
    elsif ( exists $instruction->{instance} ) {
        $test_name = 'instance';
        return ( $test_name, $instruction->{instance} );
    }

    die(
        'instruction passed to _run_the_code must have a func, meth or instance'
    );
}

=head2 sunrise

    sunrise(); # done_testing();

=cut

sub sunrise {
    my $done_testing = done_testing(shift);
    diag explain $done_testing;
    diag sprintf( '
                                  %s
            ^^                   @@@@@@@@@
       ^^       ^^            @@@@@@@@@@@@@@@
                            @@@@@@@@@@@@@@@@@@              ^^
                           @@@@@@@@@@@@@@@@@@@@
 ---- -- ----- -------- -- &&&&&&&&&&&&&&&&&&&& ------- ----------- ---
 -         --   -  -       -------------------- -       --     -- -
   -      --      -- -- --  ------------- ----  -     ---    - ---  - --
   -  --     -         -      ------  -- ---       -- - --  -- -
 -  -       - -      -           -- ------  -      --  -             --
       -             -        -      -      --   -             -',
        shift // '  \o/  ' );
    return $done_testing;
}

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moonshine-test at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Moonshine-Test>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Moonshine::Test

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Moonshine-Test>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Moonshine-Test>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Moonshine-Test>

=item * Search CPAN

L<http://search.cpan.org/dist/Moonshine-Test/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;    # End of Moonshine::Test
