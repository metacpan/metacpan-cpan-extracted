package Template::Magic ;
$VERSION = 1.40 ;
use strict ;
use 5.006_001 ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use Carp
; $Carp::Internal{+__PACKAGE__}++
; use warnings::register
; use Template::Magic::Zone
; use IO::Util
; use Class::Util
; use File::Spec

; sub NEXT_HANDLER () { 0 }
; sub LAST_HANDLER () { 1 }

; sub import
   { my ($pkg, $pragma) = @_
   ; if (  $pragma
        && $pragma eq '-compile'
        )
      { carp "The -compile pragma has no effect since version 1.39"
        if warnings::enabled
      }
     else
      { require Exporter
      ; our @ISA = 'Exporter'
      ; our @EXPORT_OK  = qw| NEXT_HANDLER
                              LAST_HANDLER
                            |
      ; $pkg->export_to_level(1, @_)
      }
   }

; sub new
   { my ($c) = shift
   ; my ($s) = @_
   ; $s = { @_ }                      # passing hash backward compatibility
          unless ref $s eq 'HASH'
   ; foreach ( keys %$s )             # passing -flag backward compatibility
      { $$s{$_} = delete $$s{-$_}
                  if s/^-//
      }
   ; foreach ( values %$s )           # each value should be an ARRAY ref
      { $_ = [ $_ ]
             unless ref eq 'ARRAY'
      }
   ; bless $s, $c
   ; $$s{markers}         ||= $s->DEFAULT_MARKERS
   ; $$s{output_handlers} ||= $s->DEFAULT_PRINT_HANDLERS
   ; $$s{text_handlers}   ||= $s->DEFAULT_TEXT_HANDLERS
                              || $$s{output_handlers}
   ; $$s{zone_handlers}   ||= $s->DEFAULT_ZONE_HANDLERS
   ; $$s{value_handlers}  ||= $s->DEFAULT_VALUE_HANDLERS
   ; $$s{post_handlers}   ||= $s->DEFAULT_POST_HANDLERS
   ; $$s{lookups}         ||= [ (caller)[0] ]
   ; $$s{options}         ||= $s->DEFAULT_OPTIONS
   ; $$s{options}           = { map { /^(no_)*(.+)$/
                                    ; $2 => $1 ? 0 : 1
                                    }
                                    @{$$s{options}}
                              }
   ; foreach my $n (qw| zone value text output post |)
      { $$s{$n.'_handlers'}
        &&= [ $s->_Hload( $$s{$n.'_handlers'}
                        , $n
                        )
            ]
      }
   ; $s
   }

; sub _Hload
   { my ($s, $arr, $n) = @_
   ; map
      { if ( ref eq 'CODE' )
         { $_
         }
        elsif ( not ref )
         { my $C = $s->can($_)
                || $s->can( join ( '_'
                                 , $_
                                 , uc $n
                                 , 'HANDLERS'
                                 )
                          )
                || croak qq(Unknown handler "$_")
         ; my $ref = $s->$C
         ; if ( ref $ref eq 'ARRAY' )
            { $s->_Hload( $ref, $n )
            }
           elsif ( ref $ref eq 'CODE' )
            { $ref
            }
         }
      }
      @$arr
   }

; sub _re
   { my ($s) = @_
   ; unless ( $$s{_re} ) # execute it just the first time AND if it has to parse
      { unless ( @{$$s{markers}} == 3 )
         { no strict 'refs' 
         ; my $m = $$s{markers}[0]
         ; my $M =  $s->can($m)
                 || $s->can($m.'_MARKERS') # backward compatibility
                 || croak qq(Unknown markers "$m")
         ; $$s{markers} = $s->$M
         }
      ; $$s{markers} = [ map { qr/$_/s
                             }
                             ( @{$$s{markers}}
                             , '(?:(?!' .$$s{markers}[2]. ').)*'
                             , '\w+'
                             )
                       ]
      ; my ($S, $I, $E, $A, $ID) = @{$$s{markers}}
      ; $$s{_re}{label}          = qr/$S$I*$ID$A$E/s
      ; $$s{_re}{start_label}    = qr/$S($ID)($A)$E/s
      ; $$s{_re}{end_label}      = qr/$S$I($ID)$E/s
      ; $$s{_re}{include_label}  = qr/$S\bINCLUDE_TEMPLATE\b($A)$E/s
      }

   ; wantarray
     ? @{$$s{markers}}
     : $$s{_re}
   }
   
; sub find_file
   { my ($s, $t) = @_
   ; my $find = sub{(grep -s, @_)[0]}
   ; File::Spec->file_name_is_absolute($t)
     ? $find->($t)
     : (  $ENV{TEMPLATE_MAGIC_ROOT}
       && $find->( File::Spec->catfile( $ENV{TEMPLATE_MAGIC_ROOT}
                                      , $t
                                      )
                 )
       || $find->( map File::Spec->catfile( $_
                                          , $t
                                          )
                 , @{$$s{paths}}
                 )
       || $ENV{TEMPLATE_MAGIC_ROOT}
       && $find->( map File::Spec->catfile( $ENV{TEMPLATE_MAGIC_ROOT}
                                          , $_
                                          , $t
                                          )
                 , @{$$s{paths}}
                 )
       || $find->($t)
       )
   }
      
; sub output
   { my $s = shift
   ; my $args
   ; $$args{template} = shift
   ; $$args{lookups}  = [ @_ ] if @_
   ; IO::Util::capture { $s->_process( $args ) }
   }

; sub print
   { my $s = shift
   ; my $args
   ; $$args{template} = shift
   ; $$args{lookups}  = [ @_ ] if @_
   ; $s->_process( $args )
   }

; sub noutput
   { my ($s, %args) = @_
   ; $args{lookups} = [ $args{lookups} ]
                      unless ref $args{lookups} eq 'ARRAY'
   ; IO::Util::capture { $s->_process( \%args ) }
   }

; sub nprint
   { my ($s, %args) = @_
   ; $args{lookups} = [ $args{lookups} ]
                      unless ref $args{lookups} eq 'ARRAY'
   ; $s->_process( \%args )
   }

; sub _process
   { my ($s, $args) = @_
   ; $$s{_temp_lookups} = $$args{lookups} if exists $$args{lookups}
   ; my $t
   ; if ( $t =  $$args{container_template}
             || ${$$s{container_template}}[0]
        )
      { $$s{_included_template} = $$args{template}
      }
     else
      { $t = $$args{template}
      }
   ; my $z = $s->load( $t )
   ; $$z{tm} = $s
   ; $z->content_process
   ; delete $$z{tm} # to avoid tm object caching
   ; delete @$s{qw|_included_template _temp_lookups _NOT_lookup|}
   }

; sub load
   { my ($s, $t) = @_
   ; my $main_zone
   ; if ( not ref $t )
      { $t = $s->find_file($t)
             or croak qq(Template file "$t" empty or not found)
      ; if ( $$s{options}{cache} )
         { $main_zone = IO::Util::_get_parsing_cache('magic_zone', $t)
         ; return $main_zone if $main_zone
         }
      }
   ; my $content = ref $t eq 'SCALAR' ? $t : IO::Util::slurp $t
   ; $main_zone  =  $s->_parse( $content )
   ; $$s{options}{cache}  &&! ref($t)    # set cache
     && IO::Util::_set_parsing_cache 'magic_zone', $t, $main_zone
   ; $main_zone
   }

; sub purge_cache
   { $_[0] = 'magic_zone'
   ; goto &IO::Util::_purge_parsing_cache
   }

; sub _parse
   { my ($s, $content_ref) = @_
   ; my $re = $s->_re
   ; my @temp
     = map { [ $_
             , do {  /$$re{end_label}/     && $1
                  || /$$re{include_label}/ && do{ (my $t = $1) =~ s/^\s+//
                                                ; $t
                                                  ? $s->load($t)
                                                  : 'CONTAINER_INCLUDE'
                                                }
                  || /$$re{start_label}/   && { id         => $1
                                              , attributes => $2
                                              }
                  }
             ]
           }
           split /($$re{label})/ , $$content_ref
  
   ; for ( my $i  = $#temp                        # find end
         ;    $i >= 0
         ;    $i --
         )
      { my $id = $temp[$i][1]
      ; next if ( ref $id or not $id )
      ; for ( ( my $ii = $i-1                     # find THE start
              , my $l  = 0
              )
            ; $ii >= 0     # condition
            ; ( $ii --
              , $l  ++
              )
            )
         { my $the_start = $temp[$ii][1]
         ; next unless ref($the_start) eq 'HASH'  # next if not start
         ; next unless $$the_start{id} eq $id     # next if not THE start
         ; $$the_start{_s} = $ii + 1
         ; $$the_start{_e} = $ii + $l
         ; last
         }
      }
   # allows to set protected props from outside class
   ; local $Class::props::force = 1
   ; Template::Magic::Zone->new( _s      => 0
                               , _e      => $#temp
                               , _t      => \@temp
                               , is_main => 1
                               )
   }
    

############################# STANDARD HANDLERS #############################

# override these DEFAULT subs in subclasses to change defaults

; sub DEFAULT_ZONE_HANDLERS
   {
   }
   
; sub DEFAULT_POST_HANDLERS
   {
   }
   
; sub DEFAULT_TEXT_HANDLERS
   {
   }

; sub DEFAULT_VALUE_HANDLERS
   { my ($s, @args) = @_
   ; [ $s->SCALAR
     , $s->REF
     , $s->CODE(@args)
     , $s->ARRAY
     , $s->HASH
     , $s->OBJECT
     ]
   }

; sub DEFAULT_PRINT_HANDLERS
   { [ sub
        { print "$_[1]" if defined $_[1]
        ; NEXT_HANDLER
        }
     ]
   }
   
; { no warnings 'once'
  ; *DEFAULT_OUTPUT_HANDLERS = \&DEFAULT_PRINT_HANDLER  # deprecated
  }
  
; sub DEFAULT_OPTIONS
   { [ qw| cache | ]
   }
   
; sub DEFAULT_MARKERS
   { [ qw| { / } | ]
   }
   
; sub HTML_MARKERS
   { [ qw| <!--{ / }--> | ]
   }

; sub CODE_MARKERS
   { [ qw| <- / -> | ]
   }

; sub HTML_VALUE_HANDLERS # value handler
   { my ($s, @args) = @_
   ; [ $s->SCALAR
     , $s->REF
     , $s->CODE(@args)
     , $s->TableTiler
     , $s->ARRAY
     , $s->HASH
     , $s->FillInForm
     , $s->OBJECT
     ]
   }
                                                                           
; sub SCALAR # value handler
   { sub
      { my ($z) = @_
      ; my $v = $z->value
      ; if ( not ref $v )           # if it's a plain string
         { $z->output($v)          # set output
         ; $z->output_process( $v ) # process output (requires string)
         ; LAST_HANDLER
         }
      }
   }

; sub REF # value handler
   { sub
      { my ($z) = @_
      ; my $v = $z->value
      ; if (ref($v) =~ /^(SCALAR|REF)$/)  # if it's a reference
         { $z->value($$v)                # dereference
         ; $z->value_process              # process the new value
         ; LAST_HANDLER
         }
      }
   }
  
; sub ARRAY # value handler
   { sub
      { my ($z) = @_
      ; if (ref $z->value eq 'ARRAY')        # if it's an ARRAY
         { my ($i, $attr, $val_key, $ix_key, $named) = 0
         ; if ( $attr = $z->attributes )
            { $attr =~ s/^\s*(OF\s)*\s*//i
            ; ($val_key, $ix_key, $i) = split /\s+/, $attr
            ; $named = 1
            }
         ; foreach my $item ( @{$z->value} ) # for each value in the array
            { $z->value( $named             # set the value for the zone
                          ? { $val_key => $item
                            , $ix_key ? ($ix_key => $i ++) : ()
                            }
                          : $item
                       )
            ; $z->value_process              # process it
            }
         ; LAST_HANDLER
         }
      }
   }
  
; sub HASH # value handler
   { sub
      { my ($z) = @_
      ; if (ref $z->value eq 'HASH')        # if it's a HASH
         { $z->content_process              # start again the process
         ; LAST_HANDLER
         }
      }
   }
   
; sub CODE # value handler
   { my ( undef, @args ) = @_
   ; sub
      { my ($z) = @_
      ; my $v = $z->value
      ; if ( ref $v eq 'CODE' )
         { my $l = $z->location
         ; my $nv = Class::Util::blessed($l)
                    ? do { no strict 'refs'
                         ; $l->$v( ${ref($l).'::no_template_magic_zone'}
                                   ? ()
                                   : $z
                                 , @args
                                 )
                         }
                    : $v->( $z , @args )
         ; if ( $v ne ($nv||'') ) # avoid infinite loop
            { $z->value($nv)
            ; $z->value_process
            }
         ; LAST_HANDLER
         }
      }
   }

; sub OBJECT
   { sub
      { my ($z) = @_
      ; if ( Class::Util::blessed($z->value) )
         { $z->content_process           # process content
         ; LAST_HANDLER
         }
      }
   }
   
; sub ID_list
   { my ($s, $indent, $end) = @_
   ; $indent ||= ' ' x 4
   ; $end   ||= '/'
   ; my $re   = $s->_re
   ; $$s{text_handlers} = [ sub{} ]  # does not print any text
   ; $$s{zone_handlers}
     = [ sub  # takes control of the whole process
          { my ($z) = @_
          ; $z->output_process( $indent x $z->level
                              . $z->id
                              . ":\n"
                              )
          ; $z->content_process
          ; my $cont = $z->content
          ; if (  $z->_e                               # if it is a block
               && $cont =~ /$$re{label}/         # and contains labels
               )
             { $z->output_process( $indent x $z->level   # print the end
                                 . $end
                                 . $z->id
                                 . ":\n"
                                 )
             }
          ; LAST_HANDLER
          }
       ]
   }
   
# START AutoLoaded handlers

# 'sub' must be at start of line to be found by AutoSplit
#  no fancy coding here :-(

sub _EVAL_ # zone handler
   { sub
      { my ($z) = @_;
      ; if ( $z->id eq '_EVAL_' )
         { $z->value( eval $z->content )
         }
      ; NEXT_HANDLER
      # lookup is skipped by the defined $z->value
      # value_process is entered by default
      }
   }

sub _EVAL_ATTRIBUTES_ # zone handler
   { sub
      { my ($z) = @_
      ; if ( $z->attributes )
         { $z->param( eval $z->attributes )
         }
      ; NEXT_HANDLER
      # $z->attributes should be a ref to a structure
      }
   }

sub TRACE_DELETIONS # zone handler
   { sub
      { my ($z) = @_
      # do lookup and value processes as usual
      ; $z->lookup_process
      ; $z->value_process
      # if they fail to find a true output trace the deletion
      ; if    ( not defined $z->output )
         { $z->output_process ( '<<' . $z->id . ' not found>>' )
           unless ref $z->value eq 'HASH'
         }
        elsif ( not $z->output )
         { $z->output_process ( '<<' . $z->id . ' found but empty>>' )
         }
      ; LAST_HANDLER
      }
   }

sub INCLUDE_TEXT # zone handler
   { sub
      { my ($z) = @_
      ; if ( $z->id eq 'INCLUDE_TEXT' )
         { my $file = $z->attributes
         ; open my $itxt, $file
           or croak qq(Error opening text file "$file": $^E)
         ; $z->text_process($_) while <$itxt>
         ; close $itxt
         ; LAST_HANDLER
         }
      }
   }

############### HTML HANDLERS ##############

sub TableTiler # value handler
   { eval
      { local $SIG{__DIE__}
      ; require HTML::TableTiler
      ; return $HTML::TableTiler::VERSION >= 1.14
      }
   ; if ( $@ )
      { carp qq("HTML::TableTiler" is not installed on this system or it is not current\n)
      ; return sub {}  # no action
      }
     else
      { sub            # normal handler
         { my ($z) = @_
         ; my $v = $z->value
         ; if (  ref($v) eq 'ARRAY'
              && HTML::TableTiler::is_matrix($v)   # if matrix
              )
            { $z->value
              ( do { my $cont = $z->content
                   ; HTML::TableTiler::tile_table( $v
                                                 , $cont && \$cont
                                                 , $z->attributes
                                                 , 1
                                                 )
                   }
              )
            ; $z->value_process
            ; LAST_HANDLER
            }
         }
      }
   }

sub FillInForm # value handler
   { eval
      { local $SIG{__DIE__}
      ; require HTML::FillInForm
      }
   ; if ( $@ )
      { carp qq("HTML::FillInForm" is not installed on this system\n)
      ; sub {}
      }
     else
      { sub
         { my ($z) = @_
         ; my $v = $z->value
         ; if (  ref($v)
              && defined UNIVERSAL::can( $v , 'param' )
              )
            { my $cont = IO::Util::capture { $z->content_process }
            ; my $attr = $z->attributes
            ; my ($list) = $attr =~ /ignore_fields\s*=>\s*\[(.*)\]/
            ; my @if = map /(?:'|")(.+)(?:'|")/  #'
                     , split /\s*,\s*/
                     , $list||''
            ; $z->value( HTML::FillInForm
                         ->new
                         ->fill( scalarref     => $cont
                               , fobject       => $v
                               , ignore_fields => \@if
                               )
                       )
            ; $z->value_process
            ; LAST_HANDLER
            }
         }
      }
   }
   
__END__
   
=pod

=head1 NAME

Template::Magic - Magic merger of runtime values with templates

=head1 VERSION 1.39

Included in Template-Magic 1.39 distribution.

The latest version changes are reported in the F<Changes> file in this distribution.

=head1 INSTALLATION

=over

=item Prerequisites

    Perl version >= 5.6.1
    OOTools      >= 2
    IO::Util     >= 1.46
    File::Spec   >= 0

=item CPAN

If you want to install Template::Magic plus all related extensions (the prerequisites to use also L<Template::Magic::HTML|Template::Magic::HTML>), all in one easy step:

    perl -MCPAN -e 'install Bundle::Template::Magic'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

B<Note>: this installs just the main distribution and does not install the prerequisites of L<Template::Magic::HTML|Template::Magic::HTML>.

=item Distribution structure

    Bundle::Template::Magic      a bundle to install everything in one step
    Template::Magic              the main module
    Template::Magic::Zone        defines the zone object
    Template::Magic::HTML        handlers useful in HTML environment

=back

=head1 SYNOPSIS

Just add these 2 magic lines to your code...

    use Template::Magic;
    Template::Magic->new->print( '/path/to/template' );

to have all your variable and subroutines merged with the F<template> file, or set one or more constructor array to customize the output generation as you need:

    use Template::Magic qw( -compile );
    
    $tm = new Template::Magic
              paths           => [ qw(/any/path /any/other/path) ] ,
              markers         => [ qw( < / > ) ]                   ,
              lookups         => [ \%my_hash, $my_obj, 'main'    ] ,
              zone_handlers   => [ \&my_zone_handler, '_EVAL_'   ] ,
              value_handlers  => [ 'DEFAULT', \&my_value_handler ] ,
              text_handlers   =>   sub {print lc $_[1]}            ,
              output_handlers =>   sub {print uc $_[1]}            ,
              post_handlers   =>   \&my_post_handler               ,
              options         =>   'no_cache'                      ;
    
    $tm->nprint( template => '/path/to/template'
                 lookups  => \%my_special_hash );

=head1 DESCRIPTION

Template::Magic is a "magic" interface between programming and design. It makes "magically" available all the runtime values - stored in your variables or returned by your subroutines - inside a static template file. B<In simple cases there is no need to assign values to the object>. Template outputs are linked to runtime values by their I<identifiers>, which are added to the template in the form of simple I<labels> or I<blocks> of content.

    a label: {identifier}
    a block: {identifier} content of the block {/identifier}

From the designer point of view, this makes things very simple. The designer has just to decide B<what> value and B<where> to put it. Nothing else is required, no complicated new syntax to learn! B<This feature make this template system the perfect choice when the templates file has to be edited by unskilled people>.

On the other side, the programmer has just to define variables and subroutines as usual and their values will appear in the right place within the output. The automatic interface allows the programmer to focus just on the code, saving him the hassle of interfacing code with output, and even complicated output - with complex switch branching and nested loops - can be easily organized by minding just a few simple concepts.

=over

=item 1

The object parses the template and searches for any I<labeled zone>

=item 2

When a I<zone> is found, the object looks into your code and searches for any variable or sub with the same identifier (name)

=item 3

When a match is found the object replaces the label or the block with the value returned by the variable or sub found into your code (dereferencing and/or executing code as needed). (see L<"Understand the output generation"> for details)

=back

B<Note>: If you are planning to use this module in CGI environment, take a look at L<CGI::Builder::Magic|CGI::Builder::Magic> that transparently integrates this module in a very handy and powerful framework.

=head2 Simple example

The following is a very simple example only aimed to better understand how it works: obviously, the usefulness of Template::Magic comes up when the output become more complex.

Imagine you need an output that looks like this template file:

    City: {city}
    Date and Time: {date_and_time}

where {city} and {date_and_time} are just placeholder that you want to be replaced in the output by some real runtime values. Somewhere in your code you have defined a scalar and a sub to return the 'city' and the 'date_and_time' values:

    $city = 'NEW YORK';
    sub date_and_time { localtime }

you have just to add these 2 magic lines to the code:

    use Template::Magic;
    Template::Magic->new->print( 'my_template_file' );

to generate this output:

    City: NEW YORK
    Date and Time: Sat Nov 16 21:03:31 2002

With the same 2 magic lines of code, Template::Magic can automatically look up values from I<scalars>, I<arrays>, I<hashes>, I<references> and I<objects> from your code and produce very complex outputs. The default settings are usually smart enough to do the right job for you, however if you need complete control over the output generation, you can fine tune them by controlling them explicitly. See L<"CUSTOMIZATION"> for details.

=head2 More complex example

=over

=item the template

The template file F<'my_template_file'>... I<(this example uses plain text for clarity, but Template::Magic works with any type of text file)>

    A scalar variable: {a_scalar}.
    A reference to a scalar variable: {a_ref_to_scalar}.
    A subroutine: {a_sub}
    A reference to subroutine: {a_ref_to_sub}
    A reference to reference: {a_ref_to_ref}
    A hash: {a_hash}this block contains a {a_scalar} and a {a_sub}{/a_hash}
    
    A loop:{an_array_of_hashes}
    Iteration #{ID}: {guy} is a {job}{/an_array_of_hashes}
    
    An included file:
    {INCLUDE_TEMPLATE my_included_file}

... and another template file F<'my_included_file'> that will be included...

    this is the included file 'my_included_file'
    that contains a label: {a_scalar}

=item the code

... some variables and subroutines already defined somewhere in your code...

B<Note>: This example uses globals just for simplicity. Please notice that Template::Magic can be used to write sloppy code or very strict code, exactly as perl itself can. Magic lookups is a very handly feature for simple scripts, while it is not recommended for complex script where you should explicitly limit the lookups to some specific package or hash (see L<"lookups">).

    $a_scalar           = 'THIS IS A SCALAR VALUE';
    $a_ref_to_scalar    = \$a_scalar;
    @an_array_of_hashes = ( { ID => 1, guy => 'JOHN SMITH',  job => 'PROGRAMMER' },
                            { ID => 2, guy => 'TED BLACK',   job => 'WEBMASTER' },
                            { ID => 3, guy => 'DAVID BYRNE', job => 'MUSICIAN' }  );
    %a_hash             = ( a_scalar => 'NEW SCALAR VALUE'
                            a_sub    => sub { 'NEW SUB RESULT' } );
    
    sub a_sub         { 'THIS SUB RETURNS A SCALAR' }
    sub a_ref_to_sub  { \&a_sub }
    sub a_ref_to_ref  { $a_ref_to_scalar }

Just add these 2 magic lines...

    use Template::Magic;
    Template::Magic->new->print( 'my_template_file' );

=item the output

I<(in this example Lower case are from templates and Upper case are from code)>:

    A scalar variable: THIS IS A SCALAR VALUE.
    A reference to a scalar variable: THIS IS A SCALAR VALUE.
    A subroutine: THIS SUB RETURNS A SCALAR
    A reference to subroutine: THIS SUB RETURNS A SCALAR
    A reference to reference: THIS IS A SCALAR VALUE
    A hash: this block contains a NEW SCALAR VALUE and a NEW SUB RESULT
    
    A loop:
    Iteration #1: JOHN SMITH is a PROGRAMMER
    Iteration #2: TED BLACK is a WEBMASTER
    Iteration #3: DAVID BYRNE is a MUSICIAN
    
    An included file:
    this is the included file 'my_included_file'
    that contains a label: THIS IS A SCALAR VALUE.

=back

=head2 Features

Since syntax and coding related to this module are very simple and mostly automatic, you should careful read this section to have the right idea about its features and power. This is a list - with no particular order - of the most useful features and advantages:

=over

=item * Simple, flexible and powerful to use

In simple cases, you will have just to use L<new()|"new ( [constructor_arrays] )"> and L<print(template)|"print ( template [, temporary lookups ] )"> methods, without having to pass any other value to the object: it will do the right job for you. However you can fine tune the behaviour as you need. (see L<"CUSTOMIZATION">)

=item * Extremely simple and configurable template syntax

The template syntax is so simple and code-independent that even the less skilled webmaster will manage it without bothering you :-). By default Template::Magic recognizes labels in the form of simple identifiers surrounded by braces (I<{my_identifier}>), but you can easily use different markers (see L<"Redefine Markers">).

=item * Automatic or manual lookup of values

By default, Template::Magic compares any I<label identifier> defined in your template with any I<variable> or I<subroutine identifier> defined in the caller namespace. However, you can explicitly define the lookup otherwise, by passing a list of package namespaces, hash references and blessed objects to the C<lookups> constructor array.

=item * Unlimited nested included templates

Sometimes it can be useful to split a template into differents files. No nesting limit when including files into files. (see L<"Include and process a template file">)

=item * Branching

You can easily create simple or complex if-elsif-else conditions to print just the blocks linked with the true conditions (see L<"Setup an if-else condition"> and L<"Setup a switch condition">)

=item * Unlimited nested loops

When you need complex outputs you can build any immaginable nested loop, even mixed with control switches and included templates (see L<"Build a loop"> and L<"Build a nested loop">)

=item * Scalable and expandable extensions system

You can load only the handlers you need, to gain speed, or you can add as many handlers you will use, to gain features. You can even write your own extension handler in just 2 or 3 lines of code, expanding its capability for your own purpose. (see L<"CUSTOMIZATION"> )

=item * Efficient and fast

The internal rapresentation and storage of templates allows minimum memory requirement and completely avoid wasting copies of content. You can even include external (and probably huge) text files in the output without memory charges. (see L<"Include (huge) text files without memory charges">)

=item * Automatic caching of template files

Under mod_perl it could be very useful to have the template structure cached in memory, already parsed and ready to be used (almost) without any other process. Template::Magic opens and parses a template file only the first time or if the file has been modified.

=item * Perl embedding

Even if I don't encourage this approach, however you can very easily embed any quantity of perl code into any template. (see L<"Embed perl into a template">)

=item * Placeholders and simulated areas

Placeholders and simulated areas can help in designing the template for a more consistent preview of the final output. (see L<"Setup placeholders"> and L<"Setup simulated areas">)

=item * Labels and block list

When you have to deal with a webmaster, you can easily print a pretty formatted output of all the identifiers present in a template. Just add your description of each label and block and save hours of explanations ;-)  (see L<ID_list()|"ID_list ( [indentation_string [, end_marker]] )"> static method)

=item * Simple to maintain

Change your code and Template::Magic will change its behaviour accordingly. In most cases you will not have to reconfigure, either the object, or the template.

=item * Simply portable

This module and its extensions are written in pure perl. You don't need any compiler in order to install it on any platform so you can distribute it with your own applications by just including a copy of its files (in this case just remember to AutoSplit the modules or take off the '__END__').

=back

=head2 Policy

The main principle of Template::Magic is: B<keeping the designing separated from the coding>, giving all the power to the programmer and letting designer do only design. In other words: while the code includes ALL the active and dynamic directions to generate the output, the template is a mere passive and static file, containing just placeholder (zones) that the code will replace with real data.

This philosophy keeps both jobs very tidy and simple to do, avoiding confusion and enforcing clearness, specially when programmer and designer are 2 different people. But another aspect of the philosophy of Template::Magic is flexibility, something that gives you the possibility to easily B<bypass the rules>.

Even if I don't encourage breaking the main principle (keeping the designing separated from the coding), sometimes you might find useful to put inside a template some degree of perl code, or may be you want just to interact DIRECTLY with the content of the template. See L<"Use subroutines to rewrite links"> and L<"Embed perl into a template"> for details.

Other important principles of Template::Magic are scalability and expandability. The whole extension system is built on these principles, giving you the possibility of control the behaviour of this module by omitting, changing the orders and/or adding your own handlers, without the need of subclassing the module. See L<"CUSTOMIZATION">.

=head2 Useful links

=over

=item *

A simple and useful navigation system between my modules is available at this URL: http://perl.4pro.net

=item *

More practical topics are discussed in the mailing list at this URL: http://lists.sourceforge.net/lists/listinfo/template-magic-users

=back

=head1 METHODS

=head2 new ( [constructor_arrays] )

If you use just the defaults, you can construct the new object by writing this:

    $tm = new Template::Magic ;

If you don't pass any parameter to the constructor method, the constructor defaults are usually smart enough to do the right job for you, but if you need complete control over the output generation, you can fine tune it by controlling it explicitly. I<(see the section L<"Constructor Arrays">)>.

=head2 output ( template [, temporary lookups ] )

B<WARNING>: this method is here for historical reasons, but it is not the maximum of efficiency. Please consider to use the L<print()|"print ( template [, temporary lookups ] )"> method when possible I<(see L<"EFFICIENCY">)>. You can also consider to write an I<output handler> that fits your needs but process the output content on the fly and without the need to collect the whole output as this method does.

B<Note:> If you need to use C<Template::Magic> with C<CGI::Application> (that requires the run modes method to collect the whole output) you may use L<CGI::Application::Magic|CGI::Application::Magic> or L<Apache::Application::Magic|Apache::Application::Magic> that transparently integrates the template system with the application and avoid this method.

This method merges the runtime values with the template and returns a reference to the whole collected output. It accepts one I<template> parameter that can be a reference to a SCALAR content, a path to a template file or a filehandle.

This method accepts any number of I<temporary lookups> elements that could be I<package names>, I<blessed objects> and I<hash references> (see L<"lookups"> to a more detailed explanation).

    # template is a path
    $output = $tm->output( '/path/to/template' ) ;
    
    # template is a reference (not efficient but possible)
    $output = $tm->output( \$tpl_content ) ;
    
    # template is a filehandler
    $output = $tm->output( \*FILEHANDLER ) ;
    
    # this adds some lookups location to the print method 
    $my_block_output = $tm->output( '/path/to/template', \%special_hash );


B<Note>: if I<template> is a path, the object will cache it automatically, so Template::Magic will open and parse the template file only the first time or if the file has been modified. If for any reason you don't want to cache the template structure, you can use the 'cache / no_cache' L<"options">.

=head2 noutput ( arguments )

A named arguments interface for the L<output()|"output ( template [, temporary lookups ] )"> method, which add also the possibility to pass the 'container_template' argument.

    $tm->nprint( template => '/path/to/template',
                 lookups  => [ \%special_hash, 'My::lookups'],
                 container_template => '/path/to/container_template') ;

=head2 print ( template [, temporary lookups ] )

This method merges the runtime values with the template and prints the output. It accepts one I<template> parameter that can be a reference to a SCALAR content, a path to a template file or a filehandle.

This method accepts any number of I<temporary lookups> elements that could be I<package names>, I<blessed objects> and I<hash references> (see L<"lookups"> to a more detailed explanation).

    # template is a path
    $tm->print( '/path/to/template' );
    
    # template is a reference (not efficient but possible)
    $tm->print( \$tpl_content ) ;
    
    # template is a filehandler
    $tm->print( \*FILEHANDLER );
    
    # this adds some lookups location to the print method 
    $tm->print( '/path/to/template', \%special_hash );

B<Note>: if I<template> is a path, the object will cache it automatically, so Template::Magic will open and parse the template file only the first time or if the file has been modified. If for any reason you don't want to cache the template structure, you can use the 'cache / no_cache' L<"options">. I<(see L<"EFFICIENCY">)>.

=head2 nprint ( arguments )

A named arguments interface for the L<print()|"print ( template [, temporary lookups ] )"> method, which add also the possibility to pass the 'container_template' argument.

    $tm->nprint( template => '/path/to/template',
                 lookups  => [ \%special_hash, 'My::lookups'],
                 container_template => '/path/to/container_template') ;

=head2 ID_list ( [indentation_string [, end_marker]] )

Calling this method (before the L<output()|"output ( template [, temporary lookups ] )"> or L<print()|"print ( template [, temporary lookups ] )"> methods) will redefine the behaviour of the module, so your program will print a pretty formatted list of only the identifiers present in the template, thus the programmer can pass a description of each label and block within a template to a designer.

The method accepts an I<indentation string> (usually a tab character or a few spaces), that will be used to indent nested blocks. If you omit the indentation string 4 spaces will be used. The method accepts also as second parameter an I<end marker> string, which is used to distinguish the end label in a container block. If you omit this, a simple '/' will be used.

    # defalut
    $tm->ID_list;
    
    # custom indentation
    $tm->ID_list("\t", 'END OF ');

See also L<"Prepare the identifiers description list">.

=head2 load( template )

This method explicitly (pre)loads and parses the template in order to cache it for future use.
You shouldn't need to use this method unless you want to build the cache in advance (e.g the F<startup.pl> for C<mod_perl> advanced users).

=head2 purge_cache ( [template_path] )

Template::Magic opens and parses a template file only the first time or if the file has been modified. Since the template caching is automatic you shouldn't need to use this method under normal situations, anyway with this method you can purge the I<template_path> from the cache. Without any I<template_path> parameter the method purges all the stored templates.

=head2 find_file ( template )

This method is internally used to find the templates you pass with C<print(), nprint(), output(), noutput()> methods or an 'INCLUDE_TEMPLATE' label (and its relative Zone method C<include_template>).

You usually don't need to use this method explicitly, unless you want to check if a template exists on your own. If a non-zero size file exists it returns the path of the found template, or undef if it doesn't.

The I<template> specified can be an absolute path (beginning with a '/' under
Unix, for example). If it isn't absolute, the path in the environment variable
TEMPLATE_MAGIC_ROOT is tried, if it exists. Next the paths in the B<paths> constructor array are tried, first as they are, and then with TEMPLATE_MAGIC_ROOT prepended if available. As a final attempt, the I<template> is checked directly.

=head1 CUSTOMIZATION

B<Note>: You can completely skip this section if you plan to use just the defaults.

The output generation can be completely customized during the creation of the new object by passing to the C<new()> method one or more L<"Constructor Arrays">.

=head2 Constructor Arrays

The new() method accepts one optional hash that can contain the following optionals constructor arrays:

    markers
    lookups
    zone_handlers
    value_handlers
    text_handlers
    output_handlers
    post_handlers
    paths
    options
    container_template

Constructor Arrays are array references containing elements that can completely change the behaviour of the object and even add code not directly related with the output generation but executed during the process.

All the constructor arrays should be array references, but if you have to pass just one element, you can pass it as a plain element as well:

    $tm = new Template::Magic
              lookups => [\%my_hash] ,
              markers => ['HTML_MARKERS'   ] ;
    
    # same thing less noisy
    $tm = new Template::Magic
              lookups => \%my_hash ,
              markers => 'HTML'    ;

All the handlers in C<-*_handlers> I<(zone handlers, value handlers, output handlers, text handlers, post handlers)> receive the I<zone object> as $_[0] parameter. Besides, the I<text handlers> and the I<output handlers> receive also the processed text as $_[1] parameter.

B<Note>: the old constructor arrays identifiers with the prepended '-' and/or the parameters passed as a reference to a hash are deprecated but still working:

    # old style with '-flag' and brackets
    $tm = new Template::Magic
              {
                -markers         =>   qw( < / > )                     ,
                -lookups         => [ \%my_hash, $my_obj, 'main'    ] ,
                -zone_handlers   => [ \&my_zone_handler, '_EVAL_'   ] ,
                -value_handlers  => [ 'DEFAULT', \&my_value_handler ] ,
                -text_handlers   =>   sub {print lc $_[1]}            ,
                -output_handlers =>   sub {print uc $_[1]}            ,
                -post_handlers   =>   \&my_post_handler               ,
              } ;

=head3 paths

Use this constructor array to supply a list of paths to search for templates. This list will be used when you pass a relative path as the template name.

See L<find_file()|find_file ( template )> method for details about how the paths are searched.

=head3 markers

Use this constructor array to define the 3 I<label markers> - START_MARKER, END_MARKER_ID, END_MARKER - you want to use in your template. The C<markers> constructor array can contain a name of L<standard markers>, or a reference to an array containing the 3 explicit markers.

If you want to use the default markers, just call the new() method without any C<markers> constructor array:

    # default markers
    $tm = new Template::Magic;
    
    # same but explicit extension name
    $tm = new Template::Magic
              markers => 'DEFAULT_MARKERS';
    
    # same but 3 explicit default markers
    $tm = new Template::Magic
              markers => [ '{', '/', '}' ] ;
    
    # HTML markers extension name
    $tm = new Template::Magic
              markers => 'HTML_MARKERS' };
    
    # same but 3 explicit HTML markers
    $tm = new Template::Magic
              markers => [ qw( <!--{ / }--> ) ] ;
    
    # custom explicit markers
    $tm = new Template::Magic
              markers => [ qw( __ END_ __ ) ] ;

Since each element of the markers array is parsed as a regular expression as: C<qr/element/>, you can extend the markers beyond a static string marker.

These markers:

    # 3 weird explicit markers
    $tm = new Template::Magic
              markers => [ '<\d+<', '\W', '>' ];

will match these blocks labeled 'identifier':

    <35<identifier> content of block <0<-identifier>
    <26<identifier> content of block <15<#identifier>

You can also pass compiled RE:

    # 3 weird explicit markers
    $start  = qr/<\d+</ ;
    $end_ID = qr/\W/    ;
    $end    = qr/>/     ;
    $tm = new Template::Magic
              markers => [ $start, $end_ID, $end ];

B<Note>: Remember that if the characters you chose as the markers have a special meaning in RE (e.g. the '[' and ']'), you need to escape them as you would do inside a pattern match.

    # this would generate an error
    $tm = Template::Magic->new( markers => [ '[', '/', ']' ] )
    
    # you probably mean this
    $tm = Template::Magic->new( markers => [ '\[', '/', '\]' ] )

=head4 standard markers

Template::Magic offers 3 standard markers: B<DEFAULT_MARKERS>, B<CODE_MARKERS> and B<HTML_MARKERS>:

=over

=item DEFAULT_MARKERS

The default markers:

    START MARKER:  {
    END_MARKER_ID: /
    END_MARKER:    }

Example of block:

    {identifier} content of the block {/identifier}

=item CODE_MARKERS

This markers are useful when you deal with templates which contain code, because they reduces the possible conflict with the content:

    START MARKER:  <-
    END_MARKER_ID: /
    END_MARKER:    ->

Example of block:

    <-identifier-> content of the block <-/identifier->

=item HTML_MARKERS

HTML-comment-like markers. If your output is a HTML text - or just because you prefer that particular look - you can use it instead of using the default markers.

    START MARKER:  <!--{
    END_MARKER_ID: /
    END_MARKER:    }-->

Example of block:

    <!--{identifier}--> content of the block <!--{/identifier}-->

Usage:

    $tm = new Template::Magic
              markers => 'HTML_MARKERS' ;

The main advantages to use it are:

=over

=item *

You can add labels and blocks and the template will still be a valid HTML file.

=item *

You can edit the HTML template with a WYSIWYG editor, keeping a consistent preview of the final output

=item *

The normal HTML comments will be preserved in the final output, while the labels will be wiped out.

=back

If you want to use the HTML handlers too, you could use Template::Magic::HTML. See L<Template::Magic::HTML> for details.

=back

See also L<"Redefine Markers">

=head3 lookups

Use this constructor array to explicitly define where to look up the values in your code. This array can contain B<package names>, B<blessed objects> and B<hash references>. If no lookups construction array is passed, the package namespace of the caller will be used by default.

With B<packages names> the lookup is done with all the IDENTIFIERS (variables and subroutines) defined in the package namespace.

B<Note>: Please, notice that the lexical variables (those declared with C<my>) are unaccessible from outside the enclosing block, file, or eval, so don't expect that the lookup could work with these variables: it is a perl intentional restriction, not a limitation of this module. However, you could declare them  with the old C<vars> pragma or C<our> declaration instead, and the lookup will work as expected.

With B<blessed objects> the lookup is done with all the IDENTIFIERS (variables and methods) defined in the class namespace. B<Note>: Use this type of location when you want to call an object method from a template: the method will receive the blessed object as the first parameter and it will work as expected.

With B<hash references> the lookup is done with the KEYS existing in the hash.

If you want to make available all the identifiers of your current package, just call the constructor without any C<lookups> parameter:

    # default lookup in the caller package
    $tm = new Template::Magic ;
    
    # same thing but explicit
    $tm = new Template::Magic
              lookups => __PACKAGE__ ;

B<Warning>: Template::Magic can be used to write sloppy code or very strict code, exactly as perl itself can. Magic lookups is a very handly feature for simple scripts, while it is not recommended for complex script where you should explicitly limit the lookups to some specific package or hash.

If you want to keep unavailable some variable or subroutine from the template, you can pass just the reference of some hash containing just the identifiers used in the template. This is the best method to use the module IF you allow untrustworthy people to edit the template AND if you have any potentially dangerous subroutine in your code. (see L<"Allow untrustworthy people to edit the template">).

    # lookup in %my_hash only
    $tm = new Template::Magic
              lookups => \%my_hash ;

You can also define an arbitrary list of packages, references to hashes and blessed object as the lookup: the precedence of the lookup will be inherited from the order of the items passed, and the first found mach will return the value.

B<Note>: If you have multiple symbols in your code that maches the label id in your template, don't expect any warning: to be fast, Template::Magic does not check your errors and consider OK the first symbol it founds.

    # lookup in several locations
    $tm = new Template::Magic
              lookups => [ \%my_hash, 'My::Pack', \%my_other_hash ] ;

In this example, the lookup will be done in C<%my_hash> first - if unsuccessful - it will be done in the C<My::Pack> package and - if unsuccessful - it will be done in C<%my_other_hash>.

If you use Template::Magic inside another module, you can pass the blessed object as the location:

    use Template::Magic;
    package Local::foo;
    sub new
    {
        my $s = bless {data=>'THE OBJECT DATA'}, shift;
        $$s{tm} = new Template::Magic
                      lookups => $s;
        $s;
    }
    
    sub method_triggered_by_lookup
    {
        my ($s, $zone) = @_; # correct object passed + zone object
        ...
        $$s{data};
    }

so that if some I<zone identifier> will trigger 'I<method_triggered_by_lookup>', it will receive the blessed object as the first parameter and it will work as expected.

I<(see also L<Template::Magic::Zone/"lookup_process()">)>.

=head4 Temporary Lookups

You can also pass some temporary lookups along with the print(), nprint(), output(), noutput() methods (i.e. lookups that will be used only for one template processing). This capability is useful when you want to use the same object but you don't want to use the same lookups e.g. to have some sort of lookup inheritance as this:

   $tm = new Template::Magic
             lookups => \%general_hash ;
   
   # in sub 1
   $tm->nprint( template => '/path/to/template1' ,
                lookups  => \%special_hash1    ) ;
   # lookup done in %special_hash1 and then in %general_hash
   
   # in sub 2
   $tm->nprint( template => '/path/to/template2' ,
                lookups  => \%special_hash2    ) ;
   # lookup done in %special_hash2 and then in %general_hash

=head3 zone_handlers

Use this constructor array to add handlers to manage the output generation before any other process (even before the C<lookup_process()>). The zone handlers are executed just after the creation of the new zone, so you can even bypass or change the way of calling the other processes.

This constructor array can contain B<code references> and/or B<standard zone handlers names> (resulting in one or more code references: see L<standard zone handlers> for details.

The default C<zone_handler> is undefined, so you must add explicitly any standard zone handler or your own handler in order to use it.

    $tm = new Template::Magic
              zone_handlers => [ '_EVAL_'           ,
                                 '_EVAL_ATTRIBUTES' ,
                                 'INCLUDE_TEXT'     ,
                                  \&my_handler      ] ;

B<Note>: If you write your own custom I<zone_handler>, remember that it must return a true value to end the C<zone_process>, or a false value to continue the C<zone_process>. In other words: if your I<zone_handler> has taken the control of the whole process it must return true, so the other processes (i.e. C<lookup_process> and C<value_process>) will be skipped, while if you want to continue the normal process your I<zone_handler> must return false.

To simplify things you can import and use the constants C<NEXT_HANDLER> and C<LAST_HANDLER> that are more readable and simpler to remember (see L<"Constants">).

(see also L<Template::Magic::Zone/"zone_process()">)

=head4 standard zone handlers

=over

=item _EVAL_

This handler sets the C<value> property to the evalued result of the I<zone content> when the I<zone identifier> is equal to '_EVAL_'

B<WARNING>: For obvious reasons you should use this zone handler ONLY if you are the programmer AND the designer.

This handler is useful if you want a cheap way to embed perl code in the template. (see L<"Embed perl into a template">)

=item _EVAL_ATTRIBUTES_

This handler sets the C<param> property to the evalued result of the I<zone attributes>

B<WARNING>: For obvious reasons you should use this zone handler ONLY if you are the programmer AND the designer.

This handler is useful if you want to pass some structure to a sub from the template without writing a parser: you will have the structure available in $z->param. (see L<"Pass a structure to a subroutine">)

=item TRACE_DELETIONS

This handler generates a diagnostic output for each zone that has not generated any output. It will output a string like <my_zone_id not found> or <my_zone_id found but empty> in place of the zone, so you can better understand what's going on.

=item INCLUDE_TEXT

This handler adds the possibility to include in the output a (probably huge) text file, without having to keep it in memory as a template, and without any other parsing.

It works with the I<zone identifier> equal to 'INCLUDE_TEXT' and the I<zone attributes> equal to the file path to include. It passes each line in the file to the C<text_process> method and bypass all the other processs.

(see L<"Include (huge) text files without memory charges">)

B<Note>: Since this handler bypasses every other process, it is useful only for text output. If you need to include and parse a real template file see L<"Include and process a template file">.

=back

=head3 value_handlers

Use this constructor array to explicitly define or modify the way the object finds the value in your code.

This constructor array can contain B<code references> and/or B<standard value handlers names> (resulting in one or more code references: see L<standard value handlers> for details).

If you don't pass any C<value_handler> constructor array, the default will be used:

    $tm = new Template::Magic;
    
    # means
    $tm = new Template::Magic
              value_handler => 'DEFAULT' ;

    # that expicitly means
    $tm = new Template::Magic
          value_handlers => [ qw( SCALAR REF CODE ARRAY
                                  HASH OBJECT ) ] ;

Where 'DEFAULT', 'SCALAR', 'REF', 'CODE', 'ARRAY', 'HASH', 'OBJECT' are I<standard value handlers names>.

You can add, omit or change the order of the elements in the array, fine tuning the behaviour of the object.

    $tm = new Template::Magic
              value_handlers => [ 'DEFAULT', \&my_handler ] ;
    
    # that explicitly means
    $tm = new Template::Magic
              value_handlers => [ 'SCALAR'     ,
                                  'REF'        ,
                                  'CODE'       ,
                                  'ARRAY'      ,
                                  'HASH'       ,
                                  'OBJECT'
                                  \&my_handler ] ;
    
    # or you can add, omit and change the order of the handlers
    $tm = new Template::Magic
              value_handlers => [ 'SCALAR',
                                  'REF',
                                  \&my_handler,
                                  'ARRAY',
                                  'HASH',
                                  'OBJECT'
                                ] ;

B<Note>: If you write your own custom I<value_handler>, remember that it must return a true value to end the C<value_process>, or a false value to continue the C<value_process>.

To simplify things you can import and use the constants C<NEXT_HANDLER> and C<LAST_HANDLER> that are more readable and simpler to remember (see L<"Constants">).
(see also L<Template::Magic::Zone/"value_process()">)

=head4 standard value handlers

=over

=item DEFAULT

This is the shortcut for the default collection of value handlers that defines the following handlers:

    SCALAR
    REF
    CODE
    ARRAY
    HASH
    OBJECT

All the default values are based on a condition that checks the found value.

=item SCALAR

A I<SCALAR> value sets the C<output> property to the value, and pass it to the C<output_process> ending the C<value_process> method.

=item REF

A I<REFERENCE> value (SCALAR or REF) sets the C<value> property to the dereferenced value and start again the C<value_process()> method

=item CODE

A I<CODE> value sets the C<value> property to the result of the execution of the code and start again the C<value_process()> method. The subroutine will receive the I<zone object> as a parameter.

If you want to avoid the execution of code, triggered by some identifier, just explicitly omit this handler

    $tm = new Template::Magic
              value_handlers => [ qw( SCALAR REF ARRAY
                                      HASH OBJECT ) ] ;

See L<"Avoid unwanted executions"> for details. See also L<"Pass parameters to a subroutine">

=item ARRAY

This handler generates a loop, merging each value in the array with the I<zone content> and replacing the I<zone> with the sequence of the outputs. I<(see L<"Build a loop">, L<"Build a nested loop"> and L<"Build a simple loop"> for details)>.

=item HASH

A B<HASH> value type will set that HASH as a B<temporary lookup> for the I<zone>. Template::Magic first uses that hash to look up the identifiers contained in the block; then, if unsuccessful, it will search into the other elements of the C<lookups> constructor array. This handler is usually used in conjunction with the ARRAY handler to generate loops. I<(see L<"Build a loop"> and L<"Build a nested loop"> for details)>.

=item OBJECT

An B<OBJECT> value type causes the object itself to be used as the temporary lookup for the zone (usually a block ;-). First Template::Magic will try all the label contained in the block as a method of the object; if unsuccessful, it will search into the other elements of the C<lookups> constructor array.

=back

=head3 output_handlers

If you need to change the way the output is processed, you can add your own handler.

This constructor array can contain B<code references> and/or B<standard output handlers names> (resulting in one or more code references: see L<standard output handlers> for details).

If you want to use the default I<output handler>, just call the new() method without any C<output_handler> constructor array:

    $tm = new Template::Magic;
    
    # this means (if you are using print() method)
    $tm = new Template::Magic
              output_handler => 'DEFAULT_PRINT_HANDLER';
    
    # or means (if you are using output() method)
    $tm = new Template::Magic
              output_handler => 'DEFAULT_OUTPUT_HANDLER' ;


B<Note>: If you write your own custom I<output_handler>, remember that it must return a true value to end the C<output_process>, or a false value to continue the C<output_process>.

To simplify things you can import and use the constants C<NEXT_HANDLER> and C<LAST_HANDLER> that are more readable and simpler to remember (see L<"Constants">).

(see also L<Template::Magic::Zone/"output_process()">)

=head4 standard output handlers

=over

=item DEFAULT_PRINT_HANDLER

This handler is set by default by the C<print()> method. It receives and print each chunk of output that comes from the output generation.

This is the code of the print handler:

    sub{ print $_[1] if defined $_[1]; NEXT_HANDLER}

=item DEFAULT_OUTPUT_HANDLER

Deprecated handler. Use the C<DEFAULT_PRINT_HANDLER> instead.

=back

=head3 text_handlers

Use this constructor array only if you want to process the text coming from the template in a different way from the text coming from the code.

This constructor array can contain B<code references> and/or B<standard output handlers names> (resulting in one or more code references: see L<standard output handlers> for details).

If you don't set any I<text handler>, the current I<output handlers> will be used.

B<Note>: If you write your own custom I<text_handler>, remember that it must return a true value to end the C<text_process>, or a false value to continue the C<text_process>.

To simplify things you can import and use the constants C<NEXT_HANDLER> and C<LAST_HANDLER> that are more readable and simpler to remember (see L<"Constants">).

(see also L<Template::Magic::Zone/"text_process()">)

=head3 post_handlers

Use this constructor array only if you want to clean up or log processes just before a zone goes out of scope. (see also L<Template::Magic::Zone/"post_process()">)

B<Note>: This constructor array can contain B<code references>.

B<Note>: If you write your own custom I<post_handler>, remember that it must return a true value to end the C<post_process>, or a false value to continue the C<post_process>.

To simplify things you can import and use the constants C<NEXT_HANDLER> and C<LAST_HANDLER> that are more readable and simpler to remember (see L<"Constants">).

(see also L<Template::Magic::Zone/"post_process()">)

=head3 options

Use this constructor array to pass some boolean value like 'cache' or 'no_cache'.

=over

=item cache / no_cache

Control the caching of the templates structures. 'cache' is the default, so you don't need to explicitly use it in order to cache the template. Use 'no_cache' to avoid the caching.

=back

=head3 container_template

You can pass a generic template which will be used as a sort of frame for all the printed templates. It can be set to one I<template> parameter that can be a reference to a SCALAR content, a path to a template file or a filehandle.

(See L<"Surrounding the output with a container template">)

=head3 Constants

If you write your own handler you can find useful a couple of constants that you can import:

=over

=item * NEXT_HANDLER (false)

=item * LAST_HANDLER (true)

=back

    use Template::Magic qw(NEXT_HANDLER LAST_HANDLER);
    
    sub my_handler
    {
      my ($zone) = @_ ;
      if (some_condition)
      {
        do_something ;
        LAST_HANDLER ;
      }
      else
      {
        NEXT_HANDLER ;
      }
    }


=head1 HOW TO...

This section is oriented to suggest you specific solutions to specific needs. If you need some more help, feel free to send me a message.

=head2 Understand the output generation

By default the output will be generated by the found I<value type>, that means that differents value types will cause different behaviour in generating the output. In details:

=over

=item *

A B<SCALAR> value type will B<replace> the I<zone> with the scalar value.

=item *

A B<REFERENCE> value will be B<dereferenced>, and the value returned will be checked again to apply an appropriate handler

=item *

A B<CODE> value type will be B<executed>, and the value returned will be checked again to apply an appropriate handler

=item *

An B<ARRAY> value type will B<generate a loop>, merging each value in the array with the I<zone content> and replacing the I<zone> with the sequence of the outputs.

=item *

A B<HASH> value type will set that HASH as a B<temporary lookup> for the I<zone>. Template::Magic first uses that hash to look up the identifiers contained in the block; then, if unsuccessful, it will search into the other elements of the C<lookups> constructor array.

=item *

An B<OBJECT> value type causes the object itself to be used as the temporary lookup for the zone (usually a block ;-). First Template::Magic will try all the label contained in the block as a method of the object; if unsuccessful, it will search into the other elements of the C<lookups> constructor array.

= item *

Finally, if no value are found in the code, the I<zone> will be B<deleted>.

=back

These are some examples of default value handlers:

The same template: '{block}|before-{label}-after|{/block}'

    ... with these values...               ...produce these outputs
    ------------------------------------------------------------------------
    $label = 'THE VALUE';            >
    $block = undef;
    ------------------------------------------------------------------------
    $label = 'THE VALUE';            >  NEW CONTENT
    $block = 'NEW CONTENT';
    ------------------------------------------------------------------------
    $label = 'THE VALUE';            >  |before-THE VALUE-after|
    $block = {};
    ------------------------------------------------------------------------
    $label = undef;                  >  |before--after|
    $block = {};
    ------------------------------------------------------------------------
    $label = 'THE VALUE';            >  |before-NEW VALUE-after|
    %block = (label=>'NEW VALUE');
    ------------------------------------------------------------------------
    $label = 'THE VALUE';            >  |before-NEW VALUE-after|
    $block = {label=>'NEW VALUE'};
    ------------------------------------------------------------------------
    $label = 'THE VALUE';            >  NEW CONTENT|before-THE VALUE-after|
    @block = ('NEW CONTENT',            |before-NEW VALUE-after|
              {},
              {label=>'NEW VALUE'});
    ------------------------------------------------------------------------
    $label = 'THE VALUE';            >  NEW CONTENT|before-THE VALUE-after|
    $block = ['NEW CONTENT',            |before-NEW VALUE-after|
              {},
              {label=>'NEW VALUE'}];
    ------------------------------------------------------------------------
    sub label { scalar localtime }   >  |before-Tue Sep 10 14:52:24 2002-
    $block = {};                        after|
    ------------------------------------------------------------------------
    $label = 'THE VALUE';            >  |BEFORE-{LABEL}-AFTER|
    sub block { uc shift }
    ------------------------------------------------------------------------
    package Local::Foo
    sub new {bless {}, shift}
    sub label {my $s = shift; 'NEW VALUE from '.$s}
    
    package main
    $block = Local::Foo->new         
                 >  |before-NEW VALUE from Local::Foo=HASH(0x1957934)-after|
    ------------------------------------------------------------------------

Different combinations of I<values> and I<zones> can easily produce complex outputs: see the other topics in this section.

=head2 Use template directories

You can set the $ENV{TEMPLATE_MAGIC_ROOT} or use the paths constructor array to pass a list of directories to use when searching the template.

See L<find_file()|find_file ( template )> method for details about how the paths are searched.

=head2 Include and process a template file

To include a file in a template use the I<INCLUDE_TEMPLATE> label passing the file path as the label attribute:

    {INCLUDE_TEMPLATE /temp/footer.html}

The  F<'/temp/footer.html'> file will be included in place of the label and it will be processed (and automatically cached) as usual.

B<WARNING>: An icluded template is processed as it was a complete template, this means that a I<block> should be always ended with an I<end label> in the same template. In other words I<blocks> cannot cross the boundary of the file they belong to, or unpredictable behaviours could occur.

=head2 Conditionally include and process a template file

Sometimes it may be useful to include a template only if a condition is true. To do so you can use the $zone->include_template method that works exacly as the I<INCLUDE_TEMPLATE> label, but it is triggered from inside your code instead of the template itself:

    sub include_if_some_condition
    {
      my $zone = shift
      if ( some_condition )
      {
        return $zone->include_template('/path/to/template')
      }
      else # may be you want just return ''
      {
         return 'template not included'
      }
    }

The template:

    this is the template {include_if_some_condition} end template

=head2 Surrounding the output with a container template

Sometime you may have headers and footers to add to a single or all the templates you want to print. You can use the 'container_template' argument, to pass the container template to the object constructor or to the C<noutput>  or C<nprint> methods:

    # will work with all the outputs
    $tm = new Template::Magic
              container_template => '/path/to/container_template';
    
    $tm->print('/path/to/template');
    
    # will work just for a single output
    $tm = new Template::Magic
    
    $tm->nprint(container_template => '/path/to/container_template',
               template => '/path/to/template' );

The container template file is a regular template, but MUST include an INCLUDE_TEMPLATE label B<without any attribute>: the original template will be used as the included template:

   An header
   {INCLUDE_TEMPLATE}
   a footer

The template file:

   The template content

The output:

   An header
   The template content
   a footer

=head2 Include (huge) text files without memory charges

To include in the output a (probably huge) text file, without having to keep it in memory as a template, and without any other parsing, add the L<INCLUDE_TEXT> I<zone handler> and add a label with the I<zone identifier> equal to 'INCLUDE_TEXT' and the I<zone attributes> equal to the file path to include.

    $tm = new Template::Magic
              zone_handlers => 'INCLUDE_TEXT' ;

The template label:

    {INCLUDE_TEXT /path/to/text/file}

B<Note>: do not use quotes!

=head2 Redefine Markers

=over

=item by explicitly define the markers constructor parameter

    # redefine the markers as needed
    $tm = new Template::Magic
              markers => [ qw( <- / -> ) ] ;

=item by using standard markers

The standard installation comes with a HTML friendly L<"standard markers"> that implements a HTML-comment-like syntax. If your output is an HTML text - or just because you prefer that particular look - you can use it instead of using the default markers.

    $tm = new Template::Magic
              markers => 'HTML_MARKERS' ;
    
    # that means
    $tm = new Template::Magic
              markers => [ qw( <!--{ / }--> ) ] ;

=back

See L<"markers"> constructor array for details.

=head2 Setup a template

A quick way to setup a template in 4 simple steps is the following:

=over

=item 1 Prepare an output

Prepare a complete output as your code could print. Place all the static items of your output where they should go, place placeholders (any runtime value that your code would supply) where they should go and format everything as you want

=item 2 Choose names

Choose meaningful names (or variables and subroutines names if you already have a code) for labels and blocks

=item 3 Insert single labels

Find the dynamic items in the template and replace them with a label, or if you want to keep them as visible placeholders, transform each one of them into a block

=item 4 Define blocks

If you have any area that will be repeated by a loop or that will be printed just under certain conditions transform it into a block.

=back

=head2 Setup placeholders

These are a couple of templates that use a HTML friendly sintax. The output will be the same for both templates, with or without placeholders: the difference is the way you can look at the template.

=over

=item template without placeholders

    <p><hr>
    Name: <b style="color:blue"><!--{name}--></b><br>
    Surname: <b style="color:blue"><!--{surname}--></b>
    <hr></p>

This is what you would see in a WYSIWYG editor: I<(you should be using a browser to see the example below this line)>

=for html
<p><hr>Name: <b style="color:blue"><!--{name}--></b><br>
Surname: <b style="color:blue"><!--{surname}--></b><hr></p>

=item template with placeholders

The placeholders "John" and "Smith" are included in blocks and will be replaced by the actual values of 'name' and 'surname' from your code.

    <p><hr>
    Name: <b style="color:blue"><!--{name}-->John<!--{/name}--></b><br>
    Surname: <b style="color:blue"><!--{surname}-->Smith<!--{/surname}--></b>
    <hr></p>

This is what you would see in a WYSIWYG editor: I<(you should be using a browser to see the example below this line)>

=for html
<p><hr>Name: <b style="color:blue"><!--{name}-->John<!--{/name}--></b><br>
Surname: <b style="color:blue"><!--{surname}-->Smith<!--{/surname}--></b><hr></p>

=back

=head2 Setup simulated areas

If you want to include in your template some area only for design purpose I<(for example to see, right in the template, how could look a large nested loop)>, just transform it into a block and give it an identifier that will never be defined in your code.

    {my_simulated_area} this block simulates a possible output
    and it will never generate any output {/my_simulated_area}

=head2 Setup labeled areas

If you want to label some area in your template I<(for example to extract the area to mix with another template)>, just transform it into a block and give it an identifier that will always be defined in your code. A convenient way to do so is to define a reference to an empty hash. This will generate the output of the block and (since the hash does not contain any keys) the lookup will fallback to the I<containers> zones and the I<lookups> locations.

=over

=item the code

    $my_labeled_area = {}  ;  # a ref to an empty hash

=item the template

    {my_labeled_area}
    this block will always generate an output
    {/my_labeled_area}

=back

=head2 Build a loop

=over

=item the template

A loop is represented by a block, usually containing labels:

    A loop:
    {my_loop}-------------------
    Date: {date}
    Operation: {operation}
    {/my_loop}-------------------

=item the code

You should have some array of hashes (or a reference to) defined somewhere:

    $my_loop = [
                  {
                      date      => '8-2-02',
                      operation => 'purchase'
                  },
                  {
                      date      => '9-3-02',
                      operation => 'payment'
                  }
                ] ;

=item the output

    A loop:
    -------------------
    Date: 8-2-02
    Operation: purchase
    -------------------
    Date: 9-3-02
    Operation: payment
    -------------------

=back

=head2 Build a nested loop

=over

=item the template

A nested loop is represented by a block nested into another block:

    A nested loop:
    {my_nested_loop}-------------------
    Date: {date}
    Operation: {operation}
    Details:{details}
               - {quantity} {item}{/details}
    {/my_nested_loop}-------------------

Notice that the block I<'details'> is nested into the block I<'my_nested_loop'>.

=item the code

You should have some array nested into some other array, defined somewhere:

    # a couple of nested "for" loops may produce this:
    $my_nested_loop = [
                         {
                            date      => '8-2-02',
                            operation => 'purchase',
                            details   => [
                                            {
                                               quantity => 5,
                                               item     => 'balls'
                                             },
                                             {
                                               quantity => 3,
                                               item     => 'cubes'
                                             },
                                             {
                                               quantity => 6,
                                               item     => 'cones'
                                             }
                                         ]
                         },
                         {
                            date      => '9-3-02',
                            operation => 'payment',
                            details   => [
                                            {
                                               quantity => 2,
                                               item     => 'cones'
                                             },
                                             { quantity => 4,
                                               item     => 'cubes'}
                                         ]
                          }
                      ] ;

Notice that the value of the keys I<'details'> are a reference to an array of hashes.

=item the output

    A nested loop:
    -------------------
    Date: 8-2-02
    Operation: purchase
    Details:
              - 5 balls
              - 3 cubes
              - 6 cones
    -------------------
    Date: 9-3-02
    Operation: payment
    Details:
              - 2 cones
              - 4 cubes
    -------------------

=back

=head2 Build a simple loop

This is a new feature implemented in Template::Magic 1.32, that allows the direct handling of array items in loops (i.e. you can use an array of strings instead of an array of hashes containing a named string).

When the loop contains just a label, you can also directly use the items of any array, eventually using also the relative index number:

=over

=item the code

You should have some array defined somewhere:

    $my_loop = [ qw( ball cube cone ) ] ;

=item the template

A loop is represented by a block, usually containing labels. This loop defines as 'product' the label representing each array item, the progressive count as 'line_number' and the starting count at 1:

    A loop:
    {my_loop OF product line_number 1}-------------------
    {line_number} - Product: {product}
    {/my_loop}-------------------

=item the output

    A loop:
    -------------------
    1 - Product: ball
    -------------------
    2 - Product: cube
    -------------------
    3 - Product: cone
    -------------------

=back

B<Note>: any loop that directly uses the values of any array, can be written as:

=over

=item {my_array}

this is used only when the array items are reference to hashes (see L<"Build a loop"> or L<"Build a nested loop">)

=item {my_array OF anything index 1}

this defines as 'anything' the label representing each array item, the progressive count as 'index' and the starting count will start at 1

=item {my_array OF anything index}

if you omit the starting count value, it will start at 0

=item {my_array OF anything}

if you don't use any progressive count inside the block you may omit it

=item {my_array anything}

you can also omit the 'OF' (case insensitive) keyword in all the above cases

=back

=head2 Process (huge) loops iteration by iteration

Usually a loop is built just by an array of hashes value (see L<"Build a loop">). This means that you have to fill an array with all the hashes BEFORE the process starts. In normal situations (i.e. the array contains just a few hashes) this is not a problem, but if the array is supposed to contain a lot of hashes, it could be more efficient by creating each hash just DURING the process and not BEFORE it (i.e. without storing it in any array).

For example imagine that in the L<"Build a loop"> example, the array comes from a huge file like this:

    8-2-02|purchase
    9-3-02|payment
    ... some hundred lines

You could generate the output line by line with a simple sub like this:

    sub my_loop
    {
      my ($z) = @_ ;
      open FILE, '/path/to/data/file' ;
      while (<FILE>) # for each line of the file
      {
        chomp ;
        my $line_hash ;
        @$line_hash{'date', 'operation'} = split /\|/ ;  # create line hash
        $z->value = $line_hash ;                         # set the zone value
        $z->value_process() ;                            # process the value
      }
    }

This way you don't waste memory to store the data for all the iteration into the array: you just use the memory needed for one iteration at a time.

=head2 Setup an if-else condition

=over

=item the template

An if-else condition is represented with 2 blocks

    {OK_block}This is the OK block, containig {a_scalar}{/OK_block}
    {NO_block}This is the NO block{/NO_block}

=item the code

Remember that a block will be deleted if the lookup of the identifier returns the UNDEF value, so your code will determine what block will generate output (defined identifier) and what not (undefined identifier).

    if ($OK) { $OK_block = {a_scalar => 'A SCALAR VARIABLE'} }
    else     { $NO_block = {} }

Same thing here:

    $a_scalar = 'A SCALAR VARIABLE';
    $OK ? $OK_block={} : $NO_block={};

=item the output

A true C<$OK> would leave undefined C<$NO_block>, so it would produce this output:

    This is the OK block, containig A SCALAR VARIABLE

A false $OK would leave undefined C<$OK_block>, so it would produce this output:

    This is the NO block

Notice that C<$OK_block> and C<$NO_block> should not return a SCALAR value, that would replace the whole block with the value of the scalar.

=back


=head2 Use the NOT_* blocks

This is a new feature implemented in Template::Magic 1.2, that allows to simplify the if-else handling for any zone. It is intended to be used only in such case (if-else), and in such order (first the * block and next the NOT_* block); for any other use, please refer to L<"Setup an if-else condition">.

For any zone you can use a NOT_* zone (where '*' stands for the zone id) which  will automatically be printed if the zone is not printed, or wiped out if the zone is printed.

The above example could be written also this way:

=over

=item the template

   {OK_block}This is the OK block, containig {a_scalar}{/OK_block}
   {NOT_OK_block}This is the NOT_OK_block, containig {a_scalar},
   and printed automatically if the OK_block will not be printed
   {/NOT_OK_block}

=item the code

   $a_scalar = 'A SCALAR VARIABLE';
   $OK_block = any_condition() ? {} : ''

=item the output

A true C<any_condition()> whould set the C<$OK_block> to an empty hash reference, thus printing

   This is the OK block, containig A SCALAR VARIABLE

While a false C<any_condition()> whould wipe out the C<OK_block>, thus automatically printing the C<NOT_OK_block>.

   This is the NOT_OK_block, containig A SCALAR VARIABLE,
   and printed automatically if the OK_block will not be printed

=back

=head2 Setup a switch condition

=over

=item the template

A simple switch (if-elsif-elsif) condition is represented with multiple blocks:

    {type_A}type A block with {a_scalar_1}{/type_A}
    {type_B}type B block with {a_scalar_2}{/type_B}
    {type_C}type C block with {a_scalar_1}{/type_C}
    {type_D}type D block with {a_scalar_2}{/type_D}

=item the code

Your code will determine what block will generate output (defined identifier) and what not (undefined identifier). In the following example, value of C<$type>  will determine what block will produce output, then the next line will define C<$type_C> using a symbolic reference:

    $type  = 'type_C';
    $$type = { a_scalar_1 => 'THE SCALAR 1',
               a_scalar_2 => 'THE SCALAR 2' };

Same thing yet but with a different programming style:

    $a_scalar_1 = 'THE SCALAR 1';
    $a_scalar_2 = 'THE SCALAR 2';
    $type       = 'type_D';
    $$type      = {};

Same thing without using any symbolic reference:

    $type           = 'type_D';
    $my_hash{$type} = { a_scalar_1 => 'THE SCALAR 1',
                        a_scalar_2 => 'THE SCALAR 2' };
    $tm = new Template::Magic
              lookups => \%my_hash ;

=item the output

A C<$type> set to 'type_C' would produce this output:

    type C block with THE SCALAR 1

A C<$type> set to 'type_D' would produce this output:

    type D block with THE SCALAR 2

=back

=head2 Pass parameters to a subroutine

Template::Magic can execute subroutines from your code: when you use a zone identifier that matches with a subroutine identifier, the subroutine will receive the I<zone object> as a parameters and will be executed. This is very useful when you want to return a modified copy of the template content itself, or if you want to allow the designer to pass parameter to the subroutines.

This example show you how to allow the designer to pass some parameters to a subroutine in your code. The 'matrix' sub, used in the example, receives the parameters written in the template and generates just a table filled of 'X'.

=over

=item the template

    {matrix}5,3{/matrix}

The content of 'matrix' block ('5,3') is used as parameter

=item the code

    sub matrix
    {
        my ($zone) = @_;
        my ($column, $row) = split ',' , $zone->content; # split the parameters
        my $out;
        for (0..$row-1) {$out .= 'X' x $column. "\n"};
        $out;
    }

The sub 'matrix' receive the reference to the I<zone object>, and return the output for the block

=item the output

    XXXXX
    XXXXX
    XXXXX

=back

The same example with named parameters, could be written as follow:

=over

=item the template

    {matrix columns => 5, rows => 3}

The attributes string of 'matrix' label (' columns => 5, rows => 3') is used as parameter

=item the code

    sub matrix
    {
        my ($zone) = shift;
        my $attributes = $zone->attributes;
        $attributes =~ tr/ //d; # no spaces
        my %attr = split /=>|,/, $attributes; # split the parameters
        my $out;
        for (0..$attr{rows}-1) {$out .= 'X' x $attr{columns} . "\n"};
        $out;
    }

The sub 'matrix' receive the reference to the I<zone object>, and return the output for the block

=item the output

    XXXXX
    XXXXX
    XXXXX

=back

=head2 Pass a structure to a subroutine

You can use the '_EVAL_ATTRIBUTES_' zone handler to pass complex named structures to a subroutine.

A simple example that use the '_EVAL_ATTRIBUTES_' zone handler could be:

    $tm = new Template::Magic
              markers       => ['<<', '/', '>>']   , # to avoid conflict
              zone_handlers => '_EVAL_ATTRIBUTES_' ;

This is a possible example of template:

    text <<my_sub {color => 'red', quantity => 2}>> text

The '_EVAL_ATTRIBUTES_' zone handler set the C<param> property to the evalued I<attributes string> C<< {color => 'red', quantity => 2} >> in the template, so you can use it directly in your sub:
    
    sub my_sub
    {
      my ($z) = @_ ;
      'The color is '. $z->param->{color}
      . ' the quantity is '. $z->param->{quantity}
    }

B<WARNING>: You should use '_EVAL_ATTRIBUTES_' handler ONLY if you are the programmer AND the designer.

=head2 Use subroutines to rewrite links

If you use a block identifier that matches with a subroutine identifier, the subroutine will receive the content of the block as a single parameter and will be executed. This is very useful when you want to return a modified copy of the template content itself.

A typical application of this capability is the template of a HTML table of content that point to several template files. You can use the capabilities of your favourite WYSIWYG editor to easily link each menu in the template with each template file. By doing so you will generate a static and working HTML file, linked with the other static and working HTML template files. This will allow you to easily check the integrity of your links, and preview how the links would work when utilized by your program.

Then a simple C<modify_link> subroutine - defined in your program - will return a self-pointing link that will be put in the output in place of the static link. See the example below:

=over

=item the template

    <p><a href="<!--{modify_link}-->add.html<!--{/modify_link}-->">Add Item
    </a></p>
    <p>
    <a href="<!--{modify_link}-->update.html<!--{/modify_link}-->">Update Item
    </a></p>
    <p>
    <a href="<!--{modify_link}-->delete.html<!--{/modify_link}-->">Delete Item
    </a></p>

Working links pointing to static templates files (useful for testing and preview purpose, without passing through the program)

=item the code

    sub modify_link
    {
        my ($zone) = shift;
        my ($content) = $zone->content;
        $content =~ m|([^/]*).html$|;
        return '/path/to/myprog.cgi?action='.$content;
    }

=item the output

    <p><a href="/path/to/myprog.cgi?action=add">Add Item</a></p>
    <p><a href="/path/to/myprog.cgi?action=update">Update Item</a></p>
    <p><a href="/path/to/myprog.cgi?action=delete">Delete Item</a></p>

Working links pointing to your program, defining different query strings.

See also L<"Pass parameters to a subroutine">.

=back

=head2 Prepare the identifiers description list

If you have to pass to a webmaster the description of every identifier in your program utilized by any label or block, Template::Magic can help you by generating a pretty formatted list of all the identifiers (from labels and blocks) present in any output printed by your program. Just follow these steps:

=over

=item 1 Add the following line anywhere before printing the output:

    $tm->ID_list;

=item 2 Capture the outputs of your program

Your program will run exactly the same way, but instead of print the regular outputs, it will print just a pretty formatted list of all the identifiers present in any output.

=item 3 Add the description

Add the description of each label and block to the captured output and give it to the webmaster.

=back

=head2 Allow untrustworthy people to edit the template

F<Magic.pm> does not use any eval() statement and the allowed characters for identifiers are only alphanumeric C<(\w+)>, so even dealing with tainted templates it should not raise any security problem that you wouldn't have in your program itself.

=head3 Avoid unwanted executions

This module can execute the subroutines of your code whenever it matches a label or block identifier with the subroutine identifier. Though unlikely, it is possible in principle that someone (only if allowed to edit the template) sneaks the correct identifier from your code, therefore, if you have any potentially dangerous subroutine in your code, you should restrict this capability. To do this, you can omit the C<CODE> value handler, or pass only explicit locations to the C<new()> method.

=over

=item potentially unsafe code

    sub my_potentially_dangerous_sub { unlink 'database_file' };
    $name = 'John';
    $surname = 'Smith';
    
    # automatic lookup in __PACKAGE__ namespace
    $tm = new Template::Magic ;

With this code, a malicious person allowed to edit the template could add the label I<{my_potentially_dangerous_sub}> in the template and that label would trigger the deletion of 'database_file'.

=item code with subs_execution disabled

Just explicitly omit the C<CODE> value handler when you create the object, so no sub will be executed:

     $tm = new Template::Magic
               value_handler => [ qw( SCALAR REF ARRAY HASH ) ] ;

=item code with restricted lookups

    sub my_potentially_dangerous_sub { unlink 'database_file' };
    %my_restricted_hash = ( name => 'John', surname => 'Smith' );
    
    # lookup in %my_restricted_hash only
    $tm = new Template::Magic
              lookups => \%my_restricted_hash ;

With this code the lookup is restricted to just the identifiers used in the template, thus the subroutine C<my_potentially_dangerous_sub> is unavailable to the outside world.

=back

=head2 Embed perl into a template

This example represents the maximum degree of inclusion of perl code into a template: in this situation, virtually any code inside the '_EVAL_' block will be executed from the template.

B<WARNING>: For obvious reasons you should use this handler ONLY if you are the programmer AND the designer.

=over

=item the template

    {_EVAL_}$char x ($num+1){/_EVAL_}

The content of '_EVAL_' block could be any perl expression

=item the code

    $tm = new Template::Magic
              zone_handlers =>  '_EVAL_' ;
    $char = 'W';
    $num = 5;


=item the output

The handler will generate as the output the evaluated content of the block.

    WWWWWW

Since a block can contain any quantity of text, you could use this type of configuration as a cheap way to embed perl into (HTML) files.

Notice that the default syntax markers ({/}) could somehow clash with perl blocks, so if you want to embed perl into your templates, you should consider to redefine the syntax with some more appropriate marker (See L<"Redefine Markers">).

=back

=head2 Caching or not the template

Template::Magic cache the template structure by default if it is passed as a path to a file. You can avoid the caching either by passing a filehandler or a reference to a template content (not so memory efficient) or by using the 'cache/nocache' L<"options">:

    $tm = new Template::Magic
              options => 'no_cache' ;

=head1 EFFICIENCY

The system is very flexible, so you can use it in a variety of ways, but you have to know what is the best option for your needs.

=head2 Memory optimization

You can avoid waste of memory by avoiding the method L<output()|"output ( template [, temporary lookups ] )"> that needs to collect and store the output in memory. Use L<print()|"print ( template[, temporary lookups ] )"> instead that prints the output while it is produced, without charging the memory.

Don't pass big templates contents as a reference, because Template::Magic copies the content in an internal and optimized representation of the template, so you would need twice the memory.

Don't do this:

    open TEMPLATE, '/path/to/big_template' ;
    $big_template = do{local $/; <TEMPLATE>} ;
    $output = $tm->output(\$big_template);
    print $$output;

You can save a lot of typing and a lot of memory if you do this instead:

    $tm->print('/path/to/big_template') ;

If you need to use C<Template::Magic> with C<CGI::Application> (that requires the run modes method to collect the whole output) you may use L<CGI::Application::Magic|CGI::Application::Magic> or L<Apache::Application::Magic|Apache::Application::Magic> that transparently integrates the template system with the application and avoid the C<output()> method.

For memory optimization see also:

=over

=item *

L<"Include and process a template file">

=item *

L<"Include (huge) text files without memory charges">

=item *

L<"Process (huge) loops iteration by iteration">

=back


=head2 Cache

If you pass the template as a path, Template::Magic will cache it (in the global C<%Template::Magic::CACHE> hash) and will open and parse it just the first time or if it has been modified, so you can save a lot of processing too! This is a big advantage under mod_perl, where the persistent environment can speed up the process, completely avoiding to read and parse the template file.

If for any reason you don't want the template to be cached, you can use the 'no_cache' L<"options">.

See also:

=over

=item * L<"Caching or not the template">

=item * L<load() method|"load( template )">

=item * L<purge_cache() method|"purge_cache ( [template_path] )">

=back

=head2 The -compile pragma

It has no effect since version 1.39.

=head1 SYNTAX GLOSSARY

=over

=item attributes string

The I<attributes string> contains every character between the end of the label I<identifier> and the I<end label> marker. This is optionally used to pass special parameters to a sub.

=item block

A I<block> is a I<template zone> delimited by (and including) a I<label> and an I<end label>:

    +-------+-------------------+------------+
    | LABEL |      CONTENT      | END_LABEL  |
    +-------+-------------------+------------+

Example: B<{my_identifier} content of the block {/my_identifier}>

where C<'{my_identifier}'> is the LABEL, C<' content of the block '> is the CONTENT and C<'{/my_identifier}'> is the END_LABEL.

=item end label

An I<end label> is a string in the form of:

    +--------------+---------------+------------+------------+
    | START_MARKER | END_MARKER_ID | IDENTIFIER | END_MARKER |
    +--------------+---------------+------------+------------+

Example of end label : B<{/my_identifier}>

where C<'{'> is the START_MARKER, C<'/'> is the END_MARKER_ID, C<'my_identifier'> is the IDENTIFIER, and C<'}'> is the END_MARKER.

=item identifier

A I<label identifier> is an alphanumeric name C<(\w+)> that represents (and usually matches) a variable or a subroutine identifier of your code.

=item illegal blocks

Each block in the template can contain arbitrary quantities of nested labels and/or blocks, but it cannot contain itself (a block with its same identifier), or cannot be cross-nested.

B<Legal  block>: {block1}...{block2}...{/block2}...{/block1}

B<Illegal auto-nested block>: {block1}...{block1}...{/block1}...{/block1}

B<Illegal cross-nested block>: {block1}...{block2}...{/block1}...{/block2}

If the template contains any illegal block, unpredictable behaviours may occur.

=item include label

An I<include label> is a I<label> used to include a I<template> file. The I<identifier> must be 'INCLUDE_TEMPLATE' and the attributes string should be a valid path.

Example: B<{INCLUDE_TEMPLATE /templates/temp_file.html}>

=item label

A I<label> is a string in the form of:

    +--------------+------------+------------+------------+
    | START_MARKER | IDENTIFIER | ATTRIBUTES | END_MARKER |
    +--------------+------------+------------+------------+

Example: B<{my_identifier attribute1 attribute2}>

where C<'{'> is the START_MARKER, C<'my_identifier'> is the IDENTIFIER, C<'attribute1 attribute2'> are the ATTRIBUTES and C<'}'> is the END_MARKER.

=item lookup

The action to match label I<identifier> with code identifier (variable, subroutine and method identifier and hash keys).

=item main template zone

The 'root' zone representing the whole template content

=item markers

The markers that defines labels and blocks. These are the default values of the markers that define the label:

    START_MARKER:   {
    END_MARKER_ID:  /
    END_MARKER:     }

You can redefine them by using the C<markers> constructor array. (see L<"Redefine Markers"> and L<markers>).

=item matching identifier

The identifier (symbol name or key name) in the code that is matching with the zone or label identifier

=item merger process

The process that merges runtime values with a I<template> producing the final output

=item nested block

A I<nested block> is a I<block> contained in another I<block>:

    +----------------------+
    |   CONTAINER_BLOCK    |
    |  +----------------+  |
    |  |  NESTED_BLOCK  |  |
    |  +----------------+  |
    +----------------------+

Example:
    {my_container_identifier}
    B<{my_nested_identifier} content of the block {/my_nested_identifier}>
    {/my_container_identifier}

where all the above is the CONTAINER_BLOCK and C<'{my_nested_identifier} content of the block {/my_nested_identifier}'> is the NESTED_BLOCK.

=item output

The I<output> is the result of the merger of runtimes values with a template

=item template

A I<template> is a text content or a text file (i.e. plain, HTML, XML, etc.) containing some I<label> or I<block>.

=item value type

The type of the value found by a lookup (i.e. UNDEF, SCALAR, HASH, ARRAY, ...), that is usually used in the I<value handler> condition to trigger the I<value handler>.

=item zone

A I<zone> is an area in the template that must have an I<identifier>, may have an I<attributes string> and may have a I<content>. A zone without any content is also called I<label>, while a zone with content is also called I<block>.

=item zone object

A I<zone object> is an internal object representing a zone.

=back

=head1 SEE ALSO

=over

=item * L<Template::Magic::Zone|Template::Magic::Zone>

=item * L<Template::Magic::HTML|Template::Magic::HTML>

=item * L<Template::Magic::Pager|Template::Magic::Pager>

=item * L<CGI::Builder::Magic|CGI::Builder::Magic>

=item * L<CGI::Application::Magic|CGI::Application::Magic>

=item * L<Apache::Application::Magic|Apache::Application::Magic>

=back

=head1 SUPPORT

Support for all the modules of the Template Magic System is via the mailing list. The list is used for general support on the use of the Template::Magic, announcements, bug reports, patches, suggestions for improvements or new features. The API to the Magic Template System is stable, but if you use it in a production environment, it's probably a good idea to keep a watch on the list.

You can join the Template Magic System mailing list at this url:

L<http://lists.sourceforge.net/lists/listinfo/template-magic-users>

=head1 AUTHOR and COPYRIGHT

© 2004-2005 by Domizio Demichelis (L<http://perl.4pro.net>)

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=head1 CREDITS

Thanks to I<Mark Overmeer> L<http://search.cpan.org/author/MARKOV/> which has submitted a variety of code cleanups/speedups and other useful suggestions.

A special thanks to Megyaszai Sandor for his very detailed revision of the POD.

=cut
