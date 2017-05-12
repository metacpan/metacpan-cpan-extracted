package Reply::Plugin::Colors;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::Colors::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: colorize output

use base 'Reply::Plugin';

use Term::ANSIColor;
BEGIN {
    if ($^O eq 'MSWin32') {
        require Win32::Console::ANSI;
        Win32::Console::ANSI->import;
    }
}


sub new {
    my $class = shift;
    my %opts = @_;

    my $self = $class->SUPER::new(@_);
    $self->{error} = $opts{error} || 'red';
    $self->{warning} = $opts{warning} || 'yellow';
    $self->{result} = $opts{result} || 'green';

    return $self;
}

sub compile {
    my $self = shift;
    my ($next, @args) = @_;

    local $SIG{__WARN__} = sub { $self->print_warn(@_) };
    $next->(@args);
}

sub execute {
    my $self = shift;
    my ($next, @args) = @_;

    local $SIG{__WARN__} = sub { $self->print_warn(@_) };
    $next->(@args);
}

sub print_error {
    my $self = shift;
    my ($next, $error) = @_;

    print color($self->{error});
    $next->($error);
    local $| = 1;
    print color('reset');
}

sub print_result {
    my $self = shift;
    my ($next, @result) = @_;

    print color($self->{result});
    $next->(@result);
    local $| = 1;
    print color('reset');
}

sub print_warn {
    my $self = shift;
    my ($warning) = @_;

    print color($self->{warning});
    print $warning;
    local $| = 1;
    print color('reset');
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::Colors - colorize output

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [Colors]
  error   = bright red
  warning = bright yellow
  result  = bright green

=head1 DESCRIPTION

This plugin adds coloring to the results when they are printed to the screen.
By default, errors are C<red>, warnings are C<yellow>, and normal results are
C<green>, although this can be overridden through configuration as shown in the
synopsis. L<Term::ANSIColor> is used to generate the colors, so any value that
is accepted by that module is a valid value for the C<error>, C<warning>, and
C<result> options.

=for Pod::Coverage print_warn

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
