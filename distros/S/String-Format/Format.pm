package String::Format;

# ----------------------------------------------------------------------
#  Copyright (C) 2002,2009 darren chamberlain <darren@cpan.org>
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License as
#  published by the Free Software Foundation; version 2.
#
#  This program is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
#  02110-1301 USA.
# -------------------------------------------------------------------

use strict;
use vars qw($VERSION @EXPORT);
use Exporter;
use base qw(Exporter);

$VERSION = '1.17';
@EXPORT = qw(stringf);

sub _replace {
    my ($args, $orig, $alignment, $min_width,
        $max_width, $passme, $formchar) = @_;

    # For unknown escapes, return the orignial
    return $orig unless defined $args->{$formchar};

    $alignment = '+' unless defined $alignment;

    my $replacement = $args->{$formchar};
    if (ref $replacement eq 'CODE') {
        # $passme gets passed to subrefs.
        $passme ||= "";
        $passme =~ tr/{}//d;
        $replacement = $replacement->($passme);
    }

    my $replength = length $replacement;
    $min_width  ||= $replength;
    $max_width  ||= $replength;

    # length of replacement is between min and max
    if (($replength > $min_width) && ($replength < $max_width)) {
        return $replacement;
    }

    # length of replacement is longer than max; truncate
    if ($replength > $max_width) {
        return substr($replacement, 0, $max_width);
    }
    
    # length of replacement is less than min: pad
    if ($alignment eq '-') {
        # left align; pad in front
        return $replacement . " " x ($min_width - $replength);
    }

    # right align, pad at end
    return " " x ($min_width - $replength) . $replacement;
}

my $regex = qr/
               (%             # leading '%'
                (-)?          # left-align, rather than right
                (\d*)?        # (optional) minimum field width
                (?:\.(\d*))?  # (optional) maximum field width
                ({.*?})?      # (optional) stuff inside
                (\S)          # actual format character
             )/x;
sub stringf {
    my $format = shift || return;
    my $args = UNIVERSAL::isa($_[0], 'HASH') ? shift : { @_ };
       $args->{'n'} = "\n" unless exists $args->{'n'};
       $args->{'t'} = "\t" unless exists $args->{'t'};
       $args->{'%'} = "%"  unless exists $args->{'%'};

    $format =~ s/$regex/_replace($args, $1, $2, $3, $4, $5, $6)/ge;

    return $format;
}

sub stringfactory {
    shift;  # It's a class method, but we don't actually want the class
    my $args = UNIVERSAL::isa($_[0], "HASH") ? shift : { @_ };
    return sub { stringf($_[0], $args) };
}

1;
__END__

=head1 NAME

String::Format - sprintf-like string formatting capabilities with
arbitrary format definitions

=head1 ABSTRACT

String::Format allows for sprintf-style formatting capabilities with
arbitrary format definitions

=head1 SYNOPSIS

  use String::Format;

  my %fruit = (
        'a' => "apples",
        'b' => "bannanas",
        'g' => "grapefruits",
        'm' => "melons",
        'w' => "watermelons",
  );

  my $format = "I like %a, %b, and %g, but not %m or %w.";

  print stringf($format, %fruit);
  
  # prints:
  # I like apples, bannanas, and grapefruits, but not melons or watermelons.

=head1 DESCRIPTION

String::Format lets you define arbitrary printf-like format sequences
to be expanded.  This module would be most useful in configuration
files and reporting tools, where the results of a query need to be
formatted in a particular way.  It was inspired by mutt's index_format
and related directives (see <URL:http://www.mutt.org/doc/manual/manual-6.html#index_format>).

=head1 FUNCTIONS

=head2 stringf

String::Format exports a single function called stringf.  stringf
takes two arguments:  a format string (see FORMAT STRINGS, below) and
a reference to a hash of name => value pairs.  These name => value
pairs are what will be expanded in the format string.

=head1 FORMAT STRINGS

Format strings must match the following regular expression:

  qr/
     (%             # leading '%'
      (-)?          # left-align, rather than right
      (\d*)?        # (optional) minimum field width
      (?:\.(\d*))?  # (optional) maximum field width
      ({.*?})?      # (optional) stuff inside
      (\S)          # actual format character
     )/x;

If the escape character specified does not exist in %args, then the
original string is used.  The alignment, minimum width, and maximum
width options function identically to how they are defined in
sprintf(3) (any variation is a bug, and should be reported).

Note that Perl's sprintf definition is a little more liberal than the
above regex; the deviations were intentional, and all deal with
numeric formatting (the #, 0, and + leaders were specifically left
out).

The value attached to the key can be a scalar value or a subroutine
reference; if it is a subroutine reference, then anything between the
'{' and '}' ($5 in the above regex) will be passed as $_[0] to the
subroutine reference.  This allows for entries such as this:

  %args = (
      d => sub { POSIX::strftime($_[0], localtime) }, 
  );

Which can be invoked with this format string:

  "It is %{%M:%S}d right now, on %{%A, %B %e}d."

And result in (for example):

  It is 17:45 right now, on Monday, February 4.

Note that since the string is passed unmolested to the subroutine
reference, and strftime would Do The Right Thing with this data, the
above format string could be written as:

  "It is %{%M:%S right now, on %A, %B %e}d."

By default, the formats 'n', 't', and '%' are defined to be a newline,
tab, and '%', respectively, if they are not already defined in the
hashref of arguments that gets passed it.  So we can add carriage
returns simply:

  "It is %{%M:%S right now, on %A, %B %e}d.%n"

Because of how the string is parsed, the normal "\n" and "\t" are
turned into two characters each, and are not treated as a newline and
tab.  This is a bug.

=head1 FACTORY METHOD

String::Format also supports a class method, named B<stringfactory>,
which will return reference to a "primed" subroutine.  stringfatory
should be passed a reference to a hash of value; the returned
subroutine will use these values as the %args hash.

  my $self = Some::Groovy::Package->new($$, $<, $^T);
  my %formats = (
        'i' => sub { $self->id      },
        'd' => sub { $self->date    },
        's' => sub { $self->subject },
        'b' => sub { $self->body    },
  );
  my $index_format = String::Format->stringfactory(\%formats);

  print $index_format->($format1);
  print $index_format->($format2);

This subroutine reference can be assigned to a local symbol table
entry, and called normally, of course:

  *reformat = String::Format->stringfactory(\%formats);

  my $reformed = reformat($format_string);

=head1 LICENSE

C<String::Format> is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; version 2.


=head1 AUTHOR

darren chamberlain <darren@cpan.org>
