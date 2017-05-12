#
# This file is part of Regexp-SQL-LIKE
#
# This software is Copyright (c) 2011 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
use 5.010;
use strict;
use warnings;

package Regexp::SQL::LIKE;
BEGIN {
  $Regexp::SQL::LIKE::VERSION = '0.001';
}
# ABSTRACT: Translate SQL LIKE pattern to a regular expression

# Dependencies
use autodie 2.00;
use Sub::Exporter
  -setup => { exports => [ qw/to_regexp/ ] };


sub to_regexp {
  my ($like) = @_;
  my $re = '';

  my %anchors = (
    start => substr($like, 0,1) ne '%',
    end   => substr($like,-1,1) ne '%',
  );

  # split out tokens with backslashes before wildcards so
  # we can figure out what is actually being escaped
  my @parts = split qr{(\\*[.%])}, $like;

  for my $p ( @parts ) {
    next unless length $p;
    my $backslash_count =()= $p =~ m{(\\)}g; 
    my $wild_count =()= $p =~ m{([%.])}g; 
    if ($wild_count) {
      if ( $backslash_count && $backslash_count % 2 ) {
        # odd slash count, so wild card is escaped 
        my $last = substr( $p, -2, 2, '');
        $p =~ s{\\\\}{\\};
        $re .= quotemeta( $p . substr($last, -1, 1) );
      }
      elsif ( $backslash_count ) {
        # even slash count, they only escape themselves
        my $last = substr( $p, -1, 1, '');
        $p =~ s{\\\\}{\\};
        $re .= quotemeta( $p ) . ( $last eq '%' ? '.*' : '.' );
      }
      else { # just a wildcard, no escaping
        $re .= $p eq '%' ? '.*' : '.';
      }
    }
    else {
      # no wildcards so apply any escapes freely
      $p =~ s{\\(.)}{$1}g;
      $re .= quotemeta( $p );
    }
  }

  substr( $re, 0, 0, '^' ) if $anchors{start};
  $re .= '$' if $anchors{end};

  return qr/$re/;
}

1;



=pod

=head1 NAME

Regexp::SQL::LIKE - Translate SQL LIKE pattern to a regular expression

=head1 VERSION

version 0.001

=head1 SYNOPSIS

   use Regexp::SQL::LIKE 'to_regexp';
 
   my $re = to_regexp( "Hello %" ); # returns qr/^Hello .*/

=head1 DESCRIPTION

This module converts an SQL LIKE pattern to its Perl regular expression
equivalent.

Currently, only C<<< % >>> and C<<< . >>> wildcards are supported and only C<<< \  >>> is
supported as an escape character.

No functions are exported by default.  You may rename a function on import as
follows:

   use Regexp::SQL::Like to_regexp => { -as => 'regexp_from_like' };

See L<Sub::Exporter> for more details on import customization.

=head1 FUNCTIONS

=head2 to_regexp

  my $re = to_regexp( "Hello %" );

This function converts an SQL LIKE pattern into an equivalent regular
expression.  A C<%> character matches any number of characters like C<.*> and a
C<.> character matchs a single character.  Backspaces may be used to escape
C<%>, C<.> and C<\> itself:

  to_regexp( "Match literal \%" );

All other characters are run through C<quotemeta()> to sanitize them.

The function returns a compiled regular expression.

=for Pod::Coverage method_names_here

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-regexp-sql-like at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-SQL-LIKE>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<http://github.com/dagolden/regexp-sql-like>

  git clone http://github.com/dagolden/regexp-sql-like

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut


__END__


