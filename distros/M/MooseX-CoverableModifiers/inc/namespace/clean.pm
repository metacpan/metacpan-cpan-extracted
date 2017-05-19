#line 1
package namespace::clean;
# ABSTRACT: Keep imports and functions out of your namespace

use warnings;
use strict;

use vars qw( $STORAGE_VAR );
use Package::Stash;

our $VERSION = '0.21';

$STORAGE_VAR = '__NAMESPACE_CLEAN_STORAGE';

BEGIN {

  use warnings;
  use strict;

  # when changing also change in Makefile.PL
  my $b_h_eos_req = '0.07';

  if (eval {
    require B::Hooks::EndOfScope;
    B::Hooks::EndOfScope->VERSION($b_h_eos_req);
    1
  } ) {
    B::Hooks::EndOfScope->import('on_scope_end');
  }
  else {
    eval <<'PP' or die $@;

  use Tie::Hash ();

  {
    package namespace::clean::_TieHintHash;

    use warnings;
    use strict;

    use base 'Tie::ExtraHash';
  }

  {
    package namespace::clean::_ScopeGuard;

    use warnings;
    use strict;

    sub arm { bless [ $_[1] ] }

    sub DESTROY { $_[0]->[0]->() }
  }


  sub on_scope_end (&) {
    $^H |= 0x020000;

    if( my $stack = tied( %^H ) ) {
      if ( (my $c = ref $stack) ne 'namespace::clean::_TieHintHash') {
        die <<EOE;
========================================================================
               !!!   F A T A L   E R R O R   !!!

                 foreign tie() of %^H detected
========================================================================

namespace::clean is currently operating in pure-perl fallback mode, because
your system is lacking the necessary dependency B::Hooks::EndOfScope $b_h_eos_req.
In this mode namespace::clean expects to be able to tie() the hinthash %^H,
however it is apparently already tied by means unknown to the tie-class
$c

Since this is a no-win situation execution will abort here and now. Please
try to find out which other module is relying on hinthash tie() ability,
and file a bug for both the perpetrator and namespace::clean, so that the
authors can figure out an acceptable way of moving forward.

EOE
      }
      push @$stack, namespace::clean::_ScopeGuard->arm(shift);
    }
    else {
      tie( %^H, 'namespace::clean::_TieHintHash', namespace::clean::_ScopeGuard->arm(shift) );
    }
  }

  1;

PP

  }
}

#line 220

my $sub_utils_loaded;
my $DebuggerRename = sub {
  my ($f, $sub, $cleanee_stash, $deleted_stash) = @_;

  if (! defined $sub_utils_loaded ) {
    $sub_utils_loaded = do {
      my $sn_ver = 0.04;
      eval { require Sub::Name; Sub::Name->VERSION($sn_ver) }
        or die "Sub::Name $sn_ver required when running under -d or equivalent: $@";

      my $si_ver = 0.04;
      eval { require Sub::Identify; Sub::Identify->VERSION($si_ver) }
        or die "Sub::Identify $si_ver required when running under -d or equivalent: $@";

      1;
    } ? 1 : 0;
  }

  if ( Sub::Identify::sub_fullname($sub) eq ($cleanee_stash->name . "::$f") ) {
    my $new_fq = $deleted_stash->name . "::$f";
    Sub::Name::subname($new_fq, $sub);
    $deleted_stash->add_symbol("&$f", $sub);
  }
};

my $RemoveSubs = sub {
    my $cleanee = shift;
    my $store   = shift;
    my $cleanee_stash = Package::Stash->new($cleanee);
    my $deleted_stash;

  SYMBOL:
    for my $f (@_) {

        # ignore already removed symbols
        next SYMBOL if $store->{exclude}{ $f };

        my $sub = $cleanee_stash->get_symbol("&$f")
          or next SYMBOL;

        if ($^P and ref(\$cleanee_stash->namespace->{$f}) eq 'GLOB') {
            # convince the Perl debugger to work
            # it assumes that sub_fullname($sub) can always be used to find the CV again
            # since we are deleting the glob where the subroutine was originally
            # defined, that assumption no longer holds, so we need to move it
            # elsewhere and point the CV's name to the new glob.
            $DebuggerRename->(
              $f,
              $sub,
              $cleanee_stash,
              $deleted_stash ||= Package::Stash->new("namespace::clean::deleted::$cleanee"),
            );
        }

        my @symbols = map {
            my $name = $_ . $f;
            my $def = $cleanee_stash->get_symbol($name);
            defined($def) ? [$name, $def] : ()
        } '$', '@', '%', '';

        $cleanee_stash->remove_glob($f);

        $cleanee_stash->add_symbol(@$_) for @symbols;
    }
};

sub clean_subroutines {
    my ($nc, $cleanee, @subs) = @_;
    $RemoveSubs->($cleanee, {}, @subs);
}

#line 298

sub import {
    my ($pragma, @args) = @_;

    my (%args, $is_explicit);

  ARG:
    while (@args) {

        if ($args[0] =~ /^\-/) {
            my $key = shift @args;
            my $value = shift @args;
            $args{ $key } = $value;
        }
        else {
            $is_explicit++;
            last ARG;
        }
    }

    my $cleanee = exists $args{ -cleanee } ? $args{ -cleanee } : scalar caller;
    if ($is_explicit) {
        on_scope_end {
            $RemoveSubs->($cleanee, {}, @args);
        };
    }
    else {

        # calling class, all current functions and our storage
        my $functions = $pragma->get_functions($cleanee);
        my $store     = $pragma->get_class_store($cleanee);
        my $stash     = Package::Stash->new($cleanee);

        # except parameter can be array ref or single value
        my %except = map {( $_ => 1 )} (
            $args{ -except }
            ? ( ref $args{ -except } eq 'ARRAY' ? @{ $args{ -except } } : $args{ -except } )
            : ()
        );

        # register symbols for removal, if they have a CODE entry
        for my $f (keys %$functions) {
            next if     $except{ $f };
            next unless $stash->has_symbol("&$f");
            $store->{remove}{ $f } = 1;
        }

        # register EOF handler on first call to import
        unless ($store->{handler_is_installed}) {
            on_scope_end {
                $RemoveSubs->($cleanee, $store, keys %{ $store->{remove} });
            };
            $store->{handler_is_installed} = 1;
        }

        return 1;
    }
}

#line 366

sub unimport {
    my ($pragma, %args) = @_;

    # the calling class, the current functions and our storage
    my $cleanee   = exists $args{ -cleanee } ? $args{ -cleanee } : scalar caller;
    my $functions = $pragma->get_functions($cleanee);
    my $store     = $pragma->get_class_store($cleanee);

    # register all unknown previous functions as excluded
    for my $f (keys %$functions) {
        next if $store->{remove}{ $f }
             or $store->{exclude}{ $f };
        $store->{exclude}{ $f } = 1;
    }

    return 1;
}

#line 391

sub get_class_store {
    my ($pragma, $class) = @_;
    my $stash = Package::Stash->new($class);
    my $var = "%$STORAGE_VAR";
    $stash->add_symbol($var, {})
        unless $stash->has_symbol($var);
    return $stash->get_symbol($var);
}

#line 408

sub get_functions {
    my ($pragma, $class) = @_;

    my $stash = Package::Stash->new($class);
    return {
        map { $_ => $stash->get_symbol("&$_") }
            $stash->list_all_symbols('CODE')
    };
}

#line 484

no warnings;
'Danger! Laws of Thermodynamics may not apply.'
