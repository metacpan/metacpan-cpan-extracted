##
# name:      Stardoc::Document::Pod
# abstract:  Stardoc Pod Generator
# author:    Ingy döt Net <ingy@cpan.org>
# copyright: 2011
# license:   perl

package Stardoc::Document::Pod;
use Mouse;

use Template::Toolkit::Simple;
use IO::All;

has module => (
    is => 'ro',
);

my $layout = [
    {name => 'encoding', requires => ['encoding']},
    {name => 'name', requires => ['name', 'abstract']},
    'synopsis',
    'description',
    'other',
    {name => 'see', requires => ['see']},
    {name => 'author', requires => ['author']},
    {name => 'license', requires => ['copyright']},
    {name => 'cut'},
];

sub format {
    my ($self) = @_;
    my $module = $self->module;
    my $data = $module->meta;
    my $pod = '';

    OUTER:
    for my $entry (@$layout) {
        my $name = ref($entry) ? $entry->{name} : $entry;
        if ($name eq 'other') {
            for my $section (@{$module->other}) {
                $pod .= "\n" if $pod;
                $pod .= $section->{text};
            }
        }
        elsif ($module->can($name) and $module->$name) {
            $pod .= "\n" if $pod;
            $pod .= $module->$name->{text};
        }
        elsif (ref $entry) {
            my $requires = $entry->{requires} || [];
            $data->{$_} or next OUTER for @$requires;
            $pod .= "\n" if $pod;
            $pod .= $self->format_template($name, $data);
        }
    }
    return $pod;
}

sub format_template {
    my ($self, $name, $data) = @_;
    my $template = eval {
        Stardoc::Pod::Templates->$name;
    } or next;
    tt->render(\$template, $data);
}

sub format_section {
}

package Stardoc::Pod::Templates;

use constant name => <<'...';
=head1 NAME

[% name %] - [% abstract %]
...

use constant status => <<'...';
=head1 STATUS

[% status %]
...

use constant encoding => <<'...';
=encoding [% encoding %]
...

use constant see => <<'...';
=head1 SEE ALSO

=over
[% FOR also = see %]
=item *

L<[% also %]>
[% END %]
=back
...

use constant author => <<'...';
=head1 AUTHOR

[% author.0.name %][% IF author.0.email %] <[% author.0.email %]>[% END %]
...

use constant license => <<'...';
=head1 COPYRIGHT AND LICENSE

Copyright (c) [% copyright %]. [% author.0.name %].

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
...

use constant cut => <<'...';
=cut
...

1;
