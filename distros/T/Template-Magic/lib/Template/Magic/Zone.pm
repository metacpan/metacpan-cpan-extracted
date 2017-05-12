package Template::Magic::Zone ;
$VERSION = 1.40 ;
use strict ;
use 5.006_001 ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; our $AUTOLOAD
; $Carp::Internal{+__PACKAGE__}++

; BEGIN
   { *OK = sub () { 1 }
   }

; BEGIN
   { foreach my $n (qw| zone output text post |)
      { no strict 'refs'
      ; *{$n.'_process'} = sub
                            { my ($z) = @_
                            ; my $ch = $z->tm->{$n.'_handlers'} || return
                            ; HANDLER:
                              foreach my $h ( @$ch )
                               { return OK if $h->(@_)
                               }
                            }
      }
   ; *mt = sub{shift()->tm(@_)}  # backward compatibility
   }
   
; use Class::constr
; use Object::props
  ( { name       => [ qw| id
                          attributes
                          is_main
                          _t
                          container
                          output
                        |
                    ]
    , protected  => 1
    }
  , { name       => 'level'
    , protected  => 1
    , default    => -1
    }
  , qw| param
        location
        value
        _s
        _e
      |
  )

; sub value_process
   { my ($z) = @_
   ; my $tm = $z->tm
   ; my $v = $z->value
   ; if ( defined $v && length $v )
      { delete $$tm{_NOT_lookup}{'NOT_'.$z->id}
      }
     else
      { $$tm{_NOT_lookup}{'NOT_'.$z->id} = {}
      ; return unless defined($v)
      }
   ; my $ch = $$tm{value_handlers} || return
   ; HANDLER:
     foreach my $h ( @$ch )
      { return OK if &$h(@_)
      }
   }
     
; sub AUTOLOAD : lvalue
   { (my $n = $AUTOLOAD) =~ s/.*://
   ; return if $n eq 'DESTROY'
   ; @_ == 2
     ? ( $_[0]{__CUSTOM}{$n} = $_[1] )
     :   $_[0]{__CUSTOM}{$n}
   }

; sub tm
   { my ($az) = my ($z) = @_ ;
   ; until (defined $$az{tm}){ $az = $az->container }
   ; $$az{tm}
   }
   
; sub content_process
   { my ($z) = @_
   ; defined $z->_e || return  # content or return
   ; ZONE:
     for ( my $i  = $z->_s
         ;    $i <= $z->_e
         ;    $i++
         )
      { my $item = $z->_t->[$i][1]
      ; if ( not $item )                       # just text
         { $z->text_process( $z->_t->[$i][0] )
         }
        elsif ( ref $item eq 'HASH' )          # normal zone
         { my $nz = ref($z)->new( %$item
                                , level     => $z->level + 1
                                , container => $z
                                , _t        => $z->_t
                                )
         ; $i = $nz->_e + 1 if $nz->_e         # skip block content
         ; next ZONE if $nz->zone_process
         ; $nz->lookup_process
         ; $nz->value_process
         ; $nz->post_process
         }
        elsif ( $item eq 'CONTAINER_INCLUDE' )
         { $z->include_template($z->tm->{_included_template})
         }
        elsif ( $item->is_main )               # included file
         { $z->_include($item)
         }
      }
   }
   
; sub _include
   { my ($z, $iz) = @_
   ; @$iz{qw|container level tm|} = ( $z
                                    , $z->level
                                    , $z->tm
                                    )
   ; $iz->content_process
   ; delete @$iz{qw|container level tm|}   # reset
   }
   
; sub lookup_process
   { my ($z) = @_
   ; defined $z->value and return
   ; $z->value($z->lookup)
   }

; sub lookup
   { my ( $z, $id ) = @_
   ; $id ||= $z->id
   ; my $val
   ; for ( my $az = $z->container
         ;    $az->container
         ;    $az = $az->container
         )
      { $val = $z->_lookup( $az->value, $id )
      ; return $val if defined $val
      }
   ; my $tm = $z->tm
   ; foreach my $l ( @{$$tm{_temp_lookups}}
                   , @{$$tm{lookups}}
                   , $$tm{_NOT_lookup}
                   )
      { next unless $l
      ; $val = $z->_lookup( $l, $id )
      ; return $val if defined $val
      }
   ; undef
   }
   
; sub _lookup
   { my ($z, $l, $id) = @_
   ; return unless $l
   ; $z->location = $l
   ; if ( ref $l eq 'HASH' )
      { $$l{$id}
      }
     elsif ( my $code = UNIVERSAL::can( $l, $id ) )
      { $code
      }
     else
      { no strict 'refs','vars'
      ; local *S = $l.'::'.$id
      ; defined $S ?  $S
            : @S ? \@S
            : %S ? \%S
            : undef
      }
   }
   
; sub content
   { my ($z) = @_
   ; defined $z->_e || return
   ; join '' , map { $$_[0]
                   }
                   @{$z->_t} [ $z->_s
                               ..
                               $z->_e
                             ]
   }

; sub include_template
   { my ($z, $t) = @_
   ; my $nz = $z->tm->load($t)
   ; $z->_include($nz)
   ; return undef
   }

; 1

__END__

=pod

=head1 NAME

Template::Magic::Zone - The Zone object

=head1 VERSION 1.39

Included in Template-Magic 1.39 distribution.

The latest versions changes are reported in the F<Changes> file in this distribution.

=head1 DESCRIPTION

Template::Magic uses the Template::Magic::Zone objects to internally represent zones. A reference to the I<Zone object> is passed as a parameter to each handler and is passed to your subroutines whenever an identifier trigger their execution.

B<Note>: Unless you plan to write an extension or some custom solution, you will find useful just the L<"attributes">, L<"content"> and L<"param"> properties that you can use to retrieve parameters from your subroutines (see L<Template::Magic/"Pass parameters to a subroutine">), and the L<"include_template()"> method that you can use to include templates from inside your code (see L<Template::Magic/"Conditionally include and process a template file">).

=head1 ZONE OBJECT METHODS

B<Note>: If you plan to write your own extension, please, feel free to ask for more support: the documentation in this distribution is not yet complete for that purpose.

With Template::Magic the output generation is so flexible and customizable, because it can be changed DURING THE PROCESS by several factors coming both from the code I<(e.g. the type of value found by the C<lookup()>)>, or from the template I<(e.g. the literal id of a zone)>, or whatever combination of factors you prefer.

It's important to understand that - for this reason - the output generation is done recursively by several processes (all customizable by the user) that are executed zone-by-zone, step-by-step, deciding the next step by evaluating the handlers conditions.

This is a sloppy code to better understand the whole process:

    ZONE: while ($zone = find_and_create_the_zone)
          {
            foreach $process (@all_the_process)
            {
              HANDLER: foreach $handler (@$process)
                       {
                         $handler->($zone)
                       }
            }
          }

As you can see, the HANDLER loop is nested inside the ZONE loop, not vice versa. This avoids unneeded recursions in zones that could be wiped out by some handler, thus allowing a faster execution. (for example when the C<value> property of a zone is undefined the zone is deleted).

These are the processes that are executed for any single zone:

  content process
    nested zones creation
      zone process
      lookup process
      value process
      text & output processes
    post process

As a general rule, a C<*_process> is a method that executes in sequence the handlers contained in C<*_handlers> constructor array. In details, these process executes the handlers contained in these constructor arrays:

    zone_process()    zone_handlers
    value_process()   value_handlers
    text_process()    text_handlers
    output_process()  output_handlers
    post_process()    post_handlers

B<Note>: the C<lookup_process> and the C<content_process> are exceptions to this rule.

=head2 content_process()

This method starts (and manage) the output generation for the zone: it process the I<zone content>, creates each new zone object and apply the appropriate process on the new zones.

B<Note>: You can change the way of parsing by customizing the I<markers> constructor array. You can change the resulting output by customizing the other constructor arrays.

=head2 zone_process()

The scope of this method is organizing the Zone object.

Since it is called first, and just after the creation of each new zone object, this is a very powerful method that allows you to manage the output generation before any other process. With this method you can even bypass or change the way of calling the other processes.

As other process methods, this process simply calls in turn all the handlers in the C<zone_handlers> constructor array until some handler returns a true value: change the C<zone_handlers> to change this process (see L<Template::Magic/"zone_handlers">).

=head2 lookup([identifier])

This method tries to match a zone id with a code identifier: if it find a match it returns the value of the found code identifier, if it does not find any match it returns the C< undef> value.

If I<identifier> is omitted, it will use the I<zone id>. Pass an I<identifier> to lookup values from other zones.

This method looks up first in the containers found values, then in the lookups locations. You can customize the lookup by changing the items in the C<lookups> constructor array.

=head2 lookup_process()

The scope of this method is setting the I<zone value> with a value from the code. It executes the C<lookup()> method with the I<zone id>

B<Note>: it works only IF the I<zone value> property is undefined.

=head2 value_process()

The scope of this method is finding out a scalar value from the code to pass to the C<output_process()>.

As other process methods, this process simply calls in turn all the handlers in the C<value_handlers> constructor array until some handler returns a true value: change the C<value_handlers> to change this process (see L<Template::Magic/"value_handlers">).

B<Note>: it works only IF the zone value property is defined.

=head2 text_process()

The scope of this method is processing only the text that comes from the template and that goes into the output (in other words the template content between I<labels>).

As other process methods, this process simply calls in turn all the handlers in the C<text_handlers> constructor array until some handler returns a true value: change the C<zone_handlers> to change this process (see L<Template::Magic/"text_handlers">).

B<Note>: If the C<text_handlers> constructor array is undefined (as it is by default) the text will be processed by the C<output_process()> instead. Use this method only if you need to process the text coming from the template in some special way, different by the text coming from the code.

=head2 output_process()

The scope of this method is processing the text that comes from the code. It is usually used to process the text coming from the template as well if the C<text_process()> method is not used (i.e. no defined C<text_handlers>).

As other process methods, this process simply calls in turn all the handlers in the C<output_handlers> constructor array until some handler returns a true value: change the C<zone_handlers> to change this process (see L<Template::Magic/"output_handlers">).

=head2 post_process()

This method is called at the end of the process, after the production of the output. It is not used by default. Use it to clean up or log processes as you need.

As other process methods, this process simply calls in turn all the handlers in the C<post_handlers> constructor array until some handler returns a true value: change the C<zone_handlers> to change this process (see L<Template::Magic/"post_handlers">).

=head2 include_template( template )

This method loads and process a template. It is useful specially if you want to conditionally load and process a template from inside your code. (see L<Template::Magic/"Conditionally include and process a template file">)

=head2 AUTOLOAD()

The Zone package has a convenient C<AUTOLOAD> method that allows you to retrive or set a propery of the I<zone object>.

All the properties are C<lvalue> methods, that means that you can use the property as a left value :

    # to set classical way (it works anyway)
    $z->value('whatever')   ;
    
    # to set new way (lvalue type)
    $z->value  = 'whatever' ;
    
    $the_value = $z->value  ; # to retrive

If you plan to customize the behaviours of Template::Magic, you will find useful the C<AUTOLOAD> method. You can automatically set and retrieve your own properties by just using them. The following example shows how you can add a custom 'my_attributes' property to the I<zone object>

In the template zone 'my_zone':

    text {my_zone attr1 attr2 attr3} content {/my_zone} text

These are the properties right after the parsing:

    $zone->id is set to the string 'my_zone'
    $zone->attributes is set to the string ' attr1 attr2 attr3'
    $zone->content is set to the string ' content '

If you want to have your own 'my_attributes' property, structured as you want, you could do this:

    # creates a 'my_attributes' property
    # and set it to an array ref containing one word per element
    $zone->my_attributes = [ split /\s+/,  substr( $zone->attributes, 1) ]

From now on you can retrieve the attributes your way:

    # retrieves the second attribute
    print $zone->my_attributes->[1]
    
    # would print
    attr2

=head1 PROPERTIES

The following are the properties that Template::Magic uses to do its job: they all are left value properties (I<lvalue> means that you can create a reference to it, assign to it and apply a regex to it; see also L<KNOWN ISSUE>).

=head2 tm

The C<tm> property allows you to access the B<Template::Magic object>.

B<Note>: this is a read only property.

=head2 mt

Obsolete and deprecated property: use C<tm> instead.

=head2 id

The C<id> property allows you to access the B<zone identifier>. It is undefined only if the zone is the I<main template zone>

B<Note>: this is a read only property.

=head2 attributes

The C<attributes> property allows you to access the B<attributes string>. This string contains everything between the end of the label IDENTIFIER and the END_LABEL marker. It returns the empty string when there are no attributes.

B<Note>: this is a read only property.

=head2 content

The C<content> property allows you to retrieve the B<zone content>. The I<zone content> is defined only for blocks (i.e. only with zones that have a start and an end label). If the zone is a single label zone, the content property will return the C<undef> value.

B<Note>: this is a read only property.

=head2 param

This property is added by the C<_EVAL_ATTRIBUTES_> zone handler (if you explicitly use it), and - in that case - holds the B<evalued attributes structure>. You can use this property to hold your favorite structure: just create it with a simple zone handler as C<_EVAL_ATTRIBUTES_>.

=head2 container

This property holds the reference to the B<container zone>. It is undefined only if the zone is the I<main template zone> and if the file is not included. If the file is included the container is the zone where the I<INCLUDE_TEMPLATE> label was found.

B<Note>: this is a read only property.

=head2 level

This property holds the number of nesting level of the zone. -1 for the I<main template zone>, 0 for the zones at the template level, 1 for the zone nested in a zone at the template level and so on. In other words ($z->level < 0) for the I<main template zone> and ($z->level > 0) if the zone is nested. The level number of a zone in an included file is relative to the main template file, not to the file itself.

=head2 location

This property holds the package name, the blessed object or the hash reference from which comes the I<matching identifier> at that particular moment of the process.

Usually you don't need to set this property, but you could find it very useful, for example, to access the object methods of a lookup element from inside an extension. I<(more documentation to come)>

=head2 value

This propery holds the value of the I<matching identifier> at that particular moment of the I<output generation>.

It's important to understand that the C<value_process()> implies a recursive assignation to this property (not to mention that other processes could set the property as well). That means that the C<value> property will return different values in different part of that process. For example: if you have this simple template:

    text {my_id_label} text

and this simple code where Template::Magic is looking up:

    $scalar = 'I am a simple string';
    $reference = \$scalar;
    $my_id_label = $reference;

At the beginning of the process, the C<value> property will return a reference, then (after passing through the other value handlers) it will be dereferenced and so the C<value> property, at that point, will return 'I am a simple string'.

B<Note>: In order to make it work, if the found value is a SCALAR or a REFERENCE it must be set the C<value> property 'as is'; if it is anything else, it must be set as a reference. For example:

    found values          value of $zone->value
    ------------------------------------
    'SCALAR'              'SCALAR'
    (1..5)                [1..5]
    [1..5]                [1..5]
    (key=>'value')        {key=>'value'}
    {key=>'value'}        {key=>'value'}
    ------------------------------------


=head2 output

This property holds the B<output string> coming from the code.

=head2 is_main

Boolean property: it returns true if the zone is a I<main template zone>.

B<Note>: this is a read only property.

=head2 _t

This property holds the reference to the template structure.

=head2 _s

This property holds the offset of the template chunk where the content starts. Use it to re-locate the content of a zone and only if you know what you are doing.

=head2 _e

This property holds the offset of the template chunk where the content ends. Use it to re-locate the content of a zone and only if you know what you are doing.

=head1 SEE ALSO

=over

=item * L<Template::Magic|Template::Magic>

=item * L<Template::Magic::HTML|Template::Magic::HTML>

=back

=head1 KNOWN ISSUE

Due to the perl bug #17663 I<(Perl 5 Debugger doesn't handle properly lvalue sub assignment)>, you must know that under the B<-d> switch the lvalue sub assignment will not work, so your program will not run as you expect.

In order to avoid the perl-bug you have 3 alternatives:

=over

=item 1

patch perl itself as suggested in this post: http://www.talkaboutprogramming.com/group/comp.lang.perl.moderated/messages/13142.html (See also the cgi-builder-users mailinglist about that topic)

=item 2

use the lvalue sub assignment (e.g. C<< $s->any_property = 'something' >>) only if you will never need B<-d>

=item 3

if you plan to use B<-d>, use only standard assignments (e.g. C<< $s->any_property('something') >>)

=back

Maybe a next version of perl will fix the bug, or maybe lvalue subs will be banned forever, meanwhile be careful with lvalue sub assignment.

=head1 SUPPORT

Support for all the modules of the Template Magic System is via the mailing list. The list is used for general support on the use of the Template::Magic, announcements, bug reports, patches, suggestions for improvements or new features. The API to the Magic Template System is stable, but if you use it in a production environment, it's probably a good idea to keep a watch on the list.

You can join the Template Magic System mailing list at this url:

L<http://lists.sourceforge.net/lists/listinfo/template-magic-users>

=head1 AUTHOR and COPYRIGHT

© 2004-2005 by Domizio Demichelis (L<http://perl.4pro.net>)

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
