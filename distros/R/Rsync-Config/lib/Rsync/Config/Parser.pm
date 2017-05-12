package Rsync::Config::Parser;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION='0.1';

use Rsync::Config::Atom;
use Rsync::Config;

use Scalar::Util qw(blessed);
use CLASS;

use base qw(Rsync::Config);

use Exception::Class(
  'Rsync::Config::Parser::File' => {
    description => 'File error: something went wrong while working with file',
    alias       => 'throw_file',
  },
  'Rsync::Config::Parser::InvalidTrailSpaces' => {
    description => 'Invalid value for eat_trail_spaces parameter',
    alias       => 'throw_invalid_eat_trail_spaces',
  },
);
Rsync::Config::Parser::File->Trace(1);
Rsync::Config::Parser::InvalidTrailSpaces->Trace(1);

sub new {
  my ($class, %opt) = @_;
  my $self;

  $self = $class->SUPER::new($class->_default_options, %opt);

  return $self;
}

sub eat_trail_spaces {
  my $self = shift;

  return $self->_default_options('eat_trail_spaces') if !ref $self;
  if (@_) {
    $self->{eat_trail_spaces} = $self->_valid_eat_trail_spaces(@_);
    return $self;
  }

  return $self->{eat_trail_spaces};
}

sub parse {
  my ($self, $filename) = @_;
  my ($fh, $conf, $module);
  my %opt = (
    map { %{$_} } grep { ref $_ eq 'HASH' } @_,
  );

  for my $opt_name (qw(eat_trail_spaces)) {
    if (! exists $opt{$opt_name}) {
      $opt{$opt_name} = $self->$opt_name;
    }
  }

  $conf = new Rsync::Config();
  $module = $conf;

  open $fh, '<', $filename or throw_file("Could not open $filename");

  while( my $line = <$fh> ) {
    chomp $line;

    if ( $line =~ m{^ \s* $}xm ) {
      $module->add_blank();
      next;
    }

    if ( $line =~ m{^ \s* (\#.*) $}xm ) {
      $module->add_comment($1);
      next;
    }
    
    #we have found a new module
    if ( $line =~ m{^ \s* \[ ([\w \_ \- \.]+) \] \s* $}xm ) {
      $module = new Rsync::Config::Module(name => $1);
      $conf->add_module_obj($module);
      next;
    }

    if ( $line =~ m{^(\s*) (\w+)(\s*)(\w*) \s* = \s* (.*) \s*$}xm ) {
      my ($atom_indent, $atom_name, $atom_value) = ($1, $2 . ($4 ? $3 . $4 : q{}), $5);

      if ($opt{'eat_trail_spaces'}) {
        $atom_name  =~ s{\s+$}{}xm;
        $atom_value =~ s{\s+$}{}xm;
      }

      $module->add_atom_obj(
        new Rsync::Config::Atom(
          name        => $atom_name,
          value       => $atom_value,
          indent      => 1,
          indent_char => $atom_indent,
        ));
      next;
    }
    print 'Garbage found:',$line,$/;
  }
  
  close $fh;
  return $conf;
}

sub _valid_eat_trail_spaces {
  my ($class, $eat_trail_spaces) = @_;

  if (!defined $eat_trail_spaces || $eat_trail_spaces !~ m{^ \d+ $}xm) {
    throw_invalid_eat_trail_spaces;
  }

  return $eat_trail_spaces;
}

sub _default_options {
  my $class = shift;
  my %defaults = (
    eat_trail_spaces     => 0,
    ignore_source_indent => 1,
    indent_atoms         => 0,
  );

  return @_ ? $defaults{ shift() } : %defaults;
}

1;

__END__

=head1 NAME

Rsync::Config::Parser

=head1 VERSION

0.1

=head1 DESCRIPTION

B<Rsync::Config::Parser> is used to parse a existing rsync configuration file.

=head1 SYNOPSIS

 use Rsync::Config::Parser;
 use Rsync::Config;

 sub main {
   my $parser = new Rsync::Config::Parser();
   
   my $conf = $parser->parse('/etc/rsyncd.conf');
 }

=head1 SUBROUTINES/METHODS

=head2 new()

Class constructor. Accepts a hash with the following options:

=over 1

=item eat_trail_spaces (def. 0)

Removes the trail spaces from all lines.

=back

=head2 parse($filename, $opt)

Calls the parser. You can override the defaults options by giving a hash ref ($opt).
Returns a B<Rsync::Config> object.

=head2 eat_trail_spaces

    my $eat_trails = $parser->eat_trail_spaces;
    $parser->eat_trail_spaces(1);

Both accessor and mutator, I<eat_trail_spaces> can be used to get the current
value or to change it.

If no arguments are provided, it will return the current eat_trail_spaces value.

If arguments are provided, first is considered to be the new eat_trail_spaces value
and applied to the current object, all others being ignored.

As mutator, the current object will be returned (useful for method chaining).

If invalid value is passed , a fatal error
is threw. Valid values are non-negative integers (0 included).

It can also be called as a class method, returning the default eat_trail_spaces
value. In this case, no mutator mode is possible.


=head1 DEPENDENCIES

Rsync::Config::Atom depends on the following modules:

=over 3

=item English

=item Scalar::Util

=item CLASS

=back

=head1 DEPENDENCIES

L<Exception::Class>, L<CLASS>.

=head1 DIAGNOSTICS

=over 2

=item C<< Rsync::Config::Parser::File >>

Occurs when the file could not be opened. 

=item C<< Rsync::Config::Parser::InvalidTrailSpaces >>

Occurs when eat_trail_spaces is called with invalid parameter

=back

=head1 CONFIGURATION AND ENVIRONMENT

This module does not use any configuration files or environment variables.

=head1 INCOMPATIBILITIES

None known to the author.

=head1 BUGS AND LIMITATIONS

No bugs known to the author.

=head1 SEE ALSO

L<Rsync::Config>.

=head1 AUTHOR

Manuel SUBREDU C<< <diablo@packages.ro> >>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006, Manuel SUBREDU C<< <diablo@packages.ro> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
