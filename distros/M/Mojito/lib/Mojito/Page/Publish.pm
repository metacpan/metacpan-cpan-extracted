use strictures 1;

package Mojito::Page::Publish;
{
  $Mojito::Page::Publish::VERSION = '0.24';
}
use Moo;
use WWW::Mechanize;
use Data::Dumper::Concise;

=pod

Starting with the ability to publish a Mojito page to a MojoMojo wiki.

NEED:
- MM base_url
- MM username/password
- MM page name (path)
- some content

=cut

with('Mojito::Role::DB');
with('Mojito::Role::Config');

has target_base_url => (
    is      => 'rw',
    lazy    => 1,
    default => sub { $_[0]->config->{MM_base_url} },
);
has user => (
    is      => 'rw',
    lazy    => 1,
    default => sub { $_[0]->config->{MM_user} },
);
has password => (
    is      => 'rw',
    lazy    => 1,
    default => sub { $_[0]->config->{MM_password} },
);
has source_page => ( is => 'rw', );
has target_page => ( is => 'rw', );
has content     => (
    is       => 'rw',
);
has page_id => (
    is => 'rw',
);
has publish_form => (
    is => 'rw',
    lazy => 1,
    builder => '_build_publish_form',
);
has mech => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_mech',
);

sub _build_mech {
    my ( $self, )  = @_;
    my $mech       = WWW::Mechanize->new(ssl_opts => { verify_hostname => 0 });
    my $base_url   = $self->target_base_url;
    my $login_page = $base_url . '.login';
    $mech->get($login_page);
    $mech->submit_form(
        with_fields      => {
            login => $self->user,
            pass  => $self->password,
        }
    );
    return $mech;
}

=head1 Methods

=head2 publish

Get, Fillin and Post the Form for a Page

=cut

sub publish {
    my $self = shift;

    my $mech = $self->mech;
    $mech->get( $self->target_base_url . $self->target_page . '.edit' );
    $mech->form_with_fields('body');
    $mech->field( body => $self->content );
    $mech->click_button( value => 'Save' );
    return $mech->success;
}


sub _build_publish_form {
    my $self = shift;
  
    return if not defined $self->target_base_url;  
    my $target_base_url = $self->target_base_url;
    my $user = $self->user;
    my $password = $self->password;
    my $form =<<"END_FORM";
<div class="demo">

<div id="dialog-form" title="Publish this page">
    <form>
    <fieldset>
    <table>
    <tr>
        <td><label for="name">Page Name:</label></td>
        <td><input type="text" name="name" id="name" class="text ui-widget-content ui-corner-all" size="48" required /></td>
    </tr>
        <td><label for="target_base_url">Pub Base:</label></td>
        <td><input type="text" name="target_base_url" id="target_base_url" value="$target_base_url" class="text ui-widget-content ui-corner-all" size="48" required /></td>
    </tr>
        <td><label for="user">User:</label>
        <td><input type="text" name="user" id="user" value="$user" class="text ui-widget-content ui-corner-all" required /></td>
    </tr>        
        <td><label for="password">Password</label>
        <td><input type="password" name="password" id="password" value="$password" class="text ui-widget-content ui-corner-all" required /></td>
    </tr>
    </table>
    </fieldset>
    </form>
</div>
<button id="publish-page">Publish</button>

</div>
END_FORM
 
    return $form;
}

1
