package Template::Lace::ModelRole;

use Moo::Role;

sub template {
  my ($class) = @_;
  return;
}

sub prepare_dom {
  my ($class, $dom) = @_;
}


sub process_dom {
  my ($self, $dom) = @_;
}

1;

=head1 NAME

Template::Lace::ModelRole

=head1 SYNOPSIS

    package MyApp::User;

    use Moo;
    with 'Template::Lace::ModelRole';


=head1 DESCRIPTION

The minimal interface that a model class must provide.

=head1 METHODS

This interface exposes the following public methods.  For detailed examples
see L<Template::Lace>.

=head2 template

Class method that should return a string which is the template for this model

=head2 prepare_dom

Class method that allows you to alter the DOM once at setup time.

=head2 process_dom

Instance method that recieves the DOM and allows you to transform it at
request time.

=head1 SEE ALSO
 
L<Template::Lace>.

=head1 AUTHOR

Please See L<Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Lace> for copyright and license information.

=cut 
