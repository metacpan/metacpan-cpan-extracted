package Rapi::Blog::DB::Component::ResultSet::ListAPI;

use strict;
use warnings;
 
use parent 'DBIx::Class::ResultSet';

use RapidApp::Util ':all';
use URI::Escape qw/uri_escape uri_unescape/;


sub _api_param_arg_order { undef; }
sub _get_api_param_arg_order { (shift)->_api_param_arg_order(@_) // [qw/search/] } 


sub _api_default_params  { undef; }
sub _get_api_default_params {
  my $params = (shift)->_api_default_params(@_) || {};
  { page => 1, limit => 500, %$params }
}


# get/set accessor:
sub _list_api_params {
  my ($self, @args) = @_;
  
  if(scalar(@args) > 0) {
    my %P = ();
    if((ref($args[0])||'') eq 'HASH') {
      # Our caller has supplied arguments already as name/values:
      %P = %{ $args[0] };
    } 
    else {
      # Also support ordered list arguments:
      my @order = @{$self->_get_api_param_arg_order};
      for my $value (@args) {
        my $param = shift(@order) or last;
        $P{$param} = $value;
      }
    }
    
    for my $key (grep { $_ =~ /^new\_/ } keys %P) {
      my $new_val = delete $P{$key};
      $key =~ s/^new_//;
      $P{$key} = $new_val;
    }
    
    my $defaults = $self->_get_api_default_params;
    exists $P{$_} or $P{$_} = $defaults->{$_} for (keys %$defaults);
    
    # Extra checks to make sure limit and page are not only defined but positive integers,
    # and if the consumer class has set
    $P{limit} = $defaults->{limit} unless ($P{limit} && $P{limit} =~ /^\d+$/);
    $P{page}  = $defaults->{page}  unless ($P{page}  && $P{page}  =~ /^\d+$/);
    
    # Finally, fallback defaults in case the consumer class _api_default_params doesn't
    # return correct/valid limit and page params (abundance of caution)
    $P{limit} = 500 unless ($P{limit} && $P{limit} =~ /^\d+$/);
    $P{page}  = 1   unless ($P{page}  && $P{page}  =~ /^\d+$/);
    
    $self->{attrs}{___list_api_params} = \%P;
  }
  
  $self->{attrs}{___list_api_params} || {}
}


sub _list_api {
  my ($self, @args) = @_;
  
  my $P = $self->_list_api_params(@args);
  
  my $Rs = $self;

  my @rows = ();
  my $pages = 1;

  my $total = $Rs->_safe_count;
  if($total > 0) {
    $pages = int($total/$P->{limit});
    $pages++ if ($total % $P->{limit});
  }
  
  $P->{page} = $pages if ($P->{page} > $pages);
  
  @rows = $Rs
    ->search_rs(undef,{ page => $P->{page}, rows => $P->{limit} })
    ->all if ($total > 0);
    
  my $count = (scalar @rows);
  
  my $thru = $P->{page} == 1 ? $count : ($P->{page}-1) * $P->{limit} + $count;
  my $remaining = $total - $thru;
  
  my $last_page = $P->{page} == $pages ? 1 : 0;
  
  my $this_qs  = $self->_to_query_string(%$P);
  my $prev_qs  = $P->{page} > 1          ? $self->_to_query_string(%$P, page => $P->{page}-1 ) : undef;
  my $next_qs  = !$last_page             ? $self->_to_query_string(%$P, page => $P->{page}+1 ) : undef;
  my $first_qs = $P->{page} > 2          ? $self->_to_query_string(%$P, page => 1            ) : undef;
  my $last_qs  = $P->{page} < ($pages-1) ? $self->_to_query_string(%$P, page => $pages       ) : undef;
  
  my %meta = (
    # Number of items returned (this page)
    count     => $count,
    
    # Total number of items (all pages)
    total     => $total,
    
    # Page number of current page
    page      => $P->{page},
    
    # Total number of pages
    pages     => $pages,
    
    # True is the current page is the last page
    last_page => $P->{page} == $pages ? 1 : 0,
    
    # True if this page already contains all items
    complete  => $total == $count ? 1 : 0,
    
    # The number (out of total items) this page starts at
    start     => $thru - $count + 1,
    
    # The number (out of total items) this page ends at
    end       => $thru,
    
    # The number of items remaining after this page
    remaining => $remaining,
    
    # The number of items in all the pages before this one
    before    => $thru - $count,
    
    # The limit of items per page
    limit     => $P->{limit},
    
    # Expressed as a query string, the params that would return the first page (undef if N/A)
    first_qs  => $first_qs,
    
    # Expressed as a query string, the params that would return the last page (undef if N/A)
    last_qs   => $last_qs,
    
    # Expressed as a query string, the params that would return the previous page (undef if N/A)
    prev_qs   => $prev_qs,
    
    # Expressed as a query string, the params that would return the next page (undef if N/A)
    next_qs   => $next_qs,
    
    # Expressed as a query string, the params that would return this same page
    this_qs   => $this_qs,
    
    # The current params for this page as a HashRef
    params    => $P
  );

  return { %meta, rows => \@rows }
}


sub _to_query_string {
  my $self = shift;
  my %params = (ref($_[0]) eq 'HASH') ? %{ $_[0] } : @_; # <-- arg as hash or hashref

  # remove params already at their default values in order to provide a cleaner url:
  my $defaults = $self->_get_api_default_params;
  for my $key (keys %$defaults) {
    delete $params{$key} if (defined $params{$key} && "$params{$key}" eq "$defaults->{$key}");
  }
  
  # strip empty string values (false values are expected to use '0')
  $params{$_} eq '' and delete $params{$_} for (keys %params);
  
  # Put the page back in - even if its already at its default value - if there 
  # are no other params to ensure we return a "true" value
  $params{page} = $defaults->{page} || 1 unless (scalar(keys %params) > 0);
  
  my %encP = map { $_ => uri_escape($params{$_}) } keys %params;
  
  join('&',map { join('=',$_,$encP{$_}) } keys %encP)
}


sub _select_only_primary_columns {
  my $self = shift;
  
  my @pri_cols = $self->result_source->primary_columns;
  die "No primary columns!" unless (scalar(@pri_cols) > 0);
  
  my $select = [ map { join('.',$self->current_source_alias,$_) } @pri_cols ];
  my $as     = \@pri_cols;
  
  $self->search_rs(undef,{ columns => [], select => $select, as => $as })
}

sub _safe_count {
  my $self = shift;
  
  # There seems to be a DBIC bug in count -
  # Get errors like: 
  #  Single parameters to new() must be a HASH ref data => DBIx::Class::ResultSource::Table=HASH(0xc8ce240)
  # When we try to call ->count when we have { join => 'post_tags', group_by => 'me.id' } in the attrs.
  # The line which is barfing is:
  #  https://metacpan.org/source/RIBASUSHI/DBIx-Class-0.082840/lib/DBIx/Class/ResultSet.pm#L3389
  # Which is DBIC trying to create a fresh_rs where it passes $self->result_source to ->new() so
  # it seems to be an internal inconsistency. I don't have time to deal with it now so I created this
  # ugly fallback for now. FIXME
  
  
  my $count = try{ $self->count };
  return $count if (defined $count);
  
  # Do a manual query and count the results, but try to make it least expensive as possible
  my @rows = $self
    ->_select_only_primary_columns
    ->search_rs(undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator'})
    ->all;
  
  return scalar(@rows);
}

1;

__END__

=head1 NAME
 
Rapi::Blog::DB::Component::ResultSet::ListAPI - Common "ListAPI" interface
 
=head1 DESCRIPTION

This is a L<DBIx::Class> component for L<ResultSet|DBIx::Class::ResultSet> classes that is used
for the common list_* methods (such as C<list_posts>, C<list_users>) exposed to L<Rapi::Blog>
scaffold templates. It provides a mechanism to define input params on a class-by-class basis, but
returns a common result packet.

=head1 RESULT PACKET

The "ListAPI" call to methods such as C<list_posts> will always return a HashRef result packet 
containing exactly two keys C<'rows'> which contains an ArrayRef of matching Row objects and C<'meta'>
which contains additional params and details regarding the data set.

The C<meta> packet is a HashRef containing the following params:

=head2 count

Number of items returned (this page)

=head2 total

Total number of items (all pages)

=head2 page

Page number of current page

=head2 pages

Total number of pages

=head2 last_page

True if the current page is the last page

=head2 complete

True if this page already contains all items

=head2 start

The number (out of total items) this page starts at

=head2 end

The number (out of total items) this page ends at

=head2 remaining

The number of items remaining after this page

=head2 before

The number of items in all the pages before this one

=head2 limit

The limit of items per page

=head2 first_qs

Expressed as a query string, the params that would return the first page (undef if N/A)

=head2 last_qs

Expressed as a query string, the params that would return the last page (undef if N/A)

=head2 prev_qs

Expressed as a query string, the params that would return the previous page (undef if N/A)

=head2 next_qs

Expressed as a query string, the params that would return the next page (undef if N/A)

=head2 this_qs

Expressed as a query string, the params that would return this same page

=head2 params

The current params for this page as a HashRef

=head1 SEE ALSO

=over

=item * 

L<Rapi::Blog>

=item * 

L<RapidApp>

=item * 

L<Rapi::Blog::Manual::Scaffolds>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut





