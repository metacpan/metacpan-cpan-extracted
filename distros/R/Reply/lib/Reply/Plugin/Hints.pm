package Reply::Plugin::Hints;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::Hints::VERSION = '0.42';
my $default_hints;
my $default_hinthash;
my $default_warning_bits;
BEGIN {
    $default_hints = $^H;
    $default_hinthash = \%^H;
    $default_warning_bits = ${^WARNING_BITS};
}

use strict;
use warnings;
# ABSTRACT: persists lexical hints across input lines

use base 'Reply::Plugin';


sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);
    $self->{hints} = $default_hints;
    $self->{hinthash} = $default_hinthash;
    $self->{warning_bits} = $default_warning_bits;

    return $self;
}

sub mangle_line {
    my $self = shift;
    my ($line) = @_;

    my $package = __PACKAGE__;
    return <<LINE;
BEGIN {
    \$^H = \$${package}::hints;
    \%^H = \%\$${package}::hinthash;
    \${^WARNING_BITS} = \$${package}::warning_bits;
}
$line
;
BEGIN {
    \$${package}::hints = \$^H;
    \$${package}::hinthash = \\\%^H;
    \$${package}::warning_bits = \${^WARNING_BITS};
}
LINE
}

sub compile {
    my $self = shift;
    my ($next, $line, %args) = @_;

    # XXX it'd be nice to avoid using globals here, but we can't use
    # eval_closure's environment parameter since we need to access the
    # information in a BEGIN block
    our $hints = $self->{hints};
    our $hinthash = $self->{hinthash};
    our $warning_bits = $self->{warning_bits};

    my @result = $next->($line, %args);

    $self->{hints} = $hints;
    $self->{hinthash} = $hinthash;
    $self->{warning_bits} = $warning_bits;

    return @result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::Hints - persists lexical hints across input lines

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [Hints]

=head1 DESCRIPTION

This plugin persists the values of various compile time lexical hints between
evaluated lines. This means, for instance, that entering a line like C<use
strict> at the Reply prompt will cause C<strict> to be enabled for all future
lines (at least until C<no strict> is given).

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
