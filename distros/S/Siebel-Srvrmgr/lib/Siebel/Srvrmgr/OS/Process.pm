package Siebel::Srvrmgr::OS::Process;

use Moose 2.0401;
use MooseX::FollowPBP 0.05;
use namespace::autoclean 0.13;
use Set::Tiny 0.02;
use Scalar::Util::Numeric 0.40 qw(isint);
use Carp qw(confess cluck);
our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::OS::Process - class to represents a operational system process of Siebel

=head2 DESCRIPTION

This class holds information regarding a operational system process that is (hopefully) related to a running Siebel Server.

=head1 ATTRIBUTES

Except for the C<comp_alias> attribute, all attributes are read-only and required during object instantiation.

=head2 pid

A integer representing the process identification.

=cut

has pid => ( is => 'ro', isa => 'Int', required => 1 );

=head2 fname

A string of the program filename

=cut

has fname => ( is => 'ro', isa => 'Str', required => 1 );

=head2 pctcpu

A float of the percentage of CPU the process was using.

=cut

has pctcpu => ( is => 'ro', isa => 'Num', required => 1 );

=head2 pctmem

A float of the percentage of memory the process was using.

=cut

has pctmem => ( is => 'ro', isa => 'Num', required => 1 );

=head2 rss

For Unix-like OS only: the RSS of the process.

=cut

has rss => ( is => 'ro', isa => 'Int', required => 1 );

=head2 vsz

For Unix-like OS only: the VSZ used by the process.

=cut

has vsz => ( is => 'ro', isa => 'Int', required => 1 );

=head2 comp_alias

A string of the component alias associated with the process.

When the process is not directly related to Siebel (for example, a web server that servers SWSE), the value will be automatically defined
to "/NA".

When the PID is not identified in the source (a class that implements L<Siebel::Srvrmgr::Comps_source>), the default value will be "unknown".

=cut

has comp_alias => ( is => 'rw', isa => 'Str', required => 0 );

sub _build_set {

    return Set::Tiny->new(
        'siebmtsh', 'siebmtshmw', 'siebproc', 'siebprocmw',
        'siebsess', 'siebsh',     'siebshmw'
    );

}

=head2 tasks_num

A integer representing the number of tasks that Siebel Component has executed in determined moment.

This is read-write, non-required attribute with the default value of zero. For processes related to Siebel but not related to Siebel
Components, this is the expected value too.

=cut

has tasks_num => (
    is       => 'ro',
    isa      => 'Int',
    required => 0,
    default  => 0,
    reader   => 'get_tasks_num',
    writer   => '_set_tasks_num'
);

=head1 METHODS

All attributes have their "getter" methods as defined in the Perl Best Practices book.

=head2 set_comp_alias

Sets the attribute C<comp_alias>. Expects a string passed as parameter.

=head2 BUILD

This method is invoked automatically when a object is created.

It takes care of setting proper initialization of the C<comp_alias> attribute.

=cut

sub BUILD {

    my $self = shift;
    my $set  = $self->_build_set();

    if ( $set->has( $self->get_fname ) ) {

        $self->set_comp_alias('unknown');

    }
    else {

        $self->set_comp_alias('N/A');

    }

}

=head2 is_comp

Returns true if the process is from a Siebel component, otherwise false.

=cut

sub is_comp {

    my $self = shift;

    my $comp_alias = $self->get_comp_alias();

    if ( ( $comp_alias eq 'unknown' ) or ( $comp_alias eq 'N/A' ) ) {

        return 0;

    }
    else {

        return 1;

    }

}

=head2 set_tasks_num

Sets the value of C<tasks_num> related to this process.

Expects as parameter a positive integer.

The method will validate if the process being updated is related to a Siebel Component. If not, a warning will be raised and
no update will be made.

=cut

sub set_tasks_num {

    my ( $self, $value ) = @_;

    confess "set_tasks_num requires a positive integer as parameter"
      unless ( isint($value) );

    my $set = $self->_build_set();

    if ( $set->has( $self->get_fname ) ) {

        $self->_set_tasks_num($value);

    }
    else {

        cluck 'the process '
          . $self->get_fname()
          . ' is not a valid Siebel Server process';

    }

}

__PACKAGE__->meta->make_immutable;
