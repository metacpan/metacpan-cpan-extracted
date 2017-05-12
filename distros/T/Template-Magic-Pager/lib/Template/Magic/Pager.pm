package Template::Magic::Pager ;
$VERSION = 1.15 ;
use 5.006_001 ;
use strict ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use Carp
; $Carp::Internal{+__PACKAGE__}++
; our $no_template_magic_zone = 1 # prevents passing the zone object to properties
     
; sub new
   { my $c = shift
   ; ref($c)  && croak qq(Can't call method "new" on a reference)
   ; (@_ % 2) && croak qq(Odd number of arguments for $c->new)
   ; my $s = bless {}, $c
   ; while ( my ($p, $v) = splice @_, 0, 2 )
      { if ($s->can($p))                     # if method
         { $s->$p( $v )
         }
        else
         { croak qq(No such property "$p")
         }
      }
   ; if ( ref $$s{total_results} eq 'ARRAY' )
      { my $r = $$s{total_results}
      ; $$s{total_results} = @$r
      ; $s->page_rows( [ @$r[ $s->_start_offset .. $s->_end_offset ] ] )
      }
   ; $$s{total_results} ? $s : undef
   }
      
; use Object::props
      ( { name       => 'total_results'
        , validation => sub
                         {  /^[\d]+$/
                         || ref eq 'ARRAY'
                         }
        }
      , { name       => 'page_rows'
        }
      , { name       => 'page_number'
        , default    => 1
        , validation => sub
                         { /^[\d]+$/
                         && $_ > 0
                         }
        }
      , { name       => [ qw | rows_per_page
                               pages_per_index
                             |
                        ]
        , default    => 10
        , validation => sub{ /^[\d]+$/ }
        }
      )
      
; sub total_pages
   { my $s = shift
   ; int ($s->total_results / $s->rows_per_page)
     + ($s->total_results % $s->rows_per_page ? 1 : 0)
   }

; sub next_page
   { my $s = shift
   ; $s->page_number + 1 if $s->page_number < $s->total_pages
   }
   
; sub next 
   { $_[0]->next_page && {}
   }

; sub previous_page
   { my $s = shift
   ; $s->page_number - 1 if $s->page_number > 1
   }
   
; sub previous 
   { $_[0]->previous_page && {}
   }
   
; sub _start_offset
   { my ($s, $page_number) = @_
   ; $page_number ||= $s->page_number
   ; $s->rows_per_page * ($page_number - 1)
   }
   
; sub _end_offset
   { my ($s, $page_number) = @_
   ; my $end = $s->_start_offset($page_number) + $s->rows_per_page - 1
   ; $end > ($s->total_results - 1)
     ? $s->total_results - 1
     : $end
   }

; sub start_result
   { my ($s, $page_number) = @_
   ; $s->_start_offset($page_number) + 1
   }

; sub end_result
   { my ($s, $page_number) = @_
   ; $s->_end_offset($page_number) + 1
   }
   
; sub index
   { my $s = shift
   ; my ( $half, $start, $end )
   ; $half = int ($s->pages_per_index / 2)
   ; my $page_number = $s->page_number
   ; my $total_pages = $s->total_pages
   ; if ( $total_pages / 2 > $page_number) # if first half
      { $start = $page_number - $half
      ; $start = 1 if $start < 1
      ; $end   = $start + $s->pages_per_index - 1
      ; $end   = $total_pages if $end > $total_pages
      }
     else
      { $end   = $page_number + $half
      ; $end   = $total_pages if $end > $total_pages
      ; $start = $end - $s->pages_per_index + 1
      ; $start = 1 if $start < 1
      }
   ; my @i = map
              { $_ != $page_number
                ? { linked_page  => {}
                  , page_number  => $_
                  , start_result => $s->start_result($_)
                  , end_result   => $s->end_result($_)
                  }
                : { current_page => {}
                  , page_number  => $_
                  }
              } $start .. $end
   ; \@i
   }

     
; 1

__END__

=pod

=head1 NAME

Template::Magic::Pager - HTML Pager for Template::Magic

=head1 VERSION 1.15

Included in Template-Magic-Pager 1.15 distribution.

The latest versions changes are reported in the F<Changes> file in this distribution.

The distribution includes:

=over

=item * Template::Magic::Pager

HTML Pager for Template::Magic

=item * Template::Magic::Slicer

Deprecated module

=back

=head1 INSTALLATION

=over

=item Prerequisites

    Perl version    >= 5.6.1
    Template::Magic >= 1.2
    OOTools         >= 1.71

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

=back

=head1 SYNOPSIS

  use Template::Magic::Pager ;
  
  # 1st way (useful when you have big number of results)
  $pager = Template::Magic::Pager->new
           ( total_results   => $results         # integer
           , page_rows       => $rows            # ARRAY ref
           , page_number     => $page_number     # integer
           , rows_per_page   => $rows_per_page   # integer
           , pages_per_index => $pages_per_index # integer
           ) ;
  
  # 2nd way (useful when you have all the result in an ARRAY)
  # total_results is an ARRAY ref and page_rows is ommitted
  $pager = Template::Magic::Pager->new
           ( total_results   => $results         # ARRAY ref
           , page_number     => $page_number     # integer
           , rows_per_page   => $rows_per_page   # integer
           , pages_per_index => $pages_per_index # integer
           ) ;

and inside the 'I<pager>' block in your template file you will have availables a complete set of L<"Labels and Blocks">.

=head1 DESCRIPTION

This module make it very simple to split an array of results into pages, and use your own totally customizable Template-Magic file to display each page; it is fully integrated with CGI::Builder::Magic and its handlers (such as TableTiler), and it can be used efficiently with any DB.

Using it is very simple: you have just to create an object in your code and define a block in your template and Template::Magic will do the rest. Inside the block you will have available a complete set of magic labels to define the result headers, dynamic index navigation bars Goooogle style and more. (see L<"Labels and Blocks">)

You can use this module in two different situations:

=over

=item 1

When you have big number of results coming from a DB query. In this situation you don't need to retrieve them all in order to initialize the object: you just need to pass the total number of results as the C<total_results> and the slice of the C<page_rows> to display in the page.

=item 2

When you already have all the results in memory, and you want to display just one slice of them. In order to do so you need just to pass the reference to the whole ARRAY of results as the C<total_results> and the object will set the C<page_rows> to the correct slice of results.

=back

=head2 Useful links

=over

=item *

A simple and useful navigation system between my modules is available at this URL: http://perl.4pro.net

=item *

More practical topics are discussed in the mailing list at this URL: http://lists.sourceforge.net/lists/listinfo/template-magic-users

=back

=head1 METHODS

=head2 new( arguments )

This method returns the new object reference ONLY if there are results to display (see L<total_results> below). It accepts the following arguments:

=over

=item * total_results

Mandatory argument. It may be an integer value of the total number of results you want to split into pages (not to be confused with the results of one page), or it may be a reference to the whole array of results; in this case you should omit the C<page_rows> argument. (see L<SYNOPSIS> to see the two ways to use the new() method)

If the passed value is not true (0 or undef), then the new() method will return the undef value instead of the object, thus allowing you to define a C<NOT_pager> block that will be printed when no result has been found.

=item * page_rows

Mandatory argument only if the C<total_result> argument is an integer. It expect a reference to an ARRAY containing the slice of results of the current page (or a reference to a sub returning the reference to the ARRAY).

=item * page_number

It expects an integer value representing the page to display. Default is 1 (i.e. if no value is passed then the page number 1 will be displayed).

=item * rows_per_page

Optional argument. This is the number of results that will be displayed for each page. Default 10.

=item * pages_per_index

Optional argument. This is the number of pages (or items) that will build the index bar. Default 10. (see also L<index|"item_index">)       

=back

=head2 Other Methods

Since all the magics of this module is done automatically by Template::Magic, usually you will explicitly use just the new() method. Anyway, each L<"Labels and Blocks"> listed below is referring to an object method that returns the indicated value. The Block methods -those indicated with "(block)"- are just boolean methods that check some conditions and return a reference to an empty array when the condition is true, or undef when it is false.

=head1 Labels and Blocks

These are the labels and blocks available inside the pager block:

=over

=item * start_result

The number of the result which starts the current page.

=item * end_result

The number of the result which ends the current page.

=item * total_results

The number of the total results (same number passed as the total_results argument: see L<new()|"new( arguments )">).

=item * page_rows (block)

This block will be automatically used by Template::Magic to generate the printing loop with the slice of results of the current page.

=item * page_number

The current page number (same number passed as the page_number argument: see L<new()|"new( arguments )">)

=item * total_pages

The total number of pages that have been produced by splitting the results.

=item * previous (block)

This block will be printed when the current page has a previous page, if there is no previous page (i.e. when the current page is the first page), then the content of this block will be wiped out. If you need to print somethingjust when the current page has no previous page (e.g. a dimmed 'Previous' link or image), then you should define a C<NOT_previous> block: it will be printed automatically when the C<previous> block is not printed.

=item * previous_page 

The number of the page previous to the current page. Undefined if there are no previous pages (i.e. when the current page is the first page).

=item * next (block)

This block will be printed when the current page has a next page, if there is no next page (i.e. when the current page is the last page), then the content of this block will be wiped out. If you need to print something just when the current page has no next page (e.g. a dimmed 'Next' link or image), then you just need to define a C<NOT_next> block: it will be printed automatically when the C<next> block is not printed.

=item * next_page

The number of the page next to the current page. Undefined if there are no next pages (i.e. the current page is the last page).  

=item * index (block)

This block defines the index bar loop: each item of the loop has its own set of values defining the C<page_number>, C<start_result> and C<end_result> of each index item. Nested inside the index block you should define a couple of other blocks: the C<current_page> and the C<linked_page> blocks.

=over

=item current_page (block)  

This block will be printed only when the index item refers to the current page, thus allowing you to print this item in a different way from the others items.

=item linked_page (block)

This block will be printed for all the index items unless the item is referring to the current page.

=back

=back

=head1 EXAMPLE

This is a complete example with results coming from a DB query. In this case you don't want to retrieve the whole results that would be probably huge, but just the results in the page to display:

  use Template::Magic ;
  use Template::Magic::Pager ;
  use CGI;
  
  my $cgi = CGI->new() ;
  my $pages_per_index = 20 ;
  my $rows_per_page   = $cgi->param('rows') ;                 # e.g. 20
  my $page_number     = $cgi->param('page') ;                 # e.g. 3
  my $offset          = $rows_per_page * ($page_number - 1) ; # e.g. 40
  
  # this manages the page_rows template block (notice the 'our')
  # (change the assignment with any real DB query)
  my $page_rows  = ... SELECT ...
                       LIMIT $offset, $rows_per_page ... ;   # ARRAY ref
  my $count      = ... SELECT FOUND_ROWS() ... ;             # integer e.g 526
  
  # $pager whould be undef if $count is not true
  our $pager = Template::Magic::Pager->new
               ( total_results   => $count           # (e.g 1526)
               , page_rows       => $page_rows       # (ARRAY ref)
               , page_number     => $page_number     # (3)
               , rows_per_page   => $rows_per_page   # (20)
               , pages_per_index => $pages_per_index # (20)
               ) ; 
  
  Template::Magic::HTML->new->print('/path/to/template') ;

In this example C<$main::page_rows> contains the array of results to display for the current page, and it will be used automagically by Template::Magic to fill the C<page_rows> template block.

B<Note>: To be sure the object is syncronized with the retrived DB query, you must use the correct C<offset> and C<rows_per_page> in both DB retrieving and object initialization. To do so you should use this simple algorithm:

  my $offset = $rows_per_page * ($page_number - 1) ;

=head2 More examples

You can find a little example (complete of templates) in the F<examples> dir included in this distribution.

B<Note>: While you are experimenting with this module, you are probably creating examples that could be useful to other users. Please submit them to theTemplate::Magic mailing list, and I will add them to the next release, giving you the credit of your code. Thank you in advance for your collaboration.

=head1 SUPPORT

Support for all the modules of the Template Magic System is via the mailing list. The list is used for general support on the use of the Template::Magic, announcements, bug reports, patches, suggestions for improvements or new features. The API to the Magic Template System is stable, but if you use it in a production environment, it's probably a good idea to keep a watch on the list.

You can join the Template Magic System mailing list at this url:

L<http://lists.sourceforge.net/lists/listinfo/template-magic-users>

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis (L<http://perl.4pro.net>)

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
