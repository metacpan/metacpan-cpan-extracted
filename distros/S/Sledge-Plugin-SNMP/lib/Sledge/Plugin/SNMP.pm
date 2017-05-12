package Sledge::Plugin::SNMP;
# $Id: SNMP.pm,v 0.01 2006/02/10 18:00:00 TSUNODA Exp $
#
# TSUNODA Kazuya <drk@drk7.jp>
#

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

use Net::SNMP;

sub import {
    my $class = shift;
    my $pkg = caller;

    no strict 'refs';
    *{"$pkg\::snmp"} = sub {
        my $self = shift;
        return $self->{snmp};   # read only
    };

    $pkg->register_hook(
        BEFORE_DISPATCH => sub {
            my $self = shift;
            $self->{snmp} = Sledge::Plugin::SNMP->new($self->create_config);
        },
    );
}


sub new {
    my $class = shift;
    my $cfg = shift;
    my ($session, $error);
       ($session, $error) = Net::SNMP->session($cfg->snmp) or die $error;
    bless { session => $session, }, $class;
}

sub DESTROY {
    my $self = shift;
    $self->{session}->close if($self->{session});
}

sub request {
    my $self = shift;
    my $mis = shift;
    my $result = $self->{session}->get_request( -varbindlist => [$mis] ) or die;
    $result->{$mis};
}

sub ssCpuUser   { my $self = shift; $self->request('.1.3.6.1.4.1.2021.11.9.0'); }
sub ssCpuSystem { my $self = shift; $self->request('.1.3.6.1.4.1.2021.11.10.0'); }
sub ssCpuIdle   { my $self = shift; $self->request('.1.3.6.1.4.1.2021.11.11.0'); }

sub laLoad1 { my $self = shift; $self->request('.1.3.6.1.4.1.2021.10.1.5.1'); }
sub laLoad2 { my $self = shift; $self->request('.1.3.6.1.4.1.2021.10.1.5.2'); }
sub laLoad3 { my $self = shift; $self->request('.1.3.6.1.4.1.2021.10.1.5.3'); }

sub memTotalSwap { my $self = shift; $self->request('.1.3.6.1.4.1.2021.4.3.0'); }
sub memAvailSwap { my $self = shift; $self->request('.1.3.6.1.4.1.2021.4.4.0'); }
sub memTotalReal { my $self = shift; $self->request('.1.3.6.1.4.1.2021.4.5.0'); }
sub memAvailReal { my $self = shift; $self->request('.1.3.6.1.4.1.2021.4.6.0'); }
sub memTotalFree { my $self = shift; $self->request('.1.3.6.1.4.1.2021.4.11.0'); }
sub memShared    { my $self = shift; $self->request('.1.3.6.1.4.1.2021.4.13.0'); }
sub memBuffer    { my $self = shift; $self->request('.1.3.6.1.4.1.2021.4.14.0'); }
sub memCached    { my $self = shift; $self->request('.1.3.6.1.4.1.2021.4.15.0'); }


sub addfunc {
    my $self = shift;
    my $method = shift;
    my $mis = shift;

    no strict 'refs'; 
    *{$method} = sub { my $self = shift; $self->request($mis); };
}


1;

__END__

=head1 NAME

Sledge::Plugin::SNMP - Object oriented interface to SNMP

=head1 SYNOPSIS

  package Foo::Pages::Bar;
  use Sledge::Plugin::SNMP;

  sub dispatch_baz {
      my $self = shift;
      $self->snmp->laLoad1;
      $self->snmp->addfunc( disk => '.1.3.6.1.4.1.2021.9.1.9.1' );
      $self->snmp->disk;
  }

=head1 DESCRIPTION

Sledge::Plugin::SNMP provide the function which acquires a server resource by using SNMP.
you can add new method or overwrite method by using the addfunc( method => MIS ).

=head1 METHODS

this plugin have the following method by the default. 

 ssCpuUser()
 ssCpuSystem()
 ssCpuIdle()
 laLoad1()
 laLoad2()
 laLoad3()
 memTotalSwap()
 memAvailSwap()
 memTotalReal()
 memAvailReal()
 memTotalFree()
 memShared()
 memBuffer()
 memCached()
 addfunc( method = MIS )

you must write config in Config/_common.pm, like this.

$C{SNMP} = {
    -hostname  => 'localhost',
    -community => 'public',
    -port      => 161 
};

=head1 AUTHOR

TSUNODA Kazuya <drk@drk7.jp>

=head1 SEE ALSO

L<Net::SNMP>

=cut


