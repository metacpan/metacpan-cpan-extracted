# this module will be loaded by ExtUtils/XSpp/Grammar.pm and needs to
# define subroutines in the ExtUtils::XSpp::Grammar namespace
package ExtUtils::XSpp::Lexer;
# for the indexer and friends
use strict;
use warnings;

package ExtUtils::XSpp::Grammar;

use ExtUtils::XSpp::Node;
use ExtUtils::XSpp::Node::Access;
use ExtUtils::XSpp::Node::Argument;
use ExtUtils::XSpp::Node::Class;
use ExtUtils::XSpp::Node::Comment;
use ExtUtils::XSpp::Node::Constructor;
use ExtUtils::XSpp::Node::Destructor;
use ExtUtils::XSpp::Node::File;
use ExtUtils::XSpp::Node::Function;
use ExtUtils::XSpp::Node::Method;
use ExtUtils::XSpp::Node::Module;
use ExtUtils::XSpp::Node::Package;
use ExtUtils::XSpp::Node::Raw;
use ExtUtils::XSpp::Node::Type;
use ExtUtils::XSpp::Node::PercAny;
use ExtUtils::XSpp::Node::Enum;
use ExtUtils::XSpp::Node::EnumValue;
use ExtUtils::XSpp::Node::Preprocessor;

use ExtUtils::XSpp::Typemap;
use ExtUtils::XSpp::Exception;

use Digest::MD5 qw(md5_hex);

my %tokens = ( '::' => 'DCOLON',
               ':'  => 'COLON',
               '%{' => 'OPSPECIAL',
               '%}' => 'CLSPECIAL',
               '{%' => 'OPSPECIAL',
                '{' => 'OPCURLY',
                '}' => 'CLCURLY',
                '(' => 'OPPAR',
                ')' => 'CLPAR',
                ';' => 'SEMICOLON',
                '%' => 'PERC',
                '~' => 'TILDE',
                '*' => 'STAR',
                '&' => 'AMP',
                '|' => 'PIPE',
                ',' => 'COMMA',
                '=' => 'EQUAL',
                '/' => 'SLASH',
                '.' => 'DOT',
                '-' => 'DASH',
                '<' => 'OPANG',
                '>' => 'CLANG',
               # these are here due to my lack of skill with yacc
               '%name'       => 'p_name',
               '%typemap'    => 'p_typemap',
               '%exception'  => 'p_exceptionmap',
               '%catch'      => 'p_catch',
               '%file'       => 'p_file',
               '%module'     => 'p_module',
               '%code'       => 'p_code',
               '%cleanup'    => 'p_cleanup',
               '%postcall'   => 'p_postcall',
               '%package'    => 'p_package',
               '%length'     => 'p_length',
               '%loadplugin' => 'p_loadplugin',
               '%include'    => 'p_include',
             );

my %keywords = ( const           => 1,
                 class           => 1,
                 unsigned        => 1,
                 short           => 1,
                 long            => 1,
                 int             => 1,
                 char            => 1,
                 package_static  => 1,
                 class_static    => 1,
                 static          => 1,
                 public          => 1,
                 private         => 1,
                 protected       => 1,
                 virtual         => 1,
                 enum            => 1,
                 );

sub get_lex_mode { return $_[0]->YYData->{LEX}{MODES}[0] || '' }

sub push_lex_mode {
  my( $p, $mode ) = @_;

  push @{$p->YYData->{LEX}{MODES}}, $mode;
}

sub pop_lex_mode {
  my( $p, $mode ) = @_;

  die "Unexpected mode: '$mode'"
    unless get_lex_mode( $p ) eq $mode;

  pop @{$p->YYData->{LEX}{MODES}};
}

sub read_more {
  my $v = readline $_[0]->YYData->{LEX}{FH};
  my $buf = $_[0]->YYData->{LEX}{BUFFER};

  unless( defined $v ) {
    if( $_[0]->YYData->{LEX}{NEXT} ) {
      $_[0]->YYData->{LEX} = $_[0]->YYData->{LEX}{NEXT};
      $buf = $_[0]->YYData->{LEX}{BUFFER};

      return $buf if length $$buf;
      return read_more( $_[0] );
    } else {
      return;
    }
  }

  $$buf .= $v;

  return $buf;
}

# for tests
sub _random_digits { sprintf '%06d', rand 100000 }

sub push_conditional {
  my $p = $_[0];
  my $file = $p->YYData->{LEX}{FILE} ?
                 substr md5_hex( $p->YYData->{LEX}{FILE} ), 0, 8 :
                 'zzzzzzzz';
  my $rand = _random_digits;

  my $symbol = 'XSpp_' . $file . '_' . $rand;
  push @{$p->YYData->{LEX}{CONDITIONAL}}, $symbol;

  return $symbol;
}

sub pop_conditional {
  pop @{$_[0]->YYData->{LEX}{CONDITIONAL}};
}

sub get_conditional {
  return undef unless $_[0]->YYData->{LEX}{CONDITIONAL};
  return undef unless @{$_[0]->YYData->{LEX}{CONDITIONAL}};
  return $_[0]->YYData->{LEX}{CONDITIONAL}[-1];
}

sub yylex {
  my $data = $_[0]->YYData->{LEX};
  my $buf = $data->{BUFFER};

  for(;;) {
    if( !length( $$buf ) && !( $buf = read_more( $_[0] ) ) ) {
      return ( '', undef );
    }

    if( get_lex_mode( $_[0] ) eq 'special' ) {
      if( $$buf =~ s/^%}// ) {
        return ( 'CLSPECIAL', '%}' );
      } elsif( $$buf =~ s/^([^\n]*)\n$// ) {
        my $line = $1;

        if( $line =~ m/^(.*?)\%}(.*)$/ ) {
          $$buf = "%}$2\n";
          $line = $1;
        }

        return ( 'line', $line );
      }
    } else {
      $$buf =~ s/^[\s\n\r]+//;
      next unless length $$buf;

      if( $$buf =~ s/^([+-]?0x[0-9a-fA-F]+)// ) {
        return ( 'INTEGER', $1 );
      } elsif( $$buf =~ s/^([+-]?(?=\d|\.\d)\d*(?:\.\d*)?(?:[Ee](?:[+-]?\d+))?)// ) {
        my $v = $1;
        return ( 'INTEGER', $v ) if $v =~ /^[+-]?\d+$/;
        return ( 'FLOAT', $v );
      } elsif( $$buf =~ s/^\/\/(.*)(?:\r\n|\r|\n)// ) {
        return ( 'COMMENT', [ $1 ] );
      } elsif( $$buf =~ /^\/\*/ ) {
        my @rows;
        for(; length( $$buf ) || ( $buf = read_more( $_[0] ) ); $$buf = '') {
          if( $$buf =~ s/(.*?\*\/)// ) {
              push @rows, $1;
              return ( 'COMMENT', \@rows );
          }
          $$buf =~ s/(?:\r\n|\r|\n)$//;
          push @rows, $$buf;
        }
      } elsif( $$buf =~ s/^(\%\w+)// ) {
        return ( $tokens{$1}, $1 ) if exists $tokens{$1};
        return ( 'p_any', substr $1, 1 );
      } elsif( $$buf =~ s/^( \%}
                      | \%{ | {\%
                      | [{}();%~*&,=\/\.\-<>|]
                      | :: | :
                       )//x ) {
        return ( $tokens{$1}, $1 );
      } elsif( $$buf =~ s/^(INCLUDE(?:_COMMAND)?:.*)(?:\r\n|\r|\n)// ) {
        return ( 'RAW_CODE', "$1\n" );
      } elsif( $$buf =~ s/^([a-zA-Z_]\w*)// ) {
        return ( $1, $1 ) if exists $keywords{$1};

        return ( 'ID', $1 );
      } elsif( $$buf =~ s/^("[^"]*")// ) {
        return ( 'QUOTED_STRING', $1 );
      } elsif( $$buf =~ s/^(#\s*(if|ifdef|ifndef|else|elif|endif)\b.*)(?:\r\n|\r|\n)// ) {
        my $symbol;
        if( $2 eq 'else' || $2 eq 'elif' || $2 eq 'endif' ) {
          pop_conditional( $_[0] );
        }
        if( $2 ne 'endif' ) {
          $symbol = push_conditional( $_[0] );
        }

        return ( 'PREPROCESSOR', [ $1, $symbol ] );
      } elsif( $$buf =~ s/^(#.*)(?:\r\n|\r|\n)// ) {
        return ( 'RAW_CODE', $1 );
      } else {
        die $$buf;
      }
    }
  }
}

sub yyerror {
  my $data = $_[0]->YYData->{LEX};
  my $buf = $data->{BUFFER};
  my $fh = $data->{FH};

  print STDERR "Error: line " . $fh->input_line_number . " (Current token type: '",
    $_[0]->YYCurtok, "') (Current value: '",
    $_[0]->YYCurval, '\') Buffer: "', ( $buf ? $$buf : '--empty buffer--' ),
      q{"} . "\n";
  print STDERR "Expecting: (", ( join ", ", map { "'$_'" } $_[0]->YYExpect ),
        ")\n";
}

sub make_const { $_[0]->{CONST} = 1; $_[0] }
sub make_ref   { $_[0]->{REFERENCE} = 1; $_[0] }
sub make_ptr   { $_[0]->{POINTER}++; $_[0] }
sub make_type  { ExtUtils::XSpp::Node::Type->new( base => $_[0] ) }

sub make_template {
    ExtUtils::XSpp::Node::Type->new( base          => $_[0],
                                     template_args => $_[1],
                                     )
}

sub add_data_raw {
  my $p = shift;
  my $rows = shift;

  ExtUtils::XSpp::Node::Raw->new( rows => $rows );
}

sub add_data_comment {
  my $p = shift;
  my $rows = shift;

  ExtUtils::XSpp::Node::Comment->new( rows => $rows );
}

sub add_top_level_directive {
  my( $parser, %args ) = @_;

  $parser->YYData->{PARSER}->handle_toplevel_tag_plugins
    ( $args{any},
      any_named_arguments      => $args{any_named_arguments},
      any_positional_arguments => $args{any_positional_arguments},
      condition                => $parser->get_conditional,
      );
}

sub make_argument {
  my( $p, $type, $name, $default ) = @_;

  ExtUtils::XSpp::Node::Argument->new( type    => $type,
                              name    => $name,
                              default => $default );
}

sub create_class {
  my( $parser, $name, $bases, $metadata, $methods, $condition ) = @_;
  my %args = @$metadata;
  _merge_keys( 'catch', \%args, $metadata );

  my $class = ExtUtils::XSpp::Node::Class->new( %args, # <-- catch only for now
                                                cpp_name     => $name,
                                                base_classes => $bases,
                                                condition    => $condition,
                                                );

  # when adding a class C, automatically add weak typemaps for C* and C&
  ExtUtils::XSpp::Typemap::add_class_default_typemaps( $name );

  my @any  = grep  $_->isa( 'ExtUtils::XSpp::Node::PercAny' ), @$methods;
  my @rest = grep !$_->isa( 'ExtUtils::XSpp::Node::PercAny' ), @$methods;

  foreach my $any ( @any ) {
    $parser->YYData->{PARSER}->handle_class_tag_plugins
      ( $class, $any->{NAME},
        any_named_arguments      => $any->{NAMED_ARGUMENTS},
        any_positional_arguments => $any->{POSITIONAL_ARGUMENTS},
        );
  }

  # finish creating the class
  $class->add_methods( @rest );

  return $class;
}

# support multiple occurrances of specific keys
# => transform to flattened array ref
sub _merge_keys {
  my $key = shift;
  my $argshash = shift;
  my $paramlist = shift;
  my @occurrances;
  for (my $i = 0; $i < @$paramlist; $i += 2) {
    if (defined $paramlist->[$i] and $paramlist->[$i] eq $key) {
      push @occurrances, $paramlist->[$i+1];
    }
  }
  @occurrances = map {ref($_) eq 'ARRAY' ? @$_ : $_}  @occurrances;
  $argshash->{$key} = \@occurrances;
}

sub add_data_function {
  my( $parser, @args ) = @_;
  my %args   = @args;
  _merge_keys( 'catch', \%args, \@args );

  my $f = ExtUtils::XSpp::Node::Function->new
              ( cpp_name  => $args{name},
                perl_name => $args{perl_name},
                class     => $args{class},
                ret_type  => $args{ret_type},
                arguments => $args{arguments},
                code      => $args{code},
                cleanup   => $args{cleanup},
                postcall  => $args{postcall},
                catch     => $args{catch},
                condition => $args{condition},
                );

  if( $args{any} ) {
    $parser->YYData->{PARSER}->handle_function_tag_plugins
      ( $f, $args{any},
        any_named_arguments      => $args{any_named_arguments},
        any_positional_arguments => $args{any_positional_arguments},
        );
  }

  return $f;
}

sub add_data_method {
  my( $parser, @args ) = @_;
  my %args   = @args;
  _merge_keys( 'catch', \%args, \@args );

  my $m = ExtUtils::XSpp::Node::Method->new
            ( cpp_name  => $args{name},
              ret_type  => $args{ret_type},
              arguments => $args{arguments},
              const     => $args{const},
              code      => $args{code},
              cleanup   => $args{cleanup},
              postcall  => $args{postcall},
              perl_name => $args{perl_name},
              catch     => $args{catch},
              condition => $args{condition},
              );

  if( $args{any} ) {
    $parser->YYData->{PARSER}->handle_method_tag_plugins
      ( $m, $args{any},
        any_named_arguments      => $args{any_named_arguments},
        any_positional_arguments => $args{any_positional_arguments},
        );
  }

  return $m;
}

sub add_data_ctor {
  my( $parser, @args ) = @_;
  my %args   = @args;
  _merge_keys( 'catch', \%args, \@args );

  my $m = ExtUtils::XSpp::Node::Constructor->new
            ( cpp_name  => $args{name},
              arguments => $args{arguments},
              code      => $args{code},
              cleanup   => $args{cleanup},
              postcall  => $args{postcall},
              catch     => $args{catch},
              condition => $args{condition},
              );

  if( $args{any} ) {
    $parser->YYData->{PARSER}->handle_method_tag_plugins
      ( $m, $args{any},
        any_named_arguments      => $args{any_named_arguments},
        any_positional_arguments => $args{any_positional_arguments},
        );
  }

  return $m;
}

sub add_data_dtor {
  my( $parser, @args ) = @_;
  my %args   = @args;
  _merge_keys( 'catch', \%args, \@args );

  my $m = ExtUtils::XSpp::Node::Destructor->new
            ( cpp_name  => $args{name},
              code      => $args{code},
              cleanup   => $args{cleanup},
              postcall  => $args{postcall},
              catch     => $args{catch},
              condition => $args{condition},
              );

  if( $args{any} ) {
    $parser->YYData->{PARSER}->handle_method_tag_plugins
      ( $m, $args{any},
        any_named_arguments      => $args{any_named_arguments},
        any_positional_arguments => $args{any_positional_arguments},
        );
  }

  return $m;
}

sub is_directive {
  my( $p, $d, $name ) = @_;

  return $d->[0] eq $name;
}

#sub assert_directive {
#  my( $p, $d, $name ) = @_;
#
#  if( $d->[0] ne $name )
#    { $p->YYError }
#  1;
#}

1;
