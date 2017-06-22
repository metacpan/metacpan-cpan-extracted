package Rapi::Blog::Controller::Remote;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use strict;
use warnings;

use RapidApp::Util ':all';
use Rapi::Blog::Util;

# This is the general-purpse controller for handing domain-specific 
# custom-code endpoint requests outside/separate of RapidApp


sub comment :Local :Args(1) {
  my ($self, $c, $arg) = @_;
  
  return $self->add_comment($c) if ($arg eq 'add');
  
  
  $self->error_response($c,"bad comment argument '$arg'");
}

sub add_comment {
  my ($self, $c) = @_;
  
  # Ignore via generic redirect if its not a POST
  $c->req->method eq 'POST' or return $c->res->redirect( $c->mount_url.'/', 307 );
  
  my $User = $c->user->linkedRow or return $self->error_response($c,
    "Not logged in or unable to find current user"
  );
  
  $User->can_comment or return $self->error_response($c,
    "Add comment: permission denied"
  );
  
  my $body = $c->req->params->{body} or return $self->error_response($c,"missing param 'body'");
  
  my %data;
  my $Post;
  
  if(my $parent_id = $c->req->params->{parent_id}) {
    my $pComment = $c->model('DB::Comment')->search_rs({ 'me.id' => $parent_id })->first
      or return $self->error_response($c,"Comment '$parent_id' does not exist or permission denied");
    
    $Post = $pComment->post;
    $data{parent_id} = $pComment->id;
  }
  elsif(my $post_id = $c->req->params->{post_id}) {
    $Post = $c->model('DB::Post')->search_rs({ 'me.id' => $post_id })->first
      or return $self->error_response($c,"Post '$post_id' does not exist or permission denied");
  }
  else {
    return $self->error_response($c,"Must supply either 'post_id' or 'parent_id'");
  }
  
  %data = ( %data,
    post_id => $Post->id,
    user_id => $User->id,
    body    => $body
  );
  
  my $Comment = $Post->comments->create(\%data)
    or return $self->error_response($c,"Unable to add comment - unknown error");
  
  my $url = join('#',$Post->public_url,$Comment->html_id);
  
  return $c->res->redirect( $url, 303 );
}

sub changepw :Local :Args(0) {
  my ($self, $c, $arg) = @_;
  
  my $User = $c->user->linkedRow;
  
  # Redirect a non POST to the admin area
  $c->req->method eq 'POST' or return $User
    ? $c->res->redirect( $c->mount_url.'/adm/main/db/db_user/item/'.$User->id, 307 )
    : $c->res->redirect( $c->mount_url.'/adm', 307 );
  
 
  # TDB
  ...

}



# placeholder for later
sub error_response {
  my ($self, $c, $err) = @_;
  
  die $err;
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Rapi::Blog::Controller::Remote - General-purpose controller actions

=head1 DESCRIPTION

This controller provides general-purpose HTTP end-points for use by scaffolds in Rapi::Blog
applications, such as posts to add comments and other functions (future) that are separate 
from the auto-generated interfaces provided by RapidApp. So far the only action that has 
been implemented is C<comment/add>.

=head1 ACTIONS

=head2 comment

Action for comment operations. Currently the only argument supported argumemnt is C<add>.

This will return with a 303 redirect back to the Post C<public_url> and the label tag C<html_id>
which is automatically generated for the comment. If the scaffold renders the C<html_id> with each
comment as the element id this will result in the page being scrolled to the just added comment.

Expects the following C<POST> params:

=head3 post_id

The id of the Post being commented on. Either C<post_id> or C<parent_id> must be supplied.

=head3 parent_id

The id of another Comment that this comment is a reply to. If C<parent_id> is supplied 
C<post_id> should not.

=head3 body

The body text of the comment

=head2 changepw

Not yet implemented.

=head1 SEE ALSO

=over

=item * 

L<Rapi::Blog>

=item * 

L<Catalyst::Controller>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

