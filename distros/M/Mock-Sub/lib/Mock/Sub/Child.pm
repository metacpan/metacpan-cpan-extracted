package Mock::Sub::Child;
use 5.006;
use strict;
use warnings;

use Carp qw(confess);
use Scalar::Util qw(weaken);

our $VERSION = '1.07';

sub new {
    my $self = bless {}, shift;
    %{ $self } = @_;

    if ($self->{side_effect}){
        $self->_check_side_effect($self->{side_effect});
    }
    return $self;
}
sub _mock {
    my $self = shift;

    # throw away the sub name if it's sent in and we're not called
    # by Mock::Sub::mock()

    my $sub_passed_in;
    if ($_[0] && $_[0] =~ /::/){
        $sub_passed_in = 1;
    }

    my $caller = (caller(1))[3] || '';
    
    if ($caller ne 'Mock::Sub::mock' && $sub_passed_in){
        undef @_;
        if(ref($self) eq 'Mock::Sub::Child' && ! $self->{name}){
            confess "can't call mock() on a child object before it is already " .
                  "initialized with the parent mock object. ";
        }
    }

    if ($caller ne 'Mock::Sub::mock' && $caller ne 'Mock::Sub::Child::remock'){
        confess "the _mock() method is not a public API call. For re-mocking " .
              "an existing sub in an existing sub object, use remock().\n";
    }

    my $sub = $self->name || shift;

    my %p = @_;
    for (keys %p){
        $self->{$_} = $p{$_};
    }

    if ($sub !~ /::/) {
        my $core_sub = "CORE::" . $sub;

        if (defined &$core_sub && ${^GLOBAL_PHASE} eq 'START') {
            warn "WARNING! we're attempting to override a global core " .
                 "function. You will NOT be able to restore functionality " .
                 "to this function.";

            $sub = "CORE::GLOBAL::" . $sub;
        }
        else {
            $sub = "main::$sub" if $sub !~ /::/;
        }
    }

    my $fake;

    if (! exists &$sub && $sub !~ /CORE::GLOBAL/) {
        $fake = 1;
        if (! $self->_no_warn) {
            warn "\n\nWARNING!: we've mocked a non-existent subroutine. ".
                    "the specified sub does not exist.\n\n";
        }
    }

    $self->_check_side_effect($self->{side_effect});

    if (defined $self->{return_value}){
        push @{ $self->{return} }, $self->{return_value};
    }

    $self->{name} = $sub;
    $self->{orig} = \&$sub if ! $fake;

    $self->{called_count} = 0;

    {
        no strict 'refs';
        no warnings 'redefine';

        my $mock = $self;
        weaken $mock;

        *$sub = sub {

            @{ $mock->{called_with} } = @_;
            ++$mock->{called_count};

            if ($mock->{side_effect}) {
                if (wantarray){
                    my @effect = $mock->{side_effect}->(@_);
                    return @effect if @effect;
                }
                else {
                    my $effect = $mock->{side_effect}->(@_);
                    return $effect if defined $effect;
                }
            }

            return if ! $mock->{return};

            return ! wantarray && @{ $mock->{return} } == 1
                ? $mock->{return}[0]
                : @{ $mock->{return} };
        };
    }
    $self->{state} = 1;

    return $self;
}
sub remock {
    shift->_mock(@_);
}
sub unmock {
    my $self = shift;
    my $sub = $self->{name};

    {
        no strict 'refs';
        no warnings 'redefine';

        if (defined $self->{orig} && $sub !~ /CORE::GLOBAL/) {
            *$sub = \&{ $self->{orig} };
        }
        else {
            undef *$sub if $self->{name};
        }
    }

    $self->{state} = 0;
    $self->reset;
}
sub called {
    return shift->called_count ? 1 : 0;
}
sub called_count {
    return shift->{called_count} || 0;
}
sub called_with {
    my $self = shift;
    if (! $self->called){
        confess "\n\ncan't call called_with() before the mocked sub has " .
            "been called. ";
    }
    return @{ $self->{called_with} };
}
sub name {
    return shift->{name};  
}
sub reset {
    for (qw(side_effect return_value return called called_count called_with)){
        delete $_[0]->{$_};
    }
}
sub return_value {
    my $self = shift;
    @{ $self->{return} } = @_;
}
sub side_effect {
    $_[0]->_check_side_effect($_[1]);
    $_[0]->{side_effect} = $_[1];
}
sub _check_side_effect {
    if (defined $_[1] && ref $_[1] ne 'CODE') {
        confess "\n\nside_effect parameter must be a code reference. ";
    }
}
sub mocked_state {
    return shift->{state};
}
sub _no_warn {
    return $_[0]->{no_warnings};
}
sub DESTROY {
    $_[0]->unmock;
}
sub _end {}; # vim fold placeholder

__END__

=head1 NAME

Mock::Sub::Child - Provides for Mock::Sub

=head1 METHODS

Please refer to the C<Mock::Sub> parent module for full documentation. The
descriptions here are just a briefing.

=head2 new

This method can only be called by the parent C<Mock::Sub> module.

=head2 called

Returns bool whether the mocked sub has been called yet.

=head2 called_count

Returns an integer representing the number of times the mocked sub has been called.

=head2 called_with

Returns a list of arguments the mocked sub was called with.

=head2 mock

This method should only be called by the parent mock object. You shouldn't be
calling this.

=head2 remock

Re-mocks an unmocked sub back to the same subroutine it was originally mocked with.

=head2 mocked_state

Returns bool whether the sub the object represents is currently mocked or not.

=head2 name

Returns the name of the sub this object is mocking.

=head2 return_value

Send in any values (list or scalar) that you want the mocked sub to return when called.

=head2 side_effect

Send in a code reference with any actions you want the mocked sub to perform after it's been called.

=head2 reset

Resets all state of the object back to default (does not unmock the sub).

=head2 unmock

Restores original functionality of the mocked sub, and calls C<reset()> on the object.

=cut
1;

