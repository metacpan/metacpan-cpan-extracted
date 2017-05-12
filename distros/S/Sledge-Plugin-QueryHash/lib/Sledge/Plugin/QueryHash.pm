package Sledge::Plugin::QueryHash;

use warnings;
use strict;

our $VERSION = '0.01';

sub import {
    my $class = shift;
    my $pkg = caller;

    no strict 'refs';
    *{"$pkg\::query_hash"} = sub {
        my $self = shift;
        my @params = @_;
        unless (@params) {
            @params = $self->r->param;
        }
        my %hash;
        foreach my $key (@params) {
            my @val = $self->r->param($key);
            if (scalar(@val) > 1) {
                $hash{$key} = \@val;
            } else {
                $hash{$key} = $val[0];
            }
        }
        return wantarray ? %hash : \%hash;
    };
}

1;
__END__

=head1 NAME

Sledge::Plugin::QueryHash - Get query params helper module for Sledge

This module ported CGI::Application::Plugin::QueryHash in plugin of Sledge.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  ## your Sledge::Pages
  use Sledge::Plugin::QueryHash;
   
  sub dispatch_index {
    my $self = shift;
    
    ## All params hash
    my %query = $self->query_hash;
    
    ## All palams hash ref.
    my $query = $self->query_hash;
    
    ## Selected params hash
    my %selected_query = $self->query_hash('key','key2');

    ## Selected params hash ref
    my $selected_query = $self->query_hash('key');
    
  }

=head1 METHODS

=head2 query_hash

return query params hash / hashref.

=head1 BUGS

Please report any bugs or suggestions at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sledge-Plugin-QueryHash>

=head1 AUTHOR

syushi matsumoto, C<< <matsumoto at alink.co.jp> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Alink INC. all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

