package Seis::IO::Path;
use strict;
use warnings;
use utf8;
use 5.010_001;

package IO::Path;
use File::Basename ();
use File::Path ();
use File::Spec ();

use overload (
    q{""} => sub {
        $_[0]->{fullpath}
    },
    fallback => 1,
);

sub _file_spec { 'File::Spec' }

sub new {
    my $class = shift;
    my $fullpath = shift;
    bless {
        fullpath => $fullpath
    }, $class;
}

sub basename { File::Basename::basename($_[0]->{fullpath}) }

sub perl {
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Indent = 0;
    Data::Dumper::Dumper($_[0]->{fullpath});
}
sub gist { goto &perl }
sub volume {
    my $self = shift;
    (my $volume, ) = $self->_file_spec->splitpath($self->{fullpath});
    $volume;
}
sub directory {
    my $self = shift;
    (undef, my $volume, ) = $self->_file_spec->splitpath($self->{fullpath});
    $volume =~ s!/\z!!r;
}
sub parent {
    require Path::Tiny;
    IO::Path->new(Path::Tiny->new($_[0])->parent->stringify);
}
{
    no strict 'refs';
    *{"isーabsolute"} = sub {
        substr( $_[0]->directory, 0, 1 ) eq '/' ? Bool::True() : Bool::False()
    };
    *{"isーrelative"} = sub {
        substr( $_[0]->directory, 0, 1 ) ne '/' ? Bool::True() : Bool::False()
    };
}

sub path { $_[0] }
sub IO {
    Seis::IO::Handle->_new($_[0]->{fullpath});
}
sub cleanup {
    my $self = shift;
    $self->_file_spec->canonpath($self->{fullpath});
}

sub isa {
    my ($self, $stuff) = @_;
    return UNIVERSAL::isa($self, $stuff->{name}) if UNIVERSAL::isa($stuff, 'Seis::Class');
    return UNIVERSAL::isa($self, $stuff);
}

sub Str { $_[0]->{fullpath} }

sub absolute {
    my $self = shift;
    (ref $self)->new($self->_file_spec->rel2abs($self->{fullpath}, @_));
}
sub relative {
    my $self = shift;
    (ref $self)->new($self->_file_spec->rel2abs($self->{fullpath}, @_));
}

package IO::Path::Unix;
BEGIN { our @ISA = qw(IO::Path); }

use File::Spec::Unix;
sub _file_spec { 'File::Spec::Unix' }

package IO::Path::Win32;
BEGIN { our @ISA = qw(IO::Path); }

sub _file_spec {
    require File::Spec::Win32;
    'File::Spec::Win32'
}

sub resolve {
    ... # NYI
}

package IO::Path::Cygwin;
BEGIN { our @ISA = qw(IO::Path); }

sub _file_spec {
    require File::Spec::Cygwin;
    'File::Spec::Cygwin'
}
sub resolve {
    ... # NYI
}

package IO::Spec::Win32;
sub canonpath {
    require File::Spec::Win32;
    File::Spec::Win32->canonpath($_[1]);
}

package IO::Spec::Cygwin;
sub canonpath {
    require File::Spec::Cygwin;
    File::Spec::Cygwin->canonpath($_[1]);
}

package IO::Spec::Unix;
sub canonpath {
    File::Spec::Unix->canonpath($_[1]);
}

1;

