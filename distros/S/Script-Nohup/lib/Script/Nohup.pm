package Script::Nohup;
use Mouse;
use Mouse::Util::TypeConstraints;

use 5.008001;
use utf8;
use POSIX qw/setsid/;
use Path::Class::File;
use Time::Piece;
use IO::Handle;

sub import {
    my $pkg = shift;

    $pkg->_fork;

    my $script_nohup = $pkg->new(@_);

    $SIG{HUP} = 'IGNORE';
    print "start  : ".$script_nohup->basename."\n";
    print "create : ".$script_nohup->filename."\n";

    $script_nohup->_logger();
}

our $VERSION = "0.01";

subtype "Path::Class::File" => as Object => where { $_->isa("Path::Class::File") };
coerce "Path::Class::File"
    => from "Str",
    => via { Path::Class::File->new($_) };

has script => (
     is      => "ro",
     isa     => "Path::Class::File",
     coerce  => 1,
     default => sub { $0 },
);

has basename => (
    is       => "ro",
    isa      => "Str",
    default  => sub {
        my $self = shift;
        $self->script->basename
    },
);

has filename => (
    is      => "ro",
    isa     => "Str",
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->basename.'_'.$self->exec_date.$self->file_extention;
    },
);

has file_extention => (
    is       => "ro",
    isa      => "Str",
    default  => ".log"
);

has exec_date => (
    is      => "ro",
    default => sub { localtime->ymd }
);

has file => (
    is      => "ro",
    isa     => "Path::Class::File",
    lazy    => 1,
    coerce  => 1,
    default => sub {
        my $self = shift;
        $self->script->dir->file($self->filename);
    },
);

no Mouse;


sub _fork {
    my $pid = fork();
    die "can't fork: $!" unless defined $pid;
    exit 0 if $pid;
    setsid();
}

sub _logger {
    my $self = shift;

    STDOUT->autoflush;
    STDERR->autoflush;

    $self->_add_log;
}

sub _add_log {
    my $self = shift;
    open(STDOUT,'>>',$self->file);
    open(STDERR,'>>',$self->file);
}

1;

__END__

=encoding utf-8

=head1 NAME

Script::Nohup - This module can be nohup the processing

=head1 SYNOPSIS
Just do this

    use Script::Nohup;

=head1 DESCRIPTION

Script::Nohup is can be running to script by nohup.

THE SOFTWARE IS ALPHA QUALITY. API MAY CHANGE WITHOUT NOTICE.

=head1 LICENSE

Copyright (C) MacoTasu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

MacoTasu E<lt>maco.tasu+cpan@gmail.comE<gt>

=cut

