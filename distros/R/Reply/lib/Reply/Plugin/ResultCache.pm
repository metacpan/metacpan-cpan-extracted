package Reply::Plugin::ResultCache;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::ResultCache::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: retain previous results to be able to refer to them later

use base 'Reply::Plugin';


sub new {
    my $class = shift;
    my %opts = @_;

    my $self = $class->SUPER::new(@_);
    $self->{results} = [];
    $self->{result_name} = $opts{variable} || 'res';

    return $self;
}

sub execute {
    my $self = shift;
    my ($next, @args) = @_;

    my @res = $next->(@args);
    if (@res == 1) {
        push @{ $self->{results} }, $res[0];
    }
    elsif (@res > 1) {
        push @{ $self->{results} }, \@res;
    }

    return @res;
}

sub mangle_result {
    my $self = shift;
    my ($result) = @_;

    return unless defined $result;
    return '$' . $self->{result_name} . '[' . $#{ $self->{results} } . '] = '
         . $result;
}

sub lexical_environment {
    my $self = shift;
    return { "\@$self->{result_name}" => [ @{ $self->{results} } ] };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::ResultCache - retain previous results to be able to refer to them later

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [ResultCache]
  variable = r

=head1 DESCRIPTION

This plugin caches the results of successful evaluations, and provides them in
a lexical array (by default C<@res>, although this can be changed via the
C<variable> option). This means that you can, for instance, access the value
returned by the previous line with C<$res[-1]>. It also modifies the output to
include an indication of where the value is stored, for later reference.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
