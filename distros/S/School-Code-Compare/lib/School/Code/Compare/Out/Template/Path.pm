package School::Code::Compare::Out::Template::Path;
# ABSTRACT: pseudo class to help locating the path of the template files
$School::Code::Compare::Out::Template::Path::VERSION = '0.101';
use strict;
use warnings;

sub get {
    if (__FILE__ =~ m!^(.*)/[^/]+$!) {
        return $1;
    }
    else {
        die "Problem in path detection for templates";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

School::Code::Compare::Out::Template::Path - pseudo class to help locating the path of the template files

=head1 VERSION

version 0.101

=head1 AUTHOR

Boris Däppen <bdaeppen.perl@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Boris Däppen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
