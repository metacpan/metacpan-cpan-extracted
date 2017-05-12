package Template::Lace::ComponentCallback;

use warnings;
use strict;
use Template::Lace::DOM;

sub new { return bless pop, shift }
sub cb { return shift->{cb} }
sub make_dom { return Template::Lace::DOM->new(pop) }
sub model_class { return ref(shift) }

sub create {
  my $self = shift;
  return bless +{ cb => $self, @_ }, ref($self);
}

sub get_processed_dom {
  my $self = shift;
  local $_ = $self;
  local %_ =  %$self;
  my $response = $self->{cb}->($self, %$self);
  return ref($response) ?
    $response :
    $self->make_dom($response);
}

1;

=head1 NAME

Template::Lace::ComponentCallback - Create a component easily from a coderef

=head1 SYNOPSIS

    {
      package Local::Template::User;

      use Moo;
      with 'Template::Lace::ModelRole';

      has [qw/title story/] => (is=>'ro', required=>1);

      sub template {q[
        <html>
          <head>
            <title></title>
          </head>
          <body>
            <div id='story'></div>
            <tag-anchor href='more.html' target='_top'>
              See More
            </tag-anchor>
          </body>
        </html>
      ]}

      sub process_dom {
        my ($self, $dom) = @_;
        $dom->title($self->title)
          ->at('#story')
          ->content($self->story);
      }
    }

    use Template::Lace::ComponentCallback;
    my $factory = Template::Lace::Factory->new(
      model_class=>'Local::Template::User',
      component_handlers=>+{
        tag => {
          anchor => Template::Lace::ComponentCallback=>new(sub {
            my ($self, %attrs) = @_;
            return "<a href='$_{href}' target='$_{target}'>$_{content}</a>";
          }),
        },
      },
    );

In this case C<%attrs> are the results of processing attributes.

B<NOTE> You might prefer to call this via L<Template::Lace::Utils> instead.

=head1 DESCRIPTION

Lets you make quick and dirty components from a coderef.  To make this even
faster and dirtier we localize $_ to $self and %_ to %attrs.

=head1 METHODS

This class defines the following public instance methods:

sub make_dom

Create an instance of L<Template::Lace::DOM>.  Useful if you have complex
component setup and transformation.

=head1 SEE ALSO
 
L<Template::Lace>.

=head1 AUTHOR

Please See L<Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Lace> for copyright and license information.

=cut 
