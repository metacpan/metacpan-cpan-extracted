package Safe::Caller;

use strict;
use warnings;
use boolean qw(true false);

use Carp qw(croak);

our $VERSION = '0.10';

use constant FRAMES => 1;

sub new
{
    my $class = shift;
    my ($frames) = @_;
    $frames ||= FRAMES;

    my $caller = sub
    {
        my ($f, $elem) = @_;
        my $frames = defined $f ? $f : $frames;
        return (caller($frames + 2))[$elem] || '';
    };

    # All fields required because we need
    # to retain backwards compatibility.
    my @sets = (
        [qw(package pkg)],
        [qw(filename file)],
        'line',
        [qw(subroutine sub)],
        'hasargs',
        'wantarray',
        'evaltext',
        'is_require',
        'hints',
        'bitmask'
    );

    my %fields;
    my $i = 0;
    foreach my $set (@sets) {
        foreach my $name (ref $set eq 'ARRAY' ? @$set : $set) {
            $fields{$name} = $i;
        }
        $i++;
    }

    my $accessors = {};
    foreach my $name (keys %fields) {
        $accessors->{$name} = sub
        {
            my $frames = shift;
            return $caller->($frames, $fields{$name});
        };
    }
    $accessors->{_frames} = $frames;

    return bless $accessors, ref($class) || $class;
}

sub called_from_package
{
    my $self = shift;
    my ($called_from_package) = @_;
    croak q(Usage: $caller->called_from_package('Package');)
      unless defined $called_from_package;

    return $self->{package}->() eq $called_from_package
      ? true : false;
}

sub called_from_filename
{
    my $self = shift;
    my ($called_from_filename) = @_;
    croak q(Usage: $caller->called_from_filename('file');)
      unless defined $called_from_filename;

    return $self->{filename}->() eq $called_from_filename
      ? true : false;
}

sub called_from_line
{
    my $self = shift;
    my ($called_from_line) = @_;
    croak q(Usage: $caller->called_from_line(42);)
      unless defined $called_from_line && $called_from_line =~ /^\d+$/;

    return $self->{line}->() == $called_from_line
      ? true : false;
}

sub called_from_subroutine
{
    my $self = shift;
    my ($called_from_subroutine) = @_;
    croak q(Usage: $caller->called_from_subroutine('Package::sub');)
      unless defined $called_from_subroutine;

    return $self->{subroutine}->($self->{_frames} + 1) eq $called_from_subroutine
      ? true : false;
}

# backwards compatibility (deprecated)
*called_from_pkg  = \&called_from_package;
*called_from_file = \&called_from_filename;
*called_from_sub  = \&called_from_subroutine;

1;
__END__

=head1 NAME

Safe::Caller - Control code execution based upon caller()

=head1 SYNOPSIS

 package abc;

 use Safe::Caller;

 $caller = Safe::Caller->new;

 a();

 sub a { b() }

 sub b {
     if ($caller->called_from_subroutine('abc::a')) { # do stuff }
     print $caller->{subroutine}->();
 }

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new

 $caller = Safe::Caller->new(1);

Providing how many frames to go back while running L<perlfunc/caller> is optional.
By default (if no suitable value is provided) 1 will be assumed. The default
will be shared among all accessors and verification routines; the accessors
may optionally accept a frame as argument, whereas verification routines
(C<called_from_*()>) don't.

=head1 METHODS

=head2 called_from_package

Checks whether the current sub was called within the given package.

 $caller->called_from_package('Package');

Returns true on success, false on failure.

=head2 called_from_filename

Checks whether the current sub was called within the given filename.

 $caller->called_from_filename('file');

Returns true on success, false on failure.

=head2 called_from_line

Checks whether the current sub was called on the given line.

 $caller->called_from_line(42);

Returns true on success, false on failure.

=head2 called_from_subroutine

Checks whether the current sub was called by the given subroutine.

 $caller->called_from_subroutine('Package::sub');

Returns true on success, false on failure.

=head1 ACCESSORS

 $caller->{package}->();
 $caller->{filename}->();
 $caller->{line}->();
 $caller->{subroutine}->();
 $caller->{hasargs}->();
 $caller->{wantarray}->();
 $caller->{evaltext}->();
 $caller->{is_require}->();
 $caller->{hints}->();
 $caller->{bitmask}->();

See L<perlfunc/caller> for the values they are supposed to return.

=head1 SEE ALSO

L<perlfunc/caller>, L<Perl6::Caller>, L<Devel::Caller>, L<Sub::Caller>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
