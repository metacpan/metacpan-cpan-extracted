package Pod::Abstract::Filter::sort;
use strict;
use warnings;

use Data::Dumper;

use base qw(Pod::Abstract::Filter);

=head1 NAME

Pod::Abstract::Filter::sort - alphabetically sort sub-sections within a
POD section.

=head1 USAGE

=over

=item *

Sort the METHODS section in the target document:

 paf sort -heading=METHODS Your::Module::Name

=item *

Sort as specified, where your document has:

 =head1 METHODS

 =for sorting

 {etc}

In this case the "=for sorting" label will cause all subheadings to be
sorted alphabetically, you don't need to specify a section.

 paf sort Your::Module::Name

=cut

our $VERSION = '0.26';

sub filter {
    my $self = shift;
    my $pa = shift;
    
    my $heading = $self->param('heading');
    $heading = 'METHODS' unless defined $heading;
    
    my @targets = $pa->select("//[\@heading =~ {$heading}]");
    my @spec_targets = $pa->select("//[/for =~ {^sorting}]");
    
    if($self->param('heading')) {
        push @targets, @spec_targets;
    } else {
        @targets = @spec_targets if @spec_targets;
    }
    
    foreach my $t (@targets) {
        my @ignore = $t->select("/[!\@heading]");
        my @to_sort = $t->select("/[\@heading]");
        
        $t->clear;
        $t->nest(@ignore);
        $t->nest(
            sort { 
                $a->param('heading')->pod cmp
                $b->param('heading')->pod
            } @to_sort
            );
    }
    return $pa;
}

=head1 AUTHOR

Ben Lilburne <bnej80@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2025 Ben Lilburne

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
