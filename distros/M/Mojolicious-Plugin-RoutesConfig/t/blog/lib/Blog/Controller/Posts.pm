package Blog::Controller::Posts;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $self = shift;

  if ($self->req->method eq 'POST') {
    return $self->render(status => 201, text => '');    #Created
  }

  return
    $self->render(
               title => 'Latest Posts',
               posts => [
                         {title => 'One post',  body => 'content of the post'},
                         {title => 'One post',  body => 'content of the post'},
                         {title => 'Post2',     body => 'content of the post2'},
                         {title => 'Post3',     body => 'content of the post3'},
                         {title => 'One post4', body => 'content of the post4'},
                         {title => 'One post5', body => 'content of the post5'},
                         {title => 'One post6', body => 'content of the pos6'},
                        ]
                 );
}

1;
