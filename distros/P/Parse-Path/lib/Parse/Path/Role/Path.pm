package Parse::Path::Role::Path;

our $VERSION = '0.92'; # VERSION
# ABSTRACT: Role for paths

#############################################################################
# Modules

use Moo::Role;
use Types::Standard qw(Dict Bool Str Int Enum ArrayRef HashRef RegexpRef CodeRef Tuple Maybe Optional);

use sanity;

use Scalar::Util qw( blessed );
use Storable qw( dclone );
use List::AllUtils qw( first all any );
use Sub::Name;

use namespace::clean;
no warnings 'uninitialized';

#############################################################################
# Overloading

use overload
   # with_assign  (XXX: No idea why it can't use '0+')
   '+'  => subname(_overload_plus => sub {
      my ($self, $thing, $swap) = @_;
      $self->depth + $thing;
   }),
   '-'  => subname(_overload_minus => sub {
      my ($self, $thing, $swap) = @_;
      $swap ?
         $thing - $self->depth :
         $self->depth - $thing
      ;
   }),

   # assign
   '.='   => subname(_overload_concat => sub {
      my ($self, $thing) = @_;
      $self->push($thing);
      $self;
   }),

   # 3way_comparison
   '<=>'  => subname(_overload_cmp_num => sub {
      my ($self, $thing, $swap) = @_;
      $swap ?
         $thing <=> $self->depth :
         $self->depth <=> $thing
      ;
   }),
   'cmp'  => subname(_overload_cmp => sub {
      my ($self, $thing, $swap) = @_;

      # If both of these are Parse::Path objects, run through the key comparisons
      if (blessed $thing and $thing->does('Parse::Path::Role::Path')) {
         ($self, $thing) = ($thing, $self) if $swap;

         my ($cmp, $i) = (0, 0);
         for (; $i <= $#{$self->_path} and $i <= $#{$thing->_path}; $i++) {
            my ($stepA, $stepB) = ($self->_path->[$i], $thing->_path->[$i]);
            my $cmp = $stepA->{type} eq 'ARRAY' && $stepB->{type} eq 'ARRAY' ?
               $stepA->{key} <=> $stepB->{key} :
               $stepA->{key} cmp $stepB->{key}
            ;

            return $cmp if $cmp;
         }

         # Now it's down to step counts
         return $self->step_count <=> $thing->step_count;
      }

      # Fallback to string comparison
      return $swap ?
         $thing cmp $self->as_string :
         $self->as_string cmp $thing
      ;
   }),

   # conversion
   'bool' => subname(_overload_bool   => sub { !!shift->step_count }),
   '""'   => subname(_overload_string => sub { shift->as_string }),
   '0+'   => subname(_overload_numify => sub { shift->depth }),

   # dereferencing
   '${}'  => subname(_overload_scalar => sub { \(shift->as_string) }),
   '@{}'  => subname(_overload_array  => sub { shift->as_array }),

   # special
   '='    => subname(_overload_clone  => sub { shift->clone })
;

#############################################################################
# Requirements

requires '_build_blueprint';

# One-time validation for speed
my $BLUEPRINT_VALIDATED = 0;
my $_blueprint_type = Dict[
   hash_step_regexp  => RegexpRef,
   array_step_regexp => RegexpRef,
   delimiter_regexp  => RegexpRef,

   unescape_translation => ArrayRef[Tuple[RegexpRef, CodeRef]],
   pos_translation      => ArrayRef[Tuple[RegexpRef, Str]],

   delimiter_placement => HashRef[Str],

   array_key_sprintf => Str,

   hash_key_stringification => ArrayRef[Tuple[RegexpRef, Str, Optional[CodeRef]]]
];

has _blueprint => (
   is       => 'ro',
   builder  => '_build_blueprint',
   lazy     => 1,
   init_arg => undef,
   isa      => sub {
      return 1 if $BLUEPRINT_VALIDATED;
      $_blueprint_type->assert_valid($_[0]);
      $BLUEPRINT_VALIDATED = 1;
   },
);

#############################################################################
# Attributes

# NOTE: hot attr; bypass isa
has _path => (
   is        => 'rw',
   #isa       => ArrayRef[Dict[
   #   type => Enum[qw( ARRAY HASH )],
   #   key  => Str,
   #   step => Str,
   #   pos  => Int,
   #]],
   predicate => 1,
);

has _tmp_path_thing => (
   is       => 'ro',
   init_arg => 'path',
   required => 1,
   clearer  => 1,
);

has auto_normalize => (
   is        => 'rw',
   isa       => Bool,
   default   => sub { 0 },
);

has auto_cleanup => (
   is        => 'rw',
   isa       => Bool,
   default   => sub { 0 },
);

#############################################################################
# Pre/post-BUILD

sub BUILD {
   my $self = $_[0];

   # Post-build coercion of path
   unless ($self->_has_path) {
      my $path_array = $self->_coerce_step( $self->_tmp_path_thing );

      $self->_path( $path_array );
      $self->cleanup if ($self->auto_cleanup and @$path_array);
   }
   $self->_clear_tmp_path_thing;  # ...and may it never return...

   return $self;
}

#############################################################################
# Methods

# XXX: The array-based methods makes internal CORE calls ambiguous
no warnings 'ambiguous';

sub step_count { scalar @{shift->_path}; }

sub depth {
   my $self = shift;

   my $depth;
   foreach my $step_hash (@{$self->_path}) {
      my $pos = $step_hash->{pos};

      # Process depth
      if    ($pos =~ /^(\d+)$/)       { $depth  = $1; }  # absolute
      elsif ($pos =~ /^X([+\-]\d+)$/) { $depth += $1; }  # relative
      else {                                             # WTF is this?
         die sprintf("Found unparsable pos: %s (step: %s)", $pos, $step_hash->{step});
      }
   }

   return $depth;
}

sub is_absolute {
   my $self = shift;
   $self->step_count ? $self->_path->[0]{pos} !~ /^X/ : undef;
}

sub as_array  { dclone(shift->_path) }
sub blueprint { dclone(shift->_blueprint) }

sub shift   { {%{ shift @{shift->_path} }} }
sub pop     { {%{   pop @{shift->_path} }} }
sub unshift {
   my $self = shift;
   my $step_hashs = $self->_coerce_step([@_]);

   my $return = unshift @{$self->_path}, @$step_hashs;
   $self->cleanup if ($self->auto_cleanup and @$step_hashs);
   return $return;
}
sub push {
   my $self = shift;
   my $step_hashs = $self->_coerce_step([@_]);

   my $return = push @{$self->_path}, @$step_hashs;
   $self->cleanup if ($self->auto_cleanup and @$step_hashs);
   return $return;
}
sub splice {
   my ($self, $offset, $length) = (shift, shift, shift);
   my $step_hashs = $self->_coerce_step([@_]);

   # Perl syntax getting retardo here...
   my @params = ( $offset, defined $length ? ($length, @$step_hashs) : () );
   my @return = splice( @{$self->_path}, @params );
   #my $return = splice( @{$self->_path}, $offset, (defined $length ? ($length, @$step_hashs) : ()) );

   $self->cleanup if ($self->auto_cleanup and defined $length and @$step_hashs);
   return (wantarray ? {%{ $return[-1] }} : @{ dclone(\@return) });
}

sub clear {
   my $self = shift;
   $self->_path([]);
   return $self;
}
sub replace {
   my $self = shift;
   $self->clear->push(@_);
}

sub clone {
   my $self = shift;

   # if an argument is passed, assume it's a path
   my %path_args = @_ ? (
      path  => shift,
   ) : (
      _path => dclone($self->_path),
      path  => '',  # ignored
   );

   $self->new(
      %path_args,
      auto_normalize => $self->auto_normalize,
      auto_cleanup   => $self->auto_cleanup,
   );
}

sub normalize {
   my $self = $_[0];
   $self->_normalize( $self->_path );
   return $self;
}

sub _normalize {
   my ($self, $path_array) = @_;

   # For normalization, can't trust the original step, so we make new ones
   my $new_array = [];
   foreach my $item (@$path_array) {
      push @$new_array, $self->key2hash( @$item{qw(key type pos)} );
   }

   return $new_array;
}

sub cleanup {
   my $self = $_[0];
   my $path = $self->_path;
   my $new_path = [];

   my ($old_pos, $old_type);
   foreach my $step_hash (@$path) {
      my $full_pos = $step_hash->{pos};

      # Process pos
      my ($pos, $type);
      if    ($full_pos =~ /^(\d+)$/)       { ($pos, $type) = ($1, 'A'); }  # absolute
      elsif ($full_pos =~ /^X([+\-]\d+)$/) { ($pos, $type) = ($1, 'R'); }  # relative
      else {                                                               # WTF is this?
         die sprintf("During path cleanup, found unparsable pos: %s (step: %s)", $full_pos, $step_hash->{step});
      }
      $pos = int($pos);

      ### XXX: We may not need this level of complexity if we are only using 0, 1, X-1, X-0, X+1

      my $new_step_hash = { %$step_hash };

      # The most important pos is the first one
      unless (defined $old_pos) {
         $old_pos = $pos;
         $old_type  = $type;

         push(@$new_path, $new_step_hash);
         $new_step_hash->{pos} = $step_hash->{pos};
         next;
      }

      # Relative is going to continue the status quo
      if ($type eq 'R') {
         $old_pos += $pos;
         $new_step_hash->{pos} = $old_type eq 'A' ? $old_pos : sprintf 'X%+d', $pos;

         # Don't use the pos for placement.  Follow the chain of the index, using the array offset.
         # IOW, if it started out with something like X+3, we won't end up with a bunch of starter blanks.
         my $array_index = $#$new_path + $pos;

         # If the index ends up in the negative, we can't clean it up yet.
         if ($array_index < 0) {
            if ($old_type eq 'A') {
               # An absolute path should never go into the negative index (ie: /..)
               die sprintf("During path cleanup, an absolute path dropped into a negative depth (full path: %s)", $self->as_string);
            }

            push(@$new_path, $new_step_hash);
         }
         # Backtracking
         elsif ($pos <= 0) {
            # If the slicing would carve off past the end, just append and move on...
            if (@$new_path < abs($pos)) {
               push(@$new_path, $new_step_hash);
               next;
            }

            # Just ignore zero-pos (ie: /./)
            next unless $pos;

            # Carve off a slice of the $new_path
            my @back_path = splice(@$new_path, $pos);

            # If any of the steps in the path are a relative negative, we have to keep all of them.
            if (any { $_->{pos} =~ /^X-/ } @back_path) { push(@$new_path, @back_path, $new_step_hash); }

            # Otherwise, we won't save this virtual step, and trash the slice.
         }
         # Moving ahead
         else {
            $new_path->[$array_index] = $new_step_hash;
         }
      }
      # Absolute is a bit more error prone...
      elsif ($type eq 'A') {
         if ($old_type eq 'R') {
            # What the hell is ..\C:\ ?
            die sprintf("During path cleanup, a relative path found an illegal absolute step (full path: %s)", $self->as_string);
         }

         # Now this is just A/A, which is rarer, but still legal
         $new_step_hash->{pos} = $old_pos = $pos;
         $new_path->[$pos] = $new_step_hash;
      }
   }

   # Replace
   $self->_path( $new_path );

   return $self;
}

sub _coerce_step {
   my ($self, $thing) = @_;

   # A string step/path to be converted to a HASH step
   unless (ref $thing) {
      my $path_array = $self->path_str2array($thing);
      return $path_array unless $self->auto_normalize;
      return $self->_normalize($path_array);
   }

   # Another DP path object
   elsif (blessed $thing and $thing->does('Parse::Path::Role::Path')) {
      # If the class is the same, it's the same type of path and we can do a
      # direct transfer.  And only if the path is normalized, or we don't care
      # about it.
      return dclone($thing->_path) if (
         $thing->isa($self) and
         $thing->auto_normalize || !$self->auto_normalize
      );

      return $self->_normalize($thing->_path);
   }

   # WTF is this?
   elsif (blessed $thing) {
      die sprintf( "Found incoercible %s step (blessed)", blessed $thing );
   }

   # A potential HASH step
   elsif (ref $thing eq 'HASH') {
      die 'Found incoercible HASH step with ref values'
         if (grep { ref $_ } values %$thing);

      if ( all { exists $thing->{$_} } qw(key type step pos) ) {
         # We have no idea what data is in $thing, so we just soft clone it into
         # something else.  Our own methods will bypass the validation if we
         # pass the right thing, by accessing _path directly.
         return [{
            type => $thing->{type},
            key  => $thing->{key},
            step => $thing->{step},
            pos  => $thing->{pos},
         }];
      }

      # It's better to have a key/type pair than a step
      if (exists $thing->{key} and exists $thing->{type}) {
         my $step_hash = $self->key2hash( @$thing{qw(key type pos)} );
         return [ $step_hash ];
      }

      return $self->path_str2array( $thing->{step} ) if (exists $thing->{step});

      die 'Found incoercible HASH step with wrong keys/data';
   }

   # A collection of HASH steps?
   elsif (ref $thing eq 'ARRAY') {
      my $path_array = [];
      foreach my $item (@$thing) {
         my $step_hash = $self->_coerce_step($item);
         push @$path_array, (ref $step_hash eq 'ARRAY') ? @$step_hash : $step_hash;
      }

      return $path_array;
   }

   # WTF is this?
   else {
      die sprintf( "Found incoercible %s step", ref $thing );
   }
}

sub key2hash {
   my ($self, $key, $type, $pos) = @_;

   # Sanity checks
   die sprintf( "type not HASH or ARRAY (found %s)", $type )
      unless ($type =~ /^HASH$|^ARRAY$/);

   my $bp = $self->_blueprint;
   my $hash_bp  = $bp->{hash_key_stringification};
   my $hash_re  = $bp->{hash_step_regexp};
   my $array_re = $bp->{array_step_regexp};

   # Transform the key to a string step
   my $step = $key;
   if ($type eq 'HASH') {
      my $tuple = first { $step =~ $_->[0] } @$hash_bp;
      die "Cannot match stringification for hash step; hash_step_stringification is not setup right!" unless $tuple;

      $step = $tuple->[2]->($step) if $tuple->[2];
      $step = sprintf ($tuple->[1], $step);
   }
   else {
      $step = sprintf ($bp->{array_key_sprintf}, $step);
   }

   # Validate the new step
   if (
      $type eq 'HASH'  and $step !~ /^$hash_re$/ ||
      $type eq 'ARRAY' and $step !~ /^$array_re$/
   ) {
      die sprintf( "Found %s key than didn't validate against regexp: '%s' --> '%s' (pos: %s)", $type, $key, $step, $pos // '???' );
   }

   return {
      type => $type,
      key  => $key,
      step => $step,
      ### XXX: No +delimiter in latter case.  Not our fault; doing the best we can with the data we've got! ###
      pos  => $pos // $self->_find_pos($step),
   };
}

sub path_str2array {
   my ($self, $path) = @_;
   my $path_array = [];

   while (length $path) {
      my $step_hash = $self->shift_path_str(\$path);

      push(@$path_array, $step_hash);
      die sprintf( "In path '%s', too deep down the rabbit hole, stopped at '%s'", $_[1], $path )
         if (@$path_array > 255);
   };

   return $path_array;
}

sub _find_pos {
   my ($self, $step_plus_delimiter) = @_;

   # Find a matching pos key
   my $dt = $self->_blueprint->{pos_translation};

   my $tuple = first { $step_plus_delimiter =~ $_->[0] } @$dt;
   die "Cannot match a position for step; pos_translation is not setup right!" unless $tuple;

   return $tuple->[1];
}

sub shift_path_str {
   my ($self, $pathref) = @_;

   my $orig_path = $$pathref;

   my $bp = $self->_blueprint;
   my $hash_re  = $bp->{hash_step_regexp};
   my $array_re = $bp->{array_step_regexp};
   my $delim_re = $bp->{delimiter_regexp};

   my $step_hash;
   # Array first because hash could have zero-length string
   if ($$pathref =~ s/^(?<step>$array_re)//) {
      $step_hash = {
         type => 'ARRAY',
         key  => $+{key},
         step => $+{step},
      };
   }
   elsif ($$pathref =~ s/^(?<step>$hash_re)//) {
      $step_hash = {
         type => 'HASH',
         key  => $+{key},
         step => $+{step},
      };

      # Support quote escaping
      my $ut = $self->_blueprint->{unescape_translation};
      my $tuple = first { $+{quote} =~ $_->[0] } @$ut;
      $step_hash->{key} = $tuple->[1]->($step_hash->{key}) if defined $tuple;
   }
   else {
      die sprintf( "Found unparsable step: '%s'", $$pathref );
   }

   $$pathref =~ s/^($delim_re)//;

   # Re-piece the step + delimiter to use with _find_pos
   $step_hash->{pos} = $self->_find_pos( $step_hash->{step}.$1 );

   # If the path is not shifting at all, then something is wrong with REs
   if (length $$pathref == length $orig_path) {
      die sprintf( "Found unshiftable step: '%s'", $$pathref );
   }

   return $step_hash;
}

sub as_string {
   my $self = $_[0];

   my $dlp = $self->_blueprint->{delimiter_placement};

   my $str = '';
   for my $i (0 .. $self->step_count - 1) {
      my $step_hash = $self->_path->[$i];
      my $next_step = ($i == $self->step_count - 1) ? undef : $self->_path->[$i+1];

      my $d = $step_hash->{pos};

      ### Left side delimiter placement
      if    (                   exists $dlp->{$d.'L'}) { $str .= $dlp->{$d.'L'};  }  # pos-specific
      elsif (not $next_step and exists $dlp->{'-1L'} ) { $str .= $dlp->{'-1L'};   }  # ending pos

      # Add the step
      $str .= $step_hash->{step};

      ### Right side delimiter placement
      my $L = substr($step_hash->{type}, 0, 1);
      if (exists $dlp->{$d.'R'}) {  # pos-specific (supercedes other right side options)
         $str .= $dlp->{$d.'R'};
      }
      elsif ($next_step) {          # ref-specific
         my $R = substr($next_step->{type}, 0, 1);
         $str .= $dlp->{$L.$R} if (exists $dlp->{$L.$R});
      }
      else {                        # ending pos
         if    (exists $dlp->{'-1R'}) { $str .= $dlp->{'-1R'}; }  # pos-specific
         elsif (exists $dlp->{$L})    { $str .= $dlp->{$L};    }  # ref-specific
      }
   }

   return $str;
}

42;

__END__

=pod

=encoding utf-8

=head1 NAME

Parse::Path::Role::Path - Role for paths

=head1 SYNOPSIS

    package Parse::Path::MyNewPath;
 
    use Moo;
 
    with 'Parse::Path::Role::Path';
 
    sub _build_blueprint { {
       hash_step_regexp  => qr/(?<key>\w+)|(?<quote>")(?<key>[^"]+)(?<quote>")/,
       array_step_regexp => qr/\[(?<key>\d{1,5})\]/,
       delimiter_regexp  => qr/(?:\.|(?=\[))/,
 
       unescape_translation => [],
 
       pos_translation => [
          [qr/.?/, 'X+1'],
       ],
 
       delimiter_placement => {
          HH => '.',
          AH => '.',
       },
 
       array_key_sprintf        => '[%u]',
       hash_key_stringification => [
          [qr/.?/, '%s'],
       ],
    } }

=head1 DESCRIPTION

This is the base role for L<Parse::Path> and contains 95% of the code.  The idea behind the path classes is that they should be able to
get by with a single blueprint and little to no changes to the main methods.

=head1 BLUEPRINT

The blueprint L<class attribute|MooX::ClassAttribute> is a hashref of various properties (built using C<<< _build_blueprint >>>) that detail
how the path is parsed and put back together.  All properties are required, though some can be turned off.

=head2 Path parsing

=head3 hash_step_regexp

    hash_step_regexp => qr/(?<key>\w+)|(?<quote>")(?<key>[^"]+)(?<quote>")/

Regular expression for parsing a hash step.  This should be a compiled RE, with a named capture called C<<< key >>>.  Optionally, a C<<< quote >>>
capture can be added for quoting capabilities.

Zero-length strings are acceptable if the RE allows for it.  In some cases, ZLS are needed for root paths, ie: a delimiter as the
first character of a path.

BeginningE<sol>ending markers should not be used, as they will be applied as needed.

=head3 array_step_regexp

    array_step_regexp => qr/\[(?<key>\d{1,5})\]/
    array_step_regexp => qr/\Z.\A/   # no-op; turn off array support

Regular expression for parsing an array step.  This should be a compiled RE, with a named capture called C<<< key >>>.  Non-digits are not
recommended, and really don't make sense in the scope of an array.  Also, the RE should have some sort of digit limit to prevent
overly sparse arrays.  (See L<Parse::Path/Sparse arrays and memory usage>.)

Arrays are checked first, as hashs could have zero-length strings.  Arrays should B<not> have zero-length strings, since they should
match some sort of digit.

Paths that don't use arrays still require a RE, but can use a no-op like the one above.

=head3 delimiter_regexp

    delimiter_regexp => qr/(?:\.|(?=\[))/

Regular expression for parsing path delimiter.  This is always parsed after the hashE<sol>array step.

=head3 unescape_translation

    unescape_translation => [
       [qr/\"/, \&String::Escape::unbackslash],
       [qr/\'/, sub { my $str = $_[0]; $str =~ s|\\([\'\\])|$1|g; $str; }],
    ],
 
    unescape_translation => []  # turn off unescape support

Arrayref-of-arrayrefs used to unescape special characters in a key.  Acts like a hashref, but is protected from Regexp
stringification.  The first value is a regular expression matching the C<<< quote >>> capture (from L</hash_step_regexp>).  The value is a
coderef of a subroutine that unescapes the string, as a single parameter in and out.

As this is a "hashref", multiple subs are supported.  This is useful for allowing single quotes in literal strings (with a smaller
subset of escape characters) and double quotes in strings that allow full escaping.

If quotes and escapes are used, the L</hash_step_regexp> needs to be smart enough to handle all cases of quote escaping.  (See the
code in L<Parse::Path::DZIL> for an example.)

Unescape support can be turned off by using an empty array.  (But, the blueprint key still needs to exist.)

=head3 pos_translation

    pos_translation => [
       [qr{^/+$},     0],
       [qr{^\.\./*$}, 'X-1'],
       [qr{^\./*$},   'X-0'],
       [qr{.?},       'X+1'],
    ],

Arrayref-of-arrayrefs used for pos translation.  Acts like a hashref, but is protected from Regexp stringification.  These are the
absolute and relative identifers of the path.  The "key" is a regular expression matching both the path step and right-side delimiter
(extracted from L<shift_path_str|Parse::Path/shift_path_str>).

The value meanings are as follows:

    X+# = Forward relative path
    X-0 = Stationary relative path (like . for file-based paths)
    X-# = Backward relative path
    #   = Absolute path (# = step position)

One of these REs B<must> match, or the parser will die when it finds one it can't parse.  Thus, it's advisable to have a "default"
RE like C<<< qr/.?/ >>>.

Don't assume the RHS delimiter is going to be there.  There may be cases where it's missing (like if L<key2hash|Parse::Path/key2hash>
was not passed a C<<< pos >>>).

If the path doesn't have relativeE<sol>absolute steps, it should be defined with a default of C<<< X+1 >>>.

=head2 Path stringification

=head3 delimiter_placement

    delimiter_placement => {
       '0R' => '/',
       HH   => '.',
       AH   => '.',
    },

Hashref used for delimiter placement.  The keys have the following meanings:

     ##[LR]   = Position-specific placement, either on the left or right side of the step.
                Position can also be '-1' for the end of the path.
 
     [AH][AH] = Type-specific placement in-between the two types (ie: AH means an array on the left side
                and a hash on the right).
 
     [AH]     = Type-specific placement for the end of the path.

The value is the delimiter used in the placement.

=head3 array_key_sprintf

    array_key_sprintf => '[%u]'
    array_key_sprintf => ''  # turn off array support

String for L<sprintf|http://perldoc.perl.org/functions/sprintf.html> that stringifies an array key to a step in the path.

=head3 hash_key_stringification

    hash_key_stringification => [
       [qr/[^\"]+/, '"%s"' => \&String::Escape::backslash],
       [qr/\W|^$/,  "'%s'" => sub { my $str = $_[0]; $str =~ s|([\'\\])|\\$1|g; $str; }],
       [qr/.?/,     '%s'],
    ],

Arrayref-of-arrayrefs used for stringification of a hash key to a step in the path.  The internal arrayref is composed of three
pieces:

    1 => RegexpRef = Matched against the hash key
    2 => Str       = String for sprintf used for stringification
    3 => CodeRef   = (Optional) Sub used to transform key prior to sprintf call

The third piece is typically used for backslashification.  Using multiple REs, you can add in different conditions for different
kinds of quoting.

=head1 CAVEATS

See L<Parse::Path/CAVEATS>.

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Parse-Path/wiki>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Parse::Path/>.

=head1 AUTHOR

Brendan Byrd <bbyrd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
