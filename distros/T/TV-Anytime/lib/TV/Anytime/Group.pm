package TV::Anytime::Group;
use strict;
use warnings;
use base 'Class::Accessor::Chained::Fast';
__PACKAGE__->mk_accessors(qw(id type title members_ref parents_ref));

sub members {
  my $self = shift;
  return @{$self->members_ref || []};
}

sub parents {
  my $self = shift;
  return @{$self->parents_ref || []};
}

sub is_series {
  my $self = shift;
  return $self->type eq 'series' ? 1 : 0;
}

1;

__END__

=head1 NAME

TV::Anytime::Group - Represent a program group

=head1 SYNOPSIS

  print "    ID: " . $group->id . "\n";
  print " Title: " . $group->title . "\n";
  print "Series: " . $group->is_series . "\n";
  print "        $_\n" foreach $group->members;
  print "    isa $_\n" foreach $group->parents;

=head1 DESCRIPTION

The L<TV::Anytime::Group> represents a program group, such 
as categorisation of programs or a series.

=head1 METHODS

head2 id

This returns the ID of the group:

  print "    ID: " . $group->id . "\n";

=head2 members

This returns a list of the member IDs of the group:

  print "        $_\n" foreach $group->members;

=head2 parents

This returns a list of the parent IDs of the group:

  print "    isa $_\n" foreach $group->parents;

=head2 title

This returns the title of the group:

  print " Title: " . $group->title . "\n";

=head2 is_series

This returns whether the group is a series (or instead a group of groups):

  print "Series: " . $group->is_series . "\n";

=head1 SEE ALSO 

L<TV::Anytime>

=head1 BUGS                                                   

Please report any bugs or feature requests to                                   
C<bug-TV-Anytime@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  

=head1 AUTHOR

Leon Brocard C<acme@astray.com>

=head1 LICENCE AND COPYRIGHT                                                    

Copyright (c) 2005, Leon Brocard C<acme@astray.com>. All rights reserved.

This module is free software; you can redistribute it and/or                    
modify it under the same terms as Perl itself.       