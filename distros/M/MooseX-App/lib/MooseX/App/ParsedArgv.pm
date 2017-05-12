# ============================================================================
package MooseX::App::ParsedArgv;
# ============================================================================

use 5.010;
use utf8;

use Moose;

use Encode qw(decode);
use MooseX::App::ParsedArgv::Element;
use MooseX::App::ParsedArgv::Value;

no if $] >= 5.018000, warnings => qw(experimental::smartmatch);

my $SINGLETON;

has 'argv' => (
    is              => 'ro',
    isa             => 'ArrayRef[Str]',
    traits          => ['Array'],
    handles         => {
        length_argv     => 'count',
        elements_argv   => 'elements',
        _shift_argv     => 'shift',
    },
    default         => sub {
        my @argv;
        @argv = eval {
            require I18N::Langinfo;
            I18N::Langinfo->import(qw(langinfo CODESET));
            my $codeset = langinfo(CODESET());
            # TODO Not sure if this is the right place?
            if ($codeset =~ m/^UTF-?8$/i) {
                binmode(STDOUT, ":encoding(UTF-8)");
                binmode(STDERR, ":encoding(UTF-8)");
            }
            return map { decode($codeset,$_) } @ARGV;
        };
        # Fallback to standard
        if ($@) {
            @argv = @ARGV;
        }
        return \@argv;
    },
);

has 'hints_novalue' => (
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    default         => sub { [] },
); # No value hints for the parser (such as for flags)

has 'hints_permute' => (
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    default         => sub { [] },
); # Permute hints for the parser

has 'hints_fixedvalue' => (
    is              => 'rw',
    isa             => 'HashRef[Str]',
    default         => sub { {} },
); # fixed value hints for the parser

has 'elements' => (
    is              => 'ro',
    isa             => 'ArrayRef[MooseX::App::ParsedArgv::Element]',
    lazy            => 1,
    builder         => '_build_elements',
    clearer         => 'reset_elements',
);

sub BUILD {
    my ($self) = @_;

    # Register singleton
    $SINGLETON = $self;
    return $self;
}

sub DEMOLISH {
    my ($self) = @_;

    # Unregister singleton if it is stll the same
    $SINGLETON = undef
        if defined $SINGLETON
        && $SINGLETON == $self;

    return;
}

sub instance {
    my ($class) = @_;
    unless (defined $SINGLETON) {
        return $class->new();
    }
    return $SINGLETON;
}

sub first_argv {
    my ($self) = @_;
    return ($self->elements_argv)[0];
}

sub shift_argv {
    my ($self) = @_;
    $self->reset_elements;
    return $self->_shift_argv;
}

sub _build_elements {
    my ($self) = @_;

    my (@elements);

    my %options;
    my $lastkey;
    my $lastelement;
    my $stopprocessing  = 0; # Flag that is set after ' -- ' and inticated end of processing
    my $position        = 0; # Argument position
    my $expecting       = 0; # Flag that indicates that a value is expected

    # Loop all elements of our ARGV copy
    foreach my $element ($self->elements_argv) {
        # We are behind first ' -- ' occurrence: Do not process further
        if ($stopprocessing) {
            push (@elements,MooseX::App::ParsedArgv::Element->new(
                key => $element,
                type => 'extra',
            ));
        # Process element
        } else {
            given ($element) {
                # Flags with only one leading dash (-h or -vh)
                when (m/^-([^-][[:alnum:]]*)$/) {
                    undef $lastkey;
                    undef $lastelement;
                    $expecting = 0;
                    # Split into single letter flags
                    foreach my $flag (split(//,$1)) {
                        unless (defined $options{$flag}) {
                            $options{$flag} = MooseX::App::ParsedArgv::Element->new(
                                key => $flag,
                                type => 'option',
                                raw => $element,
                            );
                            push(@elements,$options{$flag});
                        }
                        $options{$flag}->add_value(
                            1,
                            $position,
                            $element,
                        );
                        $lastkey = $options{$flag};
                        $lastelement = $element;
                    }
                }
                # Key-value combined (--key=value)
                when (m/^--([^-=][^=]*)=(.+)$/) {
                    undef $lastkey;
                    undef $lastelement;
                    $expecting = 0;
                    my ($key,$value) = ($1,$2);
                    unless (defined $options{$key}) {
                        $options{$key} = MooseX::App::ParsedArgv::Element->new(
                            key => $key,
                            type => 'option',
                            raw => $element,
                        );
                        push(@elements,$options{$key});
                    }
                    $options{$key}->add_value(
                        $value,
                        $position,
                        $element,
                    );
                }
                # Ordinary key
                when (m/^--?([^-].*)/) {
                    my $key = $1;

                    unless (defined $options{$key} ) {
                        $options{$key} = MooseX::App::ParsedArgv::Element->new(
                            key => $key,
                            type => 'option',
                            raw => $element,
                        );
                        push(@elements,$options{$key});
                    }
                    # This is a boolean or counter key that does not expect a value
                    if ($key ~~ $self->hints_novalue) {
                        $options{$key}->add_value(
                            ($self->hints_fixedvalue->{$key} // 1),
                            $position,
                            $element
                        );
                        $expecting = 0;
                    # We are expecting a value
                    } else {
                        $expecting = 1;
                        $lastelement = $element;
                        $lastkey = $options{$key};
                    }
                }
                # Extra values - stop processing after this token
                when ('--') {
                    undef $lastkey;
                    undef $lastelement;
                    $stopprocessing = 1;
                    $expecting = 0;
                }
                # Value
                default {
                    if (defined $lastkey) {
                        # This is a parameter - last key was a flag
                        if ($lastkey->key ~~ $self->hints_novalue) {
                            push(@elements,MooseX::App::ParsedArgv::Element->new( key => $element, type => 'parameter' ));
                            undef $lastkey;
                            undef $lastelement;
                            $expecting = 0;
                        # Permute values
                        } elsif ($lastkey->key ~~ $self->hints_permute) {
                            $expecting = 0;
                            $lastkey->add_value(
                                $element,
                                $position,
                                $lastelement
                            );
                        # Has value
                        } else {
                            $expecting = 0;
                            $lastkey->add_value($element,$position);
                            undef $lastkey;
                            undef $lastelement;
                        }
                    } else {
                        push(@elements,MooseX::App::ParsedArgv::Element->new( key => $element, type => 'parameter' ));
                    }
                }
            }
        }
        $position++;
    }

    # Fill up last value
    if (defined $lastkey
        && $expecting) {
        $lastkey->add_value(undef,$position,$lastelement);
        $position++;
    }

    return \@elements;
}

sub available {
    my ($self,$type) = @_;

    my @elements;
    foreach my $element (@{$self->elements}) {
        next
            if $element->consumed;
        next
            if defined $type
            && $element->type ne $type;
        push(@elements,$element);
    }
    return @elements;
}

sub consume {
    my ($self,$type) = @_;

    foreach my $element (@{$self->elements}) {
        next
            if $element->consumed;
        next
            if defined $type
            && $element->type ne $type;
        $element->consume;
        return $element;
    }
    return;
}

sub extra {
    my ($self) = @_;

    my @extra;
    foreach my $element (@{$self->elements}) {
        next
            if $element->consumed;
        next
            unless $element->type eq 'parameter'
            || $element->type eq 'extra';
        push(@extra,$element->key);
    }

    return @extra;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

MooseX::App::ParsedArgv - Parses @ARGV

=head1 SYNOPSIS

 use MooseX::App::ParsedArgv;
 my $argv = MooseX::App::ParsedArgv->instance;
 
 foreach my $option ($argv->available('option')) {
     say "Parsed ".$option->key;
 }

=head1 DESCRIPTION

This is a helper class that holds all options parsed from @ARGV. It is
implemented as a singleton. Unless you are developing a MooseX::App plugin
you usually do not need to interact with this class.

=head1 METHODS

=head2 new

Create a new MooseX::App::ParsedArgv instance. Needs to be called as soon
as possible.

=head2 instance

Get the current MooseX::App::ParsedArgv instance. If there is no instance
a new one will be created.

=head2 argv

Accessor for the initinal @ARGV.

=head2 hints

ArrayRef of attributes that tells the parser which attributes should be
regarded as flags without values.

=head2 first_argv

Shifts the current first element from @ARGV.

=head2 available

 my @options = $self->available($type);
 OR
 my @options = $self->available();

Returns an array of all parsed options or parameters that have not yet been consumed.
The array elements will be L<MooseX::App::ParsedArgv::Element> objects.

=head2 consume

 my $option = $self->consume($type);
 OR
 my $option = $self->consume();

Returns the first option/parameter of the local @ARGV that has not yet been
consumed as a L<MooseX::App::ParsedArgv::Element> object.

=head2 elements

Returns all parsed options and parameters.

=head2 extra

Returns an array reference of unconsumed positional parameters and
extra values.

=cut
