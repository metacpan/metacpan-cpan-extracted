package Template::Perlish;

# vim: ts=3 sts=3 sw=3 et ai :

use 5.008_000;
use warnings;
use strict;
use Carp;
use English qw( -no_match_vars );
use constant ERROR_CONTEXT => 3;
{ our $VERSION = '1.56'; }
use Scalar::Util qw< blessed reftype >;

# Function-oriented interface
sub import {
   my ($package, @list) = @_;

   for my $sub (@list) {
      croak "subroutine '$sub' not exportable"
        unless grep { $sub eq $_ } qw< crumble render traverse >;

      my $caller = caller();

      no strict 'refs';    ## no critic (ProhibitNoStrict)
      local $SIG{__WARN__} = \&Carp::carp;
      *{$caller . q<::> . $sub} = \&{$package . q<::> . $sub};
   } ## end for my $sub (@list)

   return;
} ## end sub import

sub render {
   my ($template, @rest) = @_;
   my ($variables, %params);
   if (@rest) {
      $variables = ref($rest[0]) ? shift(@rest) : {splice @rest, 0};
      %params = %{shift @rest} if @rest;
   }
   return __PACKAGE__->new(%params)->process($template, $variables);
} ## end sub render

# Object-oriented interface
{
   my (%preset_for, %inhibits_defaults);
   BEGIN {
      %preset_for = (
         'default' => {
            method_over_key => 0,
            start  => '[%',
            stdout => 1,
            stop   => '%]',
            strict_blessed => 0,
            traverse_methods => 0,
            utf8   => 1,
         },
         '1.52' => {
            method_over_key => 1,
            stdout => 0,
            traverse_methods => 1,
         },
      );

      # some defaults are inhibited by the presence of certain input
      # parameters. These parameters can still be put externally, though.
      %inhibits_defaults = (
         binmode => [qw< utf8 >],
      );
   }
   sub new {
      my $package = shift;

      my %external;
      if (@_ == 1) {
         %external = %{$_[0]};
      }
      elsif (scalar(@_) % 2 == 0) {
         while (@_) {
            my ($key, $value) = splice @_, 0, 2;
            if ($key eq '-preset') {
               croak "invalid preset $value in new()"
                 unless exists $preset_for{$value};
               %external = (%external, %{$preset_for{$value}});
            }
            else {
               $external{$key} = $value;
            }
         }
      }
      else {
         croak 'invalid number of input arguments for constructor';
      }

      # compute defaults, removing inhibitions
      my %defaults =(%{$preset_for{'default'}}, variables => {});
      for my $inhibitor (keys %inhibits_defaults) {
         next unless exists $external{$inhibitor};
         delete $defaults{$_} for @{$inhibits_defaults{$inhibitor}};
      }

      return bless {%defaults, %external}, $package;
   } ## end sub new
}

sub process {
   my ($self, $template, $vars) = @_;
   return $self->evaluate($self->compile($template), $vars);
}

sub evaluate {
   my ($self, $compiled, $vars) = @_;
   $self->_compile_sub($compiled)
     unless exists $compiled->{sub};
   return $compiled->{sub}->($vars);
} ## end sub evaluate

sub compile {    ## no critic (RequireArgUnpacking)
   my ($self, undef, %args) = @_;
   my $outcome = $self->_compile_code_text($_[1]);
   return $outcome if $args{no_check};
   return $self->_compile_sub($outcome);
} ## end sub compile

sub compile_as_sub {    ## no critic (RequireArgUnpacking)
   my $self = shift;
   return $self->compile($_[0])->{'sub'};
}

sub _compile_code_text {
   my ($self, $template) = @_;

   my $starter = $self->{start};
   my $stopper = $self->{stop};

   my $compiled = "# line 1 'input'\n";
   $compiled .= "use utf8;\n\n" if $self->{utf8};
   $compiled .= "P('');\n\n";
   my $pos     = 0;
   my $line_no = 1;
   while ($pos < length $template) {

      # Find starter and emit all previous text as simple text
      my $start = index $template, $starter, $pos;
      last if $start < 0;
      my $chunk = substr $template, $pos, $start - $pos;
      $compiled .= _simple_text($chunk)
        if $start > $pos;

      # Update scanning variables. The line counter is advanced for
      # the chunk but not yet for the $starter, so that error reporting
      # for unmatched $starter will point to the correct line
      $pos = $start + length $starter;
      $line_no += ($chunk =~ tr/\n//);

      # Grab code
      my $stop = index $template, $stopper, $pos;
      if ($stop < 0) {    # no matching $stopper, bummer!
         my $section = _extract_section({template => $template}, $line_no);
         croak "unclosed starter '$starter' at line $line_no\n$section";
      }
      my $code = substr $template, $pos, $stop - $pos;

      # Now I can advance the line count considering the $starter too
      $line_no += ($starter =~ tr/\n//);

      if (length $code) {
         if (my $path = crumble($code)) {
            $compiled .= _variable($path);
         }
         elsif (my ($scalar) =
            $code =~ m{\A\s* (\$ [[:alpha:]_]\w*) \s*\z}mxs)
         {
            $compiled .=
              "\nP($scalar); ### straight scalar\n\n";
         } ## end elsif (my ($scalar) = $code...)
         elsif (substr($code, 0, 1) eq q<=>) {
            $compiled .= "\n# line $line_no 'template<3,$line_no>'\n"
              . _expression(substr $code, 1);
         }
         else {
            $compiled .=
              "\n# line $line_no 'template<0,$line_no>'\n" . $code;
         }
      } ## end if (length $code)

      # Update scanning variables
      $pos = $stop + length $stopper;
      $line_no += (($code . $stopper) =~ tr/\n//);

   } ## end while ($pos < length $template)

   # put last part of input string as simple text
   $compiled .= _simple_text(substr($template, $pos || 0));

   return {
      template  => $template,
      code_text => $compiled,
   };
} ## end sub _compile_code_text

# The following function is long and complex because it deals with many
# different cases. It is kept as-is to avoid too many calls to other
# subroutines; for this reason, it's reasonably commented.
sub traverse {  ## no critic (RequireArgUnpacking,ProhibitExcessComplexity)

   ## no critic (ProhibitDoubleSigils)
   my $iref         = ref($_[0]);
   my $ref_wanted   = ($iref eq 'SCALAR') || ($iref eq 'REF');
   my $ref_to_value = $ref_wanted ? shift : \shift;

   # early detection of options, remove them from args list
   my $opts = (@_ && (ref($_[-1]) eq 'HASH')) ? pop(@_) : {};

   # if there's not $path provided, just don't bother going on. Actually,
   # no $path means just return root, undefined path is always "not
   # present" though.
   return ($ref_wanted ? $ref_to_value : $$ref_to_value) unless @_;
   my $path_input = shift;
   return ($ref_wanted ? undef : '') unless defined $path_input;

   my $crumbs;
   if (ref $path_input) {
      $crumbs = $path_input;
   }
   else {
      return ($ref_wanted ? $ref_to_value : $$ref_to_value)
        if defined($path_input) && !length($path_input);
      $crumbs = crumble($path_input);
   }
   return ($ref_wanted ? undef : '') unless defined $crumbs;

   # go down the rabbit hole
   my $use_method = $opts->{traverse_methods} || 0;
   my ($strict_blessed, $method_pre) = (0, 0);
   if ($use_method) {
      $strict_blessed = $opts->{strict_blessed} || 0;
      $method_pre = (! $strict_blessed && $opts->{method_over_key}) || 0;
   }
   for my $crumb (@$crumbs) {

      # $key is what we will look into $$ref_to_value. We don't use
      # $crumb directly as we might change $key in the loop, and we
      # don't want to spoil $crumbs
      my $key = $crumb;

      # $ref tells me how to look down into $$ref_to_value, i.e. as
      # an ARRAY or a HASH... or object
      my $ref = reftype $$ref_to_value;

      # if $ref is not true, we hit a wall. How we proceed depends on
      # whether we were asked to auto-vivify or not.
      if (!$ref) {
         return '' unless $ref_wanted;    # don't bother going on

         # auto-vivification requested! $key will tell us how to
         # proceed further, hopefully
         $ref = ref $key;
      } ## end if (!$ref)

      # if $key is a reference, it will tell us what's expected now
      if (my $key_ref = ref $key) {

         # if $key_ref is not the same as $ref there is a mismatch
         # between what's available ($ref) and what' expected ($key_ref)
         return($ref_wanted ? undef : '') if $key_ref ne $ref;

         # OK, data and expectations agree. Get the "real" key
         if ($key_ref eq 'ARRAY') {
            $key = $crumb->[0];    # it's an array, key is (only) element
         }
         elsif ($key_ref eq 'HASH') {
            ($key) = keys %$crumb;    # hash... key is (only) key
         }
      } ## end if (my $key_ref = ref ...)

      # if $ref is still not true at this point, we're doing
      # auto-vivification and we have a plain key. Some guessing
      # will be needed! Plain non-negative integers resolve to ARRAY,
      # otherwise we'll consider $key as a HASH key
      $ref ||= ($key =~ m{\A (?: 0 | [1-9]\d*) \z}mxs) ? 'ARRAY' : 'HASH';

      # time to actually do the next step
      my $is_blessed = blessed $$ref_to_value;
      my $method = $is_blessed && $$ref_to_value->can($key);
      if ($is_blessed && $strict_blessed) {
         return($ref_wanted ? undef : '') unless $method;
         $ref_to_value = \($$ref_to_value->$method());
      }
      elsif ($method && $method_pre) {
         $ref_to_value = \($$ref_to_value->$method());
      }
      elsif (($ref eq 'HASH') && exists($$ref_to_value->{$key})) {
         $ref_to_value = \($$ref_to_value->{$key});
      }
      elsif (($ref eq 'ARRAY') && exists($$ref_to_value->[$key])) {
         $ref_to_value = \($$ref_to_value->[$key]);
      }
      elsif ($method && $use_method) {
         $ref_to_value = \($$ref_to_value->$method());
      }
      # autovivification goes here eventually
      elsif ($ref eq 'HASH') {
         $ref_to_value = \($$ref_to_value->{$key});
      }
      elsif ($ref eq 'ARRAY') {
         $ref_to_value = \($$ref_to_value->[$key]);
      }
      else {    # don't know what to do with other references!
         return $ref_wanted ? undef : '';
      }
   } ## end for my $crumb (@$crumbs)

   # normalize output, substitute undef with '' unless $ref_wanted
   return
       $ref_wanted             ? $ref_to_value
     : defined($$ref_to_value) ? $$ref_to_value
     :                           '';

   ## use critic
} ## end sub traverse

sub V  { return '' }
sub A  { return }
sub H  { return }
sub HK { return }
sub HV { return }

sub _compile_sub {
   my ($self, $outcome) = @_;

   my @warnings;
   {
      my $utf8 = $self->{utf8} ? 1 : 0;
      my $stdout = $self->{stdout} ? 1 : 0;
      local $SIG{__WARN__} = sub { push @warnings, @_ };
      my @code;
      push @code, <<'END_OF_CODE';
   sub {
      my %variables = %{$self->{variables}};
      my $V = \%variables; # generic kid, as before by default

      {
         my $vars = shift || {};
         if (ref($vars) eq 'HASH') { # old case
            %variables = (%variables, %$vars);
         }
         else {
            $V = $vars;
            %variables = (HASH => { %variables }, REF => $V);
         }
      }

      my $buffer = ''; # output variable
      my $OFH;
END_OF_CODE

      my $handle = '$OFH';
      if ($stdout) {
         $handle = 'STDOUT';
         push @code, <<'END_OF_CODE';
      local *STDOUT;
      open STDOUT, '>', \$buffer or croak "open(): $OS_ERROR";
      $OFH = select(STDOUT);
END_OF_CODE
      }
      else {
         push @code, <<'END_OF_CODE';
      open $OFH, '>', \$buffer or croak "open(): $OS_ERROR";
END_OF_CODE
      }

      push @code, "binmode $handle, ':encoding(utf8)';\n"
         if $utf8;
      push @code, "binmode $handle, '$self->{binmode}';\n"
         if defined $self->{binmode};

      push @code, <<'END_OF_CODE';

      no warnings 'redefine';
      local *V  = sub {
         my $path = scalar(@_) ? shift : [];
         my $input = scalar(@_) ? shift : $V;
         return traverse($input, $path, $self);
      };
      local *A  = sub {
         my $path = scalar(@_) ? shift : [];
         my $input = scalar(@_) ? shift : $V;
         return @{traverse($input, $path, $self) || []};
      };
      local *H  = sub {
         my $path = scalar(@_) ? shift : [];
         my $input = scalar(@_) ? shift : $V;
         return %{traverse($input, $path, $self) || {}};
      };
      local *HK = sub {
         my $path = scalar(@_) ? shift : [];
         my $input = scalar(@_) ? shift : $V;
         return keys %{traverse($input, $path, $self) || {}};
      };
      local *HV = sub {
         my $path = scalar(@_) ? shift : [];
         my $input = scalar(@_) ? shift : $V;
         return values %{traverse($input, $path, $self) || {}};
      };
END_OF_CODE

      push @code, <<"END_OF_CODE";
      local *P = sub { return print $handle \@_; };
      use warnings 'redefine';

END_OF_CODE



      push @code, <<'END_OF_CODE';
      { # double closure to free "my" variables
         my ($buffer, $OFH); # hide external ones
END_OF_CODE

      # the real code! one additional scope indentation to ensure we
      # can "my" variables again
      push @code,
         "{\n", # this enclusure allows using "my" again
         $outcome->{code_text},
         "}\n}\n\n";

      push @code, "select(\$OFH);\n" if $stdout;
      push @code, "close $handle;\n\n";

      if ($utf8) {
         push @code, <<'END_OF_CODE';
      require Encode;
      $buffer = Encode::decode(utf8 => $buffer);

END_OF_CODE
      }

      push @code, "return \$buffer;\n}\n";

      my $code = join '', @code;
      #print {*STDOUT} $code, "\n\n\n\n\n"; exit 0;
      $outcome->{sub} = eval $code;    ## no critic (ProhibitStringyEval)
      return $outcome if $outcome->{sub};
   }

   my $error = $EVAL_ERROR;
   my ($offset, $starter, $line_no) =
     $error =~ m{at[ ]'template<(\d+),(\d+)>'[ ]line[ ](\d+)}mxs;
   $line_no -= $offset;
   s{at[ ]'template<\d+,\d+>'[ ]line[ ](\d+)}
    {'at line ' . ($1 - $offset)}egmxs
     for @warnings, $error;
   if ($line_no == $starter) {
      s{,[ ]near[ ]"[#][ ]line.*?\n\s+}{, near "}gmxs
        for @warnings, $error;
   }

   my $section = _extract_section($outcome, $line_no);
   $error = join '', @warnings, $error, "\n", $section;

   croak $error;
} ## end sub _compile_sub

sub _extract_section {
   my ($hash, $line_no) = @_;
   $line_no--;    # for proper comparison with 0-based array
   my $start = $line_no - ERROR_CONTEXT;
   my $end   = $line_no + ERROR_CONTEXT;

   my @lines = split /\n/mxs, $hash->{template};
   $start = 0       if $start < 0;
   $end   = $#lines if $end > $#lines;
   my $n_chars = length($end + 1);
   return join '', map {
      sprintf "%s%${n_chars}d| %s\n",
        (($_ == $line_no) ? '>>' : '  '), ($_ + 1), $lines[$_];
   } $start .. $end;
} ## end sub _extract_section

sub _simple_text {
   my $text = shift;

   return "P('$text');\n\n" if $text !~ /[\n'\\]/mxs;

   $text =~ s/^/ /gmxs;    # indent, trick taken from diff -u
   return <<"END_OF_CHUNK";
### Verbatim text
P(do {
   my \$text = <<'END_OF_INDENTED_TEXT';
$text
END_OF_INDENTED_TEXT
   \$text =~ s/^ //gms;      # de-indent
   substr \$text, -1, 1, ''; # get rid of added newline
   \$text;
});

END_OF_CHUNK
} ## end sub _simple_text

sub crumble {
   my ($input) = @_;
   return unless defined $input;

   $input =~ s{\A\s+|\s+\z}{}gmxs;
   return [] unless length $input;

   my $sq    = qr{(?mxs: ' [^']* ' )}mxs;
   my $dq    = qr{(?mxs: " (?:[^\\"] | \\.)* " )}mxs;
   my $ud    = qr{(?mxs: \w+ )}mxs;
   my $chunk = qr{(?mxs: $sq | $dq | $ud)+}mxs;

   # save and reset current pos() on $input
   my $prepos = pos($input);
   pos($input) = undef;

   my @path;
   ## no critic (RegularExpressions::ProhibitCaptureWithoutTest)
   push @path, $1 while $input =~ m{\G [.]? ($chunk) }cgmxs;
   ## use critic

   # save and restore pos() on $input
   my $postpos = pos($input);
   pos($input) = $prepos;

   return unless defined $postpos;
   return if $postpos != length($input);

   # cleanup @path components
   for my $part (@path) {
      my @subparts;
      while ((pos($part) || 0) < length($part)) {
         if ($part =~ m{\G ($sq) }cgmxs) {
            push @subparts, substr $1, 1, length($1) - 2;
         }
         elsif ($part =~ m{\G ($dq) }cgmxs) {
            my $subpart = substr $1, 1, length($1) - 2;
            $subpart =~ s{\\(.)}{$1}gmxs;
            push @subparts, $subpart;
         }
         elsif ($part =~ m{\G ($ud) }cgmxs) {
            push @subparts, $1;
         }
         else {    # shouldn't happen ever
            return;
         }
      } ## end while ((pos($part) || 0) ...)
      $part = join '', @subparts;
   } ## end for my $part (@path)

   return \@path;
} ## end sub crumble

sub _variable {
   my $path = shift;
   my $DQ   = q<">;    # double quotes
   $path = join ', ', map { $DQ . quotemeta($_) . $DQ } @{$path};

   return <<"END_OF_CHUNK";
### Variable from the stash (\$V)
P(V([$path]));

END_OF_CHUNK
} ## end sub _variable

sub _expression {
   my $expression = shift;
   return <<"END_OF_CHUNK";
# Expression to be evaluated and printed out
{
   my \$value = do {{
$expression
   }};
   P(\$value) if defined \$value;
}

END_OF_CHUNK

} ## end sub _expression

1;
