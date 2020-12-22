use strict; use warnings;
package Net::OAuth2Server::Set;
sub _words       { map /([^ ]+)/g, grep defined, @_ }
sub new          { my $class = shift; bless { map +( $_, 1 ), &_words }, $class }
sub clone        { my $self = shift; bless { %$self }, ref $self }
sub list         { keys %{$_[0]} }
sub is_empty     { 0 == keys %{$_[0]} }
sub as_string    { join ' ', sort keys %{$_[0]} }
sub contains     { my $self = shift; exists $self->{ $_ } and return 1 for @_; 0 }
sub contains_all { my $self = shift; exists $self->{ $_ } or  return 0 for @_; 1 }
sub add          { my $self = shift; $self->{ $_ } = 1 for &_words; $self }
sub subtract     { my $self = shift; delete @$self{ &_words }; $self }
sub restrict     { my $self = shift; my %copy = %$self; delete @copy{ &_words }; delete @$self{ keys %copy }; $self }
our $VERSION = '0.005';
