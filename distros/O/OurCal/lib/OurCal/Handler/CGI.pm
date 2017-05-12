package OurCal::Handler::CGI;

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);

my $user_cookie_name = 'ourcal_user_cookie';

=head1 NAME

OurCal::Handler::CGI - the default, cgi based handler for OurCal

=head1 SYNOPSIS

	my $config    = OurCal::Config->new( file => 'ourcal.conf' );
	my $handler   = OurCal::Handler::CGI->new( config => $config );

=head1 METHODS

=cut

=head2 new <param[s]>

Requires a C<OurCal::Config> object passed in as the config param.

=cut

sub new {
    my ($class, %opts) = @_;
    $opts{_cgi} = CGI->new;
    return bless \%opts, $class;
}

sub _get_default_date {
    my ($mon, $year) = (localtime)[4,5];
    my $default      = ($year+1900)."-";
       $default     .= '0' if ($mon<9);
       $default     .= ($mon+1);
    return $default;
}

=head2 view

Get the name of the view we should be using

=cut

sub view {
    return $_[0]->_get_with_default('view', 'html');
}

=head2 date

Returns the date 

=cut


sub date {
    return $_[0]->_get_with_default('date', _get_default_date);
}

=head2 user

Returns the user as defined by HTTP Basic Auth, cookie or user CGI 
param.

=cut

sub user {
    my $self = shift;
    return undef if 'del_cookie' eq $self->mode;
    return $self->{user} if defined $self->{user} && length($self->{user});

    $self->{_user_needed} = 0;

    my $user;
    my $tmp_user = $user = $self->param('user');

    # first try auth
    $user = $self->{_cgi}->remote_user;
    goto SKIP_USER if defined $user && length($user);
    #print STDERR "Didn't find remote user\n";
        
    # now cookie
    $user = $self->{_cgi}->cookie($user_cookie_name);
    goto SKIP_USER if defined $user && length($user);
    #print STDERR "Didn't find remote cookie\n";
    

    # lastly, set that user is needed
    SKIP_USER: 
    $user = undef unless defined $user && length($user);
    $self->{_user_needed} = (defined $tmp_user && (!defined $user || $user ne $tmp_user));
    # and get it from CGI params
    $user = $tmp_user if defined $tmp_user && length($tmp_user);

    #print STDERR "Didn't find cgi user\n" unless defined $user;
 
    $self->{user} = $user;
    return $user;
}

=head2 mode

Get what mode we should be using

=cut

sub mode {
    return $_[0]->_get_with_default('mode', 'display');
}

sub _get_with_default {
    my ($self, $name, $default) = @_;
    if (not defined $self->{$name}) {
        $self->{$name} =  $self->param($name) || $default || undef;
    }
    return $self->{$name};
}


=head2 header <mime type>

Return what header we need to print out.

=cut

sub header {
    my $self = shift;
    my $type = shift;
    my $cgi  = $self->{_cgi};
    my %vars;
    $vars{"-type"} = $type if defined $type;

    if ('del_cookie' eq $self->mode) {
        my $cookie = $cgi->cookie(-name => $user_cookie_name, -value => '' );
        $vars{"-cookie"} = $cookie;
    } elsif (defined $self->user) {
        my $cookie = $cgi->cookie(-name => $user_cookie_name, -value => $self->user );
        $vars{"-cookie"} = $cookie;
    }
    return $cgi->header(%vars);
    
}



=head2 link <span>

Make a link out a C<OurCal::Span> object

=cut

sub link {
    my $self = shift;
    my $span = shift;
    my $date = $span->date;
    my $user = $self->user;
    my $url  = "?";
    
    $url .= "date=${date}" unless $span->is_this_span && $span->isa("OurCal::Month");
    $url .= "&user=${user}" if $self->need_user;
    $url  = "." if $url eq "?";

    return $url;    
}

=head2 param <name>

Get a CGI parma with the given name

=cut

sub param {
    my $self = shift;
    my $name = shift;
    my $cgi  = $self->{_cgi};
    return $cgi->param($name);
}

=head2 need_user

Whether a link need to include a user param or not

=cut


sub need_user {
    my $self = shift;
    return $self->{_user_needed};
    #return defined $self->user;
}

1;
