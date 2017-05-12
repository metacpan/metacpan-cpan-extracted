package SOAP::UMRA;

use strict;
use warnings;

use HTTP::Cookies;
use SOAP::Lite;

our $VERSION = "1.0";

sub new {
    my ($class, $url, $opts) = @_;
    my $self = {
        verbose => $opts->{verbose} || 0,
        umra_uri => 'http://tools4ever.com/products/user-management-resource-administrator/',
        host => $url,
    };
    $self->{host} =~ s!https?://([^/]*)(/.*)?!$1!;

    $self->{umra} = SOAP::Lite
        -> service($url . '?WSDL')
        -> uri($self->{umra_uri})
        -> proxy($url);

    # Sessions are maintained with cookies in this .NET service
    my $cookies = HTTP::Cookies->new(ignore_discard => 1);
    $self->{umra}->transport->cookie_jar($cookies);

    bless($self, $class);
    return $self;
}

sub error {
    my ($self) = @_;
    return delete $self->{__error};
}

sub connect {
    my $self = shift;
    my $umra_port = 56814;
    return $self->_call('Connect', [
        SOAP::Data->name(HostName => $self->{host}),
        SOAP::Data->name(PortNumber => $umra_port)
    ]);
}

sub disconnect {
    my ($self) = @_;
    return $self->_call('Close');
}

sub _call {
    my ($self, $function, $args) = @_;
    my $r = $self->{umra}
        # It's a .NET service, so specify the action manually
        -> on_action( sub { $self->{umra_uri} . $function } )
        -> call($function, @$args);
    $self->_print_result($r) if $self->{verbose};
    return $r;
}

sub execute {
    my ($self, $project, $variables) = @_;

    my $r = $self->connect();
    if(defined($r->result) && ($r->result != 0)) {
        $self->{__error} = $r;
        return 0;
    }

    while(my($key, $val) = each %$variables) {
        $r = $self->_call('SetVariableText', [
            SOAP::Data->name(VariableName => '%'.$key.'%'), 
            SOAP::Data->name(VariableValue => $val)
        ]);
        if(defined($r->result) && ($r->result != 0)) {
            $self->{__error} = $r;
            $self->disconnect();
            return 0;
        }
    }

    $r = $self->_call('ExecuteProjectScript', [SOAP::Data->name(ProjectName => $project)]);

    $self->disconnect();

    if(defined($r->result) && ($r->result != 0)) {
        $self->{__error} = $r;
        return 0;
    }
    return 1;
}

sub project {
    my ($self, $name) = @_;
    my $project = sub {
        my ($variables) = @_;
        return $self->execute($name, $variables);
    };
    return $project;
}

sub _print_result {
    require Data::Dumper;
    Data::Dumper->import;
    my ($self, $r) = @_;
    my $r2 = $r->{_context}->{_transport}->{_proxy}->{_http_response};
    printf STDERR "\nRequest: \n%s\n", $r2->{_request}->{_content};
    printf STDERR "Response: \n%s\n", $r2->{_content};
    printf STDERR "Result: %s\n", (defined($r->result) ? $r->result : 'undef');
    print STDERR "Fault: \n";
    print STDERR Dumper($r->fault);
}

1;

__END__

=head1 NAME

SOAP::UMRA - Access an UMRA SOAP service from perl

=head1 SYNOPSIS
use SOAP::UMRA;

  my $umra = SOAP::UMRA->new('http://umra-host/umrawebservices/service.asmx');
  my $create = $umra->project('Create Account');
  $create->(
      department => 'Finance',
      givenname => 'Samuel',
      surname => 'Vimes',
      loginname => 'svimes',
      email => 'samuel.vimes@example.com',
      site => 'LND1',
      password => 'P4ssw0rd',
  );

=head1 Description

UMRA (User Management Resource Administrator) is a product by tools4ever to
link multiple authentication systems together. It can speak to AD, SAP, SQL
server and through powershell to other services too. This module allows you to
talk to its SOAP service from perl, so you can integrate account management
with your Perl based (web) application.

=head1 SOAP::UMRA objects

=head2 SOAP::UMRA->new($url, $options)

Returns a new SOAP:::UMRA object. The url should point to the SOAP service,
$options is a hash of options. Currently only $verbose is understood. In
verbose mode, all incoming and outgoing XML is printed to stdout.

=head2 $umra->project($projectname)

Returns a sub that represents a project you have created in your UMRA instance.
You can call this sub with a hash of parameters, this wraps the execute
function.

=head2 $umra->execute($project, $variables)

Repeatedly calls the SetVariable SOAP call to set variables in umra and then
calls ExecuteProject to call a project you created.

=head2 $umra->error()

Returns the last response this umra instance has seen that triggered an error.

=head1 SEE ALSO

L<http://www.tools4ever.com/nl/products/user-management-resource-administrator/>

=head1 COPYRIGHT AND LICENSE

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version. 

=cut
