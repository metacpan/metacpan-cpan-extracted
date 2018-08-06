package Pod::Knit::Plugin::Abstract;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: add the NAME section to the POD
$Pod::Knit::Plugin::Abstract::VERSION = '0.0.1';

use strict;
use warnings;

use Log::Any '$log', prefix => 'Knit::Abstract: ';

use Moose;

extends 'Pod::Knit::Plugin'; 
with 'Pod::Knit::DOM::Mojo';

use experimental qw/
    signatures
    postderef
/;

sub munge($self,$doc) {

    $log->debug( 'transforming' );

    my ( $package, $abstract );
    for ( $doc->content ) {
        no warnings 'uninitialized';
        ( $package )  = /^ \s* package \s+ (\S+);/mx;
        ( $abstract ) = /^ \s* \# \s* ABSTRACT: \s* (.*?) $/mx;
    }

    no warnings 'uninitialized';

    $doc->find_or_create_section( 'NAME', 1, undef, 
        para => join ' - ', grep { $_ } $package, $abstract 
    );

};




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Knit::Plugin::Abstract - add the NAME section to the POD

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

In F<knit.yml>

    plugins
        - ABSTRACT 

=head1 DESCRIPTION

Extracts the name and abstract from the file and add them to the POD.

    package My::Foo;
    # ABSTRACT: does the thing

will generate

    =head1 NAME 
    
    My::Foo - does the thing

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full text of the license can be found in the F<LICENSE> file included in
this distribution.

=cut

