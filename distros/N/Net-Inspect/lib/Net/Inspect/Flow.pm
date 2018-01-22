
############################################################################
# base class for packet flows
############################################################################

use strict;
use warnings;

package Net::Inspect::Flow;
use fields qw(upper_flow);

sub new {
    my ($class,$flow) = @_;
    if ( ! ref($class)) {
	# create new
	my $self = fields::new($class);
	$self->{upper_flow} = $flow;
	return $self;
    } else {
	my $self = fields::new(ref($class));
	$self->{upper_flow} = $flow
	    || ( $class->{upper_flow} && $class->{upper_flow}->new ); # clone
	return $self;
    }
}

sub new_any {
    shift;
    return Net::Inspect::Flow::Any->new(@_)
}

# does nothing per default
sub expire {}

package Net::Inspect::Flow::Any;
use Digest::MD5 'md5_hex';
use fields qw(flows);

sub new {
    my ($class,@methods) = @_;
    if (@methods) {
	my $clname = "Net::Inspect::Flow::Any::".
	    md5_hex(join("\0",sort @methods));
	if ( ! UNIVERSAL::can($clname,'new') ) {
	    # dynamically create class
	    eval "package $clname; use base 'Net::Inspect::Flow::Any';1"
		or die $@;
	    for my $method (@methods) {
		no strict 'refs';
		*{ "${clname}::$method" } = sub {
		    my $self = shift;
		    # copy, might change due detach in GuessProtocol
		    my @flows = @{$self->{flows}};
		    for my $flow (@flows) {
			if ( wantarray ) {
			    my @rv = $flow->$method(@_) or next;
			    return @rv
			} else {
			    defined( my $rv = $flow->$method(@_)) or next;
			    return $rv
			}
		    }
		    return;
		};
	    }
	}
	return $clname->new;
    }


    if ( ! ref $class ) {
	my $self = fields::new($class);
	$self->{flows} = [];
	return $self
    } else {
	my $self = fields::new(ref($class));
	# clone attached flows
	$self->{flows} = [ map { $_->new } @{ $class->{flows} } ];
	return $self;
    }
}

sub attach {
    my ($self,$flow) = @_;
    push @{ $self->{flows} }, $flow;
}

sub detach {
    my ($self,$flow) = @_;
    @{ $self->{flows} } = grep { $_ != $flow } @{ $self->{flows} };
}

sub attached {
    my $self = shift;
    return @{ $self->{flows} }
}

1;

__END__

=head1 NAME

Net::Inspect::Flow - base interface for Net::Inspect::* flows

=head1 SYNOPSIS

 my $tcp = Net::Inspect::L4::TCP->new(...);
 my $raw = Net::Inspect::L3::IP->new($tcp);
 ...

=head1 DESCRIPTION

Net::Inspect::Flow implements the interface for all flow objects, e.g. that they
have an upper flow object. It provides a member C<upper_flow> on which the
forwardinh hooks should be called.

=over 4

=item new(flow)

Create object, subclasses should call Net::Inspect::Flow::new to initialize
object. The given flow will be used for calling the hooks from the newly
created flow.
If called on object instead of class the object should clone itself. In this
case the flow from the cloned object will be cloned too, unless a new flow
is given.

=item new_any(methods)

Create if necessary a class derived from C<Net::Inspect::Flow::Any>, which
contains the given methods additionally to the methods of
C<Net::Inspect::Flow::Any>.
These methods loop over the attached C<flows>  and call the method with the
same name on the flow and returns the first defined result.

C<Net::Inspect::Flow::Any> provides the following methods:

=over 4

=item attach(flow)

adds flow to internal list of flows

=item detach(flow)

detaches flow from internal list of flows

=item attached

returns internal list of flows

=back
