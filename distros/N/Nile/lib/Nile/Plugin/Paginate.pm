#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Plugin::Paginate;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

# pagination - pag·i·na·tion
#1. the process of numbering the pages of a book.
#2. the number and arrangement of pages, as might be noted in a bookseller’s catalogue.

use Nile::Base;

=pod

=encoding utf8

=head1 NAME

Nile::Plugin::Paginate - Efficient Data Pagination

=head1 SYNOPSIS

    # example data
    my $total_entries = 100;
    my $entries_per_page = 10;
    my $pages_per_set = 7;
    my $current_page = 4;

    my $paginate = $app->plugin->paginate(

        total_entries       => $total_entries, 
        entries_per_page    => $entries_per_page, 
        current_page        => $current_page,
        pages_per_set       => $pages_per_set,
        mode => "slide", #modes are 'slide', 'fixed', default is 'slide'

        css_class        => "pagination",
        layout => 0, # next&prev position, both right, 2: both left, 0: left and right
        page_link   => "action=browse&page=%page%&id=10",
        prev_page_text => "Prev",
        next_page_text => "Next",
        last_page_text => "Last",
        first_page_text => "First",
        showing_text => "Page %page% of  %pages% (listing %first% to %last% of %entries%)",
        showing_list_text => "Page %page% of  %pages%",
        more_text => "...",
    );

    # general page information
    print "         First page: ", $paginate->first_page, "\n";
    print "          Last page: ", $paginate->last_page, "\n";
    print "          Next page: ", $paginate->next_page, "\n";
    print "      Previous page: ", $paginate->prev_page, "\n";
    print "       Current page: ", $paginate->current_page, "\n";

    # entries on current page
    print "First entry on current page: ", $paginate->first, "\n";
    print " Last entry on current page: ", $paginate->last, "\n";

    # returns the number of entries on the current page
    print "Entries on the current page: ", $paginate->entries_on_current_page, " \n";

    # page set information
    print "First page of previous page set: ",  $paginate->previous_set, "\n";
    print "    First page of next page set: ",  $paginate->next_set, "\n";
  
    # print the page numbers of the current set (visible pages)
    foreach my $page (@{$paginate->pages_in_set()}) {
        ($page == $paginate->current_page())? print "[$page] " : print "$page ";
    }
    
    # this will print out these results:
    # First page: 1
    # Last page: 10
    # Next page: 5
    # Previous page: 3
    # Current page: 4
    # First entry on current page: 31
    # Last entry on current page: 40
    # Entries on the current page: 10 
    # First page of previous page set: 
    # First page of next page set: 11
    #     1 2 3 [4] 5 6 7 

    # rendering
    print $paginate->out, "\n";
    # prints: 
    <ul class="pagination">
       <li class="ui-state-default"><a href="page=3">Prev</a></li>
       <li class="ui-state-default"><a href="page=1">1</a></li>
       <li class="ui-state-default"><a href="page=2">2</a></li>
       <li class="ui-state-default"><a href="page=3">3</a></li>
       <li class="ui-state-active active"><a href="javascript:void(0);">4</a></li>
       <li class="ui-state-default"><a href="page=5">5</a></li>
       <li class="ui-state-default"><a href="page=6">6</a></li>
       <li class="ui-state-default"><a href="page=7">7</a></li>
       <li class="ellipsis">...</li><li class=" ui-state-default"><a href="page=10">10</a></li>
       <li class="ui-state-default"><a href="page=5">Next</a></li>
    </ul>

    print $paginate->showing, "\n";
    # prints: Page 4 of  10 (listing 31 to 40 of 100)

    print $paginate->showing_list, "\n";
    # prints: Page 4 of  10
    
=head1 DESCRIPTION

The module can be used to create page navigation for any type of applications specially good for web applications.

In addition it also provides methods for dealing with set of pages,
so that if there are too many pages you can easily break them
into chunks for the user to browse through. 

This module is very friendly where you can change any single
input parameter at anytime and it will automatically recalculate
all internal methods data without the need to recreate the object again.

All the main object input options can be set direct and the module
will redo the calculations including the mode method.

You can even choose to view page numbers in your set in a 'sliding' fassion.

=head1 METHODS

=head2 paginate()

    my $paginate = $self->app->paginate(
        total_entries       => $total_entries, 
        entries_per_page    => $entries_per_page, 
        current_page        => $current_page,
        pages_per_set       => $pages_per_set,
        mode => "slide", #modes are 'slide', 'fixed', default is 'slide'
    );

This is the constructor of the object.

SETTINGS are passed in a hash like fashion, using key and value pairs. Possible settings are:

B<total_entries> - how many data units you have,

B<entries_per_page> - the number of entries per page to display,

B<current_page> -  the current page number (defaults to page 1) and,

B<pages_per_set> -  how many pages to display, defaults to 10,

B<mode> - the mode (which defaults to 'slide') determins how the paging will work.

=back 4

=cut
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub BUILD {
    my $self = shift;
    my $args = shift;

    $args->{total_entries} += 0;
    $args->{entries_per_page} += 0;
    $args->{current_page} += 0;
    $args->{pages_per_set} += 0;
    $args->{current_entry} += 0;
    
    $args->{entries_per_page} = int($args->{entries_per_page});
    $args->{current_page} = int($args->{current_page});
    $args->{pages_per_set} = int($args->{pages_per_set});

    $self->{total_entries} =  int($args->{total_entries});
    $self->{current_entry} =  int($args->{current_entry});

    $self->{entries_per_page} = $args->{entries_per_page} > 0 ? $args->{entries_per_page} : 10;
    $self->{current_page} = $args->{current_page} > 0 ? $args->{current_page} : 1;
    $self->{pages_per_set} = $args->{pages_per_set} > 0 ? $args->{pages_per_set} : 5;
    
    if ( defined $args->{mode} && $args->{mode} eq 'fixed' ) {
        $self->{mode} = 'fixed';
    } else {
        $self->{mode} = 'slide';
    }
    
    $args->{layout} += 0;
    $self->{layout} = $args->{layout}; # layout styles, 0: default, prev on left and next of right, 1: prev, next of left, and 2: prev, next on right.

    $self->{css_class} = exists $args->{css_class} ? $args->{css_class} : "pagination";
    $self->{page_link} = exists $args->{page_link} ? $args->{page_link} : "page=%page%"; # /action=browse&page=%page%&id=10
    $self->{showing_text} = exists $args->{showing_text} ? $args->{showing_text} : "Page %page% of  %pages% (listing %first% to %last% of %entries%)";
    $self->{showing_list_text} = exists $args->{showing_list_text} ? $args->{showing_list_text} : "Page %page% of  %pages%";
    $self->{first_page_text} = exists $args->{first_page_text} ? $args->{first_page_text} : "First";
    $self->{prev_page_text} = exists $args->{prev_page_text} ? $args->{prev_page_text} : "Prev";
    $self->{next_page_text} = exists $args->{next_page_text} ? $args->{next_page_text} : "Next";
    $self->{last_page_text} = exists $args->{last_page_text} ? $args->{last_page_text} : "Last";
    $self->{more_text} = exists $args->{more_text} ? $args->{more_text} : "...";
    
    $self->do_calculation();
    #$self->render();
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub do_calculation {
    my ($self) = shift;
    
    # Calculate the total pages & the last page number
    $self->{last_page} = int ($self->{total_entries} / $self->{entries_per_page});
    if (($self->{total_entries} % $self->{entries_per_page})) { $self->{last_page}++; }
    $self->{last_page} = 1 if ($self->{last_page} < 1);
    $self->{total_pages} = $self->{last_page};

    # if current enty is set, recalculate current page
    if ($self->{current_entry} > 0) {
        $self->{current_page} = int (($self->{current_entry} / $self->{entries_per_page})+ 0.5); # our ceil()
    }

    if ($self->{current_page} > $self->{last_page}) {$self->{current_page} = $self->{last_page};}

    $self->{first_page} = 1;  #always = 1

    # calculate the first data entry on the current page
    if ($self->{total_entries} == 0) {
        $self->{first} = 0;
    } else {
        $self->{first} = (($self->{current_page} - 1) * $self->{entries_per_page}) + 1;
    }
    
    # calculate the last data entry on the current page
    if ($self->{current_page} == $self->{last_page}) {
        $self->{last} = $self->{total_entries};
    } else {
        $self->{last} = ($self->{current_page} * $self->{entries_per_page});
    }

    # Calculate entries on the current page
    if ($self->{total_entries} == 0) {
        $self->{entries_on_current_page} = 0;
    } else {
        $self->{entries_on_current_page} = $self->last - $self->first + 1;
    }
    
    #calculate the previous page number if any
    if ($self->{current_page} > 1) {
        $self->{previous_page} = $self->{current_page} - 1;
    } else {
        $self->{previous_page} = undef;
    }
    
    #calculate the next page number if any
    $self->{next_page} = $self->{current_page} < $self->{last_page} ? $self->{current_page} + 1 : undef;
    
    #calculate pages sets
    $self->calculate_visible_pages();
    
    #check if the first page is currently in the pages set displayed
    $self->{first_page_in_set} = @{$self->{page_set_pages}}[0] == 1 ? 1 : 0;
    #check if the last page is currently in the pages set displayed
    $self->{last_page_in_set} = @{$self->{page_set_pages}}[$#{$self->{page_set_pages}}] == $self->{last_page} ? 1 : 0;
    
    #now render all the navigation output
    $self->render();
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub render {
    my ($self) = shift;
    my ($page, $link);

    if ($self->{total_entries} > 0) {
        $self->{showing} = $self->{showing_text};
        $self->{showing} =~ s/%page%/$self->{current_page}/g;
        $self->{showing} =~ s/%pages%/$self->{last_page}/g;
        $self->{showing} =~ s/%first%/$self->{first}/g;
        $self->{showing} =~ s/%last%/$self->{last}/g;
        $self->{showing} =~ s/%entries%/$self->{total_entries}/g;

        $self->{showing_list} = $self->{showing_list_text};
        $self->{showing_list} =~ s/%page%/$self->{current_page}/g;
        $self->{showing_list} =~ s/%pages%/$self->{last_page}/g;
        $self->{showing_list} =~ s/%first%/$self->{first}/g;
        $self->{showing_list} =~ s/%last%/$self->{last}/g;
        $self->{showing_list} =~ s/%entries%/$self->{total_entries}/g;
    }
    else {
        $self->{showing} = "";
        $self->{showing_list} = "";
        $self->{next_page_out} = "";
        $self->{last_page_out} = "";
        $self->{prev_page_out} = "";
        $self->{first_page_out} = "";
        #$self->{out} = "";
        #return;
    }
    #------------------------------------------------------
    $self->{next_page_link} = $self->{page_link};
    $self->{next_page_link} =~ s/%page%/$self->{next_page}/g;
    
    $self->{prev_page_link} = $self->{page_link};
    $self->{prev_page_link} =~ s/%page%/$self->{previous_page}/g;

    $self->{first_page_link} = $self->{page_link};
    $self->{first_page_link} =~ s/%page%/$self->{first_page}/g;

    $self->{last_page_link} = $self->{page_link};
    $self->{last_page_link} =~ s/%page%/$self->{last_page}/g;
    #------------------------------------------------------
    # Previous Page, First Page
    if ($self->{current_page} == 1) {
            $self->{prev_page_out} = qq!<li class="ui-state-default ui-state-disabled">$self->{prev_page_text}</li>!;
            #$self->{first_page_out} = qq!<li class="prev-off">$self->{first_page}</li>!;
            $self->{first_page_out} = "";
            $self->{prev_more_out} = "";
    }
    else{
            $self->{prev_page_out} = qq!<li class="ui-state-default"><a href="$self->{prev_page_link}">$self->{prev_page_text}</a></li>!;
            
            if ($self->{first_page_in_set}) {
                    #$self->{first_page_out} = qq!<li class="prev-off">$self->{first_page}</li>!;
                    $self->{first_page_out} =  ""; # First page in set
                    $self->{prev_more_out} = "";
            }
            else {
                $self->{first_page_out} = qq!<li class="ui-state-default"><a href="$self->{first_page_link}">$self->{first_page}</a></li>!;
                $self->{prev_more_out} = qq!<li class="ellipsis">$self->{more_text}</li>!;
            }
    }
    #------------------------------------------------------
    # Next Page, Last page
    if ($self->{current_page} == $self->{last_page} || $self->{total_entries} <= 0) {
            $self->{next_page_out} = qq!<li class="ui-state-default ui-state-disabled">$self->{next_page_text}</li>!;
            #$self->{last_page_out} = qq!<li class="next-off">$self->{last_page}</li>!;
            $self->{last_page_out} = "";
            $self->{next_more_out} = "";
    }
    else{
            $self->{next_page_out} = qq!<li class="ui-state-default"><a href="$self->{next_page_link}">$self->{next_page_text}</a></li>!;
            
            if ($self->{last_page_in_set}) {
                #$self->{last_page_out} = qq!<li class="next-off">$self->{last_page}</li>!;
                $self->{last_page_out} = "";
                $self->{next_more_out} = "";
            }
            else {
                $self->{last_page_out} = qq!<li class=" ui-state-default"><a href="$self->{last_page_link}">$self->{last_page}</a></li>!;
                $self->{next_more_out} = qq!<li class="ellipsis">$self->{more_text}</li>!;
            }
    }
    #------------------------------------------------------
    # Pagination Pages set
    $self->{pages_out} = ""; 
    foreach $page (@{$self->pages_in_set()}) {
            $link = $self->{page_link};
            $link =~ s/%page%/$page/g;
            $self->{current_page_link} = $link;

            if ($page == $self->{current_page}) {
                    $self->{pages_out} .= qq!<li class="ui-state-active active"><a href="javascript:void(0);">$page</a></li>!;
            }
            else{
                    $self->{pages_out} .= qq!<li class="ui-state-default"><a href="$link">$page</a></li>!;
            }
    }

    if ($self->{total_entries} < 1) {
            $self->{pages_out} = qq!<li class="ui-state-default ui-state-disabled">1</li>!;
    }

    if ($self->{layout} == 1) {# prev, next, on the right
        $self->{out} = qq!<ul class="$self->{css_class}">$self->{first_page_out}$self->{prev_more_out}$self->{pages_out}$self->{next_more_out}$self->{last_page_out}<li class="ellipsis">&nbsp;</li>$self->{prev_page_out}$self->{next_page_out}</ul>!;
    }
    elsif ($self->{layout} == 2) {# prev, next, on the left
        $self->{out} = qq!<ul class="$self->{css_class}">$self->{prev_page_out}$self->{next_page_out}<li class="ellipsis">&nbsp;</li>$self->{first_page_out}$self->{prev_more_out}$self->{pages_out}$self->{next_more_out}$self->{last_page_out}</ul>!;
    }
    else{
        $self->{out} = qq!<ul class="$self->{css_class}">$self->{prev_page_out}$self->{first_page_out}$self->{prev_more_out}$self->{pages_out}$self->{next_more_out}$self->{last_page_out}$self->{next_page_out}</ul>!;
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub render2 {
    my ($self) = shift;
    my ($page, $link);

    if ($self->{total_entries} > 0) {
        $self->{showing} = $self->{showing_text};
        $self->{showing} =~ s/%page%/$self->{current_page}/g;
        $self->{showing} =~ s/%pages%/$self->{last_page}/g;
        $self->{showing} =~ s/%first%/$self->{first}/g;
        $self->{showing} =~ s/%last%/$self->{last}/g;
        $self->{showing} =~ s/%entries%/$self->{total_entries}/g;

        $self->{showing_list} = $self->{showing_list};
        $self->{showing_list} =~ s/%page%/$self->{current_page}/g;
        $self->{showing_list} =~ s/%pages%/$self->{last_page}/g;
        $self->{showing_list} =~ s/%first%/$self->{first}/g;
        $self->{showing_list} =~ s/%last%/$self->{last}/g;
        $self->{showing_list} =~ s/%entries%/$self->{total_entries}/g;
    }
    else {
        $self->{showing} = "";
        $self->{showing_list} = "";
        $self->{next_page_out} = "";
        $self->{last_page_out} = "";
        $self->{prev_page_out} = "";
        $self->{first_page_out} = "";
        $self->{out} = "";
        return;
    }
    #------------------------------------------------------
    $self->{next_page_link} = $self->{page_link};
    $self->{next_page_link} =~ s/%page%/$self->{next_page}/g;
    
    $self->{prev_page_link} = $self->{page_link};
    $self->{prev_page_link} =~ s/%page%/$self->{previous_page}/g;

    $self->{first_page_link} = $self->{page_link};
    $self->{first_page_link} =~ s/%page%/$self->{first_page}/g;

    $self->{last_page_link} = $self->{page_link};
    $self->{last_page_link} =~ s/%page%/$self->{last_page}/g;
    #------------------------------------------------------
    # Previous Page, First Page
    if ($self->{current_page} == 1) {
            $self->{prev_page_out} = qq!<li class="prev-off">$self->{prev_page_text}</li>!;
            $self->{first_page_out} = qq!<li class="prev-off">$self->{first_page_text}</li>!;
    }
    else{
            $self->{prev_page_out} = qq!<li><a href="$self->{prev_page_link}">$self->{prev_page_text}</a></li>!;
            
            if ($self->{first_page_in_set}) {
                    #$self->{first_page_out} =  ""; # First page in set
                    $self->{first_page_out} = qq!<li class="prev-off">$self->{first_page_text}</li>!;
            }
            else {
                $self->{first_page_out} = qq!<li><a href="$self->{first_page_link}">$self->{first_page_text}</a></li>!;
            }
    }
    #------------------------------------------------------
    # Next Page, Last page
    if ($self->{current_page} == $self->{last_page} || $self->{total_entries} <= 0) {
            $self->{next_page_out} = qq!<li class="next-off">$self->{next_page_text}</li>!;
            $self->{last_page_out} = qq!<li class="next-off">$self->{last_page_text}</li>!;
    }
    else{
            $self->{next_page_out} = qq!<li><a href="$self->{next_page_link}">$self->{next_page_text}</a></li>!;
            
            if ($self->{last_page_in_set}) {
                #$self->{last_page_out} = "";
                $self->{last_page_out} = qq!<li class="next-off">$self->{last_page_text}</li>!;
            }
            else {
                $self->{last_page_out} = qq!<li><a href="$self->{last_page_link}">$self->{last_page_text}</a></li>!;
            }
    }
    #------------------------------------------------------
    # Pagination Pages set
    $self->{pages_out} = ""; 
    foreach $page (@{$self->pages_in_set()}) {
            $link = $self->{page_link};
            $link =~ s/%page%/$page/g;
            $self->{current_page_link} = $link;

            if ($page == $self->{current_page}) {
                    $self->{pages_out} .= qq!<li class="active"><a href="javascript:void(0);">$page</a></li>!;
            }
            else{
                    $self->{pages_out} .= qq!<li><a href="$link">$page</a></li>!;
            }
    }
    $self->{out} = qq!<ul class="$self->{css_class}">$self->{first_page_out}$self->{prev_page_out}$self->{pages_out}$self->{next_page_out}$self->{last_page_out}</ul>!;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 total_entries()

  $paginate->total_entries($total_entries);

This method sets or returns the total_entries. If called without 
any arguments it returns the current total entries.

=cut

sub total_entries {
    my ($self) = shift; 
    if (@_) {
        $self->{total_entries} = shift ;
        $self->do_calculation();
    }
    return $self->{total_entries};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 entries_per_page()

  $paginate->entries_per_page($entries_per_page);

This method sets or returns the entries per page (page size). If called without 
any arguments it returns the current data entries per page.

=cut

sub entries_per_page {
    my ($self) = shift; 
    if (@_) {
        $self->{entries_per_page} = shift ;
        $self->do_calculation();
    }
    return $self->{entries_per_page};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 current_page()

  $paginate->current_page($page_num);

This method sets or returns the current page. If called without 
any arguments it returns the current page number.

=cut

sub current_page {
    my ($self) = shift; 
    if (@_) {
        $self->{current_page} = shift ;
        $self->do_calculation();
    }
    return $self->{current_page};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 mode()
    
    $paginate->mode('slide');

This method sets or returns the pages set mode which takes only
two values 'fixed' or 'slide'. The default is 'slide'. The fixed mode will be
good if you want to display all the navigation pages.

=cut  

sub mode {
    my ($self) = shift; 
    if (@_) {
        $self->{mode} = shift ;
        $self->do_calculation();
    }
    return $self->{mode};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 pages_per_set()

  $paginate->pages_per_set($number_of_pages_per_set);

Sets or returns the number of pages per set (visible pages).
If called without any arguments it will return the current
number of pages per set.

=cut

sub pages_per_set {
    my ($self) = shift; 
    if (@_) {
        $self->{pages_per_set} = shift ;
        $self->do_calculation();
    }
    return $self->{pages_per_set};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 entries_on_current_page()

  $paginate->entries_on_current_page();

This method returns the number of entries on the current page.

=cut

sub entries_on_current_page {
    my ($self) = shift;

    if ($self->{total_entries} == 0) {
        return 0;
    } else {
        return $self->last - $self->first + 1;
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 first_page()

  $paginate->first_page();

Returns first page. Always returns 1.

=cut

sub first_page {
    my ($self) = shift;
    return 1;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 last_page()

  $paginate->last_page();

Returns the last page number, the total number of pages.

=cut

sub last_page {
    my ($self) = shift; 
    return $self->{last_page};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 total_pages()

  $paginate->total_pages();

Returns the last page number, the total number of pages.

=cut

sub total_pages {
    my ($self) = shift; 
    return $self->{last_page};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 first()

  $paginate->first();

Returns the number of the first entry on the current page.

=cut

sub first {
    my ($self) = shift;
    return $self->{first};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 last()

  $paginate->last();

Returns the number of the last entry on the current page.

=cut

sub last {
    my ($self) = shift;
    return $self->{last};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 prev_page()

  $paginate->prev_page();

Returns the previous page number, if one exists. Otherwise it returns undefined.

=cut

sub prev_page {
    my ($self) = shift;
    return $self->{previous_page};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 next_page()

  $paginate->next_page();

Returns  the next page number, if one exists. Otherwise it returns undefined.

=cut

sub next_page {
    my ($self) = shift;
    return $self->{next_page};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 first_page_in_set()

  $paginate->first_page_in_set();

Returns 1 if the first page is in the current pages set. Otherwise it returns 0.

=cut

sub first_page_in_set {
    my ($self) = shift;
    return $self->{first_page_in_set};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 last_page_in_set()

  $paginate->last_page_in_set();

Returns 1 if the last page is in the current pages set. Otherwise it returns 0.

=cut

sub last_page_in_set {
    my ($self) = shift;
    return $self->{last_page_in_set};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The code below originally from the module Data::Pageset
sub calculate_visible_pages {
    my ($self) = shift;

    unless ( $self->{pages_per_set} > 1 ) {
        # Only have one page in the set, must be page 1
        $self->{page_set_previous} = $self->{current_page} - 1 if ($self->{current_page} != 1);
        $self->{page_set_pages} = [1];
        $self->{page_set_next}  = $self->{current_page} + 1 if ($self->{current_page} < $self->{last_page});
    } else {
        if ( $self->{mode} eq 'fixed' ) {
            my $starting_page = $self->calc_start_page($self->{pages_per_set});
            my $end_page      = $starting_page + $self->{pages_per_set} - 1;

            if ( $end_page < $self->{last_page}) {
                $self->{page_set_next} = $end_page + 1;
            }

            if ( $starting_page > 1 ) {
                $self->{page_set_previous} = $starting_page - $self->{pages_per_set};
                $self->{page_set_previous} =  1 if $self->{page_set_previous} < 1;
            }

            $end_page = $self->{last_page} if ($self->{last_page} < $end_page);
            $self->{page_set_pages} = [ $starting_page .. $end_page ];
        } else {

            # We're in slide mode

            # See if we have enough pages to slide
            if ( $self->{pages_per_set} >= $self->{last_page} ) {

                # No sliding, no next/prev pageset
                $self->{page_set_pages} = [ '1' .. $self->{last_page} ];
            } else {

                # Find the middle rounding down - we want more pages after, than before
                my $middle = int( $self->{pages_per_set} / 2 );

                # offset for extra value right of center on even numbered sets
                my $offset = 1;
                if ( $self->{pages_per_set} % 2 != 0 ) {
                    # must have been an odd number, add one
                    $middle++;
                    $offset = 0;
                }

                my $starting_page = $self->{current_page} - $middle + 1;
                $starting_page = 1 if $starting_page < 1;
                my $end_page = $starting_page + $self->{pages_per_set} - 1;
                $end_page = $self->{last_page} if ($self->last_page() < $end_page);

                if ( $self->{current_page} <= $middle ) {
                    # near the start of the page numbers
                    $self->{page_set_next} = $self->{pages_per_set} + $middle - $offset;
                    $self->{page_set_pages} = [ '1' .. $self->{pages_per_set} ];
                } elsif ( $self->{current_page} > ( $self->{last_page} - $middle - $offset ) )
                {
                    # near the end of the page numbers
                    $self->{page_set_previous} = $self->{last_page} - $self->{pages_per_set} - $middle + 1;
                    $self->{page_set_pages}= [ ( $self->{last_page} - $self->{pages_per_set} + 1 ) .. $self->{last_page} ];
                } else {
                    # Start scrolling
                    $self->{page_set_pages} = [ $starting_page .. $end_page ];
                    $self->{page_set_previous} = $starting_page - $middle - $offset;
                    $self->{page_set_previous} = 1 if $self->{page_set_previous} < 1;
                    $self->{page_set_next} = $end_page + $middle;
                }
            }
        }
    }

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The code below originally from the module Data::Pageset
# Calculate the first page in the current set
sub calc_start_page {
    my ($self) = shift;

    my $current_page_set = 0;

    if ( $self->{pages_per_set} > 0 ) {
        $current_page_set = int( $self->{current_page} / $self->{pages_per_set} );
        if ( $self->{current_page} % $self->{pages_per_set} == 0 ) {
            $current_page_set = $current_page_set - 1;
        }
    }

    return ( $current_page_set * $self->{pages_per_set} ) + 1;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 previous_set()

  print "Previous set starts at ", $paginate->previous_set(), "\n";

This method returns the page number at the start of the previous page set.
undef is return if pages_per_set has not been set.

=cut  

sub previous_set {
    my $self = shift;
    return $self->{page_set_previous} if defined $self->{page_set_previous};
    return undef;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 next_set()

  print "Next set starts at ", $paginate->next_set(), "\n";

This method returns the page number at the start of the next page set.
undef is return if pages_per_set has not been set.

=cut  

sub next_set {
    my ($self) = shift;
    return $self->{page_set_next} if defined $self->{page_set_next};
    return undef;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 pages_in_set()

  foreach my $page_num (@{$paginate->pages_in_set()}) {
    print "Page: $page_num \n";
  }

This method returns an array ref of the the page numbers within
the current set. undef is return if pages_per_set has not been set.

=cut  

sub pages_in_set {
    my ($self) = shift;
    return $self->{page_set_pages};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 out()

  print "out: ", $paginate->out(), "\n";

=cut  

sub out {
    my ($self) = shift;
    return $self->{out};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 showing()

  print "showing: ", $paginate->showing(), "\n";

=cut  

sub showing {
    my ($self) = shift;
    return $self->{showing};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 showing_list()

  print "showing list: ", $paginate->showing_list(), "\n";

=cut  

sub showing_list {
    my ($self) = shift;
    return $self->{showing_list};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
