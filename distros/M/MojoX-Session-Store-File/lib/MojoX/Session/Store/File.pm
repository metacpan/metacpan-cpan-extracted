package MojoX::Session::Store::File;

use strict;
use warnings;
use base 'MojoX::Session::Store';

use File::Spec;
use Carp qw(croak);

our $VERSION = '0.01';

__PACKAGE__->attr(dir    => File::Spec->tmpdir);
__PACKAGE__->attr(prefix => 'mojoxsess');
__PACKAGE__->attr(driver => 'MojoX::Session::Store::File::Driver::Storable');
__PACKAGE__->attr('_driver_instance');

my $_driver_instance;

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    my $driver_classname = $self->driver;
    unless($driver_classname =~ /^MojoX::Session::Store::File::Driver::/) {
        $driver_classname = "MojoX::Session::Store::File::Driver::$driver_classname";
    }

    my $driver_available = eval "require $driver_classname; 1";
    unless($driver_available) {
        croak "Driver '$driver_classname' is not installed";
    }

    $_driver_instance ||= $driver_classname->new;
    $self->_driver_instance($_driver_instance);

    $self;
}

sub create {
    my $self = shift;

    my($sid, $expires, $data) = @_;

    my $file = $self->_get_file_name($sid);
    return if -e $file;

    return $self->_driver_instance->freeze($file, [$expires, $data]);
}

sub update {
    my $self = shift;

    my($sid, $expires, $data) = @_;

    my $file = $self->_get_file_name($sid);
    return if not -e $file or not -w _;

    $self->_driver_instance->freeze($file, [$expires, $data]);
}

sub load {
    my $self = shift;

    my $sid = shift;

    my $file = $self->_get_file_name($sid);
    return if not -e $file or not -r _;

    @{$self->_driver_instance->thaw($file)};
}

sub delete {
    my $self = shift;

    my $sid = shift;

    unlink $self->_get_file_name($sid);
}

sub _get_file_name {
    my $self = shift;

    my $sid = shift;

    File::Spec->catfile($self->dir, sprintf('%s_%s', $self->prefix, $sid));
}

1;

__END__

=encoding utf8

=head1 NAME

MojoX::Session::Store::File - File store for MojoX::Session

=head1 SYNOPSIS

    my $session = MojoX::Session->new(
        store => MojoX::Session::Store::File->new,
    );

=head1 ATTRIBUTES

L<MojoX::Session::Store::File> implemets the following attributes:

=head2 dir

Directory to store session files. Must be writable. Defaults to your OS temp directory.

=head2 prefix

String to prefix each session filename. Defaults to "mojoxsess".

=head2 driver

Module to serialize your session data. Default is L<Storable>. L<FreezeThaw> also comes with this package. You are welcome to add your own (see L<MojoX::Session::Store::File::Driver>).

=head1 METHODS

L<MojoX::Session::Store::File> inherits all methods from L<MojoX::Session::Store>.

=head1 CONTRIBUTE

L<http://github.com/ksurent/MojoX--Session--Store--File>

=head1 AUTHOR

Алексей Суриков E<lt>ksuri@cpan.orgE<gt>

=head1 LICENSE

This program is free software, you can redistribute it under the same terms as Perl itself.
