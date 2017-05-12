package Template::ExpandHash;

use 5.006;
use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';

our @EXPORT_OK = qw(expand_hash);
our $VERSION = '0.01';

sub expand_hash {
  my $params;
  my $return_ref;
  if (1 == @_ and 'HASH' eq ref($_[0])) {
    $params = $_[0];
    $return_ref = 1;
  }
  elsif (0 == @_%2) {
    $params = {@_};
    $return_ref = 0;
  }
  else {
    confess("Need a hash or hash ref");
  }

  $params = {_deep_copy(%$params)};
  my $todo = _calculate_todo($params);

  while (1) {
    (my $changed, $todo, $params) = _do_substitutions([$todo, $params]);
    if (not $changed) {
      return $return_ref ? $params : %$params;
    }
  }
}

# It would be nice to Storable::dclone, but Perl 5.14 broke on qr//. :-(
sub _deep_copy {
  my %in = @_;
  for my $key (keys %in) {
    if ('HASH' eq ref($in{$key})) {
      $in{$key} = { _deep_copy(%{ $in{$key} }) };
    }
  }
  return %in;
}

# Creates a hash of the same shape to keep track of work left.
sub _calculate_todo {
  my ($params) = @_;
  return 1 unless 'HASH' eq ref($params);
  return { map {($_ => _calculate_todo($params->{$_}))} keys %$params };
}

# Private function to do one pass of variable substitution on a config.
# This substitutes things of the form [% foo %] with a variable named foo
# in this scope or any enclosing one.  (Hashes count as scopes.)  You can use
# \ for an escape mechanism (you may need to double them, sorry).
sub _do_substitutions {
  my ($current, @rest) = @_;
  my ($todo, $to_change) = @$current;
  return (0, $todo, $to_change) unless 'HASH' eq ref($todo);

  my $changes = 0;
  for my $key (keys %$todo) {
    my $value = $to_change->{$key};
    if (not $value) {
      # print "Removing $key (no value)\n";
      delete $todo->{$key};
      next;
    }
    elsif ('HASH' eq ref($value)) {
      (my $this_changes, my $left, $value) = _do_substitutions([$todo->{$key}, $value], [$todo, $to_change], @rest);
      if ($this_changes) {
        if (keys %$left) {
          $todo->{$key} = $left;
        }
        else {
          delete $todo->{$key};
        }
        $to_change->{$key} = $value;
        $changes += $this_changes;
      }
    }
    elsif (not ref($value)) {
      # It is a string, tokenize then parse and expand.
      my @tokens = ($value =~ /(\\.|\[%|%]|\w+|.)/g);
      my $final = "";
      TOKENS: while (@tokens) {
        my $token = shift @tokens;
        if ($token =~ /^\\(.)/) {
          # Found an escaped character.
          $final .= $1;
        }
        elsif ($token eq "[%") {
          # Figure out the lookup to do.
          my $variable = "";
          while (@tokens and $tokens[0] ne "%]") {
            $variable .= shift @tokens;
          }
          $variable =~ s/^\s+//;
          $variable =~ s/\s+\z//;

          my $found;
          for my $argument ([$todo, $to_change], @rest) {
            # If we find the lookup...
            if (defined $argument->[1]->{$variable}) {
              # And it is not in todo...
              if (not defined $argument->[0]->{$variable}) {
                $found = $argument->[1]->{$variable};
              }
              last;
            }
          }

          last TOKENS if not defined $found;
          $final .= $found;

          # Remove the end marker.
          shift @tokens;
        }
        else {
          $final .= $token;
        }
      }

      if (not @tokens) {
        delete $todo->{$key};
        $changes++;
        if ($final ne $value) {
          # print "Changed $value to $final\n";
          $to_change->{$key} = $final;
        }
      }
    }
    else {
      # We don't touch the internals of array refs, objects, etc.
      delete $todo->{$key};
    }
  }

  return $changes, $todo, $to_change;
}

1;

=head1 NAME

Template::ExpandHash - Do template expansion on the values of a hash.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Template::ExpandHash qw(expand_hash);
    # ... time passes
    %expanded_hash    = expand_hash(%hash);
    $expanded_hashref = expand_hash($hashref);

Pass a hash, get back a similar hash with [% key %] expanded into the value
associated with that key.  Recursive substitutions are supported, and the
substituting goes into sub-hashes.  (Sub-hashes can expand to keys from the
surrounding hash, but not vice versa.)  Template expressions can be escaped
using backslashes.

=head1 INTENDED USE CASE

When loading a configuration it often makes sense to start with a base
configuration data structure, and then load multiple layers of tweaks for
specific environments.  This can happen within pure Perl as in this example:

    $PARAM{prod} = {
        email_qa_email      => undef,
        email_pager_email   => 'pagerlist@company.com',
        some_escaped_value  => '\[% user ]%',
        # etc
        email => {
          qa_email          => '[% email_qa_email %]',
          pager_email       => '[% email_pager_email %]',
          # etc
        },
        # More data here.
    };

    $PARAM{sandbox} = {
        %{$PARAM{prod}},
        default_email       => '[% user %]@company.com',
        email_qa_email      => 'QA <[% default_email %]>',
        email_pager_email   => 'Pagers <[% default_email %]>',
        # More data here, some of which overrides prod.
    };

    $PARAM{btilly} = {
        %{$PARAM{sandbox}},
        user                => 'btilly',
        # More data here, some of which overrides the sandbox.
    };

Alternately it can happen in a series of files which you might load from
a list of external sources with code like this:

    use Config::Any;

    # ... code here.
    my $raw_config_list
        = Config::Any->load_files({files => \@config_path, use_ext => 1});
    my $config = {map %$_, map values %$_, @$raw_config_list};

Either way there is a tendency for the set of overrides at the detail level
to get very long.  However with templating we could make this much shorter.
Suppose that our final set of parameters worked out to be something like:

    $config =  {
        user                => 'btilly',
        default_email       => '[% user %]@company.com',
        email_qa_email      => 'QA <[% default_email %]>',
        email_pager_email   => 'Pagers <[% default_email %]>',
        some_escaped_value  => '\[% user ]%',
        # etc
        email => {
          qa_email          => '[% email_qa_email %]',
          pager_email       => '[% email_pager_email %]',
          # etc
        },
        # More data here.
    }

Then we can expand all of the template parameters:

    $expanded_param = expand_hash($param);

And get:

    {
        user               => 'btilly',
        default_email      => 'btilly@company.com',
        email_qa_email     => 'QA <btilly@company.com>',
        email_pager_email  => 'Pagers <btilly@company.com>',
        some_escaped_value => '[% user ]%',
        # etc
        email => {
            qa_email       => 'QA <btilly@company.com>',
            pager_email    => 'Pagers <btilly@company.com>',
            # etc
        },
        # More data here.
    }

without having to manually override a long list of values.  This makes your
configuration much simpler and cleaner than it otherwise would be.

=head1 SUBROUTINES/METHODS

=head2 expand_hash

The only externally usable function.  You pass it a hash or hash ref and it
will recursively expand template parameters and return you a hash or hash
ref.

=head1 AUTHOR

Ben Tilly, C<< <btilly at gmail.com> >>

=head1 TODO

=over 4

=item Error checking

No checks currently exist for malformed templates, or template references to
variables that are not available.  These would catch common typos and should
be added.

=item Performance

Currently it keeps on passing through the list of not yet done variables until
no further progress is made.  Calculating a dependency graph up front could
significantly help performance.

=item Refactor

All of the real work is done in one giant recursive function.  It could be
broken up into more digestable pieces.

=item Conditionals and loops

Common template features do not work.  Perhaps they would be useful.

=item Recursive macro expansion

C<[% foo[% bar %] %]> does not currently work.  It may be simple to add.

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-expandhash at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-ExpandHash>.  I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.  

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::ExpandHash

Or email the author at C<< <btilly at gmail.com> >>.

The project home is L<https://github.com/btilly/Template-ExpandHash>.

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-ExpandHash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-ExpandHash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-ExpandHash>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-ExpandHash/>

=back

=head1 ACKNOWLEDGEMENTS

This module was produced under contract to ZipRecruiter.com.  They are a good
group of people, and I thank them for allowing this to be open sourced.

All mistakes are, of course, mine.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ben Tilly.

Sponsored by ZipRecruiter.com.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
