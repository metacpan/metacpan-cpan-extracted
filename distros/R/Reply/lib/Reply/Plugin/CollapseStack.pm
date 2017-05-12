package Reply::Plugin::CollapseStack;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::CollapseStack::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: display error stack traces only on demand

use base 'Reply::Plugin';

{
    local @SIG{qw(__DIE__ __WARN__)};
    require Carp::Always;
}


sub new {
    my $class = shift;
    my %opts = @_;

    my $self = $class->SUPER::new(@_);
    $self->{num_lines} = $opts{num_lines} || 1;

    return $self;
}

sub compile {
    my $self = shift;
    my ($next, @args) = @_;

    local $SIG{__DIE__} = \&Carp::Always::_die;
    $next->(@args);
}

sub execute {
    my $self = shift;
    my ($next, @args) = @_;

    local $SIG{__DIE__} = \&Carp::Always::_die;
    $next->(@args);
}

sub mangle_error {
    my $self = shift;
    my $error = shift;

    $self->{full_error} = $error;

    my @lines = split /\n/, $error;
    if (@lines > $self->{num_lines}) {
        splice @lines, $self->{num_lines};
        $error = join "\n", @lines, "    (Run #stack to see the full trace)\n";
    }

    return $error;
}

sub command_stack {
    my $self = shift;

    # XXX should use print_error here
    print($self->{full_error} || "No stack to display.\n");

    return '';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::CollapseStack - display error stack traces only on demand

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [CollapseStack]
  num_lines = 1

=head1 DESCRIPTION

This plugin hides stack traces until you specifically request them
with the C<#stack> command.

The number of lines of stack to always show is configurable; specify
the C<num_lines> option.

=for Pod::Coverage command_stack

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
