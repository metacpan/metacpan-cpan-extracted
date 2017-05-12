package Template::Lace::Model::HasChildren;

use Moo::Role;

my @children = ();

sub children { @children }

sub add_child { push @children, pop }

1;

=head1 NAME

Template::Lace::Model::HasChildren - Collection children components

=head1 SYNOPSIS

    package  MyApp::Template::List;

    with 'Template::Lace::ModelRole',
      'Template::Lace::Model::HasChildren';

    1;

=head1 DESCRIPTION

Collects any children components that might be added.

Please note these are the children components added as part of the model to
which this component is attached.  This component might define its own component
hierachy.

=head1 METHODS

This interface exposes the following public methods

=head2 children

Returns an array of the child components under this component (as defined by
the top model component hierachy).

=head1 SEE ALSO
 
L<Template::Lace>.

=head1 AUTHOR

Please See L<Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Lace> for copyright and license information.

=cut 
