package Module::Spy;
use 5.008005;
use strict;
use warnings;
use Scalar::Util ();

our $VERSION = "0.07";

use parent qw(Exporter);

our @EXPORT = qw(spy_on);

sub spy_on {
    my ($stuff, $method) = @_;

    if (Scalar::Util::blessed($stuff)) {
        Module::Spy::Object->new($stuff, $method);
    } else {
        Module::Spy::Class->new($stuff, $method);
    }
}

package Module::Spy::Base;

sub stuff { shift->{stuff} }
sub method { shift->{method} }

sub calls_any         { @{shift->{spy}->calls_all(@_)} > 0 }
sub calls_count       { 0+@{shift->{spy}->calls_all(@_)} }
sub calls_all         { shift->{spy}->calls_all(@_) }
sub calls_most_recent { shift->{spy}->calls_all(@_)->[-1] }
sub calls_first       { shift->{spy}->calls_all(@_)->[0] }
sub calls_reset       { shift->{spy}->calls_reset(@_) }

sub called {
    my $self = shift;
    $self->{spy}->called;
}

sub and_call_through {
    my $self = shift;
    $self->{spy}->call_through;
    return $self;
}

sub and_call_fake {
    my ($self, $code) = @_;
    $self->{spy}->call_fake($code);
    return $self;
}

sub and_returns {
    my $self = shift;
    $self->{spy}->returns(@_);
    return $self;
}
sub returns { shift->and_returns(@_) }

package Module::Spy::Object;
our @ISA=('Module::Spy::Base');

my $SINGLETON_ID = 0;

sub new {
    my $class = shift;
    my ($stuff, $method) = @_;

    my $self = bless { stuff => $stuff, method => $method }, $class;

    my $orig = $self->stuff->can($self->method)
        or die "Missing $method";
    $self->{orig} = $orig;

    my $spy = Module::Spy::Sub->new($orig);
    $self->{spy} = $spy;

    $self->{orig_class} = ref($stuff);

    {
        no strict 'refs';
        no warnings 'redefine';

        $SINGLETON_ID++;
        my $klass = "Module::Spy::__ANON__::" . $SINGLETON_ID;
        $self->{id} = $SINGLETON_ID;
        $self->{anon_class} = $klass;
        $self->{isa} = do { \@{"${klass}::ISA"} };
        unshift @{$self->{isa}}, ref($stuff);
        *{"${klass}::${method}"} = $spy;
        bless $stuff, $klass; # rebless
    }

    return $self;
}

sub get_stash {
    my $klass = shift;

    my $pack = *main::;
    foreach my $part (split /::/, $klass){
        return undef unless $pack = $pack->{$part . '::'};
    }
    return *{$pack}{HASH};
}

sub DESTROY {
    my $self = shift;

    # Restore the object's type.
    if (ref($self->stuff) eq $self->{anon_class}) {
        bless $self->stuff, $self->{orig_class};
    }

    @{$self->{isa}} = ();

    my $original_stash = get_stash("Module::Spy::__ANON__");
    my $sclass_stashgv = delete $original_stash->{$self->{id} . '::'};
    %{$sclass_stashgv} = ();

    undef $self->{spy};
}

package Module::Spy::Class;
our @ISA=('Module::Spy::Base');

use Class::Load qw(load_class);

sub new {
    my $class = shift;
    my ($stuff, $method) = @_;
    load_class($stuff); # $stuff is a class in Module::Spy::Class

    my $self = bless { stuff => $stuff, method => $method }, $class;

    my $orig = $self->stuff->can($self->method);
    $self->{orig} = $orig;

    my $spy = Module::Spy::Sub->new($orig);
    $self->{spy} = $spy;

    {
        no strict 'refs';
        no warnings 'redefine';
        *{$self->stuff . '::' . $self->method} = $spy;
    }

    return $self;
}

sub DESTROY {
    my $self = shift;
    my $stuff = $self->{stuff};
    my $method = $self->{method};
    my $orig = $self->{orig};

    if (defined $orig) {
        no strict 'refs';
        no warnings 'redefine';
        *{"${stuff}::${method}"} = $orig;
    } else {
        no strict 'refs';
        delete ${"${stuff}::"}{${method}};
    }

    undef $self->{spy};
}

package Module::Spy::Sub;
use Scalar::Util qw(refaddr);

# inside-out
our %COUNTER;
our %RETURNS;
our %CALL_THROUGH;
our %CALL_FAKE;
our %ARGS;

sub new {
    my ($class, $orig) = @_;

    my $body;
    my $code = sub { goto $body };

    my $code_addr = refaddr($code);
    $body = sub {
        $COUNTER{$code_addr}++;
        push @{$ARGS{$code_addr}}, [@_];

        if (my $fake = $CALL_FAKE{$code_addr}) {
            goto $fake;
        }

        if (exists $RETURNS{$code_addr}) {
            if (@{$RETURNS{$code_addr}} == 1) {
                return $RETURNS{$code_addr}->[0];
            }
            return @{$RETURNS{$code_addr}};
        }

        if ($CALL_THROUGH{$code_addr}) {
            goto $orig;
        }

        return;
    };
    $COUNTER{$code_addr} = 0;
    $ARGS{$code_addr} = [];

    my $self = bless $code, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
    my $code_addr = refaddr($self);

    delete $COUNTER{$code_addr};
    delete $RETURNS{$code_addr};
    delete $CALL_FAKE{$code_addr};
    delete $CALL_THROUGH{$code_addr};
    delete $ARGS{$code_addr};
}

sub called {
    my $self = shift;
    !!$COUNTER{refaddr($self)};
}

sub calls_all {
    my $self = shift;
    $ARGS{refaddr($self)};
}

sub calls_reset {
    my $self = shift;
    $COUNTER{refaddr($self)} = 0;
    $ARGS{refaddr($self)} = [];
}

sub returns {
    my $self = shift;
    $RETURNS{refaddr($self)} = [@_];
}

sub call_through {
    my $self = shift;
    $CALL_THROUGH{refaddr($self)}++;
}

sub call_fake {
    my ($self, $code) = @_;
    $CALL_FAKE{refaddr($self)} = $code;
}

1;
__END__

=encoding utf-8

=head1 NAME

Module::Spy - Spy for Perl5

=head1 SYNOPSIS

Spy for class method.

    use Module::Spy;

    my $spy = spy_on('LWP::UserAgent', 'request');
    $spy->and_returns(HTTP::Response->new(200));

    my $res = LWP::UserAgent->new()->get('http://mixi.jp/');

Spy for object method

    use Module::Spy;

    my $ua = LWP::UserAgent->new();
    my $spy = spy_on($ua, 'request')->and_returns(HTTP::Response->new(200));

    my $res = $ua->get('http://mixi.jp/');

    ok $spy->called;

=head1 DESCRIPTION

Module::Spy is spy library for Perl5.

=head1 FUNCTIONS

=over 4

=item C<< my $spy = spy_on($class|$object, $method) >>

Create new spy. Returns new Module::Spy::Class or Module::Spy::Object instance.

=back

=head1 Module::Spy::(Class|Object) methods

=over 4

=item C<< $spy->called() :Bool >>

=item C<< $spy->and_called() :Bool >>

Returns true value if the method was called. False otherwise.

=item C<< $spy->returns($value) : Module::Spy::Base >>

=item C<< $spy->and_returns($value) : Module::Spy::Base >>

Stub the method's return value as C<$value>.

Returns C<<$spy>> itself for method chaining.

=item C<< $spy->and_call_through() : Module::Spy::Base >>

Do not stub the method's return value, calls original implementation.

Returns C<<$spy>> itself for method chaining.

=item C<< $spy->calls_any() : Bool >>

Returns false if the spy has not been called at all, and then true once at least one call happens.

=item C<< $spy->calls_count() : Int >>

Returns the number of times the spy was called

=item C<< $spy->calls_all() : ArrayRef >>

Returns arguments passed all calls

=item C<< $spy->calls_most_recent() : ArrayRef >>

Returns arguments for the most recent call

=item C<< $spy->calls_first() : ArrayRef >>

Returns arguments for the first call

=item C<< $spy->calls_reset() >>

Clears all tracking for a spy

=back

=head1 SEE ALSO

The interface was inspired from Jasmine library L<http://jasmine.github.io/>.

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=cut

