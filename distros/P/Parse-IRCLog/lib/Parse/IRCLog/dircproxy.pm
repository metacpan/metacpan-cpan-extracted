use strict;
use warnings;
package Parse::IRCLog::dircproxy;
# ABSTRACT: parse dircproxy logs
$Parse::IRCLog::dircproxy::VERSION = '1.106';
use parent 'Parse::IRCLog';

sub patterns {
  my ($self) = @_;

  return $self->{patterns} if ref $self and defined $self->{patterns};

  my $p = {
    msg    => qr/^@([0-9]+)\s+<([+%@])?([^!]+)![^>]+>(\s)(.+)/,
    action => qr/^@([0-9]+)\s+\[([+%@])?([^!]+)![^\]]+\]\sACTION\s(.+)/,
  };

  $self->{patterns} = $p if ref $self;

  return $p;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::IRCLog::dircproxy - parse dircproxy logs

=head1 VERSION

version 1.106

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
