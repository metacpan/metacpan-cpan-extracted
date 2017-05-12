use strict;
package Siesta::Web::FakeApache;
use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw( filename uri headers content_type ));

sub new {
    my $class = shift;
    if (0) {
        require YAML;
        require CGI;
        print CGI->header('text/plain');
        print YAML::Dump(\%ENV );
        exit;
    }
    $class->SUPER::new({
        filename     => "$ENV{DOCUMENT_ROOT}/$ENV{SCRIPT_NAME}", # this is fragile
        uri          => $ENV{REQUEST_URI},
        headers      => [],
        content_type => 'text/html',
    });
}

sub header_out {
    my $self = shift;
    push @{ $self->headers }, [ @_ ];
}

sub send_http_header {
    my $self = shift;
    print "Content-Type: ", $self->content_type, "\r\n";
    print "$_->[0]: $_->[1]\r\n" for @{ $self->headers };
    print "\r\n";
}

sub print {
    my $self = shift;
    print @_;
}

sub log_reason {
    shift;
    print STDERR @_;
}


package Apache::Constants;
$INC{'Apache/Constants.pm'} = 1;
sub import {
    my $caller = caller;
    no strict 'refs';
    *{"$caller\::$_"} = sub {} for qw( DECLINED SERVER_ERROR OK );
}
1;
