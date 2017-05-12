package Reply::Plugin::Autocomplete::Methods;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::Autocomplete::Methods::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: tab completion for methods

use base 'Reply::Plugin';

use Scalar::Util 'blessed';

use Reply::Util qw($ident_rx $fq_ident_rx $fq_varname_rx methods);


sub tab_handler {
    my $self = shift;
    my ($line) = @_;

    my ($invocant, $method_prefix) = $line =~ /($fq_varname_rx|$fq_ident_rx)->($ident_rx)?$/;
    return unless $invocant;
    # XXX unicode
    return unless $invocant =~ /^[\$A-Z_a-z]/;

    $method_prefix = '' unless defined $method_prefix;

    my $class;
    if ($invocant =~ /^\$/) {
        # XXX should support globals here
        my $env = {
            map { %$_ } $self->publish('lexical_environment'),
        };
        my $var = $env->{$invocant};
        return unless $var && ref($var) eq 'REF' && blessed($$var);
        $class = blessed($$var);
    }
    else {
        $class = $invocant;
    }

    my @results;
    for my $method (methods($class)) {
        push @results, $method if index($method, $method_prefix) == 0;
    }

    return sort @results;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::Autocomplete::Methods - tab completion for methods

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [ReadLine]
  [Autocomplete::Methods]

=head1 DESCRIPTION

This plugin registers a tab key handler to autocomplete method names in Perl
code.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
