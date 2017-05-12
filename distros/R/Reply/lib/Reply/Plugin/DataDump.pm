package Reply::Plugin::DataDump;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::DataDump::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: format results using Data::Dump

use base 'Reply::Plugin';

use Data::Dump 'dumpf';
use overload ();


sub new {
    my $class = shift;
    my %opts = @_;
    $opts{respect_stringification} = 1
        unless defined $opts{respect_stringification};

    my $self = $class->SUPER::new(@_);
    $self->{filter} = sub {
        my ($ctx, $ref) = @_;
        return unless $ctx->is_blessed;
        my $stringify = overload::Method($ref, '""');
        return unless $stringify;
        return {
            dump => $stringify->($ref),
        };
    } if $opts{respect_stringification};

    return $self;
}

sub mangle_result {
    my $self = shift;
    my (@result) = @_;
    return @result ? dumpf(@result, $self->{filter}) : ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::DataDump - format results using Data::Dump

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [DataDump]
  respect_stringification = 1

=head1 DESCRIPTION

This plugin uses L<Data::Dump> to format results. By default, if it reaches an
object which has a stringification overload, it will dump that directly. To
disable this behavior, set the C<respect_stringification> option to a false
value.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
