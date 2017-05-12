package SSH::RPC::Shell;

our $VERSION = 1.201;

use strict;
use JSON;

=head1 NAME

SSH::RPC::Shell - The shell, or server side, of an RPC call over SSH.

=head1 SYNOPSIS

To make your own shell with it's own methods:

    package MyShell;

    use base 'SSH::RPC::Shell';

    sub run_time {
        my ($class, $args) = @_;
        return {
            status      => 200,
            response    => time(),
            };
    }

    1;


To create a usuable shell:

    #!/usr/bin/perl

    use strict;
    use MyShell;

    MyShell->run();


=head1 DESCRIPTION

SSH::RPC::Shell allows you to quickly implement your own shells that are remotely callable with L<SSH::RPC::Client>.

=head1 METHODS

The following methods are available from this class.

=cut



#-------------------------------------------------------------------

=head2 processRequest ( request ) 


=cut

sub processRequest {
    my ($class, $request) = @_;
    my $command = 'run_'.$request->{command};
    my $args = $request->{args};
    if (my $sub = $class->can($command)) {
        return $sub->($args);
    }
    return { "error" => "Method not allowed.", "status" => "405" };
}

#-------------------------------------------------------------------

=head2 run ()

Class method. This method is executed to invoke the shell.

=cut

sub run {
    my $class = shift;
    my $json = JSON->new->utf8;
    my $request;
    while (my $line = <STDIN>) {
        $request = eval {$json->incr_parse($line)};
        if ($@) {
            warn $@;
            print '{ "error" : "Malformed request.", "status" : "400" }';
            return;
        }
        last if defined $request;
    }
    my $result = $class->processRequest($request);
    $result->{version} = $VERSION;
    my $encodedResult = eval{JSON->new->pretty->utf8->encode($result)};
    if ($@) {
        print { "error" => "Malformed response.", "status" => "511" };
    }
    else {
        print $encodedResult."\n";
    }
}


#-------------------------------------------------------------------

=head2 run_noop () 

Class method. This subroutine just returns a successful status so you know that communication is working.

=cut

sub run_noop {
    return {status=>200};
}

=head1 LEGAL

 -------------------------------------------------------------------
  SSH::RPC::Client is Copyright 2008-2009 Plain Black Corporation
  and is licensed under the same terms as Perl itself.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

1;


