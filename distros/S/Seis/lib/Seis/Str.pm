package Seis::Str;
use strict;
use warnings;
use utf8;
use 5.012_001;

package # Hide from CPAN
    Str;
use Data::Dumper ();
use feature 'fc';
use Encode ();

sub uc:method { CORE::uc($_[0]) }
sub lc:method { CORE::lc($_[0]) }
sub fc:method { CORE::fc($_[0]) }
sub ord:method { CORE::ord($_[0]) }

sub say { CORE::say($_[0]) }

sub perl {
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Indent = 0;
    Data::Dumper::Dumper($_[0]);
}
sub gist { Str::perl(@_) }

sub clone { "$_[0]" }

sub Bool { Bool::boolean($_[0]) }

sub lines {
    my ($self, $n) = @_;
    my @lines = split /\n/, $self;
    $n ? [@lines[0..$n-1]] : \@lines;
}

# Generate new IO object.
# IO.new(ins => 0, chomp => Bool::True, path => "/tmp/")
sub IO {
    if (@_==1) {
        Seis::IO::Handle->_new($_[0]);
    } else {
        ...
    }
}

sub defined { 1 }

sub fmt {
    my ($self, $pattern) = @_;
    sprintf($pattern, $self);
}

sub WHAT {
    my $self = shift;
    Seis::Class->_new(name => 'Str');
}

sub Int { int shift; }

sub encode {
    my ($self, $encoding) = @_;
    Encode::encode($encoding, $self);
}

sub Str { $_[0] }

sub ords {
    my @ret = map { ord($_) } split //, $_[0];
    wantarray ? @ret : \@ret;
}

sub rindex:method {
    my ($self, $str) = @_;
    CORE::rindex($self, $str);
}

sub tc:method {
    ucfirst($_[0]);
}

# Create new IO::Path object
sub path {
    IO::Path->new($_[0]);
}

sub eval:method {
    CORE::eval($_[0]);
}

1;

