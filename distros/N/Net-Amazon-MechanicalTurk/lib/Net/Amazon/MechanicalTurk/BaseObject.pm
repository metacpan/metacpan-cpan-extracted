package Net::Amazon::MechanicalTurk::BaseObject;
use strict;
use warnings;
use Carp;
use IO::File;

our $VERSION = '1.00';

use constant USE_QUALIFIED_ATTRIBUTE_NAMES => 1;

our %CLASS_DEBUG;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->init(@_);
    return $self;
}

sub init {}

sub DESTROY {}

sub assertRequiredAttributes {
    my $self = shift; 
    foreach my $attr (@_) {
        if (!defined($self->$attr)) {
            Carp::croak("Required attribute ${attr} was not set.");
        }
    }
}

sub setAttributesIfNotDefined {
    my $self = shift;
    my %attrs = ($#_ == 0) ? %{$_[0]} : @_;
    while (my ($attr,$value) = each %attrs) {
        eval { $self->$attr($value) unless defined($self->$attr); };
        if ($@) { Carp::croak("Can't set attribute $attr - $@"); }
    }
}

sub setAttributes {
    my $self = shift;
    my %attrs = ($#_ == 0) ? %{$_[0]} : @_;
    while (my ($attr,$value) = each %attrs) {
        eval { $self->$attr($value); };
        if ($@) { Carp::croak("Can't set attribute $attr - $@"); }
    }
}

sub trySetAttributes {
    my $self = shift;
    my %attrs = ($#_ == 0) ? %{$_[0]} : @_;
    my %unsetAttrs;
    while (my ($attr,$value) = each %attrs) {
        if (UNIVERSAL::can($self, $attr)) {
            eval {
                $self->$attr($value);
            };
            if ($@) {
                Carp::carp("Couldn't set attribute $attr - $@");
                $unsetAttrs{$attr} = $value;
            }
        }
        else {
            $unsetAttrs{$attr} = $value;
        }
    }
    return \%unsetAttrs;
}

sub attributes {
    my $self = shift;
    foreach my $attr (@_) {
        $self->attribute($attr);
    }
}

sub methodAlias {
    my $self = shift;
    my %aliases = @_;
    my $class = ref($self) || $self;
    while (my ($alias,$existing) = each %aliases) {
        my $sub = UNIVERSAL::can($class, $existing);
        if (!$sub) {
            Carp::croak("Method $existing does not exist.");
        }
        no strict 'refs';
        no warnings;
        *{"${class}::${alias}"} = $sub;
    }
}

sub attribute {
    my $self = shift;
    my $attr = shift;
    my $attr_name = shift || $attr;

    my $class = ref($self) || $self;

    if (USE_QUALIFIED_ATTRIBUTE_NAMES) {
        $attr_name = "${class}::${attr_name}";
    }

    no strict 'refs';
    no warnings;
    # Create a subroutine for an attribute getter/setter
    *{"${class}::${attr}"} = sub {
        my $_self = shift;
        if ($#_ == 0) {
            $_self->{$attr_name} = $_[0];
        }
        return $_self->{$attr_name};
    };
}

sub debug {
    my $self = shift;
    my $class = ref($self) || $self;
    if ($#_ >= 0) {
        my $debug = shift;
        if (UNIVERSAL::isa($debug, "CODE") or
            UNIVERSAL::isa($debug, "GLOB") or
            UNIVERSAL::can($debug, "debugMessage"))
        {
            $CLASS_DEBUG{$class} = $debug;
        }
        elsif ($debug =~ /^STDERR$/i or $debug =~ /^(1|yes|true)$/i) {
            $CLASS_DEBUG{$class} = \*STDERR;
        }
        elsif ($debug =~ /^STDOUT$/i) {
            $CLASS_DEBUG{$class} = \*STDOUT;
        }
        elsif ($debug and $debug !~ /^(0|no|false)$/i) { # true value indicating file
            $CLASS_DEBUG{$class} = IO::File->new($debug, "a");
            if (!$CLASS_DEBUG{$class}) {
                print "Setting debug on $class to STDERR\n";
                # Couldn't open so go to STDERR.
                $CLASS_DEBUG{$class} = \*STDERR;
            }
            else {
                $CLASS_DEBUG{$class}->autoflush(1);
            }
        }
        else {
            delete $CLASS_DEBUG{$class};
        }
    }
    return $CLASS_DEBUG{$class};
}

sub debugMessage {
    my $self = shift;
    my $debug = $self->debug; 

    if (!defined($debug)) {
        return;
    }

    my @stack = caller(1); 
    my @time = localtime(time());

    my $prefix = sprintf("[%04d-%02d-%02d %02d:%02d:%02d] %s >> ",
        $time[5] + 1900,
        $time[4] + 1,
        $time[3],
        $time[2],
        $time[1],
        $time[0],
        $stack[3]
    );

    my @messages = split(/\n/, join(" ", @_));
    if (UNIVERSAL::isa($debug, "GLOB")) {
        foreach my $msg (@messages) {
            print $debug $prefix.$msg."\n";
        }
    }
    elsif (UNIVERSAL::isa($debug, "CODE")) {
        foreach my $msg (@messages) {
            $debug->($prefix.$msg."\n");
        }
    }
    else {
        foreach my $msg (@messages) {
            $debug->debugMessage($prefix.$msg."\n");
        }
    }
}

return 1;
