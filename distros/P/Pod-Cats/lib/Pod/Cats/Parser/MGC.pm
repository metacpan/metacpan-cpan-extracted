package Pod::Cats::Parser::MGC;
use strict;
use warnings;
use 5.010;

use parent qw(Parser::MGC);

our $VERSION = '0.08';

=head1 NAME

Pod::Cats::Parser::MGC - Parser for C<< X<elements> >> in L<Pod::Cats>

=head1 DESCRIPTION

Entities in Pod::Cats can be demarcated by any set of delimiters, configured in
L<Pod::Cats/new>. That configuration ends up here.

Given a string with entities so demarcated, recursively extracts the contents of
the entities and passes them to the Pod::Cats object for handling.

Thus collates a sequence of (normal string, element, normal string), etc. The
exact contents of I<element> depends on what your Pod::Cats subclass does with
the contents of the element; but the contents of I<normal string> is just the
original text up to the first element.

I<element> may, of course, be another sequence of the above, because it's
pseudo-recursive (actually it just trundles along iteratively, maintaining a
nesting level and an expectation of ending delimiters).

=head1 METHODS

=head2 new

Constructs a new parser object. Accepts a hash of C<obj> and C<delimiters>.

C<obj> is required and must contain a Pod::Cats subclass; C<delimiters> defaults
to C<< "<" >>, like normal POD.

See L<Pod::Cats/new> for delimiters.

=cut

sub new {
    my $self = shift->SUPER::new(@_);
    my %o = @_;
    $self->{obj} = $o{object} or die "Expected argument 'object'";
    $self->{delimiters} = $o{delimiters} || "<";

    return $self;
}

=head2 parse

See L<Parser::MGC> for how parse works. This just finds entities based on the
configured delimiters, and fires events to the object provided to L</new>.

=cut

sub parse {
    my $self = shift;
    my $pod_cats = $self->{obj};

    # Can't grab the whole lot with one re (yet) so I will grab one and expect
    # more.

    my $ret = $self->sequence_of(sub { 
        my $odre;
        if ($self->scope_level) {
            $odre = qr/\Q$self->{delimiters}/;
        }
        else {
            $odre = qr/[\Q$self->{delimiters}\E]/; 
        }

        $self->any_of(
            sub {
                # After we're in 1 level we've committed to an exact delimiter.
                my $tag = $self->expect( qr/[A-Z](?=$odre)/ );

                $self->commit;

                my $odel;
                
                if ($self->scope_level) {
                    $odel = $self->expect( $self->{delimiters} );
                }
                else {
                    $odel = $self->expect( $odre );
                    $odel .= $self->expect( qr/\Q$odel\E*/ );
                }

                (my $cdel = $odel) =~ tr/<({[/>)}]/;

                # The opening delimiter is the same char repeated, never
                # different ones.
                local $self->{delimiters} = $odel;

                if ($tag eq 'Z') {
                    $self->expect( $cdel );
                    $self->{level}--;
                    return;
                }

                my $retval = $pod_cats->handle_entity( 
                    $tag => @{ 
                        $self->scope_of( undef, \&parse, $cdel ) 
                    }
                );
                return $retval;
            },

            sub { 
                if ($self->scope_level) {
                    return $self->substring_before( qr/[A-Z]\Q$self->{delimiters}/ );
                }
                else {
                    return $self->substring_before( qr/[A-Z]$odre/ );
                }
            },
        )
   });
}

1;
