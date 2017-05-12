use 5.008001;
use utf8;
use strict;
use warnings FATAL => 'all';

use Class::MOP 0.98;
use Muldis::Rosetta::Interface 0.016000;

###########################################################################
###########################################################################

{ package Muldis::Rosetta::Validator; # module
    our $VERSION = '0.016000';
    $VERSION = eval $VERSION;

    use namespace::autoclean 0.09;

    use Try::Tiny 0.04;

    use Test::More 0.92;
    use Test::Moose 0.98;

###########################################################################

sub main {
    my ($args) = @_;
    my ($engine_name, $process_config)
        = @{$args}{'engine_name', 'process_config'};

    if (!defined $engine_name or $engine_name eq q{}) {
        BAIL_OUT( q{Muldis::Rosetta::Validator: Bad :$engine_name arg;}
            . q{ it is undefined or it is the empty string.} );
        return;
    }

    diag( "Muldis::Rosetta::Validator starting test of $engine_name." );

    # Load Perl module implementing the Muldis Rosetta Engine.
    my $is_bailing_now = 0;
    try {
        Class::MOP::load_class( $engine_name );
    }
    catch {
        BAIL_OUT( q{Muldis::Rosetta::Validator: Could not load}
            . qq{ Muldis Rosetta Engine module '$engine_name': $_.} );
        $is_bailing_now = 1;
    };
    return
        if $is_bailing_now;
    if (!Class::MOP::is_class_loaded( $engine_name )) {
        BAIL_OUT( q{Muldis::Rosetta::Validator:}
            . q{ Could not load Muldis Rosetta Engine module}
            . qq{ '$engine_name': while that file did compile without}
            . q{ errors, it did not declare the same-named module.} );
        return;
    }
    if (!$engine_name->can( 'select_machine' )) {
        BAIL_OUT( q{Muldis::Rosetta::Validator:}
            . q{ The Muldis Rosetta Engine module '$engine_name' does not}
            . q{ provide the select_machine() constructor function.} );
        return;
    }
    diag( "$engine_name loads + declares select_machine() constructor." );
    pass( 'Engine module loads + declares select_machine() constructor' );

    # Instantiate a Muldis Rosetta DBMS / virtual machine.
    my $machine = &{$engine_name->can( 'select_machine' )}();
    pass( 'no death from instantiating new/singleton virtual machine' );
    does_ok( $machine, 'Muldis::Rosetta::Interface::Machine' );
    my $process = $machine->new_process({
        'process_config' => $process_config,
    });
    pass( 'no death from instantiating new VM process' );
    does_ok( $process, 'Muldis::Rosetta::Interface::Process' );
    $process->update_hd_command_lang({ 'lang' => [ 'Muldis_D',
        'http://muldis.com', '0.110.0', 'HDMD_Perl5_STD',
        { catalog_abstraction_level => 'rtn_inv_alt_syn',
        op_char_repertoire => 'extended' } ] });

    _scenario_foods_suppliers_shipments_v1( $process );

    diag( "Muldis::Rosetta::Validator finished test of $engine_name." );

    done_testing();

    return;
}

###########################################################################

sub _scenario_foods_suppliers_shipments_v1 {
    my ($process) = @_;

    # Declare our example literal source data sets.

    my $src_suppliers = $process->new_value({
        'source_code' => [ 'Relation', [ [ 'farm', 'country' ] => [
            [ 'Hodgesons', 'Canada'  ],
            [ 'Beckers'  , 'England' ],
            [ 'Wickets'  , 'Canada'  ],
        ] ] ],
    });
    pass( 'no death from loading example suppliers data into VM' );
    does_ok( $src_suppliers, 'Muldis::Rosetta::Interface::Value' );

    my $src_foods = $process->new_value({
        'source_code' => [ 'Relation', [ [ 'food', 'colour' ] => [
            [ 'Bananas', 'yellow' ],
            [ 'Carrots', 'orange' ],
            [ 'Oranges', 'orange' ],
            [ 'Kiwis'  , 'green'  ],
            [ 'Lemons' , 'yellow' ],
        ] ] ],
    });
    pass( 'no death from loading example foods data into VM' );
    does_ok( $src_foods, 'Muldis::Rosetta::Interface::Value' );

    my $src_shipments = $process->new_value({
        'source_code' => [ 'Relation', [ [ 'farm', 'food', 'qty' ] => [
            [ 'Hodgesons', 'Kiwis'  , 100 ],
            [ 'Hodgesons', 'Lemons' , 130 ],
            [ 'Hodgesons', 'Oranges',  10 ],
            [ 'Hodgesons', 'Carrots',  50 ],
            [ 'Beckers'  , 'Carrots',  90 ],
            [ 'Beckers'  , 'Bananas', 120 ],
            [ 'Wickets'  , 'Lemons' ,  30 ],
        ] ] ],
    });
    pass( 'no death from loading example shipments data into VM' );
    does_ok( $src_shipments, 'Muldis::Rosetta::Interface::Value' );

    # Execute a query against the virtual machine, to look at our sample
    # data and see what suppliers there are for foods coloured 'orange'.

    my $desi_colour = $process->new_value({
        'source_code' => [ 'Text', 'orange' ] });
    pass( 'no death from loading desired colour into VM' );
    does_ok( $desi_colour, 'Muldis::Rosetta::Interface::Value' );

    my $matched_suppl = $process->func_invo({
        'function' => 'semijoin',
        'args' => {
            'source' => $src_suppliers,
            'filter' => $process->func_invo({
                'function' => 'join',
                'args' => {
                    'topic' => [ 'Set', [
                        $src_shipments,
                        $src_foods,
                        [ 'Relation', [ { 'colour' => $desi_colour } ] ],
                    ] ],
                },
            }),
        },
    });
    pass( 'no death from executing search query' );
    does_ok( $matched_suppl, 'Muldis::Rosetta::Interface::Value' );

    my $matched_suppl_as_perl = $matched_suppl->hd_source_code();
    pass( 'no death from fetching search results from VM' );

    # Finally, use the result somehow (not done here).
    # The result should be:
    # [ 'Relation', [ [ 'farm', 'country' ] => [
    #     [ 'Hodgesons', 'Canada'  ],
    #     [ 'Beckers'  , 'England' ],
    # ] ] ],

    diag( 'debug: orange food suppliers found:' );
#    diag( $matched_suppl_as_perl->as_perl() );
    diag( ' TODO, as_perl()' );

    return;
}

###########################################################################

} # module Muldis::Rosetta::Validator

###########################################################################
###########################################################################

1; # Magic true value required at end of a reusable file's code.
__END__

=pod

=encoding utf8

=head1 NAME

Muldis::Rosetta::Validator -
A common comprehensive test suite to run against all Engines

=head1 VERSION

This document describes Muldis::Rosetta::Validator version 0.16.0 for Perl
5.

=head1 SYNOPSIS

This can be the complete content of the main C<t/*.t> file for an example
Muldis Rosetta Engine distribution:

    use 5.008001;
    use utf8;
    use strict;
    use warnings FATAL => 'all';

    # Load the test suite.
    use Muldis::Rosetta::Validator;

    # Run the test suite.
    Muldis::Rosetta::Validator::main({
        'engine_name' => 'Muldis::Rosetta::Engine::Example',
        'process_config' => {},
    });

    1;

The current release of Muldis::Rosetta::Validator uses L<Test::More>
internally, and C<main()> will invoke it to output what the standard Perl
test harness expects.  I<It is expected that this will change in the future
so that Validator does not use Test::More internally, and rather will
simply return test results in a data structure that the main t/*.t then can
disseminate and pass the components to Test::More itself.>

=head1 DESCRIPTION

The Muldis::Rosetta::Validator Perl 5 module is a common comprehensive test
suite to run against all Muldis Rosetta Engines.  You run it against a
Muldis Rosetta Engine module to ensure that the Engine and/or the database
behind it implements the parts of the Muldis Rosetta API that your
application needs, and that the API is implemented correctly.
Muldis::Rosetta::Validator is intended to guarantee a measure of quality
assurance (QA) for Muldis::Rosetta, so your application can use the
database access framework with confidence of safety.

Alternately, if you are writing a Muldis Rosetta Engine module yourself,
Muldis::Rosetta::Validator saves you the work of having to write your own
test suite for it.  You can also be assured that if your module passes
Muldis::Rosetta::Validator's approval, then your module can be easily
swapped in for other Engine modules by your users, and that any changes you
make between releases haven't broken something important.

Muldis::Rosetta::Validator would be used similarly to how Sun has an
official validation suite for Java Virtual Machines to make sure they
implement the official Java specification.

For reference and context, please see the FEATURE SUPPORT VALIDATION
documentation section in the core L<Muldis::Rosetta> module.

Note that, as is the nature of test suites, Muldis::Rosetta::Validator will
be getting regular updates and additions, so that it anticipates all of the
different ways that people want to use their databases.  This task is
unlikely to ever be finished, given the seemingly infinite size of the
task.  You are welcome and encouraged to submit more tests to be included
in this suite at any time, as holes in coverage are discovered.

I<This documentation is pending.>

=head1 INTERFACE

I<This documentation is pending; this section may also be split into
several.>

=head1 DIAGNOSTICS

I<This documentation is pending.>

=head1 CONFIGURATION AND ENVIRONMENT

I<This documentation is pending.>

=head1 DEPENDENCIES

This file requires any version of Perl 5.x.y that is at least 5.8.1, and
recommends one that is at least 5.10.1.

It also requires these Perl 5 packages that are bundled with any version of
Perl 5.x.y that is at least 5.10.1, and are also on CPAN for separate
installation by users of earlier Perl versions:
L<Test::More-ver(0.92..*)|Test::More>.

It also requires these Perl 5 packages that are on CPAN:
L<namespace::autoclean-ver(0.09..*)|namespace::autoclean>,
L<Try::Tiny-ver(0.04..*)|Try::Tiny>, L<Class::MOP-ver(0.98..*)|Class::MOP>,
L<Test::Moose-ver(0.98..*)|Test::Moose>.

It also requires these Perl 5 packages that are in the current
distribution:
L<Muldis::Rosetta::Interface-ver(0.16.0..*)|Muldis::Rosetta::Interface>.

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

Go to L<Muldis::Rosetta> for the majority of distribution-internal
references, and L<Muldis::Rosetta::SeeAlso> for the majority of
distribution-external references.

=head1 BUGS AND LIMITATIONS

I<This documentation is pending.>

=head1 AUTHOR

Darren Duncan (C<darren@DarrenDuncan.net>)

=head1 LICENSE AND COPYRIGHT

This file is part of the Muldis Rosetta framework.

Muldis Rosetta is Copyright © 2002-2010, Muldis Data Systems, Inc.

See the LICENSE AND COPYRIGHT of L<Muldis::Rosetta> for details.

=head1 TRADEMARK POLICY

The TRADEMARK POLICY in L<Muldis::Rosetta> applies to this file too.

=head1 ACKNOWLEDGEMENTS

The ACKNOWLEDGEMENTS in L<Muldis::Rosetta> apply to this file too.

=cut
