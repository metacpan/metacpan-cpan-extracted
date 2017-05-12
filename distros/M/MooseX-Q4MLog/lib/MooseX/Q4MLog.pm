# $Id: /mirror/coderepos/lang/perl/MooseX-Q4MLog/trunk/lib/MooseX/Q4MLog.pm 66311 2008-07-17T01:20:46.950350Z daisuke  $

package MooseX::Q4MLog;
use Moose::Role;
use MooseX::Q4MLog::Logger;

our $VERSION   = '0.00002';
our $AUTHORITY = 'cpan:DMAKI';

requires 'format_q4mlog';

has 'logger' => (
    is => 'rw',
    isa => 'MooseX::Q4MLog::Logger',
);

no Moose;

sub BUILD {
    my ($self, $args) = @_;

    $self->logger( 
        MooseX::Q4MLog::Logger->new( %{ $args->{q4mlog} } )
    );
}

sub log {
    my ($self, %args) = @_;

    my $q4m_args = $self->format_q4mlog(%args);

    $self->logger->log( q4m_args => $q4m_args );
}

1;

__END__

=head1 NAME

MooseX::Q4MLog - Log Data To Q4M

=head1 SYNOPSIS

  package MyObject;
  use Moose;

  with 'MooseX::Q4MLog';

  no Moose;

  sub format_q4mlog {
    my ($self, %args) = @_; # %args is application dependent

    # create a hash that can be passed to Queue::Q4M->insert
    my %q4m_args = ( .... );

    return \%q4m_args
  }

  my $obj = MyObject->new(
    q4mlog => {
      table => 'q_log', # optional
      connect_info => [ ... ],
    }
  );
  $obj->log( %whatever );

=head1 METHODS

=head2 format_q4mlog(%args)

Given the arguments, you must create a hash that can be passed to 
Queue::Q4M->insert

=head2 log(%args)

=cut