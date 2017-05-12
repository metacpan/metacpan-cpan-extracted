package Perldoc::Server::Model::PerlFunc;

use strict;
use warnings;
use 5.010;
use parent 'Catalyst::Model';

# requires required for PAR
require PerlIO;
require PerlIO::scalar;

use Pod::Functions;

foreach my $function (keys %Flavor) {
  if ($function =~ /^(-?\w+)\W/) {
    my $real_function = $1;
    $Flavor{$real_function} = $Flavor{$function};
  }
}


sub ACCEPT_CONTEXT { 
  my ( $self, $c, @extra_arguments ) = @_; 
  bless { %$self, c => $c }, ref($self); 
}


sub pod {
  my $self         = shift;
  my $function     = shift;
  my $function_pod = $self->function_pod;
  
  return $function_pod->{$function};
}


sub exists {
  my $self         = shift;
  my $function     = shift;
  my $function_pod = $self->function_pod;
  
  return exists $function_pod->{$function};  
}


sub list {
  my $self         = shift;
  my $function_pod = $self->function_pod;
  
  return keys %{$function_pod};
}


sub description {
  my $self     = shift;
  my $function = shift;
  
  return $Flavor{$function};
}


sub category_list {
  my $self = shift;
  
  return @Type_Order;
}


sub category_description {
  my $self     = shift;
  my $category = shift;
  
  return $Type_Description{$category};
}


sub category_functions {
  my $self     = shift;
  my $category = shift;
  
  return @{$Kinds{$category}};
}


sub function_pod {
  state %function_pod;
  return \%function_pod if %function_pod;
  
  my $self     = shift;
  my $perlfunc = $self->{c}->model('Pod')->pod('perlfunc');
    
  # This probably needs refactoring to use Pod::POM
  open PERLFUNC,'<',\$perlfunc;
  while (<PERLFUNC>) {
    last if /^=head2 Alphabetical Listing of Perl Functions/;
  }
  my (@headers,$body,$inlist);
  my $state = 'header_search';
  SEARCH: while (<PERLFUNC>) {
    if ($state eq 'header_search') {
      next SEARCH unless (/^=item\s+\S/);
      $state = 'header_capture';
    }
    if ($state eq 'header_capture') {
      if (/^\s*$/) {
        next SEARCH;
      } elsif (/^=item\s+(\S.*)/) {
        push @headers,$_;
      } else {
        $inlist = 0;
        $state  = 'body';
        $body   = '';
      }
    }
    if ($state eq 'body') {
      if (/^=over/) {
        ++$inlist;
      } elsif (/^=back/ and ($inlist > 0)) {
        --$inlist;
      } elsif (/^=item/ or /^=back/) {
        unless ($inlist) {
          my %unique_functions;
          foreach my $header (@headers) {
            $unique_functions{$1}++ if ($header =~ m/^=item\s+(-?\w+)/)
          }
          foreach my $function (keys %unique_functions) {
            #warn("Storing $function\n");
            #if ($header =~ /^=item\s+(\S\S+)/) {
              #my $function = $1;
              my $pod = "=over\n\n";
              $pod   .= join "\n",grep {/=item $function/} @headers;
              $pod   .= "\n$body=back\n\n";
              $function_pod{$function} .= $pod;
              #last;
	    #}
          }
          $state  = 'header_search';
          @headers = ();
          redo SEARCH;
        }
      } 
      $body .= $_;
    }
  }
  close PERLFUNC;

  return \%function_pod;
}

=head1 NAME

Perldoc::Server::Model::PerlFunc - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
