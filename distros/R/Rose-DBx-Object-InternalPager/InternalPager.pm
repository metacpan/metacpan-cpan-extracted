###########################################
package Rose::DBx::Object::InternalPager;
###########################################
use strict;
use warnings;
use Log::Log4perl qw(:easy);

our $VERSION = "0.03";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        %options,
    };

    $self->{pager_options}->{per_page} = 50 unless defined
        $self->{pager_options}->{per_page};

    $self->{pager_options}->{start_page} = 1 unless defined
        $self->{pager_options}->{start_page};

    for my $param (qw(manager_options class_name manager_method)) {
        if(!defined $options{ $param}) {
            LOGDIE "Missing mandatory paramter $param";
        }
    }

    bless $self, $class;

    $self->{pager} = $self->make_pager(
        $self->{ class_name },
        $self->{ manager_method },
        $self->{ pager_options },
        $self->{ manager_options },
    );

    return $self;
}

###########################################
sub next {
###########################################
    my($self) = @_;

    return $self->{pager}->();
}

###########################################
sub make_pager {
###########################################
    my($self, $class, $method, $options, $moptions) = @_;

    $options  = {} unless $options;
    $moptions = {} unless $moptions;

    my $manager_class   = "${class}::Manager";
    my $iterator_method = "${method}_iterator";

    my $per_page        = $options->{per_page};
    my $page            = $options->{start_page};
    my $page_items_done = 0;

    if(!defined $per_page) {
       LOGDIE "Parameter per_page not defined";
    }
    if(!defined $page) {
       LOGDIE "Parameter start_page not defined";
    }

    DEBUG "Creating first pager iterator ",
          "class=$class per_page=$per_page";

    my $itr = $manager_class->$iterator_method(
        page     => $page, 
        per_page => $per_page,
        %$moptions,
    );

    return sub {

        if($page_items_done == $per_page) {
            # Page done? Get next iterator.
            $page++;
            DEBUG "Getting next iterator for ",
                  "class=$class (page=$page)"; 

            $itr = $manager_class->$iterator_method( 
                page     => $page, 
                per_page => $per_page,
                %$moptions);

            $page_items_done = 0;
        }

        $page_items_done++;

        return $itr->next();
    }
}

1;

__END__

=head1 NAME

Rose::DBx::Object::InternalPager - Throttle Rose DB Iterator Fetching

=head1 SYNOPSIS

    use Rose::DBx::Object::InternalPager;

    my $pager = Rose::DBx::Object::InternalPager->new(
        class_name      => "Namespace::Author",
        manager_method  => "get_authors",
        manager_options => { 
          query           => [ published => 'yes' ],
          require_objects => [ 'city_of_birth' ],
          sort_by         => 'last_name',
        },
    );

    while(my $author = $pager->next()) {
        print $author->first_name(), " ",
              $author->last_name(), " ",
              $author->city_of_birth->string(), "\n";
    }

=head1 DESCRIPTION

C<Rose::DBx::Object::InternalPager> is a 3rd party module for C<Rose::DB> iterators
to work around MySQL client's limited control over how many rows are
fetched from the database at a time. 

C<Rose::DBx::Object::InternalPager> provides a hack to limit 
the number of fetched records and prevents programs from running out
of memory.
   
The pager creates an iterator object, similar to the Rose C<Manager>'s 
C<get_xxx_iterator()>, method. 
Except, behind the scenes, the pager makes sure to never fetch more
than a preset number of records from the database at a time. To
accomplish this, it uses LIMIT to limit the number of records
retrieved, and OFFSET to fetch the next batch.

This approach might lead to anomalies when the database gets modified while
the pager is at work, and this is the reason why this module has been 
released I<outside> of the C<Rose::DB> realm as a 3rd party module.

While normally, you would call

    my $itr = Namespace::Author::Manager->get_authors_iterator(...);

to get an iterator object which offers a C<next()> method to move
from one database record to the next. With C<Rose::DBx::Object::InternalPager>, 
you call

    my $pager = Rose::DBx::Object::InternalPager->new(
        class_name     => "Namespace::Author", # Note: no 'Manager'
        manager_method => "get_authors",       # Note: no 'iterator'
        # ...
    );

which returns a pager object that can be used to iterate over
all database records found via

    while(my $author = $pager->next()) {
        # ...     
    }

Just as the manager's C<get_xxx_iterator()> method offers ways
to modify the query with C<query>, C<sort_by> and other parameters,
these parameters can be set with the pager by using the C<manager_options>
parameter:

    my $pager = Rose::DBx::Object::InternalPager->new(
        class_name      => "Namespace::Author", # Note: no 'Manager'
        manager_method  => "get_authors",       # Note: no 'iterator'
        manager_options => { 
          query           => [ published => 'yes' ],
          require_objects => [ 'city_of_birth' ],
          sort_by         => 'last_name',
        },
    );

By default, the pager fetches 50 records at a time. This value can
be modified by setting the C<per_page> parameter in the 
optional C<pager_options> hash:

    my $pager = Rose::DBx::Object::InternalPager->new(
        # ...
        pager_options => {
          per_page => 100,
        },
    );

By default, the pager starts at page 1. This value can
be modified by setting the C<start_page> parameter in the 
optional C<pager_options> hash:

    my $pager = Rose::DBx::Object::InternalPager->new(
        # ...
        pager_options => {
          start_page => 17,
        },
    );

=head1 WHY THIS MODULE?

Even with C<mysql_use_result> set, I've found that with large database
tables, clients run out of memory when they want to iterate over all
records of a table. At the cost of eventually creating anomalies, the
pager provides fine-grained control over the amount of memory used by
the database client application.

=head1 DISCLAIMER

Note that while this module uses C<Rose::DB>, it was released and will
be maintained I<separately> from John Siracusa's project.

=head1 LEGALESE

Copyright 2007 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2007, Mike Schilli <m@perlmeister.com>
