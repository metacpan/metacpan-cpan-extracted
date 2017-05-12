package Seis::Array;
use strict;
use warnings;
use utf8;
use 5.010_001;

package # Hide from PAUSE
    Array;

sub new {
    my ($class, @ary) = @_;
    bless \@ary, 'Array';
}

sub pop:method { CORE::pop $_[0] }
sub shift:method { CORE::shift $_[0] }
sub push:method { CORE::push $_[0], $_[1] }
sub unshift:method { CORE::unshift $_[0], $_[1] }
sub elems:method { 0+@{$_[0]} }

# is(([+] (1..999).grep( { $_ % 3 == 0 || $_ % 5 == 0 } )), 233168, 'Project Euler #1');
sub grep {
    my ($self, $code) = @_;
    grep { $code->($_) } @$self;
}

sub join:method {
    my ($self, $stuff) = @_;

    CORE::join $stuff, @$self;
}

sub WHAT {
    Seis::Class->_new(name => 'Array');
}

sub map:method {
    my ($self, $code) = @_;
    if (wantarray) {
        map { $code->($_) } @$self;
    } else {
        [map { $code->($_) } @$self];
    }
}

sub keys:method {
    my $self = shift;
    if (wantarray) {
        CORE::keys(@$self);
    } else {
        [CORE::keys(@$self)];
    }
}
sub values:method {
    my $self = shift;
    if (wantarray) {
        CORE::values(@$self);
    } else {
        [CORE::values(@$self)];
    }
}

sub perl {
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Indent = 0;
    Data::Dumper::Dumper($_[0]);
}

sub Bool { !!@{$_[0]} }

sub end { @{$_[0]}-1 }

sub exists:method { (0+@{$_[0]})>$_[1] }
sub sort:method {
    if (wantarray) {
        sort @{$_[0]};
    } else {
        [sort @{$_[0]}];
    }
}

sub pick:method {
    if (@_==1) {
        $_[0]->[int rand(@{$_[0]})];
    } elsif (@_==2 && UNIVERSAL::isa($_[1], 'Seis::Whatever')) {
        wantarray ? @{$_[0]} : $_[0];
    } else {
        ...
    }
}

sub fmt {
    my $self    = shift;
    my $pattern = @_ > 0 ? shift @_ : '%s';
    my $joiner  = @_ > 0 ? shift @_ : ' ';
    CORE::join($joiner, CORE::map { sprintf($pattern, $_) } @$self);
}

sub min:method {
    my $self = shift;
    scalar List::Util::minstr(grep { defined $_ } @$self);
}

sub Int { 0+@{$_[0]} }
sub Str { CORE::join(' ', @{$_[0]}) }

sub kv:method {
    my $self = shift;
    map { $_ => $self->[$_] } keys $self;
}

sub reverse:method {
    CORE::reverse(@{$_[0]})
}

1;

