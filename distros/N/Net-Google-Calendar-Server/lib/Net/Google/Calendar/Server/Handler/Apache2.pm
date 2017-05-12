package Net::Google::Calendar::Server::Handler::Apache2;

use strict;
use Apache2::RequestRec ();
use Apache2::Const -compile => qw(':common');

=head1 NAME

Net::Google::Calendar::Server::handler::Apache2 - an Apache2 handler to pretend to be Google Calendar

=head1 SYNOPSIS

    <Location /calendar>
        SetHandler perl-script
        PerlHandler Net::Google::Calendar::Server::Handler::Apache2
        PerlSendHeader On
        PerlSetVar     CalendarBackend       ICalendar
        PerlSetVar     CalendarBackendFile   /path/to/calendar.ics
        PerlSetVar     CalendarAuth          Dummy
    </Location>

=head1 DESCRIPTION

Backend and Auth vars

=cut


sub handler($$) : method  {
    my ($class, $r) = @_;

    my $self = bless { r => $r }, $class;    
    # Fetch config variables
    my $vars = $r->per_dir_config;


    my $dp_class = $vars->get('CalendarBackend');
    return $self->error("You must set a Backend class via PerlSetVar CalendarBackend <backend class>") unless defined $dp_class;
    my $au_class = $vars->get('CalendarAuth');
    return $self->error("You must set a Auth class via PerlSetVar CalendarAuth <auth class>") unless defined $dp_class;


    # fetch the variables for the Backend and the Auth classes
    my %backend_opts;
    while(my($key,$val) = each %$vars) {
        next unless $key =~ m!^CalendarBackend(.+)$!;
        $backend_opts{lc($1)} = $val;
    }

    my %auth_opts;
    while(my($key,$val) = each %$vars) {
        next unless $key =~ m!^CalendarAuth(.+)$!;
        $auth_opts{lc($1)} = $val;
    }


    my $cal = eval { Net::Google::Calendar::Server->new( backend_class => $dp_class, backend_opts => \%backend_opts,
                                                         auth_class    => $au_class, auth_opts    => \%auth_opts,
                                                     ) };

    return $self->error($@) if $@;
    return $cal->handle_request($self);

}


sub error {
    my $self  = shift;
    my $error = shift;
    my $code  = shift;
    $code     = 'SERVER_ERROR' unless defined $code; 
    $code     = $self->response_code($code);
    $self->{r}->status_line("$code $error");
    return $code;
}

sub get_request_method {
    my $self = shift;
    return $self->{r}->method;

}

sub send_response {
    my $self = shift;
    my %what = @_;

    $self->{r}->content_type( $what{type} );
    # TODO - other headers
    print $what{body}."\n";
    return $self->response_code($what{code});
}

sub redirect {
    my $self  = shift;
    my $where = shift;

    $self->{r}->header_out->set( Location => $where );
    return $self->response_code(REDIRECT);
}

sub get_args {
    my $self = shift;
    return $self->{r}->args();
}

sub header_in {
    my $self = shift;
    my $what = shift || return;
    return $self->{r}->header_in($what);
}


sub path {
    my $self  = shift;
    my $r     = $self->{r};

    # get all the path info
    my $loc       = $r->location;  $loc  =~ s!/$!!;
    my $rest      = $r->filename;  $rest .= "/" unless $rest =~ m!/$!;
    $rest         =~ s!^$loc!!;
    $rest         =~ s!/$!!;
    $rest        .= $r->path_info;
    $rest         =~ s!(^/|/$)!!g;

    return $rest;
}

sub response_code {
    my $self = shift;
    my $code = shift;
    return  Apache2::Const->$code;    

}
1;
