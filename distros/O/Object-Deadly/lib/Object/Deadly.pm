## no critic (PodSections,UseWarnings,RcsKeywords)
package Object::Deadly;

use strict;

use Devel::Symdump ();
use Scalar::Util qw(refaddr blessed);
use English '$EVAL_ERROR';    ## no critic Interpolation
use Carp::Clan 5.4;

use vars '$VERSION';          ## no critic Interpolation
$VERSION = '0.09';

sub new_with {

    # Public, overridable class method. Returns an _unsafe
    # object. Accepts a single reference which will be blessed.
    my ( $class, $self ) = @_;
    my $implementation_class = "$class\::_unsafe";

    return bless $self, $implementation_class;
}

sub new {

    # Public, overridable class method. Returns an ${class}::_unsafe
    # object.

    my $class                = shift @_;
    my $implementation_class = "$class\::_unsafe";

    my $data;
    if (@_) {
        $data = shift @_;
    }
    else {

        # No sense in loading this unless we actually use it.
        require Devel::StackTrace;

        $data = Devel::StackTrace->new( ignore_package => $class )->as_string;
        $data =~ s/\AT/Object::Deadly t/xm;

    }

    my $self = bless \$data, $implementation_class;
    no strict 'refs';    ## no critic strict
    ${"${implementation_class}::SIMPLE_OBJECTS"}{ refaddr $self} = undef;

    return $self;
}

sub kill_function {

    # Public, overridable class method. Creates a deadly function in
    # the ${class}::_unsafe class.

    my ( $class, $func, $death ) = @_;
    my $implementation_class = "$class\::_unsafe";
    my $function_name        = "$implementation_class\::$func";
    no strict 'refs';    ## no critic Strict

    if ( defined &$function_name ) {    ## no critic Sigil
        return;
    }

    # Get a default death if our caller hasn't given us something
    # special.
    if ( not defined $death ) {
        $death = $class->get_death;
    }

    my $src = <<"PROXY_FOR_DEATH";
#line @{[__LINE__+2]} "@{[__FILE__]}"
        package $implementation_class;
        \$death = \$death;
        sub $func {
            if ( defined Object::Deadly::blessed \$_[0] ) {

                # Object method calls are fatal.
                \$death->( \$_[0], "Function $func" );
            }
            else {
                my \$class = shift \@_;
                return \$class->SUPER::$func( \@_ );
            }
        }
PROXY_FOR_DEATH
    eval $src;    ## no critic eval
    if ($EVAL_ERROR) {
        croak "$src\n$EVAL_ERROR";
    }

    return 1;
}

# A dictionary of stuff that can show up in UNIVERSAL.
our @UNIVERSAL_METHODS = (

    # core perl
    qw( isa can VERSION ),

    # core perl 5.9.4+
    'DOES',

    # UNIVERSAL.pm
    'import',

    # UNIVERSAL/require.pm
    qw( require use ),

    # UNIVERSAL/dump.pm
    qw( blessed dump peek refaddr ),

    # UNIVERSAL/exports.pm
    'exports',

    # UNIVERSAL/moniker.pm
    qw( moniker plural_moniker ),

    # UNIVERSAL/which.pm
    'which',

    # SUPER.pm
    qw( super SUPER ),
);

sub kill_UNIVERSAL {

    # Public, overridable method call. Creates deadly functions in
    # ${class}::_unsafe to mask all UNIVERSAL methods.

    my $class = shift @_;
    for my $fqf_function (
        @UNIVERSAL_METHODS,

        # Anything else we happen to find
        Devel::Symdump->rnew('UNIVERSAL')->functions
        )
    {
        my $function = $fqf_function;
        $function =~ s/\AUNIVERSAL:://mx;

        $class->kill_function($function);
    }

    return 1;
}

sub get_death {

    # Public, overridable method call. Returns the _death function
    my $class = shift @_;

    no strict 'refs';    ## no critic Strict
    return \&{"${class}::_unsafe::death"};
}

# Compile and load our implementing classes.
use Object::Deadly::_safe   ();
use Object::Deadly::_unsafe ();

## no critic EndWithOne
'For the SAKE... of the FUTURE of ALL... mankind... I WILL have
a... SMALL sprite!';

__END__

=head1 NAME

Object::Deadly - An object that dies whenever examined

=head1 SYNOPSIS

  use Object::Deadly;
  use Test::Exception 'lives_ok';
  
  # Test that a few functions inspect their parameters safely
  lives_ok { some_function( Object::Deadly->new ) } 'some_function';
  lives_ok { Dumper( Object::Deadly->new ) } 'Data::Dumper';

=head1 DESCRIPTION

This object is meant to be used in testing. All possible overloading
and method calls die. You can pass this object into methods which are
not supposed to accidentally trigger any potentially overloading.

This problem arose when testing L<Data::Dump::Streamer> and
L<Carp>. The former was triggering overloaded object methods instead
of just dumping their data. L<Data::Dump::Streamer> is now safe for
overloaded objects but it wouldn't have been unless it hadn't have
been tested with a deadly, overloaded object.

=head1 DEALING WITH DEATH

TODO

=head1 METHODS

=over

=item C<< Object::Deadly->new() >>

=item C<< Object::Deadly->new( MESSAGE ) >>

The class method C<< Object::Deadly->new >> returns an C<< Object::Deadly >>
object. Dies with a stack trace and a message when evaluated in any
context. The default message contains a stack trace from where the
object is created.

=item C<< Object::Deadly->new_with( REFERENCE ) >>

The class method C<< Object::Deadly->new_with >> returns an C<< Object::Deadly >>
object. Dies with a stack trace and a message when evaluated in any
context. The default message contains a stack trace from where the
object is created.

=item C<< Object::Deadly->kill_function( FUNCTION NAME ) >>

=item C<< Object::Deadly->kill_function( FUNCTION NAME, DEATH CODE REF ) >>

The class method kill_function accepts a function name like C<< isa >>,
C<< can >>, or similar and creates a function in the
C<< Object::Deadly::_unsafe >> class of the same name.

An optional second argument is a code reference to die with. This
defaults to C<< Object::Deadly->can( '_death' ) >>.

=item C<< Object::Deadly->kill_UNIVERSAL >>

This class method kills all currently known UNIVERSAL functions so
they can't be called on a C<< Object::Deadly >> object. This includes
a list of methods known to the author and then an inspection of
UNIVERSAL::.

=item C<< Object::Deadly->get_death >>

Returns the function C<< Object::Deadly::_death >>.

=back

=head1 PRIVATE FUNCTIONS

The following functions are all private and not meant for public
consumption.

=over

=item C<< _death( $obj ) >>

This function temporarilly reblesses the object into
C<< Object::Deadly::_safe >>, extracts the message from inside of it,
and C<< confess >>'s with it.

=back

=head1 AUTHOR

Joshua ben Jore, C<< <jjore at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<< bug-object-deadly at
rt.cpan.org >>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Deadly>. I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Object::Deadly

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Object-Deadly>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Object-Deadly>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Object-Deadly>

=item * Search CPAN

L<http://search.cpan.org/dist/Object-Deadly>

=back

=head1 ACKNOWLEDGEMENTS

Yves Orton and Yitzchak Scott-Thoennes.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Joshua ben Jore, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
