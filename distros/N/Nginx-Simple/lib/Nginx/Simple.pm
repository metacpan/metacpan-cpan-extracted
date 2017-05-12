package Nginx::Simple;
use Exporter;

our $VERSION = '0.07';

@ISA = qw(Exporter);

use nginx;
use strict;

use Nginx::Simple::Cookie;
use Time::HiRes qw(gettimeofday tv_interval);

BEGIN { require 5.008004; }

# Export all @HTTP_STATUS_CODES
our @EXPORT = ('dispatch');

# data for request
my %request_data;
my @error_stack;
my $die_error;

=head1 NAME

Nginx::Simple - Easy to use interface for "--with-http_perl_module"

=head1 SYNOPSIS

  nginx.conf:  
    perl_modules perl;
    perl_require Test.pm;

    server {
       listen       80;
       server_name  localhost;

       location / {
          perl Test::handler; # always enter package::handler
       }
    }

  Test.pm:
    package Test;
    use Nginx::Simple;

    # (optional) triggered before main is run
    sub init
    {
        my $self = shift;

        $self->{user} = 'stinky_pete';
    }

    # automatically dispatches here
    sub main
    {
        my $self = shift;
        
        $self->header_set('Content-Type' => 'text/html');
        $self->print('rock on!');
        $self->print("$self->{user} is using the system");
	
        $self->log('I found a rabbit...');
        
        my $something = $self->param("here");
        $self->print("I found $something...");
    }

    # (optional) triggered after main is run
    sub cleanup
    {
        my $self = shift;

        # do something?
    }

    # (optional) triggered on a server error (otherwise returns a normal 500 error)
    sub error
    {
        my $self = shift;
        my $error = shift;

        $self->status(500);
        $self->print("oh, uh, there is an error! ($error)");
    }
    
=cut

sub import
{
    my ($class, $settings) = @_;

    my $caller = caller;
    {
        no strict 'refs';
        *{"$caller\::handler"} = sub { 
            return dispatch(
                shift, 
                class  => $caller,
                method => 'main',
            );                     
        };
    }
    __PACKAGE__->export_to_level(1, $class);
}

sub dispatch
{
    my ($r, %params) = @_;

    my $class      = $params{class};
    my $method     = $params{method};
    my $error      = $params{error};
    my $bless      = $params{bless};
    my $base_class = $params{base_class};

    $r->variable('call_class',  $class               );
    $r->variable('call_method', $method     || 'main');
    $r->variable('error',       $error      || ''    );
    $r->variable('bless',       $bless      || ''    );
    $r->variable('base_class',  $base_class || ''    );

    unless ($method eq 'error')
    {
        @error_stack = ( );
        $die_error   = q[];
    }

    if (not $error and $r->has_request_body(\&handle_request_body))
    {
        return OK; 
    } 
    else
    {
        return &init_dispatcher($r);
    }

    return OK;
}

=head1 METHODS

=head3 $self->server

Returns the nginx server object.

=cut

sub server           { $request_data{server_object}        }

=head3 $self->uri

Returns the uri.

=cut

sub uri              { shift->server->uri                  }

=head3 $self->filename

Returns the path filename.

=cut

sub filename         { shift->server->filename             }

=head3 $self->request_method

Returns the request_method.

=cut

sub request_method   { shift->server->request_method       }

=head3 $self->remote_addr

Returns the remote_addr.

=cut

sub remote_addr      { shift->server->remote_addr          }

=head3 $self->header_in

Return value of header_in.

=cut

sub header_in        { shift->server->header_in(@_)        }

sub rflush           { shift->server->rflush               }
sub flush            { shift->rflush                       }


=head3 $self->print(...)

Output via http.

=cut

sub print 
{
    my $self = shift;

    $request_data{output} .= join '', @_;
}

=head3 $self->auto_header

Returns true if set, otherwise args 1 sets true and 0 false.

=cut

sub auto_header
{
    my ($self, $arg) = @_;

    if (defined $arg)
    {
        if ($arg)
        {
            delete $request_data{disable_auto_header};
        }
        else	
        {
            $request_data{disable_auto_header} = 1;
        }
    }

    return(not exists $request_data{disable_auto_header});
}

=head3 $self->dispatching

Returns true if we're dispatching actively.

=cut

sub dispatching
{
    my ($self, $arg) = @_;

    if (defined $arg)
    {
        if ($arg)
        {
            delete $request_data{disable_dispatching};
        }
        else	
        {
            $request_data{disable_dispatching} = 1;
        }
    }

    return(not exists $request_data{disable_dispatching});
}

=head3 $self->header_set('header_type', 'value')

Set output header.

=cut

sub header_set 
{
    my ($self, $key, $value) = @_;

    $request_data{headers}{$key} = $value;
}

=head3 $self->header('content-type')

Set content type.

=cut

sub header
{
    my ($self, $value) = @_;

    $self->header_set('Content-Type', $value);
}

=head3 $self->headers

Returns hashref of headers.

=cut

sub headers
{
    my ($self, $value) = @_;

    return $request_data{headers};
}

=head3 $self->location('url')

Redirect to a url.

=cut

sub location         { shift->header_set('Location', shift) }

=head3 $self->status(...)

Set output status... (200, 404, etc...)
If no argument given, returns status.

=cut

sub status 
{
    my ($self, $status) = @_;

    if ($status)
    {
        $request_data{status} = $status;
    }
    else
    {
        return $request_data{status};
    }
}

# map $self->log to print STDERR
sub log              { shift; print STDERR @_;             }

=head3 $self->param(...)

Return a parameter passed via CGI--works like CGI::param.

=cut

sub param 
{
    my ($self, $lookup_key) = @_;
    
    my @values;
    my %seen_hash;
    my $request = $request_data{args};

    if ($request_data{request_parts})
    {
        for my $part (@{$request_data{request_parts}})
        {
            if ($lookup_key)
            {
                push @values, $self->unescape($part->{data})
                    if $lookup_key eq $part->{name};
            }
            else
            {
                next if $seen_hash{$part->{name}}++;
                push @values, $part->{name};
            }
        }
    }
    else
    {
        my @args = split('&', $request);
        for my $arg (@args)
        {
            my ($key, $value) = split('=', $arg);
            
            if ($lookup_key)
            {
                push @values, $self->unescape($value)
                    if $lookup_key eq $key;
            }
            else
            {
                next if $seen_hash{$key}++;
                push @values, $key;
            }
        }
    }
    
    return unless @values;
    
    return (scalar @values == 1 ? $values[0] : @values);
}

=head3 $self->param_hash
    
Return a friendly hashref of CGI parameters.

=cut

sub param_hash
{
    my $self = shift;

    my %param_hash;
    
    for my $key ($self->param)
    {
        next if $param_hash{$key};
        
        my @params = $self->param($key);
        
        if (scalar @params == 1)
        {
            $param_hash{$key} = $params[0];
        }
        else
        {
            $param_hash{$key} = [ @params ],
        }
    }
    
    return \%param_hash;
}

=head3 $self->request_body & $self->request
    
Returns request body.

=cut

sub request_body { $request_data{request} }
sub request      { shift->request_body    }

=head3 $self->args

Returns args.

=cut

sub args         { $request_data{args}    }

sub handle_request_body
{
    my $r = shift;

    my $request_body = $r->request_body;

    my @r_body = split("\n", $request_body);

    my %params;

    if (scalar(@r_body) == 1)
    {
        $params{args} = $request_body;
    }
    else # process multi-line data
    {
        # decode multi-part data
        if ($r_body[0] =~ /^-/)
        {
            my @request_parts;

            # trim whitespace on header
            $r_body[0] =~ s/\s//g;

            # grab segments
            my @parts = split(/$r_body[0]\-*\s*/, $request_body);
            @parts = grep { $_ } @parts;

            for my $part (@parts)
            {
                my @lines = split("\n", $part);

                $_ .= "\n" for @lines;

                # grab header
                my @header;
                for my $line (@lines)
                {
                    my $t_line = shift @lines;

                    $t_line =~ s/[\r\n]//g;
                    push @header, $t_line if $t_line;

                    last unless $t_line;
                }

                $lines[-1] =~ s/[\r\n]//g;
                my $data = join('', @lines);

                my $name;
                if ($header[0] =~ /name="(.*?)"/)
                {
                    $name = $1;
                }

                push @request_parts, {
                    name   => $name,
                    header => \@header,
                    data   => $data,
                };
            }
            $params{request_parts} = \@request_parts;
        }
    }

    return &init_dispatcher($r, %params);
}

sub init_dispatcher {
    my ($r, %params) = @_;
    
    %request_data = (
        headers       => { 'Content-Type' => 'text/html' },
        output        => q[],
        status        => 200,
        server_object => $r,
        request       => $params{request} || $r->request_body,
        args          => $params{args}    || $r->args,
        request_parts => $params{request_parts},
        begin_time    => [gettimeofday],
    );
    
    my $class      = $r->variable('call_class');
    my $bless      = $r->variable('bless');
    my $base_class = $r->variable('base_class');
    my $method     = $r->variable('call_method');

    $r->variable('call_class',  undef);
    $r->variable('bless',       undef);
    $r->variable('base_class',  undef);
    $r->variable('call_method', undef);

    my $self = { };
    $bless ? bless($self, $class) : bless($self);

    my $sub_call = "$class\::$method";
    if (UNIVERSAL::can($class, $method))
    { 
        no strict 'refs';

        # pre-run sub, if defined
        my $init_class = $base_class || $class;
        if (UNIVERSAL::can($init_class, 'init') and not $method eq 'error')
        {
            no strict 'refs';
            eval {
                local $SIG{__DIE__} = sub { &format_error(shift) };
                if ($bless)
                {
                    $self->init;
                }
                else
                {
                    my $prerun_sub = "$init_class\::init";
                    $prerun_sub->($self);
                }
            };

            if ($@ and $@ ne "nginx-exit\n")
            {
                if ($method eq 'error')
                {
                    # you've got an error in your error handler
                    warn "Error in error handler... ($class\::error)\n";

                    return $self->init_error($sub_call);
                }

                # reset request data
                %request_data = (
                    %request_data,
                    headers       => { 'Content-Type' => 'text/html' },
                    output        => q[],
                    status        => 200,
                    server_object => $r,
                    request       => $params{request} || $r->request_body,
                    args          => $params{args}    || $r->args,
                    request_parts => $params{request_parts},
                );

                eval {
                    local $SIG{__DIE__} = sub { &format_error(shift) };
                    if ($bless)
                    {
                        $self->error;
                    }
                    else
                    {
                        my $prerun_sub = "$init_class\::error";
                        $prerun_sub->($self);
                    }
                };

                if ($@ and $@ ne "nginx-exit\n")
                {
                    if ($method eq 'error')
                    {
                        # you've got an error in your error handler
                        warn "Error in error handler... ($class\::error)\n";

                        return $self->init_error($sub_call);
                    }
                }
                else
                {
                    $self->process_auto_header
                        if $self->auto_header and $self->dispatching;

                    return OK;
                }
            }
        }

        my $error = $self->server->variable('error');

        if ($self->dispatching)
        {
            eval { 
                local $SIG{__DIE__} = sub { &format_error(shift) };

                if ($bless)
                {
                    $self->$method($error);
                }
                else
                {
                    $sub_call->($self, $error);
                }
            };

            if ($@ and $@ ne "nginx-exit\n")
            {
                if ($method eq 'error')
                {
                    # you've got an error in your error handler
                    warn "Error in error handler... ($class\::error)\n";

                    return $self->init_error($sub_call);
                }

                # reset request data
                %request_data = (
                    %request_data,
                    headers       => { 'Content-Type' => 'text/html' },
                    output        => q[],
                    status        => 200,
                    server_object => $r,
                    request       => $params{request} || $r->request_body,
                    args          => $params{args}    || $r->args,
                    request_parts => $params{request_parts},
                );

                eval {
                    local $SIG{__DIE__} = sub { &format_error(shift) };
                    if ($bless)
                    {
                        $self->error;
                    }
                    else
                    {
                        my $prerun_sub = "$init_class\::error";
                        $prerun_sub->($self);
                    }
                };

                if ($@ and $@ ne "nginx-exit\n")
                {
                    if ($method eq 'error')
                    {
                        # you've got an error in your error handler
                        warn "Error in error handler... ($class\::error)\n";

                        return $self->init_error($sub_call);
                    }
                }
                else
                {
                    $self->process_auto_header
                        if $self->auto_header and $self->dispatching;

                    return OK;
                }
            }
            else
            {
                # process all data
                $self->process_auto_header
                    if $self->auto_header and $self->dispatching;

                # post-run sub, if defined
                my $cleanup_class = $base_class || $class;
                if (UNIVERSAL::can($cleanup_class, 'cleanup') and $method ne 'error'
                    and $self->dispatching)
                {
                    no strict 'refs';
                    eval { 
                        local $SIG{__DIE__} = sub { &format_error(shift) };
                        if ($bless)
                        {
                            $self->cleanup;
                        }
                        else
                        {
                            my $cleanup_sub = "$cleanup_class\::cleanup";
                            $cleanup_sub->($self);
                        }
                    };
                }
            }
        }

        undef $self;

        return OK;

    }
    else
    {
        return $self->init_error($sub_call);
    }
}

=head3 process_auto_header

Process the autoheader.

=cut

sub process_auto_header
{
    my $self = shift;

    $self->server->status($self->status);
            
    my $content_type = delete $request_data{headers}{'Content-Type'};

    $self->server->header_out($_, $request_data{headers}{$_})
        for keys %{$request_data{headers}};

    $self->server->send_http_header($content_type);

    $self->server->print($request_data{output});

    # ensure all data is transmitted
    $self->flush;
}

sub format_error
{
    my $error  = shift;
    my @stack  = &make_error_stack;
    $die_error = $error;

    return if $error eq "nginx-exit\n";

    warn $error;

    for my $e (@stack)
    {
        warn "$e->{sub} called at $e->{file} line $e->{line}\n";
    }
}

=head3 error_stack

Returns the "error stack" as an array.

=cut

sub error_stack { @error_stack };

=head3 get_error

Returns error as string.

=cut

sub get_error   { $die_error   };

sub make_error_stack
{
    my @stack;
    my $i = 0;
    while (my @x = caller(++$i)) {
        push @stack, {
            pack => $x[0],
            file => $x[1],
            line => $x[2],
            sub  => $x[3],
        };
    }

    shift @stack;
    shift @stack;

    pop @stack;

    for (1..5)
    {
        pop @stack
            if $stack[-1] and $stack[-1]->{sub} =~ /^Nginx::Simple/;

        pop @stack
            if $stack[-1] and $stack[-1]->{file} =~ /\/Nginx\/Simple.pm$/;
    }

    @error_stack = @stack;

    return @stack;
}

sub init_error
{
    my ($self, $sub) = @_;
    
    warn(__PACKAGE__ . qq[: '$sub' does not exist...\n]) 
        unless $sub =~ /error$/;

    return HTTP_SERVER_ERROR;
}

=head3 $self->unescape

Unscape HTTP URI encoding.

=cut

sub unescape
{
    my ($self, $value) = @_;

    $value =~ s/\+/ /g;
    $value = $self->server->unescape($value);

    return $value;
}

=head3 $self->cookie

Cookie methods:

   $self->cookie->set(-name => 'foo', -value => 'bar');
   my %cookies = $self->cookie->read;

=cut

sub cookie { new Nginx::Simple::Cookie(shift) }

# override CORE::GLOBAL::exit & print
{
    no strict 'refs';
    *{"CORE::GLOBAL::exit"}  = sub { die "nginx-exit\n" };
    *{"CORE::GLOBAL::print"} = sub { };
}

=head3 $self->elapsed_time

Returns elapsed time since initial dispatch.

=cut

sub elapsed_time { tv_interval($request_data{begin_time}, [gettimeofday]) }

=head1 Author

Michael J. Flickinger, C<< <mjflick@gnu.org> >>

=head1 Copyright & License

You may distribute under the terms of either the GNU General Public
License or the Artistic License.

=cut

1;
