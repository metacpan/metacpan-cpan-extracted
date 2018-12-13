package IV_ANY;
sub new { my $class = shift; bless {@_}, $class }
sub optional { shift->{optional} }
sub nillable { shift->{nillable} }
sub empty    { shift->{empty} }
sub error { my $self = shift; $self->{error} = shift if @_; $self->{error} }
sub pattern {
    my $self         = shift;
    $self->{pattern} = shift if @_;
    $self->{pattern}
}
sub accepts {
    my ($self, $value, $path) = @_;
    return 1 if ($self->nillable and not defined $value)
             or ($self->empty and defined $value and !ref $value and $value eq '')
             or (defined $value && !$self->pattern)
             or ($self->pattern && $value =~ $self->pattern);

    $self->error("Value '$value' does not match at path " . ($path || '/'));
    return 0;
}

package IV_WORD;
use base 'IV_ANY';
sub new { my $class = shift; bless {@_}, $class }
sub accepts {
    my ($self, $value, $path) = @_;
    return 1 if ($self->nillable and not defined $value)
             or ($self->empty and defined $value and !ref $value and $value eq '')
             or ($value =~ /^\w+$/);

    $self->error("Value '$value' does not match word characters only at path " . ($path || '/'));
    return 0;
}

package IV_FLOAT;
use base 'IV_ANY';
sub new { my $class = shift; bless {@_}, $class }
sub accepts {
    my ($self, $value, $path) = @_;
    return 1 if ($self->nillable and not defined $value)
             or ($self->empty and defined $value and !ref $value and $value eq '')
             or ($value =~ /^-?\d+\.\d+$/);

    $self->error("Value '$value' is not a float at path " . ($path || '/'));
    return 0;
}

package IV_INT;
use base 'IV_ANY';
sub new { my $class = shift; bless {@_}, $class }
sub accepts {
    my ($self, $value, $path) = @_;
    return 1 if ($self->nillable and not defined $value)
             or ($self->empty and defined $value and !ref $value and $value eq '')
             or ($value =~ /^-?\d+$/);

    $self->error("Value '$value' is not an integer at path " . ($path || '/'));
    return 0;
}

package IV_ARRAY;
use base 'IV_ANY';
sub new {
    my $class     = shift;
    my $options   = {};

    while (@_) {
        my $elem = shift;
        if (ref $elem eq 'ARRAY') {
            $options->{pattern} = $elem;
        }
        else {
            $options->{$elem} = shift;
        }
    }

    bless $options, $class
}
sub accepts {
    my ($self, $value, $path) = @_;

    return 1 if $self->nillable and not defined $value;

    unless (ref $value eq 'ARRAY') {
        $self->error("Array expected at path " . ($path || '/'));
        return 0;
    }

    my $elems = scalar @$value;

    if (defined $self->{max} && $elems > $self->{max}) {
        $self->error(sprintf("Too many elements in array (%d vs %d) at path %s",
            $elems, $self->{max}, $path || '/'));
        return 0;
    }

    if (defined $self->{min} && $elems < $self->{min}) {
        $self->error(sprintf("Too few elements in array (%d vs %d) at path %s",
            $elems, $self->{min}, $path || '/'));
        return 0;
    }

    if ($self->{of}) {
        for (my $i = 0; $i < ($self->{max} // $elems); $i++) {
            my $err = Mojolicious::Plugin::InputValidation::_validate_structure($value->[$i], $self->{of}, "$path/$i");

            if ($err) {
                $self->error($err);
                return 0;
            }
        }
    }
    elsif ($self->{pattern} && !$self->{min} && !$self->{min}) {
        for (my $i = 0; $i < scalar @{$self->{pattern}}; $i++) {
            my $err = Mojolicious::Plugin::InputValidation::_validate_structure($value->[$i], $self->{pattern}[$i], "$path/$i");

            if ($err) {
                $self->error($err);
                return 0;
            }
        }
    }
    else {
        $self->error('Error: illegal pattern for array at path ' . ($path // '/'));
        return 0;
    }

    return 1;
}

package IV_OBJECT;
use base 'IV_ANY';
sub new {
    my $class     = shift;
    my $options   = {};

    while (@_) {
        my $elem = shift;
        if (ref $elem eq 'HASH') {
            $options->{pattern} = $elem;
        }
        else {
            $options->{$elem} = shift;
        }
    }

    bless $options, $class
}
sub accepts {
    my ($self, $value, $path) = @_;

    return 1 if $self->nillable and not defined $value;

    unless (ref $value eq 'HASH') {
        $self->error("Object expected at path " . ($path || '/'));
        return 0;
    }

    my @have_keys  = sort keys %$value;
    my @want_keys  = sort keys %{$self->{pattern}};
    my %want_keys  = map { $_ => 1 } @want_keys;
    my %have_keys  = map { $_ => 1 } @have_keys;
    my @unexpected = grep { !$want_keys{$_} } @have_keys;
    my @missing    = grep { !$have_keys{$_} && !$self->{pattern}{$_}->optional } @want_keys;

    if (@unexpected) {
        $self->error(sprintf("Unexpected keys '%s' found at path %s", join(',', @unexpected), $path || '/'));
        return 0;
    }

    if (@missing) {
        $self->error(sprintf("Missing keys '%s' at path %s", join(',', @missing), $path || '/'));
        return 0;
    }

    for my $key (grep { $have_keys{$_} } @want_keys) {
        my $err = Mojolicious::Plugin::InputValidation::_validate_structure($value->{$key}, $self->{pattern}{$key}, "$path/$key");

        if ($err) {
            $self->error($err);
            return 0;
        }
    }

    return 1;
}

package IV_DATETIME;
use base 'IV_ANY';
sub new { my $class = shift; bless {@_}, $class }
sub pattern {
    my $self         = shift;
    $self->{pattern} = shift if @_;
    $self->{pattern} || qr/^20\d\d-\d\d-\d\dT\d\d:\d\d:\d\d(Z|[+-]\d\d\d\d)$/
}
sub accepts {
    my ($self, $value, $path) = @_;
    return 1 if ($self->nillable and not defined $value)
             or ($self->empty and defined $value and !ref $value and $value eq '')
             or ($value =~ $self->pattern);

    $self->error("Value '$value' does not match datetime format at path " . ($path || '/'));
    return 0;
}

package Mojolicious::Plugin::InputValidation;
use Mojo::Base 'Mojolicious::Plugin';
no strict 'subs';

our $VERSION = '0.07';

use Mojo::Util 'monkey_patch';

sub iv_datetime { IV_DATETIME->new(@_) }
sub iv_object   { IV_OBJECT->new(@_) }
sub iv_array    { IV_ARRAY->new(@_) }
sub iv_int      { IV_INT->new(@_) }
sub iv_float    { IV_FLOAT->new(@_) }
sub iv_word     { IV_WORD->new(@_) }
sub iv_any      { IV_ANY->new(@_) }

sub import {
    my $caller = caller;
    monkey_patch $caller, 'iv_datetime', \&iv_datetime;
    monkey_patch $caller, 'iv_object',   \&iv_object;
    monkey_patch $caller, 'iv_array',    \&iv_array;
    monkey_patch $caller, 'iv_int',      \&iv_int;
    monkey_patch $caller, 'iv_float',    \&iv_float;
    monkey_patch $caller, 'iv_word',     \&iv_word;
    monkey_patch $caller, 'iv_any',      \&iv_any;
}

sub register {
    my ($self, $app, $conf) = @_;

    $app->helper(validate_json_request => sub {
        my ($c, $pattern) = @_;
        return _validate_structure($c->req->json, $pattern);
    });
    $app->helper(validate_params => sub {
        my ($c, $pattern) = @_;
        return _validate_structure($c->params, $pattern);
    });
    $app->helper(validate_structure => sub {
        my ($c, $structure, $pattern) = @_;
        return _validate_structure($structure, $pattern);
    });
}

sub _validate_structure {
    my ($input, $pattern, $path) = @_;

    if (ref $pattern eq 'HASH') {
        $pattern = iv_object($pattern);
    }
    elsif (ref $pattern eq 'ARRAY') {
        $pattern = iv_array($pattern);
    }

    return sprintf("Error: pattern '%s' must be of kind iv_*", $pattern)
        unless UNIVERSAL::isa($pattern, IV_ANY);

    return $pattern->error unless $pattern->accepts($input, $path // '');

    return '';
}

=encoding utf8

=head1 NAME

Mojolicious::Plugin::InputValidation - Validate incoming requests

=head1 SYNOPSIS

  use Mojolicious::Lite;
  plugin 'InputValidation';

  # This needs to be done where one wants to use the iv_* routines.
  use Mojolicious::Plugin::InputValidation;

  post '/books' => sub {
      my $c = shift;

      # Validate incoming requests against our data model.
      if (my $error = $c->validate_json_request({
          title    => iv_any,
          abstract => iv_any(optional => 1, empty => 1),
          author   => {
              firstname => iv_word,
              lastname  => iv_word,
          },
          published => iv_datetime,
          price     => iv_float,
          revision  => iv_int,
          isbn      => iv_any(pattern => qr/^[0-9\-]{10,13}$/),
      })) {
          return $c->render(status => 400, text => $error);
      }

      # Now the payload is safe to use.
      my $payload = $c->req->json;
      ...
  };

=head1 DESCRIPTION

L<Mojolicious::Plugin::InputValidation> compares structures against a pattern.
The pattern is usually a nested structure, so the compare methods search
recursively for the first non-matching value. If such a value is found a
speaking error message is returned, otherwise a false value.

=head1 METHODS

L<Mojolicious::Plugin::InputValidation> adds methods to the connection object
in a mojolicous controller. This way input validation becomes easy.

=head2 validate_json_request

  my $error = $c->validate_json_request($pattern);

This method try to match the json request payload ($c->req->json) against the
given pattern. If the payload matches, a false value is returned. If the payload
on the other hand does not match the pattern, the first non-matching value is
returned along with a speaking error message. The error message could look like:

  "Unexpected keys 'id,name' found at path /author"

=head1 TYPES

The pattern consists of one or more types the input is matched against.
The following types are available.

=over 4

=item iv_any

This is the base type for all other types. By default it matches defined values
only. It supports beeing optional, means that it is okay if this element is
missing entirely in the payload.
When this type is marked as nillable, it also accepts a null/undef value.
To accept an empty string, mark it as empty.
This type supports a regex pattern to match against. All options can be combined.

  {
      foo  => iv_any,
      bar  => iv_any(optional => 1, empty => 1),
      baz  => iv_any(nillable => 1),
      quux => iv_any(pattern => qr/^new|mint|used$/),
  }

=item iv_int

This type matches integers, literally digits with an optional leading dash.

  {
      foo => iv_int,
      bar => iv_int(optional => 1),
      baz => iv_int(nillable => 1),
  }

=item iv_float

This type matches floats, so digits divided by a single dot, with an optional
leading dash.

  {
      foo => iv_float,
      bar => iv_float(optional => 1),
      baz => iv_float(nillable => 1),
  }

=item iv_word

This type is meant to match identifiers. It matches word character strings (\w+).
Using the iv_any type one can achieve the same with: iv_any(pattern => qr/^\w+$/)
To accept an empty string, mark it as empty.

  {
      foo => iv_word,
      bar => iv_word(optional => 1, empty => 1),
      baz => iv_word(nillable => 1),
  }

=item iv_datetime

This type matches datetime strings in the following format:

  YYYY-mm-DDTHH:mm:ssZ
  YYYY-mm-DDTHH:mm:ss-0100
  YYYY-mm-DDTHH:mm:ss+0000
  YYYY-mm-DDTHH:mm:ss+0100

It also supports a regex pattern, but that kinda defeats the purpose of this type.

  {
      foo  => iv_datetime,
      bar  => iv_datetime(optional => 1),
      baz  => iv_datetime(nillable => 1),
      quux => iv_datetime(pattern => qr/^\d\d\d\d-\d\d-\d\d$/,
  }

=item iv_object

This types matches objects (hashes). It will recurse into the elements it contains.
A hash as a pattern is automatically turned into a iv_object. Using a hash is the
idiomatic way, unless you need to mark it as optional or nillable.

  {
      foo => { ... },
      bar => iv_object(optional => 1, { ... }),
      baz => iv_object(nillable => 1, { ... }),
  }

=item iv_array - will match arrays

This type will match arrays in two different ways. For one it can match a payload
against a fixed shape, and second it can match against an elemnt base type.
A literal array reference ([]) is turned into an iv_array of the first kind
automatically. The following is valid:

  {
      foo  => [iv_int, iv_word, ...],
      bar  => iv_array(optional => 1, [iv_int, iv_word, ...]),
      baz  => iv_array(nillable => 1, [iv_int, iv_word, ...]),
      quux => iv_array(of => iv_int, min => 1, max => 7),
  }

=back

=head1 ALERT

This plugin is in alpha state, means it might not work at all or not as advertised.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Tobias Leich.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
