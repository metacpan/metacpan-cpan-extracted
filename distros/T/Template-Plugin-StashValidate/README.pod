package Template::Plugin::StashValidate;

=head1 NAME

Template::Plugin::StashValidate - MooseX::Params::Validate for template stash values

=head1 DESCRIPTION

Allows a template to validate specific hash keys via MooseX::Params::Validate

=head1 SYNOPSIS

 [% USE StashValidate {
    'advice_discrepant' => { 'isa' => 'ArrayRef | HashRef', 'optional' => 1 },
  } %]

=head1 OVERVIEW

Allows a template to validate keys from the stash (L<Template::Stash>) using
L<MooseX::Params::Validate>. Accepts a hashref as the sole argument, and this is
the C<parameter_spec> that's passed straight through to
L<MooseX::Params::Validate>'s C<validated_hash>. We only validate elements in
the stash for which you've specified an allowed value - other keys in the stash
are ignored.

B<In short, for options, see>: L<MooseX::Params::Validate>.

L<MooseX::Params::Validate> supports both coerced values and default values -
this means the value you put in might not be the value you get out again. This
module supports that - the stash is updated with any changes returned.

=cut

use strict;
use warnings;
use MooseX::Params::Validate;
use base 'Template::Plugin';

=head1 METHODS

=head2 new

This is the method called when you say C<[% USE StashValidate {} %]>, as per
the documentation in L<Template::Plugin>.

=cut

sub new {
    my ($class, $context, $params) = @_;
    my $stash = $context->stash;

    my %check;
    {
        # Template::Stash returns an empty string for undefined values. That's
        # almost certainly NOT what we want here, so knock it out for this block
        no warnings "redefine";
        local *Template::Stash::undefined = sub { return undef; };

        # Take only the values that were specified to be checked
        %check = map {
            my $key = $_;
            my $value = $stash->get( $key );
            defined $value ? ( $key => $value ) : ();
        } keys %$params;
    }

    my %returned = eval { validated_hash( [%check], %$params ) };
    if ( $@ ) {
        # If you're thinking "this is really weird", then yes, you're right.
        # Seems to be the right thing to do though.
        $class->error( $@ );
        die $class->error();
    }

    # Update the values in the stash if they might have been changed
    for my $key ( keys %returned ) {
        $stash->set( $key, $returned{ $key } );
    }

    return 1;
}

=head1 AUTHOR

Peter Sergeant - C<pete@clueball.com>, while working for
L<Net-A-Porter|http://www.net-a-porter.com/>.

=cut

1;
