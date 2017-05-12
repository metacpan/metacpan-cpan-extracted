package Poet::Moose;    ## no critic (Moose::RequireMakeImmutable)
$Poet::Moose::VERSION = '0.16';
use Moose                      ();
use MooseX::HasDefaults::RO    ();
use MooseX::StrictConstructor  ();
use Method::Signatures::Simple ();
use Moose::Exporter;
use strict;
use warnings;
Moose::Exporter->setup_import_methods( also => ['Moose'] );

sub init_meta {
    my $class     = shift;
    my %params    = @_;
    my $for_class = $params{for_class};
    Method::Signatures::Simple->import( into => $for_class );
    Moose->init_meta(@_);
    MooseX::StrictConstructor->import( { into => $for_class } );
    MooseX::HasDefaults::RO->import( { into => $for_class } );
}

1;

__END__

=pod

=head1 NAME

Poet::Moose - Poet Moose policies

=head1 SYNOPSIS

    # instead of use Moose;
    use Poet::Moose;

=head1 DESCRIPTION

Sets certain Moose behaviors for Poet's internal classes. Using this module is
equivalent to

    use Moose;
    use MooseX::HasDefaults::RO;
    use MooseX::StrictConstructor;
    use Method::Signatures::Simple;

=head1 SEE ALSO

L<Poet|Poet>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
