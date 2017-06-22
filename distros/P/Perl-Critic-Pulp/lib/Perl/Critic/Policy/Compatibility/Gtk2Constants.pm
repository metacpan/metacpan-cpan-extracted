# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

# Perl-Critic-Pulp is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.


package Perl::Critic::Policy::Compatibility::Gtk2Constants;
use 5.006;
use strict;
use warnings;
use List::Util;
use version (); # but don't import qv()
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(is_function_call
                           is_method_call);
use Perl::Critic::Pulp::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 94;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes       => qw(pulp bugs);
use constant applies_to           => qw(PPI::Token::Word PPI::Token::Symbol);

my $v1_190 = version->new('1.190');
my $v1_210 = version->new('1.210');
my $v1_211 = version->new('1.211');

my %constants = (
                 GTK_PRIORITY_RESIZE       => ['Gtk2',$v1_190],
                 GDK_PRIORITY_EVENTS       => ['Gtk2',$v1_190],
                 GDK_PRIORITY_REDRAW       => ['Gtk2',$v1_190],
                 GDK_CURRENT_TIME          => ['Gtk2',$v1_190],

                 EVENT_PROPAGATE           => ['Gtk2',$v1_210],
                 EVENT_STOP                => ['Gtk2',$v1_210],

                 GTK_PATH_PRIO_LOWEST      => ['Gtk2',$v1_211],
                 GTK_PATH_PRIO_GTK         => ['Gtk2',$v1_211],
                 GTK_PATH_PRIO_APPLICATION => ['Gtk2',$v1_211],
                 GTK_PATH_PRIO_THEME       => ['Gtk2',$v1_211],
                 GTK_PATH_PRIO_RC          => ['Gtk2',$v1_211],
                 GTK_PATH_PRIO_HIGHEST     => ['Gtk2',$v1_211],

                 SOURCE_CONTINUE  => ['Glib',$v1_210],
                 SOURCE_REMOVE    => ['Glib',$v1_210],
                );

sub violates {
  my ($self, $elem, $document) = @_;

  my $elem_str;
  if ($elem->isa('PPI::Token::Symbol')) {
    $elem->symbol_type eq '&'
      or return; # only &SOURCE_REMOVE is for us
    $elem_str = substr $elem->symbol, 1;
  } else {
    $elem_str = $elem->content;
  }
  my ($elem_qualifier, $elem_basename) = _qualifier_and_basename ($elem_str);

  # quick lookup excludes names not of interest
  my $constinfo = $constants{$elem_basename}
    || return;
  my ($const_module, $want_version) = @$constinfo;

  if ($elem->isa('PPI::Token::Symbol') || is_function_call ($elem)) {
    if (defined $elem_qualifier) {
      if ($elem_qualifier ne $const_module) {
        return;  # from another module, eg. Foo::Bar::SOURCE_REMOVE
      }
    } else {
      if (! _document_uses_module ($document, $const_module)) {
        return;  # unqualified SOURCE_REMOVE, and no mention of Glib, etc
      }
    }

  } elsif (is_method_call ($elem)) {
    if (defined $elem_qualifier) {
      # an oddity like Some::Where->Gtk2::SOURCE_REMOVE
      if ($elem_qualifier ne $const_module) {
        return;  # from another module, Some::Where->Foo::Bar::SOURCE_REMOVE
      }
    } else {
      # unqualified method name, eg. Some::Thing->SOURCE_REMOVE
      my $class_elem = $elem->sprevious_sibling->sprevious_sibling;
      if (! $class_elem || ! $class_elem->isa('PPI::Token::Word')) {
        # ignore oddities like $foo->SOURCE_REMOVE
        return;
      }
      my $class_name = $class_elem->content;
      if ($class_name ne $const_module) {
        # some other class, eg. Foo::Bar->SOURCE_REMOVE
        return;
      }
    }

  } else {
    # not a function or method call
    return;
  }

  my $got_version = _highest_explicit_module_version ($document,$const_module);
  if (defined $got_version && ref $got_version) {
    if ($got_version >= $want_version) {
      return;
    }
  }

  return $self->violation
    ("$elem requires $const_module $want_version, but "
     . (defined $got_version && ref $got_version
        ? "version in file is $got_version"
        : "no version specified in file"),
     '',
     $elem);
}

# "Foo"            return (undef, "Foo")
# "Foo::Bar::Quux" return ("Foo::Bar", "Quux")
#
sub _qualifier_and_basename {
  my ($str) = @_;
  return ($str =~ /(?:(.*)::)?(.*)/);
}

# return true if $document has a "use" or "require" of $module (string name
# of a package)
sub _document_uses_module {
  my ($document, $module) = @_;

  my $aref = $document->find ('PPI::Statement::Include')
    || return;  # if no Includes at all
  return List::Util::first {$_->type eq 'use'
                              && (($_->module || '') eq $module)
                            } @$aref;
}

# return a "version" object which is the highest explicit use for $module (a
# string) in $document
#
# A call like Foo::Bar->VERSION(123) is a version check, but not sure that's
# worth looking for.
#
# If there's no version number on any "use" of $module then the return is
# version->new(0).  If there's no "use" of $module at all then the return is
# undef.
#
sub _highest_explicit_module_version {
  my ($document, $module) = @_;

  my $cache_key = __PACKAGE__.'::_highest_explicit_module_version--'.$module;
  if (exists $document->{$cache_key}) { return $document->{$cache_key}; }

  my $aref = $document->find ('PPI::Statement::Include')
    || return; # if no Includes at all
  my @incs = grep {$_->type eq 'use'
                     && (($_->module || '') eq $module)} @$aref;
  ### all incs: @$aref
  ### matched incs: @incs
  if (! @incs) { return undef; }

  my @vers = map { _include_module_version_with_exporter($_) } @incs;
  ### versions: @vers
  @vers = grep {defined} @vers;
  if (! @vers) { return 0; }

  @vers = map {version->new($_)} @vers;
  my $maxver = List::Util::reduce {$a >= $b ? $a : $b} @vers;
  return ($document->{$cache_key} = $maxver);
}


# $inc is a PPI::Statement::Include.
#
# If $inc has a version number, either in perl's native form or as a string
# or number as handled by the Exporter package, then return that as a
# version object.
#
sub _include_module_version_with_exporter {
  my ($inc) = @_;

  if (my $ver = Perl::Critic::Pulp::Utils::include_module_version ($inc)) {
    return version->new ($ver->content);
  }

  if (my $ver = Perl::Critic::Pulp::Utils::include_module_first_arg ($inc)) {
    if ($ver->isa('PPI::Token::Number')) {
      $ver = $ver->content;
    } elsif ($ver->isa('PPI::Token::Quote')) {
      $ver = $ver->string;
    } else {
      return undef;
    }
    # Exporter looks only for a leading digit before calling ->VERSION, but
    # be tighter here to avoid errors from version.pm about bad values
    if ($ver =~ $Perl::Critic::Pulp::Utils::use_module_version_number_re) {
      return version->new ($ver);
    }
  }

  return undef;
}

1;
__END__

=for stopwords Gtk2 Ryde

=head1 NAME

Perl::Critic::Policy::Compatibility::Gtk2Constants - new enough Gtk2 version for its constants

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It requires that if you use certain constant subs from
L<C<Gtk2>|Gtk2> and L<C<Glib>|Glib> then you must explicitly have a C<use>
of a high enough version of those modules.

    use Gtk2 1.160;
    ... return Gtk2::EVENT_PROPAGATE;  # bad

    use Gtk2 1.200 ':constants';
    ... return GDK_CURRENT_TIME;       # good

The following C<Gtk2> constants are checked,

    GTK_PRIORITY_RESIZE       # new in Gtk2 1.200 (devel 1.190)
    GDK_PRIORITY_EVENTS
    GDK_PRIORITY_REDRAW
    GDK_CURRENT_TIME

    EVENT_PROPAGATE           # new in Gtk2 1.220 (devel 1.210)
    EVENT_STOP

    GTK_PATH_PRIO_LOWEST      # new in Gtk2 1.220 (devel 1.211)
    GTK_PATH_PRIO_GTK
    GTK_PATH_PRIO_APPLICATION
    GTK_PATH_PRIO_THEME
    GTK_PATH_PRIO_RC
    GTK_PATH_PRIO_HIGHEST

and the following C<Glib> constants

    SOURCE_CONTINUE           # new in Glib 1.220 (devel 1.210)
    SOURCE_REMOVE

The idea is to keep you from using the constants without a new enough
C<Gtk2> or C<Glib>.  Of course there's a huge number of other things you
might do that also require a new enough version, but these constants tripped
me up a few times.

The exact version numbers above and demanded are development versions.
You're probably best off rounding up to a "stable" one like 1.200 or 1.220.

As always if you don't care about this and in particular if for instance you
only ever use Gtk2 1.220 or higher anyway then you can disable
C<Gtk2Constants> from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Compatibility::Gtk2Constants]

=head2 Constant Forms

Constants are recognised as any of for instance

    EVENT_PROPAGATE
    Gtk2::EVENT_PROPAGATE
    Gtk2->EVENT_PROPAGATE
    &EVENT_PROPAGATE
    &Gtk2::EVENT_PROPAGATE

When there's a class name given it's checked, so that other uses of say
C<EVENT_PROPAGATE> aren't picked up.

    Some::Other::Thing::EVENT_PROPAGATE      # ok
    Some::Other::Thing->EVENT_PROPAGATE      # ok
    &Some::Other::Thing::EVENT_PROPAGATE     # ok

When there's no class name, then it's only assumed to be Gtk2 or Glib when
the respective module has been included.

    use Something::Else;
    EVENT_PROPAGATE           # ok

    use Gtk2 ':constants';
    EVENT_PROPAGATE           # bad

In the latter form there's no check for C<:constants> or explicit import in
the C<use>, it's assumed that if you've used Gtk2 then C<EVENT_PROPAGATE>
means that one no matter how the imports might be arranged.

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>, L<Gtk2>, L<Glib>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

=cut
