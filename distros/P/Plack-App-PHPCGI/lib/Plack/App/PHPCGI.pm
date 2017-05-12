package Plack::App::PHPCGI;

use strict;
use warnings;
use parent qw(Plack::Component);
use Plack::Util::Accessor qw(script php_cgi _app);
use CGI::Emulate::PSGI;
use File::Which; 
use File::Spec;
use Carp;
use POSIX ":sys_wait_h";

our $VERSION = '0.05';

sub wrap_php {
    my ($php_cgi, $script) = @_;
    my $app = sub {
        my $env = shift;

        pipe( my $stdoutr, my $stdoutw );
        pipe( my $stdinr,  my $stdinw );

        my $pid = fork();
        Carp::croak("fork failed: $!") unless defined $pid;

        if ($pid == 0) { # child
            local $SIG{__DIE__} = sub {
                print STDERR @_;
                exit(1);
            };

            close $stdoutr;
            close $stdinw;
            
            local %ENV = (%ENV, CGI::Emulate::PSGI->emulate_environment($env));
            local $ENV{REDIRECT_STATUS} = 1;
            local $ENV{SCRIPT_FILENAME} = $script;

            open( STDOUT, ">&=" . fileno($stdoutw) ) ## no critic
                or Carp::croak "Cannot dup STDOUT: $!"; 
            open( STDIN, "<&=" . fileno($stdinr) ) ## no critic
                or Carp::croak "Cannot dup STDIN: $!"; 

            exec($php_cgi,$script) or Carp::croak("cannot exec: $!");

            exit(2);
        }

        close $stdoutw;
        close $stdinr;
        
        syswrite($stdinw, do {
            local $/;
            my $fh = $env->{'psgi.input'};
            <$fh>;
        });
        # close STDIN so child will stop waiting
        close $stdinw;
        
        my $res = '';
        while (waitpid($pid, WNOHANG) <= 0) {
            $res .= do { local $/; my $str = <$stdoutr>; defined $str ? $str : '' };
        }
        $res .= do { local $/; my $str = <$stdoutr>; defined $str ? $str : '' };
        
        if (POSIX::WIFEXITED($?)) {
            return CGI::Parse::PSGI::parse_cgi_output(\$res);
        } else {
            Carp::croak("Error at run_on_shell CGI: $!");
        }
    };
    $app;
}

sub prepare_app {
    my $self = shift;
    my $script = $self->script
        or croak "'script' is not set";
    $script = File::Spec->rel2abs($script);

    my $php_cgi = $self->php_cgi;
    $php_cgi ||= which('php-cgi');
    croak "cannot find 'php-cgi' command" unless -x $php_cgi;

    $self->_app(wrap_php($php_cgi,$script));
}

sub call {
    my($self, $env) = @_;
    $self->_app->($env);
}


1;
__END__

=head1 NAME

Plack::App::PHPCGI - execute PHP script as CGI

=head1 SYNOPSIS

  use Plack::App::PHPCGI;

  my $app = Plack::App::PHPCGI->new(
      script => '/path/to/test.php'
  );

=head1 DESCRIPTION

Plack::App::WrapCGI supports CGI scripts written in other languages. but WrapCGI cannot execute 
PHP script that does not have shebang line and exec bits.
Plack::App::PHPCGI execute any PHP scripts as CGI with php-cgi command.

=head1 METHODS

=over 4

=item new

  my $app = Plack::App::PHPCGI->new(%args);

Creates a new PSGI application using the given script. I<%args> has two
parameters:

=over 8

=item script

The path to a PHP program. This is a required parameter.

=item php_cgi

An optional parameter. path for php-cgi command

=back

=back

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

L<Plack::App::WrapCGI>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
