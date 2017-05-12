package Template::Plugin::Siesta;
use strict;
use base qw( Template::Plugin Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( errors context success cgi user ));
use Siesta;
use Siesta::Message;
use Siesta::Deferred;
use CGI ();

=head1 NAME

Template::Plugin::Siesta - convenience class for Siesta template pages

=head1 METHODS

=item ->new( {foo => 'bar'} )

creates a new Template::Siesta::Plugin from, using a hashref to
provide arguments,

=item ->new( foo => 'bar' )

creates a new Template::Siesta::Plugin from, using an array of name
value pairs to provide arguments,

if the arguments contain an action request then ( see ->action() )
then the requested action will be performed before returning the new
object;

=cut

sub new {
    my $referent = shift;
    my $context  = shift;
    my %args     = ref($_[0]) eq 'HASH' ? %{ $_[0] } : @ _;

    my $class = ref $referent || $referent;
    my $self = bless { %args,
                       errors  => [],
                       context => $context,
                       cgi     => CGI->new,
                   }, $class;

    $self->_perform_action
      if $self->action && $self->cgi->param('submit');

    return $self;
}

=item ->action

if called with no aruments, returns the currently defined action.  if
called with a string value, sets the action or warns of an error if
the class cannot ->ACTION_$action

=cut

sub action {
    my ($self, $action) = @_;

    if ($action) {
        if ($self->can("ACTION_$action") ) {
            $self->{action} = $action;
        }
        else {
            $self->error("Template::Siesta::Plugin - Unknown action $action");
        }
    }
    return $self->{action};
}

sub _perform_action {
    my $self = shift;

    my $action_method = "ACTION_" . $self->action;
    $self->errors([]); # zero the errors from previous action.
    $self->success( $self->$action_method() );
}


my $MIN_PASS = 6; # should come out of a config I guess ...
sub ACTION_register {
    my $self = shift;

    my ($pass1) = $self->_getParam('pass1',"(\\w{$MIN_PASS,40})");
    my ($pass2) = $self->_getParam('pass2',"(\\w{$MIN_PASS,40})");
    my ($email) = $self->_getParam('email','(\S{6,40})' );

    unless (defined $pass1) {
        $self->error("Passwords must be at least $MIN_PASS long");
    }
    if ( defined($pass1) && defined($pass2) && $pass1 ne $pass2) {
        $self->error("Password and confirmation must match");
    }

    my $user = Siesta::Member->load($email);
    if ($user) {
        $self->error("This email address is already subscribed");
    }

    # should return a list of the ticked checkboxes need to confirm
    # they are public lists, as you shouldnt be able to sub to private
    # lists before you are subscribed I guess.
    my @subscriptions = $self->cgi->param('subscribe');

    $user ||= Siesta::Member->create({ email => $email });
    $user->password($pass1);
    $user->update;

    foreach my $list_name (@subscriptions) {
        #print "list name $list_name";
        my($list) =  Siesta::List->load( $list_name );
        unless ($list) {
            $self->error( "Failed to find a list called $list_name" );
            next;
        }
        $list->add_member($user);

        my $mail = Siesta::Message->new();
        $mail->reply( to   => $list->owner->email,
                      subject => 'web subscription',
                      body => Siesta->bake('subscribe_notify',
                                           list    => $list,
                                           user    => $user,
                                           message => $mail ),
                     );
    }
    return 1; # success
}

sub ACTION_login {
    my $self = shift;
    my ($email) = $self->_getParam('email', '(\S+)' );
    my ($pass) =  $self->_getParam('pass',  '(\S+)' );

    my $user = Siesta::Member->load( $email ) or return;

    # no null passwords
    return unless $pass;
    if ($pass eq $user->password) {
        return $user;
    }
    return;
}

sub ACTION_move_plugin {
    my $self = shift;

    my $plugin = Siesta::Plugin->retrieve( $self->_getParam('id', '(\d+)' ))
      or return;
    my $list = $plugin->list;
    return unless $self->user == $list->owner;

    my ($to) = $self->_getParam( 'to', '(\d+)' );
    # the rest of the queue
    my @queue = grep { $_ != $plugin } $list->plugins( $plugin->queue );
    splice @queue, $to - 1, 0, $plugin;
    $list->set_plugins( $plugin->queue => map { $_->name } @queue );
}

sub ACTION_add_plugin {
    my $self = shift;

    my $list = Siesta::List->load( $self->_getParam('list', '(\S+)') )
      or return;
    return unless $self->user->id == $list->owner->id;

    my ($queue) = $self->_getParam('queue', '(\S+)');
    my ($type)  = $self->_getParam('type',  '(\S+)');

    # mmm, evil tastes sooo good
    eval {
        $list->add_plugin( $queue,
                           ( $self->_getParam('personal', '(\S+)') ? '+' : '') . $type );
    } or do { $self->error( $@ ); return };
    return 1;
}

sub ACTION_delete_plugin {
    my $self = shift;

    my ($id) = $self->_getParam( 'id', '(\d+)' );
    my $plugin = Siesta::Plugin->retrieve( $id ) or return;
    return unless $plugin->list->owner->id == $self->user->id;
    $plugin->delete;
    return 1;
}

sub ACTION_resume_message {
    my $self = shift;

    my $message = Siesta::Deferred->retrieve(
        $self->_getParam( 'id', '(\d+)' )
       )
      or return;
    return unless $self->user->id == $message->who;

    Siesta::Message->resume( $message->id );
    return 1;
}

sub ACTION_set_pref {
    my $self = shift;

    my $list = Siesta::List->retrieve( $self->_getParam( 'list',
                                                         qr/^(\d+)$/ ) )
      or return;
    for my $plugin (map { $_->promote } Siesta::Plugin->search({ list => $list })) {
        for my $pref (keys %{ $plugin->options }) {
            my $val;
            if ($plugin->personal &&
                  ( ($val) = $self->_getParam( "personal_$pref", '(.*)' ) ) ) {
                $plugin->member( $self->user );
                $plugin->pref( $pref, $val );
            }
            if (( $plugin->list->owner == $self->user ) &&
                  ( ($val) = $self->_getParam( "list_$pref", '(.*)' ) ) ) {
                $plugin->member( undef );
                $plugin->pref( $pref, $val );
            }
        }
    }
    return 1;
}


sub _getParam {
    my ($self,$param,$regex) = @_;

    my $var = $self->cgi->param($param);
    if (defined $var) {
        return $var =~ /$regex/;
    }
    return;
}

sub user { $_[0]->context->stash->get('session.user') }

sub available_plugins {
    [ Siesta->available_plugins ];
}

sub lists {
    [ Siesta::List->retrieve_all ];
}

sub list {
    my ($self, $list) = @_;
    Siesta::List->load( $list );
}

# messages deferred for the current user
sub deferred {
    my $self = shift;
    my $id = shift;
    if ($id) {
        return Siesta::Deferred->search( who => $self->user, id => $id);
    }
    [ Siesta::Deferred->search( who => $self->user ) ];
}

=item ->error( $what )

blow an error

=cut

sub error {
    my $self = shift;
    push @{ $self->errors }, @_;
}

=item ->errors

returns a list of errors that ocurred during an action request.

=item ->success

Return value of the action

=cut

1;
