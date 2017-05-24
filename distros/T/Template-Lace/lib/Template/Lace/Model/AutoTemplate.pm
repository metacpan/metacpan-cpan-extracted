package Template::Lace::Model::AutoTemplate;

use Moo::Role;
use File::Spec;

sub get_path_to_template {
  my ($class) = @_;
  my @parts = split("::", $class);
  my $filename = lc(pop @parts);
  my $path = "$class.pm";
  $path =~s/::/\//g;
  my $inc = $INC{$path};
  my $base = $inc;
  $base =~s/$path$//g;
  return my $template_path = File::Spec->catfile($base, @parts, $filename.'.html');
}

sub slurp_template_from {
  my ($class, $template_path) = @_;
  open(my $fh, '<', $template_path)
    || die "can't open '$template_path': $@";
  local $/; my $slurped = $fh->getline;
  close($fh);
  return $slurped;
}

sub template {
  my ($class, @args) = @_;
  my $template_path = $class->get_path_to_template;
  return $class->slurp_template_from($template_path);
}

1;

=head1 NAME

Template::Lace::Model::AutoTemplate - More easily find your template

=head1 SYNOPSIS

Create a template class at path $HOME/lib/MyApp/Template/List.pm

    package  MyApp::Template::List;

    use Moo;
    with 'Template::Lace::Model::AutoTemplate';

    has 'items' => (is=>'ro', required=>1);

    sub process_dom {
      my ($self, $dom) = @_;
      $dom->ol('#todos'=>$self->items);
    }

Also create an HTML file like this at $HOME/lib/MyApp/Template/list.html

    <html>
      <head>
        <title>Things To Do</title>
      </head>
      <body>
        <ol id='todos'>
          <li>What To Do?</li>
        </ol>
      </body>
    </html>

When you create an factory of the template class, we automatically load the
template from the file and make it available for running transformations.

=head1 DESCRIPTION

By default we look for a string returned from a method c<template> in your class
to provide the source for your generated HTML.  This can be handy for small templates
but often when a template is larger or when you have an HTML designer you prefer to
have your templates in a stand alone file.  This role will first check if you are
returning something from C<template> method and if not it will look for a file in the
same directory as the template class with a name based on the class.  If it finds the
file it with use that as your template.

The convention for the filename of the HTML version of the template is to take the
class file name, replace the '.pm' with '.html' and lowercase the name.  For example
if you have a class 'MyApp::Templates::User', at '$HOME/lib/MyApp/Templates/User.pm'
we'd expect to find a file template at '$HOME/lib/MyApp/Templates/user.html'.

Since its generally not great practice to rely on mixed case alone to distinguish
your filenames this convention should be acceptable.  Your results may vary. You can
override the method 'get_path_to_template' if you prefer a different lookup
convention (or even hardcode a particular path).

=head1 SEE ALSO
 
L<Template::Lace>.

=head1 AUTHOR

Please See L<Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Lace> for copyright and license information.

=cut 
