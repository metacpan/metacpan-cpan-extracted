package Net::Appliance::Logical;
use base qw(Class::Data::Inheritable);

use Carp;
use LWP::UserAgent;
use Net::SNMP;
use Net::Appliance::Session;
use Class::Date qw(date -DateParse);
use Regexp::Common qw /URI/;



our $VERSION = '0.01';



=head1 NAME

Net::Appliance::Logical - Base Class for interacting various network appliances

=head1 SYNOPSIS

  use base 'Net::Appliance::Logical';

=head1 DESCRIPTION

When managing a variety of network appliances, several common needs arise
that this module attempts to automate.

=cut




__PACKAGE__->mk_classdata( actions => {
	uptime			=> { snmpget => '1.3.6.1.2.1.1.3.0' },
	location		=> { snmpget => '1.3.6.1.2.1.1.6.0' }
} );



__PACKAGE__->mk_classdata( ua => LWP::UserAgent->new(agent => __PACKAGE__) );



=pod

=head1 METHODS
=cut


sub new {
    my ( $class, $host, $opts ) = @_;

    my $self = bless {}, $class;
    
    croak "Must provide host"
      unless $host;

    $opts->{host} = $host;

    $self->{config} = $opts;

    return $self;
}


=pod
=item action

  my $val = $obj->action( $name );

Given an action, uses the appropriate action method.

=cut

sub action
{
	my ($self, $name, $opts) = @_;
	
	croak "No action specified"
		unless $name;
	
	my %pair = %{$self->actions->{$name}};   # because each remembers
	my ($method, $value) = each %pair;
	
	croak "No action method called $method"
		unless UNIVERSAL::can($self, $method);
	
	return $self->$method($value, $opts);
}


=pod

=item snmpget

  my $val = $obj->snmpget( $oid );

This method takes an OID number and returns the value it got from an SNMP
query for that oid.  Any timeticks are not translated, they are returned as
an integer instead.  L<Time::Duration> is handy for translating it yourself.

=cut

sub snmpget
{
	my ($self, $key) = @_;
		
	croak "No key specified"
		unless $key;
	
	my ($snmp, $error) = Net::SNMP->session(
			-hostname	=> $self->{config}->{host},
			-community	=> $self->{config}->{community},
			-translate	=> [ -timeticks	=> 0x0 ]
	) or croak "Could not create snmp session: $error";

	my $result = $snmp->get_request(
		-varbindlist	=> [$key]
	);

	$snmp->close;
	
	croak "Could not fetch snmp value: " . $snmp->error
		unless defined($result);

	return $result->{$key};
}

=pod

=item session

Returns a connected L<Net::Appliance::Session> object.

=cut

sub session {
    my ($self) = shift;
    
    my $s = Net::Appliance::Session->new(
        Host => $self->{config}->{host},
        Transport => $self->{config}->{cli_transport}
    );
    $s->connect(
        Name => $self->{config}->{user},
        Password => $self->{config}->{password}
    );
}

=pod

=item cmd

    $obj->cmd('ping 1.2.3.4');

Executes a command via the connected session.  You can pass an
array to execute more than one command at a time.

=cut

sub cmd {
    my $self = shift;

    my $s = $self->session;
    return map { $s->cmd($_) } @_;
}

=pod

=item privcmd

    $obj->privcmd('reboot');

Executes a priviledged command via the connected session.
You can pass an array to execute more than one command at a time.

=cut


sub privcmd {
    my $self = shift;
    
    my $s = $self->session;
    $s->begin_privileged($self->{config}->{enable});
    my @return = map { $s->cmd($_) } @_;
    $s->end_priviledged;
    return @return;
}



=pod

=item trim

  my $trimmed = $obj->trim( $string );

Trims whitespace from the beginning and end of a string

=cut

sub trim
{
	my ($self, $str) = @_;
	
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	return $str;
}




sub AUTOLOAD
{
	our $AUTOLOAD;
	my $self = shift;
	my $method = $AUTOLOAD;
	$method =~ s/.*:://s;

	croak "Method $method not implemented"
		unless $self->actions->{$method};

	return $self->action($method, @_);
}




1;




__END__

=head1 SEE ALSO

L<Net::Appliance::Logical::BlueCoat::SGOS>

=head1 AUTHOR

Christopher Heschong, <F<chris@wiw.org>>.

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
