## no critic (Version,PodSections,Warnings,Rcs)
package Object::Deadly::_unsafe;

use strict;

use overload ();
my $death = Object::Deadly->get_death;
overload->import(
    map {
        my $bad_operation = $_;

        # returns a pair.
        $bad_operation => sub {

            ## no critic Local
            local *__ANON__ = __PACKAGE__ . "::$bad_operation";
            $death->( $_[0], "Overloaded $bad_operation" );
            }
        }
        map { split ' ' }    ## no critic EmptyQuotes
        values %overload::ops    ## no critic PackageVars
);

# Kill off all UNIVERSAL things and try it at several points during
# execution just in case someone added something along the way.
use Object::Deadly ();
Object::Deadly->kill_UNIVERSAL;

# Eval CHECK and INIT blocks into existance but only if we haven't
# reached the main program yet. This is just to avoid the warning.
use B ();
use English '$EVAL_ERROR';       ## no critic

BEGIN {
    if ( not ${ B::main_start() } ) {
        eval <<"CODE";           ## no critic
#line @{[__LINE__]} "@{[__FILE__]}"
            CHECK { Object::Deadly->kill_UNIVERSAL; }
            INIT  { Object::Deadly->kill_UNIVERSAL; }
CODE
        croak $EVAL_ERROR if $EVAL_ERROR;
    }
}

END { Object::Deadly->kill_UNIVERSAL; }

Object::Deadly->kill_function('AUTOLOAD');

use vars '%SIMPLE_OBJECTS';

# DESTROY is the only legal method for these objects. It has to be.
sub DESTROY {
    delete $Object::Deadly::SIMPLE_OBJECTS{ Object::Deadly::refaddr $_[0] };
    return;
}

sub death {    ## no critic RequireFinalReturn
               # The common death
    my ( $self, $bad_operation ) = @_;

    my $unsafe_implementation_class = Object::Deadly::blessed $self;
    my $addr                        = Object::Deadly::refaddr $self;
    my $name = sprintf '%s=(0x%07x)', $unsafe_implementation_class, $addr;
    my $message;
    if ( exists $SIMPLE_OBJECTS{$addr} ) {

        # Fetch the message in the object by switching the object into
        # something that's safe.
        my $safe_implementation_class = $unsafe_implementation_class;
        $safe_implementation_class =~ s/\::_unsafe\z/::_safe/mx;

        bless $self, $safe_implementation_class;
        $message = $$self;    ## no critic DoubleSigils
        bless $self, $unsafe_implementation_class;

        Object::Deadly::confess
            "Attempt to call $bad_operation on $name: $message";
    }
    else {
        Object::Deadly::confess "Attempt to call $bad_operation on $name";
    }
}

1;

__END__

=head1 NAME

Object::Deadly::_unsafe - Implementation for the deadly object

=head1 METHODS

=over

=item C<< $obj->DESTROY >>

The DESTROY method doesn't die. This is defined so it won't be
AUTOLOADed or fetched from UNIVERSAL.

=item C<< $obj->isa >>

=item C<< $obj->can >>

=item C<< $obj->version >>

=item C<< $obj->DOES >>

=item C<< $obj->import >>

=item C<< $obj->require >>

=item C<< $obj->use >>

=item C<< $obj->blessed >>

=item C<< $obj->dump >>

=item C<< $obj->peek >>

=item C<< $obj->refaddr >>

=item C<< $obj->exports >>

=item C<< $obj->moniker >>

=item C<< $obj->plural_moniker >>

=item C<< $obj->which >>

=item C<< $obj->AUTOLOAD >>

Each of AUTOLOAD, a named list of known UNIVERSAL functions and then a
query for everything currently known are all implemented with C<<
Object::Deadly->get_death >> to prevent anything from sneaking through
to a successful call against something in UNIVERSAL.

That list of functions are what core perl uses plus a bunch from CPAN
modules including L<UNIVERSAL>, L<UNIVERSAL::require>,
L<UNIVERSAL::dump>, L<UNIVERSAL::exports>, L<UNIVERSAL::moniker>,
L<UNIVERSAL::which>. That's just the list as it exists today. If
someone else creates a new one and you load it, be sure to do it
*prior* to loading this module so I can have at least a chance at
noticing anything it's loaded.

=back

=head1 SEE ALSO

L<Object::Deadly>, L<Object::Deadly::_safe>

=cut

1;
