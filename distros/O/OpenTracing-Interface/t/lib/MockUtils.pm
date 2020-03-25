package MockUtils;

=head1 DESCRIPTION

This module provides two convenient subroutines for Types test

=cut

use strict;
use warnings;

use Exporter 'import'; # gives you Exporter's import() method directly
our @EXPORT_OK= qw/build_mock_object build_mock_missing_object/;

sub build_mock_object {
    my %params = @_;
    
    my $mocked_class = "Mocked::Class::" . $params{class_name};
    
    no strict qw/refs/;
    
    foreach my $method_name ( @{$params{class_methods}} ) {
        my $mocked_method = $mocked_class . '::' . $method_name;
        
        *{ $mocked_method} = sub {;} ;
    }
    
    bless {}, $mocked_class 
}



sub build_mock_missing_object {
    my %params = @_;
    
    my $remaining_methods = _remove_from_list(
        $params{class_methods}, $params{missing_method}
    );
    
    return build_mock_object(
        class_name    => $params{class_name} . '::' . $params{missing_method},
        class_methods => $remaining_methods,
    )
}



sub _remove_from_list {
    my ($list, $item ) = @_;
    
    my @remaining = grep {
        $_ ne $item
    } @$list;
    
    return \@remaining
}



1;