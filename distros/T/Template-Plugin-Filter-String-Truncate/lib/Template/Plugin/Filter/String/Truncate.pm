package Template::Plugin::Filter::String::Truncate;
$Template::Plugin::Filter::String::Truncate::VERSION = '0.03';
# ABSTRACT: String::Truncate filter for Template::Toolkit

use 5.006;
use strict;
use base 'Template::Plugin::Filter';
use String::Truncate;

our $DYNAMIC = 1;

sub init {
    my $self = shift;

    $self->install_filter('elide');

    return $self;
}

sub filter {
    my ($self, $text, $args, $conf) = @_;

    my ($len) = @$args;

    $text = String::Truncate::elide($text, $len, $conf);

    return $text;
}

1;

__END__

=pod

=head1 NAME

Template::Plugin::Filter::String::Truncate - String::Truncate filter for Template::Toolkit

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 [% USE Filter.String.Truncate %]

 # right side elide
 [% 'This is your brain' | elide(16) %]
 This is your ...

 # left side elide
 [% 'This is your brain' | elide(16, truncate => 'left') %]
 ...is your brain

 # middle elide
 [% 'This is your brain' | elide(16, truncate => 'middle') %]
 This is... brain

 # block syntax
 [% FILTER elide(16) -%]
 This is your brain
 [%- END %]
 THis is your ...

=head1 DESCRIPTION

This module is a Template Toolkit filter, which uses L<String::Truncate> to
truncate strings.

=for Pod::Coverage filter
init

=head1 SEE ALSO

L<String::Truncate>

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/template-plugin-filter-string-truncate>
and may be cloned from L<git://github.com/mschout/template-plugin-filter-string-truncate.git>

=head1 BUGS

Please report any bugs or feature requests to bug-template-plugin-filter-string-truncate@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Template-Plugin-Filter-String-Truncate

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
