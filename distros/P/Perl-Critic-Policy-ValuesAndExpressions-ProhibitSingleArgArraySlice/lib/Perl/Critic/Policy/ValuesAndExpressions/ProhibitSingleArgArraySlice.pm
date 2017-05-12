package Perl::Critic::Policy::ValuesAndExpressions::ProhibitSingleArgArraySlice;
our $AUTHORITY = 'cpan:XSAWYERX';
# ABSTRACT: Prohibit using an array slice with only one index
$Perl::Critic::Policy::ValuesAndExpressions::ProhibitSingleArgArraySlice::VERSION = '0.004';
use strict;
use warnings;

use parent 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(:severities :classification :ppi);

use constant 'DESC' => 'Single argument to array slice';
use constant 'EXPL' => 'Using an array slice returns a list, '
                     . 'even when accessing a single value. '
                     . 'Instead, please rewrite this as a a '
                     . 'single value access, not array slice.';

sub supported_parameters { () }
sub default_severity     {$SEVERITY_HIGH}
sub default_themes       {'bugs'}
sub applies_to           {'PPI::Token::Symbol'}

# TODO Check for a function in the subscript? Strict mode?

sub violates {
    my ( $self, $elem ) = @_;
    $elem->isa('PPI::Token::Symbol')
        or return ();

    substr( "$elem", 0, 1 ) eq '@'
        or return ();

    my $next = $elem->snext_sibling;
    $next && $next->isa('PPI::Structure::Subscript')
        or return ();

    my @children = $next->children;
    @children > 1
        and return ();

    @children == 0
        and return $self->violation( 'Empty subscript',
        'You have an array slice with an empty subscript', $next, );

    my $child          = $children[0];
    my @child_elements = $child->elements;

    @child_elements > 1
        and return ();

    @children == 0
        and return $self->violation( 'Empty expression subscript',
        'You have an array slice with an empty expression subscript',
        $next, );

    my $element = $child_elements[0];

    # @foo[1]
    $element->isa('PPI::Token::Number')
        or return ();

    return $self->violation( DESC(), EXPL(), $next );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitSingleArgArraySlice - Prohibit using an array slice with only one index

=head1 VERSION

version 0.004

=head1 DESCRIPTION

When using an array slice C<@foo[]>, you can retrieve multiple values by
giving more than one index. Sometimes, however, either due to typo or
inexperience, we might only provide a single index.

Perl warns you about this, but it will only do this during runtime. This
policy allows you to detect it statically.

  # scalar context, single value retrieved
  my $one_value = $array[$index];            # ok

  # List context, multiple values retrieved
  my @values    = @array[ $index1, $index2 ] # ok

  # Scalar context, single value retrived (the last item in the array)
  # Perl will warn you, but only in runtime
  my $value     = @array[$index];            # not ok

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 SEE ALSO

L<Perl::Critic>

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Sawyer X.

This is free software, licensed under:

  The MIT (X11) License

=cut
