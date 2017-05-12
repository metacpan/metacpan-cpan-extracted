package Params::Attr;

=head1 Params::Attr

check function invocation parameters, using attributes to specify the signature

=cut

use strict;
use warnings;
use feature  qw( :5.10 );

use base qw( Exporter );
our @EXPORT_OK = qw( check_string );

use Attribute::Handlers  qw( );
use Carp                 qw( confess );
use Params::Validate     qw( validate_with
                             SCALAR ARRAYREF HASHREF CODEREF UNDEF );
use Scalar::Util         qw( blessed );
use List::Util           qw( first );

our $VERSION = '1.00';

# ----------------------------------------------------------------------------

sub CheckP : ATTR(CODE) {
  my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum)
    = @_;

  my $caller = join('::', $package, *$symbol{NAME});

  # Attribute::Handlers can't always parse the args into an array
  # this happens if, say, args contains a '?'
  my @fields = UNIVERSAL::isa($data, 'ARRAY') ? @$data : split /,/, $data;

  my $optional;
  my @spec;
 FIELD:
  for my $f (@fields) {
    my $type;
    my @isa;
    my $regex;
    my %callbacks;

    if ( ';' eq $f ) {
      my $dstring = ref $data ? join ',', @$data : $data;

      die sprintf "too many ';' in spec '%s' at %s (%s:%d); '%s'\n",
                  $dstring, $caller, $filename, $linenum, $_
        if $optional;
      $optional = 1;
      next FIELD;
    }

    my %type_matrix = ( S  => +{ type => SCALAR },
                        AR => +{ type => ARRAYREF },
                        HR => +{ type => HASHREF, 
                                 keys => qr/^(?:\w+(?:,\w+)*)?$/,
                                 callbacks =>
                                   +{ 'key list __K' => sub {
                                         my ($value, $keys) = @_;
                                         $value //= +{};
                                         for my $k (keys %$value) {
                                           return unless grep $k eq $_, @$keys;
                                         }
                                         return 1;
                                       }
                                    },
                               },
                        CR => +{ type => CODEREF },
                        i  => +{ type => SCALAR,
                                 keys     => qr/^\d+\.\.\d+$/,
                                 keysplit => qr/\.\./,
                                 callbacks =>
                                   +{ 'intrange __0..__1' => sub {
                                        $_[0] >= $_[1]->[0] && $_[0] <= $_[1]->[1]
                                    } },
                               },
                      );
    # type alternation
    my $ta = join '|', sort keys %type_matrix;

    $f =~ s/\[([^]]+)\]$//;
    my $subtype = $1;
    if ( defined $subtype ) {
      die "subtype '$subtype' not supported\n"
        unless $subtype =~ m/^(?<type>(\w+::)+|S)(\|(?&type))+$/;
    }

    for my $_ (split /\|/, $f) {
      when ( '_' )
        { push @isa, $package                                }
      when ( /\?$/ )
        { $type |= UNDEF ; continue                          }
      when ( /^(?<type>$ta)(\((?<keys>.*)\))?\??$/ )
        { 
          my $tm = $type_matrix{$+{type}};
          $type |= $tm->{type};
          my @keys;
          if ( my $keys = $+{keys} ) {
            if ( my $keycheck = $tm->{keys} ) {
              die sprintf "inappropriate keys %s found for param proto %s a %s (%s:%d)\n",
                          $keys, $_, $caller, $filename, $linenum
                unless $keys ~~ $keycheck;
            } else {
              die sprintf "key list not supported with type %s at %s (%s:%d)\n",
                          $+{type}, $caller, $filename, $linenum
            }

            my $keysplit = $tm->{keysplit} // qr/,/;
            @keys = split $keysplit, $keys;

            if ( exists $tm->{callbacks} ) {
              my %r = ( K => join(',', @keys),
                        0 => $keys[0],
                        1 => $keys[1], );
              for my $k ( keys %{$tm->{callbacks}} ) {
                (my $c_name = $k) =~ s/__([K01])/$r{$1}/eg;
                my $cb = $tm->{callbacks}->{$k};
                $callbacks{$c_name} = 
                  sub { $cb->($_[0], \@keys) }
              }
            }
          }
        }
      when ( /^i\??$/ )
        { $type |= SCALAR; $regex = qr/^\d+$/;               }
      when ( /::/ )
        { (my $p = $_) =~ /^::/; $p =~ /::$/, push @isa, $p  }
      default
        {
          (my $thismethod = (caller 0)[3]) =~ s/^.*:://;
          die sprintf "unrecognized %s spec at %s (%s:%d); '%s'\n",
                      $thismethod, $caller, $filename, $linenum, $_;
        }
    }
no warnings 'internal';
    die "use of a subtype with isa is not supported\n"
      if @isa and $subtype;

    my %spec;
    $spec{type}      = $type        if $type and ! @isa;
    $spec{isa}       = \@isa        if @isa and ! $type;
    $spec{regex}     = $regex       if $regex;

    if ( $type and @isa ) {
      die "internal error - @isa && $subtype\n"
        if $subtype;
      $spec{callbacks}->{'type or isa'} = 
        sub {
          my ($value) = @_;
          if ( blessed $value ) {
            return grep $value->isa($_), @isa;
          } elsif ( ! defined $value ) {
            return $type & UNDEF;
          } else {
            given ( ref $value ) {
              when ( '' )       { return $type & SCALAR };
              default           { return }
            }
          }
        };
    } elsif ( $subtype ) {
      die "internal error - $subtype && @isa\n"
        if @isa;

      if ( $type & ~(ARRAYREF | UNDEF) ) {
        die "Subtype: $subtype is not supported with basic type $f\n";
      } else {
        my @subtypes = split /\|/, $subtype;
        $spec{callbacks}->{"compound type: $subtype"} =
          sub {
            my ($value) = @_;
            if ( defined $value ) {
              confess "internal error: should be an arrayref (got " . ref($value) . ")"
                unless 'ARRAY' eq ref $value;
              my @values = @$value;
              for my $v (@values ) {
                for my $st (@subtypes) {
                  if ( -1 < index $st, '::' ) {
                    (my $class = $st) =~ s/(?<!:)::$//g;
                    return 1
                      if defined($v) && blessed($v) && $v->isa($class);
                  } elsif ( 'S' eq $st) {
                    return 1
                      if defined($v) && ! ref($v);
                  }
                }
                return;
              }
            } else {
              return;
            }
          } };
    }

    $spec{callbacks} = \%callbacks
      if keys %callbacks;
    push @spec, \%spec;
  } continue {
    $spec[-1]->{optional} = 1
      if $optional;
  }

  if ( $ENV{__DUMP_PARAM_CHECK} ) {
    require Data::Dumper;
    printf STDERR "%s:%d:\n%s\n", $filename, $linenum, Data::Dumper->new([\@spec],[qw( spec )])->Indent(0)->Dump;
  }

  no warnings 'redefine';
  *$symbol = sub {
    validate_with(params => \@_, spec => \@spec, called => $caller,
                  on_fail => sub {
                    my $frame = 1;
                    # exclude C::MM as it's auto-generated and almost always
                    # pass-through; so problems are from the frame calling it
                    $frame++
                      while (caller $frame)[0] =~ /^Class::MethodMaker/;

                    my $msg = sprintf " at %s:%d (%s)\n",
                                      (caller $frame)[1,2],
                                      (caller 1+$frame)[3];
                    if ( $ENV{PERL_PARAMCHECK_CONFESS} ) {
                      confess @_, $msg;
                    } else {
                      die @_, $msg;
                    }
                  }
                 );
    goto &$referent;
  };
}

# -------------------------------------

sub check_string {
  my ($name, $value, $legit) = @_;
  no warnings 'uninitialized';
  die sprintf "value '%s' is not a legal value for $name\n", $value // '*undef*'
    unless grep $_ ~~ $value, @$legit;
}

# ----------------------------------------------------------------------------

if ( caller ) {
  1; # keep require happy
} else {
  # unit test
  require Test::More;
  Test::More->import(tests => 19);

  require_ok('File::stat');
  require_ok('IO::All');
  IO::All->import('io');

  sub scallywag : CheckP(S)
    { ok(! ref $_[0], "scallywag $_[0]") }
  sub objit     : CheckP(File::stat)
    { ok($_[0]->isa('File::stat'), "objit $_[0]") }
  sub objscal   : CheckP(qw( File::stat|S ))
    { ok(! ref $_[0] || $_[0]->isa('File::stat'), 'objscal') }

  # ----

  scallywag('foo');

  ok( !$@, '$@ unset');
  eval { scallywag([]) };
  ok($@ =~ /which is not one of the allowed types/, 'scalar check');

  # ----

  objit(File::stat::stat($0));

  undef $@;
  ok( !$@, '$@ unset');
  eval { objit('foo') };
  ok($@ =~ /which is not one of the allowed types/, 'object check');

  my $io = io($0);
  ok($io->isa('IO::All'), 'io is expected type');
  undef $@;
  ok( !$@, '$@ unset');
  eval { objit($io) };
  ok($@ =~ /which is not one of the allowed types/, 'object type check');

  # ----

  objscal('bar');
  objscal(File::stat::stat($0));

  $io = io($0);
  ok($io->isa('IO::All'), 'io is expected type');
  undef $@;
  ok( !$@, '$@ unset');
  eval { objscal($io) };
  ok($@ =~ /which is not one of the allowed types/, 'object/scalar type check');

  # ----

  sub isint : CheckP(i)
    { ok($_[0] =~ m!^\d+$!, "int $_[0]") }

  isint(7);
  ok( !$@, '$@ unset');
  eval { isint('foo') };
  ok($@ =~ /which is not one of the allowed types/, 'int check');

}
# XX check object|scalar
